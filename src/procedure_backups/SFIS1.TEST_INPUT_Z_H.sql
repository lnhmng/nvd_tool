PROCEDURE                         test_input_z_h (
   emp         IN       VARCHAR2,
   line        IN       VARCHAR2,
   section     IN       VARCHAR2,
   w_station   IN       VARCHAR2,
   datetime    IN       DATE,
   ec          IN       VARCHAR2,
   DATA        IN       VARCHAR2,
   mo_date     IN       VARCHAR2,
   w_section   IN       NUMBER,
   mygroup     IN       VARCHAR2,
   res         OUT      VARCHAR2
)
AS
   g         VARCHAR2 (25);
   mo        VARCHAR2 (25);
   ok        VARCHAR2 (16);
   c_model   VARCHAR2 (25);
   p_type    VARCHAR2 (1);
   --- add by Derrick on 2011-09-09 for Project P1108017 
   H1RES   VARCHAR2(50);
   HRES    VARCHAR2(50);
   e_H1RES_ERROR  EXCEPTION;
   e_HRES_ERROR  EXCEPTION;
   --- add by Derrick  on 2011-09-09 for Project P1108017 
BEGIN
   g := '';
   mo := '';
   ok := 'OK';

   SELECT mo_number, model_name
     INTO mo, c_model
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = DATA AND ROWNUM = 1;

   ------------- ADD  BY Derrick on 2011-09-09 for Project P1108017 Begin
   sfis1.check_lsa_h1 (DATA, line, mygroup, h1res);

   IF h1res <> 'OK'
   THEN
      RAISE e_h1res_error;
   END IF;
   --------- ADD  BY Derrick on 2011-09-09 for Project P1108017  end
   IF ec = 'N/A'
   THEN
      check_route (line, mygroup, DATA, ok);

      IF ok = 'OK'
      THEN
         stn_rec_z (line,
                    section,
                    mygroup,
                    w_station,
                    mo,
                    DATA,
                    mo_date,
                    w_section,
                    '0'
                   );

         IF w_station = 'I_RUN_IN'
         THEN
            update_run_in (emp,
                           line,
                           section,
                           mygroup,
                           w_station,
                           mo,
                           DATA,
                           '0',
                           datetime
                          );
            res := ok;
         ELSE
            update_r107 (emp,
                         line,
                         section,
                         mygroup,
                         w_station,
                         mo,
                         DATA,
                         '0',
                         datetime
                        );
            update_rlsa_h (DATA, line, mygroup, mo, ec, res);
            res := ok;
         END IF;
      ELSE
         res := ok;
      END IF;
   ELSE
      SELECT group_name
        INTO g
        FROM sfism4.r_wip_tracking_t w, sfism4.r_repair_t r
       WHERE w.line_name = line
         AND w.group_name = mygroup
         AND w.serial_number = DATA
         AND ROWNUM = 1
         AND w.line_name = r.test_line
         AND r.test_station = w_station
         AND w.serial_number = r.serial_number;

      SELECT ERROR_TYPE
        INTO p_type
        FROM sfis1.c_error_code_t
       WHERE ERROR_CODE = ec;

      IF p_type = 'W'
      THEN
         INSERT INTO sfism4.r_repair_t
                     (serial_number, mo_number, test_time, test_code,
                      test_station, test_line, record_type, model_name,
                      repairer, repair_time, reason_code, repair_station,
                      repair_status, duty_type, error_item_code
                     )
              VALUES (DATA, mo, datetime, ec,
                      w_station, line, 'T', c_model,
                      w_station, datetime, 'ERQ002', w_station,
                      'N', 'W', 'A0000'
                     );
      ELSE
         update_r107 (emp,
                      line,
                      section,
                      mygroup,
                      w_station,
                      mo,
                      DATA,
                      '1',
                      datetime
                     );

         INSERT INTO sfism4.r_repair_t
                     (serial_number, mo_number, test_time, test_code,
                      test_station, test_line, record_type, model_name
                     )
              VALUES (DATA, mo, datetime, ec,
                      w_station, line, 'T', c_model
                     );
      END IF;

      update_rlsa_h (DATA, line, mygroup, mo, ec, res);
       --------- ADD  BY Derrick on 2011-09-09 for Project P1108017 Begin      
         SFIS1.CHECK_LSA_H (DATA ,LINE ,MYGROUP , HRES );
    
         IF H1RES<>'OK' THEN
    
          RAISE  e_HRES_ERROR;
    
          END IF; 
        --------- ADD  BY Derrick on 2011-09-09 for Project P1108017 end
      res := 'OK';
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      check_route (line, mygroup, DATA, ok);

      IF ok = 'OK'
      THEN
         stn_rec_z (line,
                    section,
                    mygroup,
                    w_station,
                    mo,
                    DATA,
                    mo_date,
                    w_section,
                    '1'
                   );

         SELECT ERROR_TYPE
           INTO p_type
           FROM sfis1.c_error_code_t
          WHERE ERROR_CODE = ec;

         IF p_type = 'W'
         THEN
            update_r107 (emp,
                         line,
                         section,
                         mygroup,
                         w_station,
                         mo,
                         DATA,
                         '0',
                         datetime
                        );

            INSERT INTO sfism4.r_repair_t
                        (serial_number, mo_number, test_time, test_code,
                         test_station, test_line, record_type, model_name,
                         repairer, repair_time, reason_code, repair_station,
                         repair_status, duty_type, error_item_code
                        )
                 VALUES (DATA, mo, datetime, ec,
                         w_station, line, 'T', c_model,
                         w_station, datetime, 'ERQ002', w_station,
                         'N', 'W', 'A0000'
                        );
         ELSE
            update_r107 (emp,
                         line,
                         section,
                         mygroup,
                         w_station,
                         mo,
                         DATA,
                         '1',
                         datetime
                        );

            INSERT INTO sfism4.r_repair_t
                        (serial_number, mo_number, test_time, test_code,
                         test_station, test_line, record_type, model_name
                        )
                 VALUES (DATA, mo, datetime, ec,
                         w_station, line, 'T', c_model
                        );
         END IF;

         update_rlsa_h (DATA, line, mygroup, mo, ec, res);
         
         --------- ADD  BY Derrick on 2011-09-09 for Project P1108017 Begin      
         SFIS1.CHECK_LSA_H (DATA ,LINE ,MYGROUP , HRES );
    
         IF H1RES<>'OK' THEN
    
          RAISE  e_HRES_ERROR;
    
          END IF; 
      --------- ADD  BY Derrick on 2011-09-09 for Project P1108017 end
      END IF;

      res := ok;
END;