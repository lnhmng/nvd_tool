PROCEDURE       O_REPORT_JOB3
AS
   v_res          VARCHAR2 (100);
   v_start_date   VARCHAR (20);
   v_start_time   VARCHAR (20);
   v_end_date     VARCHAR (20);
   v_end_time     VARCHAR (20);
   v_now_date     VARCHAR (20);
   v_desc         VARCHAR2 (100);
   ex             EXCEPTION;

   CURSOR dailymodel
   IS
      SELECT DISTINCT model_name
        FROM sfism4.r_sn_detail_t
       WHERE     in_station_time >=
                    TO_DATE (v_start_time, 'YYYY/MM/DD HH24:MI:SS')
             AND in_station_time <
                    TO_DATE (v_end_time, 'YYYY/MM/DD HH24:MI:SS') and (serial_number like '179%' OR serial_number like '188%');
BEGIN
   v_res := 'Get start_date error!';

   BEGIN

      SELECT TRIM (vr_value)
        INTO v_start_date
        FROM sfis1.C_PARAMETER_INI
       WHERE     PRG_NAME = 'O_REPORT'
             AND vr_class = 'NVD'
             AND VR_ITEM = 'O_GET_REPORT_DATA_T'
             AND vr_name = 'LAST_GET_TIME_FOR_0AM';

      IF v_start_date || 'A' = 'A'
      THEN
         RAISE ex;
      END IF;

      SELECT TO_CHAR (TO_DATE (vr_value, 'YYYY/MM/DD'), 'YYYYMMDD')
        INTO v_start_date
        FROM sfis1.C_PARAMETER_INI
       WHERE     PRG_NAME = 'O_REPORT'
             AND vr_class = 'NVD'
             AND VR_ITEM = 'O_GET_REPORT_DATA_T'
             AND vr_name = 'LAST_GET_TIME_FOR_0AM';
   EXCEPTION
      WHEN OTHERS
      THEN
         DELETE FROM sfis1.C_PARAMETER_INI
               WHERE     PRG_NAME = 'O_REPORT'
                     AND vr_class = 'NVD'
                     AND VR_ITEM = 'O_GET_REPORT_DATA_T'
                     AND vr_name = 'LAST_GET_TIME_FOR_0AM';

         SELECT TO_CHAR (SYSDATE-1, 'YYYYMMDD')
           INTO v_start_date
           FROM DUAL;

         INSERT INTO sfis1.C_PARAMETER_INI (PRG_NAME,
                                            vr_class,
                                            VR_ITEM,
                                            vr_name,
                                            vr_value,
                                            LAST_MODIFY_DATE)
              VALUES ('O_REPORT',
                      'NVD',
                      'O_GET_REPORT_DATA_T',
                      'LAST_GET_TIME_FOR_0AM',
                      v_start_date,
                      SYSDATE);
   END;

    SELECT VR_DESC
    INTO v_desc
    FROM sfis1.C_PARAMETER_INI
    WHERE     PRG_NAME = 'O_REPORT'
          AND vr_class = 'NVD'
          AND VR_ITEM = 'O_GET_REPORT_DATA_T'
          AND vr_name = 'LAST_GET_TIME_FOR_4PM';

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
      TO_CHAR (TO_DATE (v_start_date, 'YYYY/MM/DD')+1, 'YYYY/MM/DD');

   v_start_time := TO_CHAR (TO_DATE (v_start_date, 'YYYY/MM/DD'), 'YYYY/MM/DD') || ' 14:30:00';
   v_end_time := v_end_date || ' 00:00:00';


   FOR detailmodel IN dailymodel
   LOOP
         ---------------Get INPUT SN Detail strat   modify by flying 20180321
      v_res := 'Insert Input Detail1 error!' || detailmodel.MODEL_NAME;

      INSERT INTO SFISM4.O_INPUT_DETAIL_T (model_name,
                                           mo_number,
                                           group_name,
                                           serial_number,
                                           in_station_time,
                                           work_date)
           SELECT DISTINCT aa.model_name,
                           aa.mo_number,
                           aa.group_name,
                           aa.serial_number,
                           aa.in_station_time, 
                           v_start_date
           FROM (SELECT DISTINCT a.model_name, a.mo_number, a.group_name,
                                 a.serial_number,min(a.in_station_time) as in_station_time
                 from(select DISTINCT a.model_name, a.mo_number, a.group_name,
                                 a.serial_number,a.in_station_time
                            FROM sfism4.r_sn_detail_t a,
                                 --web.c_model_info_t web,
                                 sfism4.r_wip_tracking_t p
                           WHERE (UPPER (p.customer_no) LIKE 'NV%'  OR upper(p.customer_no)='MELLANOX')
                             AND a.serial_number = p.serial_number
                             AND a.model_name = p.model_name
                             AND a.MO_NUMBER = p.MO_NUMBER --ruanshiqiao ADD 20250925
                             --AND p.model_name = web.model_name
                             AND p.model_name = 
                                           detailmodel.MODEL_NAME
                             AND a.in_station_time >=
                                    TO_DATE (v_start_time,
                                             'YYYY/MM/DD HH24:MI:SS'
                                            )
                             AND a.in_station_time <
                                    TO_DATE (v_end_time,
                                             'YYYY/MM/DD HH24:MI:SS'
                                            )
                     )a
                     left join(SELECT distinct model_name,
                                                  mo_number,
                                                  TEST_STATION,
                                                  serial_number,
                                                  test_time
                                           FROM sfism4.R_REPAIR_T
                                           WHERE model_name =
                                                       detailmodel.MODEL_NAME
                                                 and regexp_like(TEST_CODE,'98[A-Za-z]{1}')) b
                    ON a.model_name=b.model_name and a.mo_number=b.mo_number and b.TEST_STATION like a.GROUP_NAME||'%' and a.serial_number=b.serial_number and A.IN_STATION_TIME=B.TEST_TIME
                    where b.serial_number is null
                    group by a.model_name, a.mo_number, a.group_name,a.serial_number
                ) aa
                LEFT JOIN
                  (SELECT DISTINCT a.group_name, a.serial_number,
                                 MIN (a.in_station_time) AS in_station_time
                         FROM (SELECT DISTINCT a.group_name,a.model_name,a.mo_number,a.serial_number,a.in_station_time
                                 FROM sfism4.r_sn_detail_t a,
                                      --web.c_model_info_t web,
                                      sfism4.r_wip_tracking_t p
                                WHERE (UPPER (p.customer_no) LIKE 'NV%'  OR upper(p.customer_no)='MELLANOX')
                                      AND a.serial_number = p.serial_number
                                      AND a.model_name = p.model_name
                                      AND a.MO_NUMBER = p.MO_NUMBER --ruanshiqiao ADD 20250925
                                      --AND p.model_name = web.model_name
                                      AND p.model_name =
                                             detailmodel.MODEL_NAME) a
                        left join (SELECT distinct model_name,
                                                  mo_number,
                                                  TEST_STATION,
                                                  serial_number,
                                                  test_time
                                           FROM sfism4.R_REPAIR_T
                                           WHERE model_name =
                                                         detailmodel.MODEL_NAME
                                                 and regexp_like(TEST_CODE,'98[A-Za-z]{1}')) b
                        ON a.model_name=b.model_name and a.mo_number=b.mo_number and b.TEST_STATION like a.GROUP_NAME||'%' and a.serial_number=b.serial_number and A.IN_STATION_TIME=B.TEST_TIME
                         left join (SELECT distinct model_name,
                                                  mo_number,
                                                  serial_number,
                                                  repair_station,
                                                  repair_time
                                           FROM sfism4.R_REPAIR_T
                                           WHERE model_name =
                                                         detailmodel.MODEL_NAME
                                                 and regexp_like(TEST_CODE,'98[A-Za-z]{1}')) ff
                        ON a.model_name=ff.model_name and a.mo_number=ff.mo_number and ff.repair_station like a.GROUP_NAME||'%' and a.serial_number=ff.serial_number
                        and A.IN_STATION_TIME  
                        between   ff.repair_time - ( 50 / 24/60/ 60) and   ff.repair_time+ ( 50 / 24/60/ 60)
                        where b.serial_number is null and ff.serial_number is null
                        group by a.group_name, a.serial_number                             
                 ) bb
               ON aa.serial_number = bb.serial_number
               AND aa.group_name = bb.group_name
               LEFT JOIN
                (SELECT DISTINCT b.model_name, b.mo_number, b.station_type,
                                 b.serial_number,
                                 MIN
                                    (TO_DATE (b.test_date || b.test_time,
                                              'yyyymmddhh24:mi:ss'
                                             )
                                    ) AS test_time
                            FROM sfism4.h_test_temp_t b,
                                 --web.c_model_info_t web,
                                 sfism4.r_wip_tracking_t p
                           WHERE (UPPER (p.customer_no) LIKE 'NV%'  OR upper(p.customer_no)='MELLANOX')
                             AND b.serial_number = p.serial_number
                             AND b.model_name = p.model_name
                             AND b.MO_NUMBER = p.MO_NUMBER --ruanshiqiao ADD 20250925
                             --AND p.model_name = web.model_name
                             AND p.model_name =
                                           detailmodel.MODEL_NAME
                        GROUP BY b.model_name,
                                 b.mo_number,
                                 b.station_type,
                                 b.serial_number) cc
                ON aa.serial_number = cc.serial_number
              AND aa.group_name = cc.station_type                                 
          WHERE aa.in_station_time = bb.in_station_time
     -- add by    20200311  luo yang   note off by LSC  20211220
           AND (cc.serial_number IS NULL or aa.in_station_time<cc.test_time);

      v_res := 'Insert Input Detail2 error!' || detailmodel.MODEL_NAME;

      INSERT INTO SFISM4.O_INPUT_DETAIL_T (model_name,
                                           mo_number,
                                           group_name,
                                           serial_number,
                                           in_station_time,
                                           work_date)
      SELECT DISTINCT aa.model_name,
                      aa.mo_number,
                      aa.station_type,
                      aa.serial_number,
                      aa.test_time,
                      v_start_date
              FROM (SELECT DISTINCT b.model_name,
                                    b.mo_number,
                                    b.station_type,
                                    b.serial_number,
                        MIN (TO_DATE (b.test_date || b.test_time,
                                      'yyyymmddhh24:mi:ss'
                                     )
                            ) AS test_time
                   FROM sfism4.h_test_temp_t b,
                        --web.c_model_info_t web,
                        sfism4.r_wip_tracking_t p
                  WHERE (UPPER (p.customer_no) LIKE 'NV%'  OR upper(p.customer_no)='MELLANOX')
                    AND b.model_name = p.model_name
                    AND b.serial_number = p.serial_number
                    AND b.MO_NUMBER = p.MO_NUMBER --ruanshiqiao ADD 20250925
                    --AND p.model_name = web.model_name
                    AND p.model_name =
                                  detailmodel.MODEL_NAME
                    AND TO_DATE (b.test_date || b.test_time,
                                 'yyyymmddhh24:mi:ss'
                                ) >=
                           TO_DATE (v_start_time,
                                    'YYYY/MM/DD HH24:MI:SS'
                                   )
                    AND TO_DATE (b.test_date || b.test_time,
                                 'yyyymmddhh24:mi:ss'
                                ) <
                           TO_DATE (v_end_time,
                                    'YYYY/MM/DD HH24:MI:SS'
                                   )
               GROUP BY b.model_name,
                        b.mo_number,
                        b.station_type,
                        b.serial_number) aa
               LEFT JOIN
                        (SELECT DISTINCT b.model_name,
                                         b.mo_number,
                                         b.station_type,
                                         b.serial_number,
                        MIN (TO_DATE (b.test_date || b.test_time,
                                      'yyyymmddhh24:mi:ss'
                                     )
                            ) AS test_time
                         FROM sfism4.h_test_temp_t b,
                              --web.c_model_info_t web,
                              sfism4.r_wip_tracking_t p
                        WHERE (UPPER (p.customer_no) LIKE 'NV%'  OR upper(p.customer_no)='MELLANOX')
                              AND b.serial_number = p.serial_number
                              AND b.model_name = p.model_name
                              AND b.MO_NUMBER = p.MO_NUMBER --ruanshiqiao ADD 20250925
                              --AND p.model_name = web.model_name
                              AND p.model_name =
                                             detailmodel.MODEL_NAME
                       GROUP BY b.model_name,
                                b.mo_number,
                                b.station_type,
                                b.serial_number) bb
            ON aa.serial_number = bb.serial_number
               AND aa.station_type = bb.station_type
               LEFT JOIN 
                                 (SELECT DISTINCT a.group_name, a.serial_number,
                                 MIN (a.in_station_time) AS in_station_time
                         FROM (SELECT DISTINCT a.group_name,a.model_name,a.mo_number,a.serial_number,a.in_station_time
                                 FROM sfism4.r_sn_detail_t a,
                                      --web.c_model_info_t web,
                                      sfism4.r_wip_tracking_t p
                                WHERE (UPPER (p.customer_no) LIKE 'NV%'  OR upper(p.customer_no)='MELLANOX')
                                      AND a.serial_number = p.serial_number
                                      AND a.model_name = p.model_name
                                      AND a.MO_NUMBER = p.MO_NUMBER --ruanshiqiao ADD 20250925
                                      --AND p.model_name = web.model_name
                                      AND p.model_name =
                                                      detailmodel.MODEL_NAME
                                      ) a
                        left join (SELECT distinct model_name,
                                                  mo_number,
                                                  TEST_STATION,
                                                  serial_number,
                                                  test_time
                                           FROM sfism4.R_REPAIR_T
                                           WHERE model_name =
                                                         detailmodel.MODEL_NAME
                                                 and regexp_like(TEST_CODE,'98[A-Za-z]{1}')) b
                        ON a.model_name=b.model_name and a.mo_number=b.mo_number and b.TEST_STATION like a.GROUP_NAME||'%' and a.serial_number=b.serial_number and A.IN_STATION_TIME=B.TEST_TIME
                        where b.serial_number is null
                        group by a.group_name, a.serial_number                             
                 ) cc
               ON aa.serial_number = cc.serial_number
               AND aa.station_type = cc.group_name
            WHERE aa.test_time = bb.test_time
           -- add by    20200311  luo yang   note off by LSC  20211220
                and (aa.test_time < cc.in_station_time or cc.in_station_time is null);


    --------------Get INPUT SN Detail end   modify by flying 20180321


      v_res := 'Insert OUTPUT Detail error!' || detailmodel.MODEL_NAME;

             INSERT INTO SFISM4.O_OUTPUT_DETAIL_T(WORK_DATE,
                                                  MODEL_NAME,
                                                  MO_NUMBER,
                                                  GROUP_NAME,
                                                  SERIAL_NUMBER,
                                                  IN_STATION_TIME)
                     SELECT DISTINCT   v_start_date,
                                       aa.model_name,
                                       aa.mo_number,
                                       aa.group_name,
                                       aa.serial_number,
                                       aa.in_station_time
                       FROM (SELECT DISTINCT a.model_name, a.mo_number, a.group_name,a.serial_number,
                                             MIN (a.in_station_time) AS in_station_time
                                        FROM sfism4.r_sn_detail_t a,
                                             --web.c_model_info_t web,
                                             sfism4.r_wip_tracking_t p
                                       WHERE (UPPER (p.customer_no) LIKE 'NV%'  OR upper(p.customer_no)='MELLANOX')
                                         AND a.serial_number = p.serial_number
                                         AND a.model_name = p.model_name
                                         AND a.MO_NUMBER = p.MO_NUMBER --ruanshiqiao ADD 20250925
                                         --AND p.model_name = web.model_name
                                         AND a.error_flag='0'
                                         AND p.model_name =
                                                            detailmodel.MODEL_NAME
                                         AND a.in_station_time >=
                                                TO_DATE (v_start_time,
                                                         'YYYY/MM/DD HH24:MI:SS'
                                                        )
                                         AND a.in_station_time <
                                                TO_DATE (v_end_time,
                                                         'YYYY/MM/DD HH24:MI:SS'
                                                        )
                                    GROUP BY a.model_name,
                                             a.mo_number,
                                             a.group_name,
                                             a.serial_number) aa
                            LEFT JOIN
                            (SELECT DISTINCT a.group_name, a.serial_number,
                                             MIN (a.in_station_time) AS in_station_time
                                        FROM sfism4.r_sn_detail_t a,
                                             --web.c_model_info_t web,
                                             sfism4.r_wip_tracking_t p
                                       WHERE (UPPER (p.customer_no) LIKE 'NV%'  OR upper(p.customer_no)='MELLANOX')
                                         AND a.serial_number = p.serial_number
                                         AND a.model_name = p.model_name
                                         AND a.MO_NUMBER = p.MO_NUMBER --ruanshiqiao ADD 20250925
                                         --AND p.model_name = web.model_name
                                         AND a.error_flag='0'
                                         AND p.model_name =
                                                         detailmodel.MODEL_NAME
                                    GROUP BY a.group_name, a.serial_number) bb
                            ON aa.serial_number = bb.serial_number
                          AND aa.group_name = bb.group_name
                      WHERE aa.in_station_time = bb.in_station_time;    


      v_res := 'Insert First fail Detail1 error!' || detailmodel.MODEL_NAME;

      INSERT INTO SFISM4.O_FAIL_DETAIL_TEMP_T (work_date,
                                               FAIL_TYPE,
                                               Model_name,
                                               mo_number,
                                               group_name,
                                               serial_number,
                                               in_station_time,
                                               test_code)
                           SELECT DISTINCT v_start_date,
                              'FIRST' AS TYPR,
                              aa.MODEL_NAME,
                              aa.MO_NUMBER,
                              cc.group_name,
                              aa.serial_number,
                              aa.test_time,
                              ee.test_code
                        FROM (SELECT DISTINCT
                             b.MODEL_NAME,
                             b.MO_NUMBER,
                             b.TEST_STATION,
                             b.serial_number,
                             MIN (b.TEST_TIME) AS TEST_TIME
                        FROM sfism4.R_REPAIR_T b,
                             --WEB.C_MODEL_INFO_T web,
                             sfism4.r_wip_tracking_t p
                       WHERE   --(a.serial_number, a.group_name) NOT IN (SELECT serial_number, STATION_TYPE FROM sfism4.H_TEST_TEMP_T)    ------delete from flying
                             (UPPER (p.customer_no) LIKE 'NV%'  OR upper(p.customer_no)='MELLANOX')
                             AND B.SERIAL_NUMBER = P.SERIAL_NUMBER
                             AND b.MO_NUMBER = p.MO_NUMBER --ruanshiqiao ADD 20250925
                             --AND P.MODEL_NAME = WEB.MODEL_NAME
                             and not regexp_like(B.TEST_CODE,'98[A-Za-z]{1}')
                             AND p.MODEL_NAME =
                                           detailmodel.MODEL_NAME
                             AND b.TEST_TIME >=
                                    TO_DATE (v_start_time,
                                             'YYYY/MM/DD HH24:MI:SS')
                             AND b.TEST_TIME <
                                    TO_DATE (v_end_time,
                                             'YYYY/MM/DD HH24:MI:SS')
                    GROUP BY b.MODEL_NAME,
                             b.MO_NUMBER,
                             b.TEST_STATION,
                             b.serial_number) aa
                   left join( select MODEL_NAME,MO_NUMBER,TEST_STATION,serial_number,min(test_time) as test_time 
                              from sfism4.R_REPAIR_T 
                              where  MODEL_NAME =
                                           detailmodel.MODEL_NAME
                              and not regexp_like(TEST_CODE,'98[A-Za-z]{1}')
                              group by MODEL_NAME,MO_NUMBER,TEST_STATION,serial_number ) bb on aa.serial_number=bb.serial_number and aa.TEST_STATION=bb.TEST_STATION
                   left join(SELECT DISTINCT a.MODEL_NAME,a.MO_NUMBER,a.group_name,a.serial_number,MIN (a.in_station_time) AS in_station_time
                        FROM sfism4.r_sn_detail_t a,
                             sfism4.R_REPAIR_T b,
                             --WEB.C_MODEL_INFO_T web,
                             sfism4.r_wip_tracking_t p
                       WHERE (UPPER (p.customer_no) LIKE 'NV%'  OR upper(p.customer_no)='MELLANOX')
                             and A.SERIAL_NUMBER=P.SERIAL_NUMBER
                             and A.MODEL_NAME=p.MODEL_NAME 
                             AND B.SERIAL_NUMBER = P.SERIAL_NUMBER
                             AND a.MO_NUMBER = b.MO_NUMBER --ruanshiqiao ADD 20250925
                            AND a.MO_NUMBER = p.MO_NUMBER --ruanshiqiao ADD 20250925
                             --AND P.MODEL_NAME = WEB.MODEL_NAME
                             AND p.MODEL_NAME =
                                           detailmodel.MODEL_NAME
                             and not regexp_like(b.TEST_CODE,'98[A-Za-z]{1}')
                             AND b.TEST_TIME >=
                                    TO_DATE (v_start_time,
                                             'YYYY/MM/DD HH24:MI:SS')
                             AND b.TEST_TIME <
                                    TO_DATE (v_end_time,
                                             'YYYY/MM/DD HH24:MI:SS')
                    GROUP BY a.MODEL_NAME,
                             a.MO_NUMBER,
                             a.group_name,
                             a.serial_number)cc on aa.serial_number=cc.serial_number
                   left join (SELECT serial_number,STATION_TYPE FROM sfism4.H_TEST_TEMP_T where  MODEL_NAME = detailmodel.MODEL_NAME) dd
                                          on aa.serial_number=dd.serial_number AND cc.group_name = dd.STATION_TYPE
                   LEFT JOIN sfism4.R_REPAIR_T ee ON aa.model_name=ee.model_name and aa.mo_number=ee.mo_number and aa.serial_number = ee.serial_number
                             AND aa.TEST_STATION = ee.TEST_STATION
                             AND aa.TEST_TIME = ee.TEST_TIME                        
                   where  aa.test_time=bb.test_time
                         and aa.test_time=cc.in_station_time
                         and not regexp_like(ee.TEST_CODE,'98[A-Za-z]{1}')
                         and aa.TEST_STATION like cc.GROUP_NAME||'%'
                         and dd.serial_number IS null;

      v_res := 'Insert First fail Detail 2 error!' || detailmodel.MODEL_NAME;


      INSERT INTO SFISM4.O_FAIL_DETAIL_TEMP_T (work_date,
                                               FAIL_TYPE,
                                               Model_name,
                                               mo_number,
                                               group_name,
                                               serial_number,
                                               in_station_time,
                                               test_code)
       SELECT DISTINCT v_start_date,
                    'FIRST' AS TYPR,
                    aa.model_name,
                    aa.mo_number,
                    aa.station_type,
                    aa.serial_number,
                    aa.test_time,
                    dd.ERROR_CODE
              FROM (SELECT DISTINCT b.model_name,
                                    b.mo_number,
                                    b.station_type,
                                    b.serial_number,
                        MIN (TO_DATE (b.test_date || b.test_time,
                                      'yyyymmddhh24:mi:ss'
                                     )
                            ) AS test_time
                   FROM sfism4.h_test_temp_t b,
                        --web.c_model_info_t web,
                        sfism4.r_wip_tracking_t p
                  WHERE   (UPPER (p.customer_no) LIKE 'NV%'  OR upper(p.customer_no)='MELLANOX')
                    AND b.model_name = p.model_name and upper(b.error_code)<>'OTHERS'
                    AND b.serial_number = p.serial_number
                     AND b.MO_NUMBER = p.MO_NUMBER --ruanshiqiao ADD 20250925
                    --AND p.model_name = web.model_name
                    AND p.model_name =
                                  detailmodel.MODEL_NAME
                    AND TO_DATE (b.test_date || b.test_time,
                                 'yyyymmddhh24:mi:ss'
                                ) >=
                           TO_DATE (v_start_time,
                                    'YYYY/MM/DD HH24:MI:SS'
                                   )
                    AND TO_DATE (b.test_date || b.test_time,
                                 'yyyymmddhh24:mi:ss'
                                ) <
                           TO_DATE (v_end_time,
                                    'YYYY/MM/DD HH24:MI:SS'
                                   )
               GROUP BY b.model_name,
                        b.mo_number,
                        b.station_type,
                        b.serial_number) aa
               LEFT JOIN
                        (SELECT DISTINCT b.model_name,
                                         b.mo_number,
                                         b.station_type,
                                         b.serial_number,
                        MIN (TO_DATE (b.test_date || b.test_time,
                                      'yyyymmddhh24:mi:ss'
                                     )
                            ) AS test_time
                         FROM sfism4.h_test_temp_t b,
                              --web.c_model_info_t web,
                              sfism4.r_wip_tracking_t p
                        WHERE (UPPER (p.customer_no) LIKE 'NV%'  OR upper(p.customer_no)='MELLANOX')
                              AND b.serial_number = p.serial_number and upper(b.error_code)<>'OTHERS'
                              AND b.model_name = p.model_name
                              AND b.MO_NUMBER = p.MO_NUMBER --ruanshiqiao ADD 20250925
                              --AND p.model_name = web.model_name
                              AND p.model_name =
                                             detailmodel.MODEL_NAME
                       GROUP BY b.model_name,
                                b.mo_number,
                                b.station_type,
                                b.serial_number) bb
            ON aa.serial_number = bb.serial_number
               AND aa.station_type = bb.station_type
               LEFT JOIN 
                                 (SELECT DISTINCT a.group_name, a.serial_number,
                                 MIN (a.in_station_time) AS in_station_time
                         FROM (SELECT DISTINCT a.group_name,a.model_name,a.mo_number,a.serial_number,a.in_station_time
                                 FROM sfism4.r_sn_detail_t a,
                                      --web.c_model_info_t web,
                                      sfism4.r_wip_tracking_t p
                                WHERE (UPPER (p.customer_no) LIKE 'NV%'  OR upper(p.customer_no)='MELLANOX')
                                      AND a.serial_number = p.serial_number
                                      AND a.model_name = p.model_name
                                      AND a.MO_NUMBER = p.MO_NUMBER --ruanshiqiao ADD 20250925
                                      --AND p.model_name = web.model_name
                                      AND p.model_name =
                                                      detailmodel.MODEL_NAME
                                      ) a
                        left join (SELECT distinct model_name,
                                                  mo_number,
                                                  TEST_STATION,
                                                  serial_number,
                                                  test_time
                                           FROM sfism4.R_REPAIR_T
                                           WHERE model_name =
                                                         detailmodel.MODEL_NAME
                                                 and regexp_like(TEST_CODE,'98[A-Za-z]{1}')) b
                        ON a.model_name=b.model_name and a.mo_number=b.mo_number and b.TEST_STATION like a.GROUP_NAME||'%' and a.serial_number=b.serial_number and A.IN_STATION_TIME=B.TEST_TIME
                        where b.serial_number is null
                        group by a.group_name, a.serial_number                             
                 ) cc
               ON aa.serial_number = cc.serial_number
               AND aa.station_type = cc.group_name
             LEFT JOIN sfism4.h_test_temp_t dd
               ON aa.serial_number = dd.serial_number
                    AND aa.station_type = dd.station_type
                    AND aa.test_time =
                          TO_DATE (dd.test_date || dd.test_time, 'yyyymmddhh24:mi:ss')
            WHERE aa.test_time = bb.test_time and (aa.test_time <= cc.in_station_time or cc.in_station_time is null);                                             




      v_res := 'Insert Adjust Fail Detail error!' || detailmodel.MODEL_NAME;

      INSERT INTO SFISM4.O_FAIL_DETAIL_T (work_date,
                                          FAIL_TYPE,
                                          Model_name,
                                          mo_number,
                                          group_name,
                                          serial_number,
                                          in_station_time,
                                          test_code,
                                          REASON_CODE,
                                          ERROR_ITEM_CODE)
            SELECT DISTINCT v_start_date,
                            'ADJUST' AS TYPR,
                            aa.MODEL_NAME,
                            aa.MO_NUMBER,
                            cc.group_name,
                            aa.serial_number,
                            aa.test_time,
                            ee.test_code,
                            ee.REASON_CODE,
                            ee.ERROR_ITEM_CODE
                        FROM (SELECT DISTINCT
                             b.MODEL_NAME,
                             b.MO_NUMBER,
                             b.TEST_STATION,
                             b.serial_number,
                             MIN (b.TEST_TIME) AS TEST_TIME
                        FROM sfism4.R_REPAIR_T b,
                             --WEB.C_MODEL_INFO_T web,
                             sfism4.r_wip_tracking_t p
                       WHERE (UPPER (p.customer_no) LIKE 'NV%'  OR upper(p.customer_no)='MELLANOX')
                             AND B.SERIAL_NUMBER = P.SERIAL_NUMBER
                              AND b.MO_NUMBER = p.MO_NUMBER --ruanshiqiao ADD 20250925
                             --AND P.MODEL_NAME = WEB.MODEL_NAME
                             and not regexp_like(B.TEST_CODE,'98[A-Za-z]{1}')
                             AND p.MODEL_NAME =
                                        detailmodel.MODEL_NAME
                             AND b.TEST_TIME >=
                                    TO_DATE (v_start_time,
                                             'YYYY/MM/DD HH24:MI:SS')
                             AND b.TEST_TIME <
                                    TO_DATE (v_end_time,
                                             'YYYY/MM/DD HH24:MI:SS')
                    GROUP BY b.MODEL_NAME,
                             b.MO_NUMBER,
                             b.TEST_STATION,
                             b.serial_number) aa
                   left join( select MODEL_NAME,MO_NUMBER,TEST_STATION,serial_number,min(test_time) as test_time 
                              from sfism4.R_REPAIR_T 
                              where  MODEL_NAME =
                                         detailmodel.MODEL_NAME
                                     and not regexp_like(TEST_CODE,'98[A-Za-z]{1}') 
                              group by MODEL_NAME,MO_NUMBER,TEST_STATION,serial_number ) bb on aa.serial_number=bb.serial_number and aa.TEST_STATION=bb.TEST_STATION
                   left join(SELECT DISTINCT a.MODEL_NAME,a.MO_NUMBER,a.group_name,a.serial_number,MIN (a.in_station_time) AS in_station_time
                        FROM sfism4.r_sn_detail_t a,
                             sfism4.R_REPAIR_T b,
                             --WEB.C_MODEL_INFO_T web,
                             sfism4.r_wip_tracking_t p
                       WHERE (UPPER (p.customer_no) LIKE 'NV%'  OR upper(p.customer_no)='MELLANOX')
                             and A.SERIAL_NUMBER=P.SERIAL_NUMBER
                             and A.MODEL_NAME=p.MODEL_NAME 
                             AND B.SERIAL_NUMBER = P.SERIAL_NUMBER
                              AND a.MO_NUMBER = b.MO_NUMBER --ruanshiqiao ADD 20250925
                               AND a.MO_NUMBER = p.MO_NUMBER --ruanshiqiao ADD 20250925
                             --AND P.MODEL_NAME = WEB.MODEL_NAME
                             and not regexp_like(B.TEST_CODE,'98[A-Za-z]{1}')
                             AND p.MODEL_NAME =
                                       detailmodel.MODEL_NAME
                             AND b.TEST_TIME >=
                                    TO_DATE (v_start_time,
                                             'YYYY/MM/DD HH24:MI:SS')
                             AND b.TEST_TIME <
                                    TO_DATE (v_end_time,
                                             'YYYY/MM/DD HH24:MI:SS')
                    GROUP BY a.MODEL_NAME,
                             a.MO_NUMBER,
                             a.group_name,
                             a.serial_number)cc on aa.serial_number=cc.serial_number
                   --left join (SELECT serial_number,STATION_TYPE FROM sfism4.H_TEST_TEMP_T where  MODEL_NAME = detailmodel.MODEL_NAME) dd
                                         -- on aa.serial_number=dd.serial_number AND cc.group_name = dd.STATION_TYPE
                   LEFT JOIN sfism4.R_REPAIR_T ee ON aa.model_name=ee.model_name and aa.mo_number=ee.mo_number and aa.serial_number = ee.serial_number
                             AND aa.TEST_STATION = ee.TEST_STATION
                             AND aa.TEST_TIME = ee.TEST_TIME                        
                   where  aa.test_time=bb.test_time
                         and not regexp_like(ee.TEST_CODE,'98[A-Za-z]{1}')
                         and aa.test_time=cc.in_station_time
                       --and dd.serial_number IS null
                         and aa.TEST_STATION like cc.GROUP_NAME||'%';



      v_res := 'Insert Input O_REPORT_T  error!' || detailmodel.MODEL_NAME;

      INSERT INTO SFISM4.O_REPORT_T (work_date,
                                     model_name,
                                     mo_number,
                                     group_name,
                                     input_qty,
                                     first_qty,
                                     adjusted_qty,
                                     output_qty)
         SELECT v_start_date,
                model_name,
                mo_number,
                group_name,
                TO_NUMBER (input),
                TO_NUMBER (FIRST),
                TO_NUMBER (Adjusted),
                TO_NUMBER (input - Adjusted) AS Output
           FROM (  SELECT m.MODEL_NAME,
                          m.MO_NUMBER,
                          m.group_name,
                          COUNT (m.serial_number) AS input,
                          (CASE WHEN n.FIRST IS NULL THEN 0 ELSE n.FIRST END)
                             AS FIRST,
                          (CASE
                              WHEN e.Adjusted IS NULL THEN 0
                              ELSE e.Adjusted
                           END)
                             AS Adjusted
                     FROM (SELECT distinct model_name,
                                  mo_number,
                                  group_name,
                                  serial_number,
                                  in_station_time
                             FROM sfism4.O_INPUT_DETAIL_T
                            WHERE     work_date = v_start_date
                                  AND model_name = detailmodel.MODEL_NAME) m
                          LEFT JOIN (  SELECT model_name,
                                              mo_number,
                                              group_name,
                                              COUNT (serial_number) AS FIRST
                                         FROM (SELECT distinct model_name,
                                                      mo_number,
                                                      group_name,
                                                      serial_number,
                                                      in_station_time
                                                 FROM sfism4.O_FAIL_DETAIL_T
                                                WHERE     work_date =
                                                             v_start_date
                                                      AND model_name =
                                                             detailmodel.MODEL_NAME
                                                      AND fail_type = 'FIRST')
                                     GROUP BY group_name, model_name, mo_number) n
                             ON     m.group_name = n.group_name
                                AND m.model_name = n.model_name
                                AND m.mo_number = n.mo_number
                          LEFT JOIN (  SELECT model_name,
                                              MO_NUMBER,
                                              group_name,
                                              COUNT (serial_number) AS Adjusted
                                         FROM (SELECT distinct model_name,
                                                      mo_number,
                                                      group_name,
                                                      serial_number,
                                                      in_station_time
                                                 FROM sfism4.O_FAIL_DETAIL_T
                                                WHERE     work_date =
                                                             v_start_date
                                                      AND model_name =
                                                             detailmodel.MODEL_NAME
                                                      AND fail_type = 'ADJUST')
                                     GROUP BY model_name, MO_NUMBER, group_name) e
                             ON     m.group_name = e.group_name
                                AND m.model_name = e.model_name
                                AND m.mo_number = e.mo_number
                 GROUP BY m.MODEL_NAME,
                          m.MO_NUMBER,
                          m.group_name,
                          n.FIRST,
                          e.Adjusted);
   END LOOP;

   v_res := 'update end_date error!';

   UPDATE sfis1.C_PARAMETER_INI
      SET vr_value = v_end_date, LAST_MODIFY_DATE = SYSDATE,vr_desc='OK'
    WHERE     PRG_NAME = 'O_REPORT'
          AND vr_class = 'NVD'
          AND VR_ITEM = 'O_GET_REPORT_DATA_T'
          AND vr_name = 'LAST_GET_TIME_FOR_0AM';

   COMMIT;
EXCEPTION
   WHEN OTHERS
   THEN
      rollback;
      UPDATE sfis1.C_PARAMETER_INI
         SET VR_DESC = v_res, LAST_MODIFY_DATE = SYSDATE
       WHERE     PRG_NAME = 'O_REPORT'
             AND vr_class = 'NVD'
             AND VR_ITEM = 'O_GET_REPORT_DATA_T'
             AND vr_name = 'LAST_GET_TIME_FOR_0AM';
END; 