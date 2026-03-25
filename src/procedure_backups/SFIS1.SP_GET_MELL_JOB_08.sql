PROCEDURE             SP_GET_MELL_JOB_08
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
   ex             EXCEPTION;



   CURSOR snlist
    IS

       SELECT DISTINCT B.SERIAL_NUMBER FROM SFISM4.R_WIP_TRACKING_T A,sfism4.r_sn_detail_t B,SFIS1.C_MODEL_DESC_T C 
         WHERE A.SERIAL_NUMBER=B.SERIAL_NUMBER AND A.MODEL_NAME=C.MODEL_NAME AND a.version_code=c.rev  AND  
         B.GROUP_NAME='ICT' AND B.ERROR_FLAG='0' AND C.CUSTOMER='MELLANOX' AND B.in_station_time >=
                    TO_DATE (v_start_time,'YYYY/MM/DD HH24:MI:SS')
             AND B.in_station_time <
                    TO_DATE (v_end_time,'YYYY/MM/DD HH24:MI:SS');
   /*
    CURSOR snlist2
    IS

       SELECT DISTINCT B.SERIAL_NUMBER FROM SFISM4.R_WIP_TRACKING_T A,sfism4.r_sn_detail_t B,SFIS1.C_MODEL_DESC_T C  
         WHERE A.SERIAL_NUMBER=B.SERIAL_NUMBER AND A.MODEL_NAME=C.MODEL_NAME AND a.version_code=c.rev AND  
         B.GROUP_NAME='KANBAN IN' AND B.in_station_time >=
                    TO_DATE (v_start_time,'YYYY/MM/DD HH24:MI:SS')
             AND B.in_station_time <
                    TO_DATE (v_end_time,'YYYY/MM/DD HH24:MI:SS');
   */

