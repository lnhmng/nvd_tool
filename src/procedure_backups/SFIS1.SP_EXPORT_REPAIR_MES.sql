PROCEDURE sp_export_repair_mes (
    p_lastTime    IN  VARCHAR2,         -- 'YYYYMMDDHH24MI'
    p_currentTime IN  VARCHAR2,         -- 'YYYYMMDDHH24MI'
    p_serial      IN  VARCHAR2 DEFAULT NULL,  -- debug theo SN (có thể NULL)
    o_cur         OUT SYS_REFCURSOR
) AS
    v_start_dt DATE;
    v_end_dt   DATE;
BEGIN
    v_start_dt := TO_DATE(p_lastTime, 'YYYYMMDDHH24MI');
    v_end_dt   := TO_DATE(p_currentTime, 'YYYYMMDDHH24MI');

    OPEN o_cur FOR
    WITH
    /* =========================================================
     * 1) BASE REPAIR (lọc ngay theo time window + optional SN)
     * ========================================================= */
    c_base AS (
        SELECT /*+ MATERIALIZE */
            c.ROWID AS c_rowid,
            c.serial_number,
            c.mo_number,
            c.model_name AS nvpn,
            c.test_line,
            c.test_station,
            c.repair_station,
            c.test_time,
            c.repair_time,
            TRIM(c.test_code)    AS test_code,
            TRIM(c.error_degree) AS error_degree,
            c.reason_code,
            c.repairer,
            c.section_flag,
            c.old_hhpn,
            c.supplier,
            c.supplier_model,
            c.date_code AS new_datecode,
            c.old_vendor_code,
            c.old_date_code,
            c.old_lot_no,
            c.lot_no,
            c.action_code,
            CASE
                WHEN c.error_item_code IS NULL THEN NULL
                WHEN TRIM(c.error_item_code) IN ('', 'N/A') THEN NULL
                ELSE TRIM(c.error_item_code)
            END AS error_item_code
        FROM sfism4.r_repair_t c
        WHERE c.repairer IS NOT NULL
          AND c.repair_time >= v_start_dt
          AND c.repair_time <  v_end_dt
          AND (p_serial IS NULL OR c.serial_number = p_serial)
    ),

    /* =========================================================
     * 2) STATION GROUP (union 2 bảng, lọc theo station xuất hiện)
     * ========================================================= */
    stn_names AS (
        SELECT DISTINCT test_station AS station_name FROM c_base WHERE test_station IS NOT NULL
        UNION
        SELECT DISTINCT repair_station FROM c_base WHERE repair_station IS NOT NULL
    ),
    station_grp_raw AS (
        SELECT station_name, group_name, 1 AS src
        FROM sfis1.c_station_config_t
        WHERE station_name IN (SELECT station_name FROM stn_names)
        UNION ALL
        SELECT station_name, group_name, 2 AS src
        FROM sfis1.c_ict_station_t
        WHERE station_name IN (SELECT station_name FROM stn_names)
    ),
    station_grp AS (
        SELECT station_name,
               MAX(group_name) KEEP (DENSE_RANK FIRST ORDER BY src) AS group_name
        FROM station_grp_raw
        GROUP BY station_name
    ),
    stn AS (
        SELECT
            cb.c_rowid,
            CASE
                WHEN sg1.group_name IS NULL OR sg1.group_name = '' THEN cb.test_station
                ELSE sg1.group_name
            END AS test_station_grp,
            CASE
                WHEN cb.repair_station IS NULL OR cb.repair_station = '' THEN ''
                ELSE COALESCE(NULLIF(sg2.group_name,''), cb.repair_station)
            END AS repair_station_grp
        FROM c_base cb
        LEFT JOIN station_grp sg1 ON sg1.station_name = cb.test_station
        LEFT JOIN station_grp sg2 ON sg2.station_name = cb.repair_station
    ),

    /* =========================================================
     * 3) STATION NV MAP
     * ========================================================= */
    station_map_test AS (
        SELECT /*+ MATERIALIZE */ station_sfc, station_nv
        FROM sfis1.c_station_mapping_t
        WHERE area = 'F20'
          AND station_sfc IN (SELECT DISTINCT test_station_grp FROM stn WHERE test_station_grp IS NOT NULL)
    ),
    repair_keys AS (
        SELECT DISTINCT repair_station_grp
        FROM stn
        WHERE repair_station_grp IS NOT NULL AND repair_station_grp <> ''
    ),
    station_map_repair AS (
        SELECT
            r.repair_station_grp,
            MIN(m.station_nv) KEEP (DENSE_RANK FIRST ORDER BY m.station_sfc) AS station_nv
        FROM repair_keys r
        JOIN sfis1.c_station_mapping_t m
          ON m.area = 'F20'
         AND m.station_sfc LIKE r.repair_station_grp || '%'
        GROUP BY r.repair_station_grp
    ),

    /* =========================================================
     * 4) WIP + EMP (lọc theo c_base)
     * ========================================================= */
    wip AS (
        SELECT serial_number, MAX(version_code) AS version_code
        FROM sfism4.r_wip_tracking_t
        WHERE serial_number IN (SELECT DISTINCT serial_number FROM c_base)
          AND UPPER(customer_no) LIKE 'NV%'
        GROUP BY serial_number
    ),
    emp AS (
        SELECT emp_name, MAX(emp_no) AS emp_no
        FROM sfis1.c_emp_desc_t
        WHERE emp_name IN (SELECT DISTINCT repairer FROM c_base WHERE repairer IS NOT NULL)
        GROUP BY emp_name
    ),

    /* =========================================================
     * 5) REASON MAP
     * ========================================================= */
    reason_map AS (
        SELECT
            cb.c_rowid,
            NVL(cb.reason_code,'') AS reasoncode,
            NVL(m1.reason_desc,'') AS reason_desc,
            NVL(m1.reason_desc2,'') AS reason_desc2,
            NVL(m1.component_gpu,0) AS component_gpu,
            NVL(m1.component_mem,0) AS component_mem,
            NVL(m1.component_others,0) AS component_others,
            NVL(m1.termination,0) AS termination,
            NVL(m1.placement,0) AS placement,
            NVL(m1.assembly,0) AS assembly,
            NVL(m1.design,0) AS design,
            NVL(m1.ntf,0) AS ntf
        FROM c_base cb
        LEFT JOIN sfis1.c_reason_code_t_dpmo m1
          ON m1.reason_code = cb.reason_code
    ),

    /* =========================================================
     * 6) ERROR DESCRIPTION (ưu tiên exact -> '_' -> bỏ 'E' -> EX last3)
     *    KHÔNG đổi error_code output (vẫn cb.test_code)
     * ========================================================= */
    err_map AS (
        SELECT
            cb.c_rowid,
            NVL(cb.test_code,'') AS errorcode_prod,
            COALESCE(
                NULLIF(e0.error_desc2,''), NULLIF(e0.error_desc,''),
                NULLIF(e1.error_desc2,''), NULLIF(e1.error_desc,''),
                NULLIF(e2.error_desc2,''), NULLIF(e2.error_desc,''),
                NULLIF(ex.error_desc2,''), NULLIF(ex.error_desc,''),
                ''
            ) AS error_desc
        FROM c_base cb
        LEFT JOIN sfis1.c_error_code_t e0
          ON TRIM(cb.test_code) = TRIM(e0.error_code)
        LEFT JOIN sfis1.c_error_code_t e1
          ON INSTR(TRIM(cb.test_code), '_') > 0
         AND SUBSTR(TRIM(cb.test_code), 1, INSTR(TRIM(cb.test_code), '_') - 1) = TRIM(e1.error_code)
        LEFT JOIN sfis1.c_error_code_t e2
          ON SUBSTR(TRIM(cb.test_code), 1, 1) = 'E'
         AND SUBSTR(TRIM(cb.test_code), 2) = TRIM(e2.error_code)
        LEFT JOIN (
            SELECT SUBSTR(error_code, -3) AS last3, error_desc, error_desc2
            FROM sfis1.c_error_code_t
            WHERE error_code LIKE 'EXXXXXXXXX%'
        ) ex
          ON LENGTH(TRIM(cb.test_code)) = 13
         AND SUBSTR(TRIM(cb.test_code), -3) = ex.last3
    ),

    /* =========================================================
     * 7) PKG_DETAIL match theo error_item_code == location token
     * ========================================================= */
    pkg_detail_match AS (
        SELECT /*+ MATERIALIZE */
            cb.c_rowid,
            p.ROWID AS p_rowid,
            p.pkg_id,
            CASE
                WHEN p.pkg_id IS NULL THEN NULL
                WHEN INSTR(p.pkg_id, '^') > 0 THEN SUBSTR(p.pkg_id, 1, INSTR(p.pkg_id, '^') - 1)
                ELSE p.pkg_id
            END AS pkg_id_base,
            p.feeder_number,
            CASE
                WHEN p.feeder_number IS NULL THEN NULL
                WHEN INSTR(p.feeder_number, '-', -1) > 0
                    THEN SUBSTR(p.feeder_number, INSTR(p.feeder_number, '-', -1) + 1)
                ELSE TRIM(p.feeder_number)
            END AS feeder_key,
            p.in_station_time
        FROM c_base cb
        JOIN smtinfo.r_sn_pkg_detail_t p
          ON p.serial_number = cb.serial_number
         AND cb.error_item_code IS NOT NULL
         AND INSTR(
                ',' || UPPER(REPLACE(p.location,' ','')) || ',',
                ',' || UPPER(cb.error_item_code) || ','
             ) > 0
    ),

    /* pick 1 pkg_detail gần test_time nhất, ưu tiên <= test_time */
    pkg_detail_pick AS (
        SELECT *
        FROM (
            SELECT
                pdm.*,
                cb.test_time,
                ROW_NUMBER() OVER(
                    PARTITION BY pdm.c_rowid
                    ORDER BY
                        CASE
                            WHEN pdm.in_station_time <= cb.test_time THEN 0 ELSE 1
                        END,
                        ABS((pdm.in_station_time - cb.test_time) * 86400),
                        pdm.in_station_time DESC,
                        pdm.p_rowid DESC
                ) rn
            FROM pkg_detail_match pdm
            JOIN c_base cb ON cb.c_rowid = pdm.c_rowid
        )
        WHERE rn = 1
    ),

    /* =========================================================
     * 8) SMT PKGID LOG pick (trail_no/feeder_no). Nếu log NULL -> fallback pkg_detail
     * ========================================================= */
    pkgid_log_pick AS (
        SELECT *
        FROM (
            SELECT
                pdp.c_rowid,
                pl.pkg_id,
                pl.feeder_no,
                pl.trail_no,
                pl.begin_time,
                ROW_NUMBER() OVER(
                    PARTITION BY pdp.c_rowid
                    ORDER BY pl.begin_time DESC NULLS LAST, pl.ROWID DESC
                ) rn
            FROM pkg_detail_pick pdp
            LEFT JOIN smtinfo.r_smt_pkgid_log_t pl
              ON (   TRIM(pl.pkg_id) = TRIM(pdp.pkg_id)
                  OR TRIM(pl.pkg_id) = TRIM(pdp.pkg_id_base)
                  OR TRIM(pl.pkg_id) LIKE TRIM(pdp.pkg_id_base) || '^%')
        )
        WHERE rn = 1
    ),

    pkg_pick AS (
        SELECT
            cb.c_rowid,
            /* feeder_id: ưu tiên log.feeder_no, fallback pkg_detail.feeder_number */
            COALESCE(NULLIF(TRIM(pl.feeder_no), ''),
                     NULLIF(TRIM(pdp.feeder_number), ''),
                     '') AS feeder_id,

            /* track_no: ưu tiên log.trail_no; nếu NULL -> feeder_key (xxxL) */
            COALESCE(NULLIF(TRIM(pl.trail_no), ''),
                     NULLIF(TRIM(pdp.feeder_key), ''),
                     '') AS track_no
        FROM c_base cb
        LEFT JOIN pkg_detail_pick pdp ON pdp.c_rowid = cb.c_rowid
        LEFT JOIN pkgid_log_pick  pl  ON pl.c_rowid  = cb.c_rowid
    ),

    /* =========================================================
     * 9) FINAL Z
     * ========================================================= */
    z AS (
        SELECT
            cb.serial_number AS nvsn,
            cb.mo_number,
            cb.nvpn,
            cb.test_line,
            cb.old_hhpn,
            w.version_code,
            mt.station_nv AS station,
            cb.test_time   AS fa_start_dt,
            cb.repair_time AS fa_end_dt,
            em.errorcode_prod,
            em.error_desc AS errorcode_description,
            cb.error_item_code AS flocation,
            rm.reasoncode,
            rm.reason_desc,
            rm.reason_desc2,
            CASE
                WHEN e.emp_no IS NULL OR e.emp_no = '' THEN cb.repairer
                ELSE e.emp_no
            END AS empid,
            pp.track_no,
            pp.feeder_id,
            cb.section_flag,
            cb.action_code,
            cb.supplier,
            cb.supplier_model,
            cb.new_datecode,
            cb.old_vendor_code,
            cb.old_date_code,
            cb.old_lot_no,
            cb.lot_no
        FROM c_base cb
        LEFT JOIN stn st              ON st.c_rowid = cb.c_rowid
        LEFT JOIN station_map_test mt ON mt.station_sfc = st.test_station_grp
        LEFT JOIN wip w               ON w.serial_number = cb.serial_number
        LEFT JOIN emp e               ON e.emp_name = cb.repairer
        LEFT JOIN reason_map rm       ON rm.c_rowid = cb.c_rowid
        LEFT JOIN err_map em          ON em.c_rowid = cb.c_rowid
        LEFT JOIN pkg_pick pp         ON pp.c_rowid = cb.c_rowid
    )

    /* =========================================================
     * 10) OUTPUT
     * ========================================================= */
    SELECT
        'QuangChau' AS site,
        'NVD' AS business_unit_name,
        'CNV1' AS plant_code,
        'L6' AS level_grade,
        z.test_line AS line_name,
        CASE
            WHEN TO_NUMBER(TO_CHAR(NVL(z.fa_end_dt, z.fa_start_dt), 'HH24')) >= 8
             AND TO_NUMBER(TO_CHAR(NVL(z.fa_end_dt, z.fa_start_dt), 'HH24')) < 20
            THEN 'SHIFT1' ELSE 'SHIFT2'
        END AS shift,
        z.mo_number AS workorder_number,
        '' AS rma_number,
        z.nvpn AS model_name,
        NVL(z.version_code,'') AS model_rev,
        '' AS product_life_cycle,
        'NVIDIA' AS customer,
        z.old_hhpn AS customer_partnumber,
        '' AS customer_rev,
        z.nvsn AS device_serial_number,
        z.station AS customer_operation_name,
        z.station AS operation_name,

        z.track_no,
        z.feeder_id,

        z.empid AS operator,
        TO_CHAR(z.fa_start_dt, 'YYYY-MM-DD HH24:MI:SS') AS operation_start_datetime,
        TO_CHAR(z.fa_start_dt - NUMTODSINTERVAL(7,'HOUR'), 'YYYY-MM-DD HH24:MI:SS') AS operation_start_datetime_utc,
        TO_CHAR(z.fa_end_dt,   'YYYY-MM-DD HH24:MI:SS') AS operation_end_datetime,
        TO_CHAR(z.fa_end_dt   - NUMTODSINTERVAL(7,'HOUR'), 'YYYY-MM-DD HH24:MI:SS') AS operation_end_datetime_utc,

        z.errorcode_prod AS error_code,
        z.errorcode_description AS error_description,
        z.errorcode_description AS error_description2,

        NVL(z.flocation,'') AS error_item,

        z.reasoncode AS repair_reasoncode,
        z.reason_desc AS repair_reasoncode_description,
        z.reason_desc2 AS repair_reasoncode_description2,

        CASE WHEN NVL(z.section_flag,'') = '' THEN 'P' ELSE 'F' END AS repair_status,

        /* giữ chỗ các field RA008 nếu bạn cần */
        CASE WHEN z.action_code = 'RA008' THEN z.old_hhpn ELSE '' END AS remove_partnumber,
        CASE WHEN z.action_code = 'RA008' THEN z.old_vendor_code ELSE '' END AS remove_vendor_name,
        CASE WHEN z.action_code = 'RA008' THEN z.old_lot_no ELSE '' END AS remove_packageid,
        CASE WHEN z.action_code = 'RA008' THEN z.old_date_code ELSE '' END AS remove_datecode,

        CASE WHEN z.action_code = 'RA008' THEN z.supplier ELSE '' END AS add_partnumber,
        CASE WHEN z.action_code = 'RA008' THEN z.supplier_model ELSE '' END AS add_vendor_part,
        CASE WHEN z.action_code = 'RA008' THEN z.new_datecode ELSE '' END AS add_datecode,
        CASE WHEN z.action_code = 'RA008' THEN z.lot_no ELSE '' END AS add_packageid,

        '7' AS utc_zone,
        'QuangChau_SFC' AS add_user,
        TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS') AS add_date,
        TO_CHAR(SYSDATE - NUMTODSINTERVAL(7,'HOUR'),'YYYY-MM-DD HH24:MI:SS') AS add_date_utc,
        'N' AS data_status
    FROM z
    ORDER BY z.fa_start_dt, z.fa_end_dt;

END sp_export_repair_mes;
/
