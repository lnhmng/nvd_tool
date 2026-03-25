PROCEDURE             sp_upload_cwo (
   i_transtype   IN     VARCHAR2,
   o_res            OUT VARCHAR2,
   cwolist          OUT sys_refcursor
)
IS
   v_count      NUMBER;
   v_batch_no   VARCHAR2 (35);
BEGIN
   IF i_transtype = 'CWO'
   THEN
      SELECT   SUBSTR (TO_CHAR (SYSTIMESTAMP, 'yyyymmddhh24missffffff'),
                       1,
                       20)
        INTO   v_batch_no
        FROM   DUAL;

      IF (fn_getcontrolvalue ('ALL', 'SPECIAL_SAP_WO_DONOT_DO_CWO', 'N') =
             'Y')
      THEN
         -- add by JESSE 20100927  begin
         UPDATE   sfism4.wip_d_cwo_sn
            SET   cwo_batch = v_batch_no
          WHERE   cwo_flag = 0 AND cwo_batch = 'N/A' AND ROWNUM <= 20000;

         -- add by JESSE 20100927  end

         -- add by zong-long 2013.3.12 begin
         UPDATE   sfism4.wip_d_cwo_sn a
            SET   cwo_batch = v_batch_no
          WHERE   EXISTS
                     (SELECT   PALLET_NO
                        FROM   sfism4.wip_d_cwo_sn b
                       WHERE       b.cwo_batch = v_batch_no
                               AND a.pallet_no = b.pallet_no
                               AND b.INSTORE_SCAN_TYPE = 'PALLET'
                               AND a.cwo_batch = 'N/A');

         UPDATE   sfism4.wip_d_cwo_sn a
            SET   cwo_batch = v_batch_no
          WHERE   EXISTS
                     (SELECT   CARTON_NO
                        FROM   sfism4.wip_d_cwo_sn b
                       WHERE       b.cwo_batch = v_batch_no
                               AND a.CARTON_NO = b.CARTON_NO
                               AND b.INSTORE_SCAN_TYPE = 'CARTON'
                               AND a.cwo_batch = 'N/A');

         -- add by zong-long 2013.3.12 end

         UPDATE   sfism4.wip_d_cwo_sn
            SET   cwo_flag = 8, updater = 'SYSTEM', update_date = SYSDATE
          WHERE   erp_wo IN
                        (SELECT   DISTINCT a.erp_wo
                           FROM   sfism4.wip_d_cwo_sn a,
                                  sfism4.wip_d_wo_master b,
                                  sfism4.R_MO_BASE_T c
                          WHERE       a.erp_wo = b.work_order
                                  AND b.WORK_ORDER = c.order_no
                                  AND b.print_flag = 'X'
                                  AND a.cwo_batch = v_batch_no)
                  AND cwo_flag = 0
                  --AND cwo_batch = 'N/A';
                  AND cwo_batch = v_batch_no;

         --modify by JESSE 20100927  AND cwo_batch = 'N/A' ->cwo_batch = v_batch_no

         UPDATE   sfism4.wip_d_cwo_sn
            SET   cwo_flag = 1, --cwo_batch = v_batch_no,
                                updater = 'SYSTEM', update_date = SYSDATE
          WHERE   cwo_flag = 0 --AND cwo_batch = 'N/A'
                  AND cwo_batch = v_batch_no ;--modify by JESSE 20100927  AND cwo_batch = 'N/A' ->cwo_batch = v_batch_no
                  --AND ROWNUM <= 20000;  --delete by zong-long 2013.3.12
      ELSE
         UPDATE   sfism4.wip_d_cwo_sn
            SET   cwo_flag = 1,
                  cwo_batch = v_batch_no,
                  updater = 'SYSTEM',
                  update_date = SYSDATE
          WHERE   cwo_flag = 0 AND cwo_batch = 'N/A' AND ROWNUM <= 20000;

         -- add by zong-long 2013.3.12 begin
         UPDATE   sfism4.wip_d_cwo_sn a
            SET   cwo_flag = 1,
                  cwo_batch = v_batch_no,
                  updater = 'SYSTEM',
                  update_date = SYSDATE
          WHERE   EXISTS
                     (SELECT   PALLET_NO
                        FROM   sfism4.wip_d_cwo_sn b
                       WHERE       b.cwo_batch = v_batch_no
                               AND a.pallet_no = b.pallet_no
                               AND b.INSTORE_SCAN_TYPE = 'PALLET'
                               AND a.cwo_batch = 'N/A');

         UPDATE   sfism4.wip_d_cwo_sn a
            SET   cwo_flag = 1,
                  cwo_batch = v_batch_no,
                  updater = 'SYSTEM',
                  update_date = SYSDATE
          WHERE   EXISTS
                     (SELECT   CARTON_NO
                        FROM   sfism4.wip_d_cwo_sn b
                       WHERE       b.cwo_batch = v_batch_no
                               AND a.CARTON_NO = b.CARTON_NO
                               AND b.INSTORE_SCAN_TYPE = 'CARTON'
                               AND a.cwo_batch = 'N/A');
      -- add by zong-long 2013.3.12 end

      END IF;

      --CWO by Pallet begin

      /*  OPEN cwolist FOR
        SELECT   plant_code, erp_wo, part_no, cpo_no, pallet_no, cwo_type,
                 COUNT (pallet_no) AS qty
            FROM sfism4.wip_d_cwo_sn
           WHERE cwo_batch = v_batch_no
        GROUP BY plant_code, erp_wo, part_no, cpo_no, cwo_type, pallet_no;

        INSERT INTO sfism4.wip_d_cwo_partlist
                    (plant_code, erp_wo, part_no, qty, cwo_batch, cpo_no, pallet_no,
                     creator, cwo_type)
           SELECT   plant_code, erp_wo, part_no, COUNT (pallet_no), cwo_batch, cpo_no,
                    pallet_no, 'SYSTEM', cwo_type
               FROM sfism4.wip_d_cwo_sn
              WHERE cwo_batch = v_batch_no
           GROUP BY plant_code,
                    erp_wo,
                    part_no,
                    cwo_batch,
                    cpo_no,
                    pallet_no,
                    cwo_type;
         */
      --WO by Pallet end

      --CWO by sysserialno begin
      --**************?? WHID,cwo_batch,INSTORE_SCAN_TYPE ??????*******Modify by Hugo 2010/7/27 begin *********************************
      OPEN cwolist FOR
           SELECT   plant_code,
                    erp_wo,
                    part_no,
                    cpo_no,
                    sysserialno AS pallet_no,
                    cwo_type,
                    COUNT (sysserialno) AS qty,
                    whid,
                    cwo_batch,
                    instore_scan_type
             FROM   sfism4.wip_d_cwo_sn
            WHERE       instore_scan_type = 'PPID'
                    AND cwo_batch = v_batch_no
                    AND cwo_flag = 1
         GROUP BY   plant_code,
                    erp_wo,
                    part_no,
                    cpo_no,
                    cwo_type,
                    sysserialno,
                    whid,
                    cwo_batch,
                    instore_scan_type
         UNION
           SELECT   plant_code,
                    erp_wo,
                    part_no,
                    cpo_no,
                    pallet_no AS pallet_no,
                    cwo_type,
                    COUNT (sysserialno) AS qty,
                    whid,
                    cwo_batch,
                    instore_scan_type
             FROM   sfism4.wip_d_cwo_sn
            WHERE       instore_scan_type = 'PALLET'
                    AND cwo_batch = v_batch_no
                    AND cwo_flag = 1
         GROUP BY   plant_code,
                    erp_wo,
                    part_no,
                    cpo_no,
                    cwo_type,
                    pallet_no,
                    whid,
                    cwo_batch,
                    instore_scan_type
         UNION
           SELECT   plant_code,
                    erp_wo,
                    part_no,
                    cpo_no,
                    carton_no AS pallet_no,
                    cwo_type,
                    COUNT (sysserialno) AS qty,
                    whid,
                    cwo_batch,
                    instore_scan_type
             FROM   sfism4.wip_d_cwo_sn
            WHERE       instore_scan_type IN ('CARTON', 'POCARTON')
                    AND cwo_batch = v_batch_no
                    AND cwo_flag = 1
         GROUP BY   plant_code,
                    erp_wo,
                    part_no,
                    cpo_no,
                    cwo_type,
                    carton_no,
                    whid,
                    cwo_batch,
                    instore_scan_type;

      --*************??WHID,cwo_batch,INSTORE_SCAN_TYPE ??????*******odify by Hugo 2010/7/27 end *****************************************
      INSERT INTO sfism4.wip_d_cwo_partlist (plant_code,
                                             erp_wo,
                                             part_no,
                                             qty,
                                             cwo_batch,
                                             cpo_no,
                                             pallet_no,
                                             creator,
                                             cwo_type,
                                             instore_scan_type,
                                             whid)
           SELECT   plant_code,
                    erp_wo,
                    part_no,
                    COUNT (sysserialno),
                    cwo_batch,
                    cpo_no,
                    sysserialno,
                    'SYSTEM',
                    cwo_type,
                    instore_scan_type,
                    whid
             FROM   sfism4.wip_d_cwo_sn
            WHERE       instore_scan_type = 'PPID'
                    AND cwo_batch = v_batch_no
                    AND cwo_flag = 1
         GROUP BY   plant_code,
                    erp_wo,
                    part_no,
                    cwo_batch,
                    cpo_no,
                    sysserialno,
                    cwo_type,
                    instore_scan_type,
                    whid
         UNION
           SELECT   plant_code,
                    erp_wo,
                    part_no,
                    COUNT (sysserialno),
                    cwo_batch,
                    cpo_no,
                    pallet_no,
                    'SYSTEM',
                    cwo_type,
                    instore_scan_type,
                    whid
             FROM   sfism4.wip_d_cwo_sn
            WHERE       instore_scan_type = 'PALLET'
                    AND cwo_batch = v_batch_no
                    AND cwo_flag = 1
         GROUP BY   plant_code,
                    erp_wo,
                    part_no,
                    cwo_batch,
                    cpo_no,
                    pallet_no,
                    cwo_type,
                    instore_scan_type,
                    whid
         UNION
           SELECT   plant_code,
                    erp_wo,
                    part_no,
                    COUNT (sysserialno),
                    cwo_batch,
                    cpo_no,
                    carton_no,
                    'SYSTEM',
                    cwo_type,
                    instore_scan_type,
                    whid
             FROM   sfism4.wip_d_cwo_sn
            WHERE       instore_scan_type IN ('CARTON', 'POCARTON')
                    AND cwo_batch = v_batch_no
                    AND cwo_flag = 1
         GROUP BY   plant_code,
                    erp_wo,
                    part_no,
                    cwo_batch,
                    cpo_no,
                    carton_no,
                    cwo_type,
                    instore_scan_type,
                    whid;

      /*
        INSERT INTO sfism4.wip_d_cwo_partlist
                    (plant_code, erp_wo, part_no, qty, cwo_batch, cpo_no,
                     pallet_no, creator, cwo_type)
           SELECT   plant_code, erp_wo, part_no, COUNT (pallet_no), cwo_batch,
                    cpo_no, sysserialno, 'SYSTEM', cwo_type
               FROM sfism4.wip_d_cwo_sn
              WHERE cwo_batch = v_batch_no
           GROUP BY plant_code,
                    erp_wo,
                    part_no,
                    cwo_batch,
                    cpo_no,
                    sysserialno,
                    cwo_type;
          */
      --CWO by sysserialno end

      /*sfis1.sp_upload_erp (v_batch_no,'SYSTEM','',o_res);

      IF o_res <> 'OK'
      THEN
         RETURN;
      END IF; */
      o_res := 'OK';
      RETURN;
   END IF;

   o_res := 'Transtype=' || i_transtype || ' is unknown.';
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      --o_res := 'sp_upload_cwo error';
      o_res := SQLCODE || SQLERRM;
END;