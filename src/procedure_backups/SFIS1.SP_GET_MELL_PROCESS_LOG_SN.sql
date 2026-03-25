PROCEDURE       SP_GET_MELL_PROCESS_LOG_SN (
   i_START_DATE      IN     VARCHAR2,
   i_END             IN     VARCHAR2,
   i_work_order      IN     VARCHAR2,
   o_res                OUT VARCHAR2)
IS
   p_sn                VARCHAR2 (60);
   p_model_name        VARCHAR2 (60);
   p_version           VARCHAR2 (60);
   p_mo_number          VARCHAR2 (60);
   p_in_station_time   VARCHAR2 (60);
   p_SECTION_NAME      VARCHAR2 (60);
   
   p_DESCRIPTION          VARCHAR2 (200);

   p_group_name        VARCHAR2 (60);
   p_STATION_NAME      VARCHAR2 (60);
   p_CONTAINER_NO      VARCHAR2 (80);

   p_PALLET_NO         VARCHAR2 (60);
   p_CARTON_NO         VARCHAR2 (60);
   p_num               NUMBER;
   p_ERROR_FLAG        NUMBER;
   p_KEY_PART_NO       VARCHAR2 (60);
   p_EMP_NO            VARCHAR2 (30);



   CURSOR ssn_cur
   IS
      SELECT Y.SERIAL_NUMBER,
             Y.MODEL_NAME,
             Y.VERSION_CODE,
             Y.MO_NUMBER,      
             TO_CHAR (X.IN_STATION_TIME,'YYYY/MM/DD HH24:MI:SS') AS IN_STATION_TIME,
             Z.DESCRIPTION,
             X.SECTION_NAME,
             X.GROUP_NAME,
             X.STATION_NAME,
             X.CONTAINER_NO,
             X.PALLET_NO,
             X.CARTON_NO,
             
             CASE
               WHEN X.ERROR_FLAG='0'
                THEN '1'
                WHEN X.ERROR_FLAG='1'
                THEN '0'
               ELSE NULL END AS ERROR_FLAG,       
           --  X.ERROR_FLAG,           
             
             X.KEY_PART_NO,
             X.EMP_NO
        FROM    SFISM4.R_WIP_TRACKING_T Y
              LEFT JOIN SFIS1.C_MODEL_DESC_T Z
           
             ON Z.MODEL_NAME = Y.MODEL_NAME AND Z.REV=Y.VERSION_CODE      
             LEFT JOIN
                sfism4.r_sn_detail_t X
             ON Y.SERIAL_NUMBER = X.SERIAL_NUMBER
       WHERE     
             Z.CUSTOMER='MELLANOX' AND 
              X.IN_STATION_TIME >=
                    TO_DATE (i_START_DATE, 'YYYY/MM/DD HH24:MI:SS')
             AND X.IN_STATION_TIME <
                    TO_DATE (i_END, 'YYYY/MM/DD HH24:MI:SS') ORDER BY Y.SERIAL_NUMBER,X.IN_STATION_TIME;
