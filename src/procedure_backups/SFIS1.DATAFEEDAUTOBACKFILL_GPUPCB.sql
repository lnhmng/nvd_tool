PROCEDURE       DatafeedAutoBackfill_GpuPcb
IS
    v_start_date DATE;
    v_end_date   DATE;
BEGIN
    v_start_date := TRUNC(SYSDATE) - 8;
    v_end_date := TRUNC(SYSDATE) - 1;
    --Backfill GPU 2024-07-30
    INSERT INTO SFISM4.R_DATAFEED_SENDING_MATERIAL_T
        (file_log_name, NVSN, MACHINE, START_TIME, COMP_PN, scomp_pn, comp_type, datecode, lot, vendor, LOCATION, QTY, nvpn, comp_sn, MFG_PN, MFG_SN, COMP_CSN, PLANNING_NVPN, COO,COMP_CPN, EOL)
    SELECT 'backfill' AS file_log_name, z.*
    FROM (
        SELECT *
        FROM (
            SELECT
                smt.nvsn AS nvsn,
                smt.machine AS machine,
                 TO_CHAR(smt.start_time, 'yyyy-mm-dd HH24:mi:ss') AS start_time,
                smt.comp_pn AS comp_pn,
                smt.scomp_pn AS scomp_pn,
                NVL(smt.comp_type, 'N/A') AS comp_type,
                NVL(smt.datecode, 'N/A') AS datecode,
                smt.lot AS lot,
                smt.vendor AS VENDOR,
                smt.location AS LOCATION,
                1 AS QTY,
               smt.nvpn AS NVPN,
                c.barcode AS COMP_SN,
                smt.mfg_pn AS MFG_PN,
                smt.mfg_sn AS MFG_SN,
                smt.comp_csn AS COMP_CSN,
                'N/A' AS PLANNING_NVPN,
                'N/A' AS COO,
                'N/A' AS COMP_CPN,
                'EOL' AS EOL
            FROM sfism4.r_material_t smt
            LEFT JOIN sfism4.r_aoi_memory_t c ON smt.nvsn = c.serial_number AND smt.location = c.location where c.barcode is not null
        )
        WHERE nvsn IN (
            SELECT a.serial_number
            FROM (
                SELECT DISTINCT serial_number
                FROM SFISM4.R_sn_detail_t
                WHERE serial_number LIKE '1%'
                AND group_name = 'AVI'
                AND SUBSTR(model_name, 6, 1) = 'G'
                AND in_station_time >= v_start_date
                AND in_station_time < v_end_date
            ) a
            LEFT JOIN (
                SELECT nvsn, comp_sn
                FROM SFISM4.R_DATAFEED_SENDING_material_T
                WHERE comp_type IN ('GPU', 'CPU')
                AND comp_sn <> 'N/A'
            ) b ON a.serial_number = b.nvsn
            WHERE b.comp_sn IS NULL
        )
        AND location LIKE 'G%'
    ) z;

    COMMIT;
    --Backfill GPU 2024-07-30
      --Backfill PCB 2024-07-30
      INSERT INTO SFISM4.R_DATAFEED_SENDING_MATERIAL_T
        (file_log_name, NVSN, MACHINE, START_TIME, COMP_PN, scomp_pn, comp_type, datecode, lot, vendor, LOCATION, QTY, nvpn, comp_sn, MFG_PN, MFG_SN, COMP_CSN, PLANNING_NVPN, COO,COMP_CPN, EOL)
    SELECT 'backfill' AS file_log_name, z.*
    FROM (
            SELECT 
                a.serial_number AS nvsn,
                'PCB_OPEN' AS machine,
                TO_CHAR(a.in_station_time, 'yyyy-mm-dd HH24:mi:ss') AS start_time,
                c.hh_pn AS comp_pn,
                c.mfg_pn AS scomp_pn,
                NVL(comp.description, 'N/A') AS comp_type,
                c.date_code AS datecode,
                c.lot_no AS lot,
                NVL(M1.VENDOR_NAME, M.VENDOR_NAME) AS VENDOR,
                'N/A' AS LOCATION,
                1 AS QTY,
              e.model_name AS NVPN,
                NVL(b.vendor_info, 'N/A') AS COMP_SN,
                'N/A' AS MFG_PN,
                'N/A' AS MFG_SN,
                'N/A' AS COMP_CSN,
               'N/A' AS PLANNING_NVPN,
                'N/A' AS COO,
                'N/A' AS COMP_CPN,
                'EOL' AS EOL
            FROM (
                SELECT serial_number, pkg_id, in_station_time
                FROM SFISM4.r_pcb_datecode_t
                WHERE serial_number IN (
                    SELECT serial_number
                    FROM (
                        SELECT DISTINCT serial_number
                        FROM SFISM4.R_sn_detail_t
                        WHERE serial_number LIKE '1%'
                        AND group_name = 'AVI'
                        AND SUBSTR(model_name, 6, 1) = 'G'
                        AND in_station_time >= v_start_date
                        AND in_station_time < v_end_date
                    ) x
                    LEFT JOIN (
                        SELECT nvsn, comp_sn
                        FROM SFISM4.R_DATAFEED_SENDING_material_T
                        WHERE comp_type = 'PCB'
                        AND comp_sn <> 'N/A'
                    ) y ON x.serial_number = y.nvsn
                    WHERE y.comp_sn IS NULL
                )
            ) a
            LEFT JOIN SFISM4.r_sn_vendor_info b ON a.serial_number = b.serial_number
            LEFT JOIN IQC.r_kpn_incoming_t c ON c.pkg_id = a.pkg_id
            LEFT JOIN SFIS1.C_COMP_TYPE comp ON c.HH_PN LIKE comp.COMPONENT_CODE || '%'
            LEFT JOIN sfism4.r_wip_tracking_t e ON a.serial_number = e.serial_number
            LEFT JOIN IQC.C_VENDOR_CODE_T M ON M.VENDOR_CODE = c.RESERVE3
            LEFT JOIN IQC.C_VENDOR_CODE_T M1 ON M1.VENDOR_CODE = c.HH_PN 
    ) z where  z.COMP_SN <>'N/A';
    commit;
    --Backfill PCB 2024-07-30
END;