BEGIN
   v_res := 'Get start_date error!';

   BEGIN
      SELECT TRIM (vr_value)
        INTO v_start_date
        FROM sfis1.C_PARAMETER_INI
       WHERE     PRG_NAME = 'MELLANOX_REPORT'
             AND vr_class = 'NVD'
             AND VR_ITEM = 'MELLANOX_GET_REPORT_DATA_T'
             AND vr_name = 'LAST_GET_TIME_FOR_08';

      IF v_start_date || 'A' = 'A'
      THEN
         RAISE ex;
      END IF;


       SELECT TO_CHAR (TO_DATE (vr_value, 'YYYY/MM/DD HH24:MI:SS')+1, 'YYYYMMDD')
       INTO v_start_date
       FROM sfis1.C_PARAMETER_INI
       WHERE     PRG_NAME = 'MELLANOX_REPORT'
             AND vr_class = 'NVD'
             AND VR_ITEM = 'MELLANOX_GET_REPORT_DATA_T'
             AND vr_name = 'LAST_GET_TIME_FOR_08';


   EXCEPTION
      WHEN OTHERS
      THEN
         DELETE FROM sfis1.C_PARAMETER_INI
               WHERE     PRG_NAME = 'MELLANOX_REPORT'
                     AND vr_class = 'NVD'
                     AND VR_ITEM = 'MELLANOX_GET_REPORT_DATA_T'
                     AND vr_name = 'LAST_GET_TIME_FOR_08';

         SELECT TO_CHAR (SYSDATE, 'YYYYMMDD')
           INTO v_start_date
           FROM DUAL;

         INSERT INTO sfis1.C_PARAMETER_INI (PRG_NAME,
                                            vr_class,
                                            VR_ITEM,
                                            vr_name,
                                            vr_value,
                                            LAST_MODIFY_DATE)
              VALUES ('MELLANOX_REPORT',
                      'NVD',
                      'MELLANOX_GET_REPORT_DATA_T',
                      'LAST_GET_TIME_FOR_08',
                      v_start_date,
                      SYSDATE);
   END;

    SELECT VR_DESC
    INTO v_desc
    FROM sfis1.C_PARAMETER_INI
    WHERE     PRG_NAME = 'MELLANOX_REPORT'
          AND vr_class = 'NVD'
          AND VR_ITEM = 'MELLANOX_GET_REPORT_DATA_T'
          AND vr_name = 'LAST_GET_TIME_FOR_16';

    IF v_desc <> 'OK'
          THEN
            RAISE ex;
    END IF;

   SELECT TO_CHAR (SYSDATE, 'YYYY/MM/DD') INTO v_now_date FROM DUAL;

   IF TO_DATE (v_start_date, 'YYYY/MM/DD') >
         TO_DATE (v_now_date, 'YYYY/MM/DD')
   THEN
      v_res := 'OK';
      RETURN;
   END IF;



   v_end_date :=
      TO_CHAR (TO_DATE (v_start_date, 'YYYY/MM/DD') , 'YYYY/MM/DD');

   v_start_time := TO_CHAR (TO_DATE (v_start_date, 'YYYY/MM/DD'), 'YYYY/MM/DD') || ' 00:00:00';
   v_end_time := v_end_date || ' 08:00:00';
   v_work_order := (TO_CHAR (TO_DATE (v_start_time, 'YYYY/MM/DD HH24:MI:SS'), 'YYYYMMDDHH24'))||'-'||(TO_CHAR (TO_DATE (v_end_time, 'YYYY/MM/DD HH24:MI:SS'), 'YYYYMMDDHH24'));

      FOR SNINFO IN snlist
        LOOP
          v_sn:=SNINFO.SERIAL_NUMBER;    

          SP_GET_MELL_ICT_LOG_SN(v_sn,v_start_time,v_end_time,v_work_order,v_res);         -- ?????SN ICT LOG ??????,??????,

            IF v_res <> 'OK' THEN

                v_res:='ERROR_ICT TEST FAIL';
                RETURN; 

             END IF;


         END LOOP; 

        /*
          FOR SNINFO2 IN snlist2

           LOOP
             v_sn:=SNINFO2.SERIAL_NUMBER;    

             SP_GET_MELL_SA_LOG_SN(v_sn,v_start_time,v_end_time,v_work_order,v_res);         -- ?????SN KANBAN IN LOG ??????,??????,

             IF v_res <> 'OK' THEN

                v_res:='ERROR_SA TEST FAIL';
                RETURN; 

             END IF;


           END LOOP; 
          */

         SP_GET_MELL_PROCESS_LOG_SN (v_start_time,v_end_time,v_work_order,v_res);         -- ?????SN PROCESS LOG ??????,??????,


         IF v_res <> 'OK' THEN

             v_res:='ERROR_PROCESS LOG FAIL';
             RETURN; 

          END IF;


       SP_GET_MELL_FA_LOG_SN (v_start_time,v_end_time,v_work_order,v_res);                 -- ?????SN FAIL LOG ??????,??????,


         IF v_res <> 'OK' THEN

              v_res:='ERROR_TEST FA_LOG FAIL';
               RETURN; 

          END IF;

   v_res := 'update end_date error!';

   UPDATE sfis1.C_PARAMETER_INI
    --  SET vr_value = v_end_date, LAST_MODIFY_DATE = SYSDATE,vr_desc='OK'
     SET vr_value = v_end_time, LAST_MODIFY_DATE = SYSDATE,vr_desc='OK'
    WHERE     PRG_NAME = 'MELLANOX_REPORT'
          AND vr_class = 'NVD'
          AND VR_ITEM = 'MELLANOX_GET_REPORT_DATA_T'
          AND vr_name = 'LAST_GET_TIME_FOR_08';

   COMMIT;
EXCEPTION
   WHEN OTHERS
   THEN
      rollback;
      UPDATE sfis1.C_PARAMETER_INI
         SET VR_DESC = v_res, LAST_MODIFY_DATE = SYSDATE
       WHERE     PRG_NAME = 'MELLANOX_REPORT'
             AND vr_class = 'NVD'
             AND VR_ITEM = 'MELLANOX_GET_REPORT_DATA_T'
             AND vr_name = 'LAST_GET_TIME_FOR_08';
END;