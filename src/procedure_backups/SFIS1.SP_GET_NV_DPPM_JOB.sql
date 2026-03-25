PROCEDURE             SP_GET_NV_DPPM_JOB
AS
   v_sn          VARCHAR2 (100);  
   v_res          VARCHAR2 (100);
   v_start_date   VARCHAR (20);
   v_start_time   VARCHAR (20);
   v_end_date     VARCHAR (20);
   v_end_time     VARCHAR (20);
   v_now_date     VARCHAR (20);
   v_work_order     VARCHAR (40); 
   v_desc         VARCHAR2 (100);

   p_week           VARCHAR (30);
   p_qty          int;
   p_pkgid          VARCHAR (60);
   p_w_date         VARCHAR (30);
   p_model_name     VARCHAR (60);
   p_sn             VARCHAR (60);
   p_hh_pn          VARCHAR (60);
   p_nv_pn          VARCHAR (60);
   p_mfg            VARCHAR (100);
   p_vendor_name    VARCHAR (100);
   P_test_station   VARCHAR (60);
   p_error_drgree   VARCHAR (100);
   p_location       VARCHAR (100);
   p_LOT_NO          VARCHAR (60);
   p_DATE_CODE       VARCHAR (60);
   p_repairer        VARCHAR (30);
   p_reason          VARCHAR (100); 
   p_mark            VARCHAR (100); 
   ex             EXCEPTION;


  CURSOR ssn_cur
   IS

     SELECT SUBSTR(C.W_DATE,1,4)||TO_CHAR(TO_DATE (C.W_DATE,'YYYY/MM/DD'),'IW') AS WEEK, C.W_DATE,C.MODEL_NAME,C.SERIAL_NUMBER,C.HH_PN,
            CASE
               WHEN c.hh_pn LIKE '%CHF' OR c.hh_pn LIKE '%HF'
                 THEN CASE
                 WHEN  SUBSTR (c.hh_pn,LENGTH(c.hh_pn)-2,3) ='CHF'
                             THEN SUBSTR(c.hh_pn,1,LENGTH(c.hh_pn)-3)                    
                WHEN  SUBSTR (c.hh_pn,LENGTH(c.hh_pn)-1,2) ='HF'
                              THEN SUBSTR(c.hh_pn,1,LENGTH(c.hh_pn)-2)  
                  END
                 ELSE NVL (c.hh_pn, 'N/A') 
               END AS NV_pn,
          C.MFG_PN,F.VENDOR_NAME as MANUFACTURER_NAME,C.TEST_STATION,C.ERROR_DEGREE,C.ERROR_ITEM_CODE,
          C.LOT_NO,C.DATE_CODE,C.REPAIRER,C.REASON_CODE,'' AS MARK FROM (
           SELECT W.SERIAL_NUMBER ,W.MODEL_NAME,W.TEST_STATION,T.HH_PN,'' AS NV_PN,T.RESERVE3,W.REASON_CODE,W.ERROR_DEGREE,W.ERROR_ITEM_CODE,W.REPAIRER,W.W_DATE,T.DATE_CODE,T.LOT_NO,T.MFG_PN FROM IQC.R_KPN_INCOMING_T T,(
            select DISTINCT A.SERIAL_NUMBER,A.MODEL_NAME,A.TEST_STATION,A.TEST_CODE,A.REASON_CODE,A.ERROR_ITEM_CODE,A.ERROR_DEGREE,A.REPAIRER,TO_CHAR(A.REPAIR_TIME,'yyyy-mm-dd') AS W_DATE,B.PKG_ID from SFISM4.R_REPAIR_T A, SMTINFO.R_SN_PKG_DETAIL_T B WHERE A.SERIAL_NUMBER=B.SERIAL_NUMBER AND B.LOCATION LIKE '%'||A.ERROR_ITEM_CODE||'%' AND 
             A.repair_time>=TO_DATE (v_start_date,'YYYY/MM/DD HH24:MI:SS') and A.repair_time<=TO_DATE (v_end_date,'YYYY/MM/DD HH24:MI:SS') AND A.REASON_CODE='RC36' AND A.SERIAL_NUMBER LIKE '1%'
              ) W WHERE  T.PKG_ID=W.PKG_ID 
             ) C LEFT JOIN iqc.c_vendor_code_t f ON f.vendor_code = C.reserve3 ORDER BY C.W_DATE;


   CURSOR list_sn
   IS

      SELECT SUBSTR(C.DATE_TIME,1,4)||TO_CHAR(TO_DATE (C.DATE_TIME,'YYYY/MM/DD'),'IW') AS WEEK_DATE,
      C.MODEL_NAME,C.PKG_ID,C.DATE_TIME,C.QTY,D.HH_PN,D.DATE_CODE,D.LOT_NO,D.MFG_PN,D.RESERVE3,D.VENDOR_NAME as MANUFACTURE_NAME FROM (
       select B.MODEL_NAME,A.PKG_ID,to_char(A.IN_STATION_TIME,'yyyymmdd') AS DATE_TIME,COUNT(*) AS QTY from SFISM4.R_WIP_TRACKING_T B, 
       SMTINFO.R_SN_PKG_DETAIL_T A 
       WHERE A.in_station_time>=TO_DATE (v_start_date,'YYYY/MM/DD HH24:MI:SS') 
       AND A.in_station_time<TO_DATE (v_end_date,'YYYY/MM/DD HH24:MI:SS') AND A.SERIAL_NUMBER=B.SERIAL_NUMBER AND (A.SECTION_NAME LIKE 'ASS%' OR A.SECTION_NAME LIKE 'PTH%')
       GROUP BY B.MODEL_NAME,A.PKG_ID,to_char(A.IN_STATION_TIME,'yyyymmdd')) C,(SELECT * FROM IQC.R_KPN_INCOMING_T M,iqc.c_vendor_code_t F WHERE M.RESERVE3=F.vendor_code) D  WHERE C.PKG_ID=D.PKG_ID;


