PROCEDURE                   TW_NG_SHIPPING (line      IN     VARCHAR2,
                                                  mygroup   IN     VARCHAR2,
                                                  DATA      IN     VARCHAR2,
                                                  res          OUT VARCHAR2)
AS
   group_name        VARCHAR (20);
   station           VARCHAR (20);
   flag              VARCHAR (10);
   ng_mo             VARCHAR (20);
   ng_model          VARCHAR (20);
   ng_test_code      VARCHAR (20);
   C_COUNT     NUMBER;
   station_error     EXCEPTION;
   station_correct   EXCEPTION;
   REPAIR_EXCP       EXCEPTION;
BEGIN
   IF mygroup = 'NG_CHECK'
   THEN
      SELECT group_name
        INTO station
        FROM sfism4.r_wip_tracking_t
       WHERE serial_number = DATA;

      IF station = 'NG_SHIPPING_600'
      THEN

       SELECT COUNT(*) INTO C_COUNT FROM  sfism4.r_repair_t WHERE serial_number = DATA;
       IF C_COUNT>0
       THEN
           SELECT MO_NUMBER, MODEL_NAME, TEST_CODE
           INTO ng_mo, ng_model, ng_test_code
           FROM sfism4.r_repair_t
          WHERE serial_number = DATA  and test_time=( SELECT MAX(test_tIME) FROM SFISM4.R_REPAIR_t where serial_number=DATA );
       ELSE 
              RAISE REPAIR_EXCP;
      END IF;

         INSERT INTO sfism4.r_repair_t (serial_number,
                                        mo_number,
                                        model_name,
                                        test_time,
                                        test_code,
                                        test_station,
                                        test_line)
              VALUES (DATA,
                      ng_mo,
                      ng_model,
                      SYSDATE,
                      ng_test_code,
                      'P_VI',
                      line);
               commit;       
         UPDATE sfism4.r_wip_tracking_t
            SET section_name = 'PTH',
                group_name = 'P_VI',
                station_name = 'NG_CHECK',
                error_flag = '1',
                line_name = line,
                in_station_time = SYSDATE
          WHERE serial_number = DATA;
        commit;

         RAISE station_correct;
      END IF;

      IF station = 'SHIPPING_600'
      THEN
         UPDATE sfism4.r_wip_tracking_t
            SET section_name = 'PTH',
                group_name = 'P_VI',
                station_name = 'NG_CHECK',
                error_flag = '0',
                line_name = line,
                in_station_time = SYSDATE
          WHERE serial_number = DATA;
            commit;
         RAISE station_correct;
      END IF;

      RAISE station_error;
   ELSE
      RAISE station_error;
   END IF;
EXCEPTION
   WHEN station_error
   THEN
      res := 'PLEAS GO TO Correct Station!!!';
   WHEN station_correct
   THEN
      res := 'OK';
   WHEN  REPAIR_EXCP
   THEN
        res:='NO REPAIR record';
   WHEN OTHERS
   THEN
      ROLLBACK;
      res := 'OTHER ERROR';
END;