BEGIN

       o_res := 'Open Cursor Error.';

   /*

   OPEN ssn_cur;

   FETCH ssn_cur
   INTO p_sn,
        p_model_name,
        p_version,
        p_mo_number,
        p_in_station_time,
        p_DESCRIPTION,
        p_SECTION_NAME,
        p_group_name,
        p_STATION_NAME,
        p_CONTAINER_NO,
        p_PALLET_NO,
        p_CARTON_NO,
        p_ERROR_FLAG,
        p_KEY_PART_NO,
        p_EMP_NO;


   WHILE ssn_cur%FOUND
   LOOP
      o_res := 'Insert into SFISM4.B2B_MELL_PROCESS_LOG_T Error';



      SELECT NVL (MAX (ROWNUM), 0) + 1
        INTO p_num
        FROM SFISM4.B2B_MELL_PROCESS_LOG_T
       WHERE WORK_DATE = i_work_order;

      INSERT INTO SFISM4.B2B_MELL_PROCESS_LOG_T (WORK_DATE,
                                                 FILE_NAME,
                                                 RECORD_ID,
                                                 SERIAL_NUMBER,
                                                 MODEL_NAME,
                                                 WORK_ORDER,
                                                 PRD_DESC,
                                                 STATION,
                                                 STATION_ID,
                                                 ERROR_FLAG,
                                                 OPERATOR,
                                                 FIXTURE_ID,
                                                 CREATE_DATE,
                                                 IN_STATION_TIME)
           VALUES (i_work_order,
                   'N/A',
                   p_num,
                   p_sn,
                   p_model_name,
                   p_mo_number,                
                   p_DESCRIPTION,
                   p_group_name,
                   p_STATION_NAME,
                   TO_CHAR(p_ERROR_FLAG),
                   p_EMP_NO,
                   '',
                   sysdate,
                   TO_DATE(p_in_station_time,'YYYY/MM/DD HH24:MI:SS')

                   );


      FETCH ssn_cur
      INTO p_sn,
           p_model_name,
           p_version,
           p_mo_number,
           p_in_station_time,
           p_DESCRIPTION,
           p_SECTION_NAME,
           p_group_name,
           p_STATION_NAME,
           p_CONTAINER_NO,
           p_PALLET_NO,
           p_CARTON_NO,
           p_ERROR_FLAG,
           p_KEY_PART_NO,
           p_EMP_NO;
   END LOOP;

   CLOSE ssn_cur;   
   
   */   
   
              INSERT INTO SFISM4.B2B_MELL_PROCESS_LOG_T (WORK_DATE,
                                                 FILE_NAME,
                                                 RECORD_ID,
                                                 SERIAL_NUMBER,
                                                 MODEL_NAME,
                                                 WORK_ORDER,
                                                 PRD_DESC,                                               
                                                 STATION,
                                                 STATION_ID,
                                                 ERROR_FLAG,
                                                 OPERATOR,
                                                 FIXTURE_ID,
                                                 CREATE_DATE,
                                                 IN_STATION_TIME,
                                                 SEND_FLAG,
                                                 SEND_FTP,
                                                 UPDATE_FTP_DATE)
             SELECT i_work_order as WORK_DATE, 'N/A' as FILE_NAME,rownum as record_id, Y.SERIAL_NUMBER,
             Y.MODEL_NAME,
    
             Y.MO_NUMBER AS WORK_ORDER,      
     
             Z.DESCRIPTION AS PRD_DESC,
             X.GROUP_NAME AS STATION,
             X.GROUP_NAME AS STATION_ID,       
             
             CASE
               WHEN X.ERROR_FLAG='0'
                THEN '1'
                WHEN X.ERROR_FLAG='1'
                THEN '0'
               ELSE NULL END AS ERROR_FLAG,       
             
             X.EMP_NO,           
             '' AS FIXTURE_ID,
              SYSDATE AS CREATE_DATE,         
             X.in_station_time,
             'N' AS SEND_FLAG,
             'N' AS SEND_FTP,
             '' AS UPDATE_FTP_DATE
        FROM  SFISM4.R_WIP_TRACKING_T Y
              LEFT JOIN SFIS1.C_MODEL_DESC_T Z           
             ON Z.MODEL_NAME = Y.MODEL_NAME AND Z.REV=Y.VERSION_CODE      
             LEFT JOIN
                sfism4.r_sn_detail_t X
             ON Y.SERIAL_NUMBER = X.SERIAL_NUMBER
       WHERE     
             Z.CUSTOMER='MELLANOX' AND 
              X.IN_STATION_TIME >=
                  -- TO_DATE ('2022/11/01 01:00:00', 'YYYY/MM/DD HH24:MI:SS')
                    TO_DATE (i_START_DATE, 'YYYY/MM/DD HH24:MI:SS')
             AND X.IN_STATION_TIME <
                   --  TO_DATE ('2022/11/01 08:00:00', 'YYYY/MM/DD HH24:MI:SS') ORDER BY record_id,IN_STATION_TIME;
                     TO_DATE (i_END, 'YYYY/MM/DD HH24:MI:SS') ORDER BY record_id,IN_STATION_TIME;
       o_res := 'OK';
   
EXCEPTION
   WHEN OTHERS
   THEN
      o_res := o_res;
      ROLLBACK;
END;