BEGIN
   v_res := 'Get start_date error!';

   BEGIN
      SELECT TRIM (vr_value)
        INTO v_start_date
        FROM sfis1.C_PARAMETER_INI
       WHERE     PRG_NAME = 'NV_DPPM_REPORT'
             AND vr_class = 'NVD'
             AND VR_ITEM = 'NV_DPPM_GET_REPORT_DATA_T'
             AND vr_name = 'LAST_GET_TIME_FOR_NV';

      IF v_start_date || 'A' = 'A'
      THEN
         RAISE ex;
      END IF;

   EXCEPTION
      WHEN OTHERS
      THEN
         DELETE FROM sfis1.C_PARAMETER_INI
               WHERE     PRG_NAME = 'NV_DPPM_REPORT'
               AND vr_class = 'NVD'
               AND VR_ITEM = 'NV_DPPM_GET_REPORT_DATA_T'
               AND vr_name = 'LAST_GET_TIME_FOR_NV';

       --  SELECT TO_CHAR (SYSDATE, 'YYYY/MM/DD HH24:MI:SS')
       --    INTO v_start_date
       --    FROM DUAL;

         INSERT INTO sfis1.C_PARAMETER_INI (PRG_NAME,
                                            vr_class,
                                            VR_ITEM,
                                            vr_name,
                                            vr_value,
                                            LAST_MODIFY_DATE)
              VALUES ('NV_DPPM_REPORT',
                      'NVD',
                      'NV_DPPM_GET_REPORT_DATA_T',
                      'LAST_GET_TIME_FOR_NV',
                      v_start_date,
                      SYSDATE);
   END;

    SELECT VR_DESC
    INTO v_desc
    FROM sfis1.C_PARAMETER_INI
     WHERE     PRG_NAME = 'NV_DPPM_REPORT'
             AND vr_class = 'NVD'
             AND VR_ITEM = 'NV_DPPM_GET_REPORT_DATA_T'
             AND vr_name = 'LAST_GET_TIME_FOR_NV';

    IF v_desc <> 'OK'
          THEN
            RAISE ex;
    END IF;

   SELECT TO_CHAR (SYSDATE, 'YYYY/MM/DD HH24:MI:SS') INTO v_now_date FROM DUAL;

   IF TO_DATE (v_start_date, 'YYYY/MM/DD HH24:MI:SS') >
         TO_DATE (v_now_date, 'YYYY/MM/DD HH24:MI:SS')
   THEN
      v_res := 'OK';      
      RETURN;
   END IF;



     v_end_date :=TO_CHAR(TO_DATE (v_now_date, 'YYYY/MM/DD HH24:MI:SS') , 'YYYY/MM/DD HH24:MI:SS');

     v_res := 'Open Cursor Error.';

     OPEN ssn_cur;

     FETCH ssn_cur INTO p_week,p_w_date,p_model_name,p_sn,p_hh_pn,p_nv_pn,p_mfg,p_vendor_name,p_test_station,p_error_drgree,p_location,p_LOT_NO,p_DATE_CODE,p_repairer,p_reason,p_mark;


    WHILE ssn_cur%FOUND
    LOOP

     -- TO_CHAR(sysdate,'YYYYMMDD'),


        v_res  := 'Insert  SFISM4.R_WIP_DPPM_COMPONET_T Error';


          Insert into SFISM4.R_WIP_DPPM_COMPONENT_T

          (WEEK_DATE,CURRENT_DATE,MODEL_NAME,SERIAL_NUMBER,HH_PN,NV_PN,MFG_PN,MANUFACTURER_NAME,TEST_STATION,ERROR_CODE,LOCATION,     --11111

            LOT_CODE,DATE_CODE,OPERATOR,REASON_CODE,MARK,CREATE_DATE)                                --22222  

          Values

           (p_week,TO_DATE (p_w_date,'YYYY-MM-DD'),p_model_name,p_sn,p_hh_pn,p_nv_pn,p_mfg,p_vendor_name,p_test_station,p_error_drgree,p_location,   --1111111

             p_LOT_NO,p_DATE_CODE,p_repairer, p_reason, p_mark,SYSDATE);        

      FETCH ssn_cur

       INTO  p_week,p_w_date,p_model_name,p_sn,p_hh_pn,p_nv_pn,p_mfg,p_vendor_name,p_test_station,p_error_drgree,p_location,p_LOT_NO,p_DATE_CODE,p_repairer,p_reason,p_mark;

   END LOOP;

   CLOSE ssn_cur;



    v_res := 'Open Cursor Error.';

    OPEN list_sn;

     FETCH list_sn INTO p_week,p_model_name,p_pkgid,p_w_date,p_qty,p_hh_pn,p_DATE_CODE,p_LOT_NO,p_mfg,p_test_station,p_vendor_name;


    WHILE list_sn%FOUND
    LOOP

     -- TO_CHAR(sysdate,'YYYYMMDD'),


        v_res  := 'Insert  SFISM4.R_WIP_DPPM_INFO Error';


          Insert into SFISM4.R_WIP_DPPM_INFO_T

          (WEEK_DATE,MODEL_NAME,PKG_ID,HH_PN,DATE_CODE,LOT_NO,MFG_PN,RESERVE3,MANUFACTURE_NAME,IN_DATE_TIME,QTY,CREATE_DATE,EMP_NO)                                --22222  

          Values

           (p_week,p_model_name,p_pkgid,p_hh_pn,p_DATE_CODE,p_LOT_NO,p_mfg,p_test_station,p_vendor_name,p_w_date,p_qty,SYSDATE,'AUTO_DBA');        

      FETCH list_sn

       INTO p_week,p_model_name,p_pkgid,p_w_date,p_qty,p_hh_pn,p_DATE_CODE,p_LOT_NO,p_mfg,p_test_station,p_vendor_name;

   END LOOP;

   CLOSE list_sn;



   v_res := 'OK';
   v_res := 'update end_date error!';

   UPDATE sfis1.C_PARAMETER_INI 
     --create_date=TO_DATE(v_start_date,'YYYY/MM/DD HH24:MI:SS')
     SET vr_value = v_end_date, LAST_MODIFY_DATE = SYSDATE,vr_desc='OK'      
     WHERE     PRG_NAME = 'NV_DPPM_REPORT'
             AND vr_class = 'NVD'
             AND VR_ITEM = 'NV_DPPM_GET_REPORT_DATA_T'
             AND vr_name = 'LAST_GET_TIME_FOR_NV';

   COMMIT;
EXCEPTION
   WHEN OTHERS
   THEN
      rollback;
      UPDATE sfis1.C_PARAMETER_INI
         SET VR_DESC = v_res||p_pkgid, LAST_MODIFY_DATE = SYSDATE
       WHERE     PRG_NAME = 'NV_DPPM_REPORT'
             AND vr_class = 'NVD'
             AND VR_ITEM = 'NV_DPPM_GET_REPORT_DATA_T'
             AND vr_name = 'LAST_GET_TIME_FOR_NV';
END;