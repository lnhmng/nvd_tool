PROCEDURE             sp_get_productdata_for_tjpcas
AS
   v_start_date    date;
   v_end_date      date;
   v_res           VARCHAR (500);
BEGIN
   v_res := 'Get start_date error!'; 
   
   v_start_date:=sysdate-1;
  
   BEGIN
      SELECT  LAST_MODIFY_DATE
        INTO   v_start_date
        FROM   sfis1.C_PARAMETER_INI_PCAS
       WHERE       PRG_NAME = 'PCAS_GET_PROD_DATA_TJ'
               AND VR_CLASS = 'LAST_GET_TIME'
               AND VR_ITEM = 'PCAS'
               and rownum=1;
   EXCEPTION
      WHEN OTHERS
      THEN
         DELETE FROM   sfis1.C_PARAMETER_INI_PCAS
               WHERE       PRG_NAME = 'PCAS_GET_PROD_DATA_TJ'
                       AND VR_CLASS = 'LAST_GET_TIME'
                       AND VR_ITEM = 'PCAS';

         INSERT INTO sfis1.C_PARAMETER_INI_PCAS (PRG_NAME,
                                            VR_CLASS,
                                            VR_ITEM,
                                            VR_NAME,
                                            LAST_MODIFY_DATE)
           VALUES   ('PCAS_GET_PROD_DATA_TJ',
                     'LAST_GET_TIME',
                     'PCAS',
                     '',
                     v_start_date);
   END;

   v_end_date := sysdate;

      v_res := 'delete data error from table : mes4.mfsysevent_nvd_temp@ODMDBTJ';
                       
      DELETE  mes4.mfsysevent_nvd_temp@ODMDBTJ WHERE BU_NAME = 'NVD';

      v_res := 'insert into mes4.mfsysevent_nvd_temp@ODMDBTJ error';

      INSERT INTO mes4.mfsysevent_nvd_temp@ODMDBTJ (SYSSERIALNO,
                                                  EVENTNAME,
                                                  SCANDATETIME,
                                                  FACTORYID,
                                                  PRODUCTIONLINE,
                                                  SHIFT,
                                                  SCANBY,
                                                  PRODUCTSTATUS,
                                                  SKUNO,
                                                  WORKORDERNO,
                                                  ORGSYSSERIALNO,
                                                  EVENTPASS,
                                                  EVENTFAIL,
                                                  WORKTIME,
                                                  BU_NAME)
           SELECT   *
             FROM   (WITH sn_detail_1
                            AS (SELECT   serial_number, group_name
                                  FROM   sfism4.r_sn_detail_t
                                 WHERE   in_station_time >=v_start_date
                                         AND in_station_time <v_end_date
                                MINUS
                                SELECT   serial_number, group_name
                                  FROM   sfism4.r_sn_detail_t a
                                 WHERE   in_station_time <v_start_date
                                         AND in_station_time >v_end_date
                                         AND EXISTS
                                               (SELECT   1
                                                  FROM   (SELECT   serial_number,  group_name
                                                            FROM   sfism4.r_sn_detail_t
                                                           WHERE   in_station_time >=v_start_date
                                                                   AND in_station_time <v_end_date) b
                                                 WHERE   a.serial_number =  b.serial_number
                                                         AND a.group_name =  b.group_name)),
                         sn_detail
                            AS (SELECT   *
                                  FROM   sfism4.r_sn_detail_t
                                 WHERE   (serial_number, group_name, in_station_time) IN
                                               (  SELECT   a.serial_number,  a.group_name, MIN ( a.in_station_time )
                                                    FROM   sfism4.r_sn_detail_t a,
                                                           sn_detail_1 b
                                                   WHERE   a.in_station_time >=v_start_date
                                                           AND a.in_station_time <v_end_date
                                                           AND a.group_name = b.group_name
                                                           AND a.serial_number =  b.serial_number
                                                GROUP BY   a.serial_number, a.group_name)
                                         AND in_station_time >=v_start_date
                                         AND in_station_time <v_end_date)
                     SELECT   a.serial_number,
                              a.group_name,
                              a.in_station_time,
                              k.plant_code,
                              (CASE
                                  WHEN a.group_name LIKE 'ICT%'
                                  THEN a.station_name
                                  WHEN A.LINE_NAME = 'NVP08'
                                  THEN  'B3P05'
                                  WHEN A.LINE_NAME = 'F5T01'
                                  THEN  'F5T03'
                            WHEN A.LINE_NAME = 'NVS08B'
                            THEN 'B3S02A'
                            WHEN A.LINE_NAME = 'NVS08T'
                            THEN 'B3S02B'
                                  ELSE   line_name
                               END)
                                 AS line_name,                
                              (CASE
                                  WHEN ((a.in_station_time >= TO_DATE ( TO_CHAR (a.in_station_time, 'YYYY/MM/DD')|| ' 07:30:00', 'YYYY/MM/DD HH24:MI:SS'))
                                    AND (a.in_station_time < TO_DATE (TO_CHAR (a.in_station_time, 'YYYY/MM/DD')|| ' 19:30:00','YYYY/MM/DD HH24:MI:SS')))
                                   THEN 'SHIFT1'
                                   ELSE 'SHIFT2'
                              END)
                                 AS shift,                              
                              a.emp_no,
                              (DECODE (c.mo_type, 'REWORK ', 'REWORK', 'FRESH'))
                                 AS is_rework,
                              (CASE
                                  WHEN a.carton_no = 'N/A' THEN a.model_name
                                  WHEN a.key_part_no IS NULL THEN a.model_name
                                  ELSE A.KEY_PART_NO
                               END)
                                 AS model_name,
                              k.mo_no,
                              a.serial_number AS org_sn,
                              (DECODE (a.error_flag, '0', '1', '0')) AS passqty,
                              (DECODE (a.error_flag, '1', '1', '0')) AS failqty,
                              SYSDATE AS WORKTIME,
                              'NVD' AS bu_name
                       FROM   sn_detail a,
                              sfis1.C_PARAMETER_INI_PCAS b,
                              sfism4.r_mo_base_t c,
                              KITTING.M_MO_T k
                      WHERE   a.line_name = b.VR_ITEM
                              AND ( (a.group_name = b.VR_NAME
                                     AND b.VR_VALUE IS NULL)
                                   OR (a.STATION_name = b.VR_VALUE
                                       AND b.VR_VALUE IS NOT NULL))
                              AND b.PRG_NAME = 'PCAS'
                              AND a.mo_number = c.mo_number
                              AND (C.MO_TYPE = 'NORMAL'
                                   OR (c.mo_type = 'REWORK'
                                       AND C.DEFAULT_GROUP NOT IN
                                                ('900_INPUT',
                                                 'BIOSCHECK',
                                                 '900_VI',
                                                 '900_AOI',
                                                 '900_AOI_B',
                                                 '900_AOI_T')
                                       AND A.CARTON_NO <> 'N/A'
                                       AND A.KEY_PART_NO IS NOT NULL))
                              AND K.MO_NO = SUBSTR (c.mo_number, 1,INSTR (c.mo_number, '-') - 1))
         GROUP BY   SERIAL_NUMBER,
                    GROUP_NAME,
                    IN_STATION_TIME,
                    PLANT_CODE,
                    LINE_NAME,
                    SHIFT,
                    EMP_NO,
                    IS_REWORK,
                    MODEL_NAME,
                    MO_NO,
                    ORG_SN,
                    PASSQTY,
                    FAILQTY,
                    WORKTIME,
                    BU_NAME;
                    
         v_res := 'insert into mes4.mfsysevent_nvd@ODMDBTJ error';
        insert into mes4.mfsysevent_nvd@ODMDBTJ
            (SYSSERIALNO, EVENTNAME, SCANDATETIME, 
               FACTORYID, PRODUCTIONLINE, SHIFT, 
               SCANBY, PRODUCTSTATUS, SKUNO, 
               WORKORDERNO, ORGSYSSERIALNO, EVENTPASS, 
               EVENTFAIL, WORKTIME, BU_NAME)
        select SYSSERIALNO, EVENTNAME, SCANDATETIME, 
               FACTORYID, PRODUCTIONLINE, SHIFT, 
               SCANBY, PRODUCTSTATUS, SKUNO, 
               WORKORDERNO, ORGSYSSERIALNO, EVENTPASS, 
               EVENTFAIL, WORKTIME, BU_NAME
        from mes4.mfsysevent_nvd_temp@ODMDBTJ a
        where not exists (select 0 from mes4.mfsysevent_nvd@ODMDBTJ b 
                          where b.SYSSERIALNO=a.SYSSERIALNO 
                            and b.EVENTNAME=a.EVENTNAME 
                            and b.SCANDATETIME=a.SCANDATETIME); 

   v_res := 'OK';

   UPDATE   sfis1.C_PARAMETER_INI_PCAS
      SET   VR_DESC = v_res, LAST_MODIFY_DATE = v_end_date
    WHERE       PRG_NAME = 'PCAS_GET_PROD_DATA_TJ'
            AND VR_CLASS = 'LAST_GET_TIME'
            AND VR_ITEM = 'PCAS';
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      
   UPDATE   sfis1.C_PARAMETER_INI_PCAS
      SET   VR_DESC = v_res
    WHERE       PRG_NAME = 'PCAS_GET_PROD_DATA_TJ'
            AND VR_CLASS = 'LAST_GET_TIME'
            AND VR_ITEM = 'PCAS';      
      
      INSERT INTO sfis1.R_TRACE_T  (PROC_NAME, INSERT_TIME, DATA1)
        VALUES   ('SP_GET_PRODUCTDATA_FOR_PCAS', SYSDATE, v_res);
END;