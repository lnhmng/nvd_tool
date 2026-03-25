PROCEDURE             npi_check_smt(
   line      IN       VARCHAR2,
   mygroup   IN       VARCHAR2,
   DATA      IN       VARCHAR2,
   res       OUT      VARCHAR2
)
AS
   group_name        VARCHAR (20);
   line_name         VARCHAR (10);
   sn1               VARCHAR (20);
   sn_count1         VARCHAR (20);
   station           VARCHAR (20);
   key_diag          VARCHAR (100);
   group_name1       VARCHAR (20);
   countdiag         VARCHAR (20);
   countecid         VARCHAR (20);
   key_ecid          VARCHAR (100);
   countbios         VARCHAR (20);
   counsndiag        VARCHAR (10);
   flag              VARCHAR (2);
   models            VARCHAR (20);
   bioss             VARCHAR (20);
   biosss            VARCHAR (20);
   modelss           VARCHAR (20);
   flag1             VARCHAR (20);
   e_error           EXCEPTION;
   station_error     EXCEPTION;
   station_correct   EXCEPTION;
   sn_error          EXCEPTION;

   CURSOR carton
   IS
      SELECT serial_number
        FROM sfism4.r_wip_tracking_t
       WHERE (carton_no = DATA) or (serial_number=DATA);

   row1              carton%ROWTYPE;
BEGIN
   SELECT DISTINCT (group_name)
              INTO station
              FROM sfism4.r_wip_tracking_t
             WHERE (serial_number = DATA OR carton_no = DATA);

   IF station IS NULL
   THEN
      RAISE station_error;
   END IF;

      IF mygroup = 'NPI_OUT1'
      THEN
         OPEN carton;

         FETCH carton
          INTO row1;

         IF carton%FOUND
         THEN
            LOOP
               EXIT WHEN carton%NOTFOUND;

               IF SUBSTR (row1.serial_number, 0, 3) = '133'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET section_name = mygroup,
                         group_name = mygroup,
                         in_station_time = SYSDATE
                   WHERE serial_number = row1.serial_number;

                  SELECT COUNT (serial_number)
                    INTO counsndiag
                    FROM sfism4.r_link_t
                   WHERE serial_number = row1.serial_number AND flag = 'DIAG';

                  IF counsndiag > 0
                  THEN
                     SELECT key_value
                       INTO key_diag
                       FROM sfism4.r_link_t
                      WHERE serial_number = row1.serial_number
                        AND flag = 'DIAG'
                        AND create_dt =
                               (SELECT MAX (create_dt) AS maxtime
                                  FROM sfism4.r_link_t
                                 WHERE serial_number = row1.serial_number
                                   AND flag = 'DIAG');

                     INSERT INTO sfism4.r_link_t
                                 (serial_number, key_value, available, flag,
                                  create_by, create_dt, last_edit_by,
                                  last_edit_dt, group_name
                                 )
                          VALUES (row1.serial_number, key_diag, '0', 'DIAG',
                                  SYSDATE, SYSDATE, '',
                                  '', mygroup
                                 );

                     --- add  by   LY   20200608
                     SELECT COUNT (serial_number)
                       INTO countecid
                       FROM sfism4.r_link_t
                      WHERE serial_number = row1.serial_number
                        AND flag = 'ECID';

                     IF countecid > 0
                     THEN
                        SELECT key_value
                          INTO key_ecid
                          FROM sfism4.r_link_t
                         WHERE serial_number = row1.serial_number
                           AND flag = 'ECID'
                           AND create_dt =
                                  (SELECT MAX (create_dt) AS maxtime
                                     FROM sfism4.r_link_t
                                    WHERE serial_number = row1.serial_number
                                      AND flag = 'ECID');

                        INSERT INTO sfism4.r_link_t
                                    (serial_number, key_value, available,
                                     flag, create_by, create_dt,
                                     last_edit_by, last_edit_dt, group_name
                                    )
                             VALUES (row1.serial_number, key_ecid, '0',
                                     'ECID', SYSDATE, SYSDATE,
                                     '', '', mygroup
                                    );
                     END IF;

                     UPDATE sfism4.r_nvbios_model_t
                        SET group_name = mygroup,
                            datetime = SYSDATE
                      WHERE serial_number = row1.serial_number;
                  ELSE
                     INSERT INTO sfism4.r_link_t
                                 (serial_number, key_value, available,
                                  flag, create_by, create_dt, last_edit_by,
                                  last_edit_dt, group_name
                                 )
                          VALUES (row1.serial_number, 'NO_TEST', '0',
                                  'DIAG', SYSDATE, SYSDATE, '',
                                  '', mygroup
                                 );
                  END IF;
               END IF;

               FETCH carton
                INTO row1;

               IF SUBSTR (row1.serial_number, 0, 3) = '132'
               THEN
                  RAISE station_correct;
               END IF;
            END LOOP;

            RAISE station_correct;
         END IF;

         CLOSE carton;
      END IF;
      
      
   IF station = 'OUT'
   THEN
      SELECT COUNT (*)
        INTO countdiag
        FROM sfism4.r_link_t
       WHERE serial_number = DATA AND flag = 'DIAG';

      IF countdiag > 0
      THEN
         SELECT key_value
           INTO key_diag
           FROM sfism4.r_link_t
          WHERE serial_number = DATA
            AND flag = 'DIAG'
            AND create_dt = (SELECT MAX (create_dt) AS maxtime
                               FROM sfism4.r_link_t
                              WHERE serial_number = DATA AND flag = 'DIAG');

         INSERT INTO sfism4.r_link_t
                     (serial_number, key_value, available, flag, create_by,
                      create_dt, last_edit_by, last_edit_dt, group_name
                     )
              VALUES (DATA, key_diag, '0', 'DIAG', SYSDATE,
                      SYSDATE, '', '', mygroup
                     );

         UPDATE sfism4.r_wip_tracking_t
            SET section_name = mygroup,
                group_name = mygroup,
                in_station_time = SYSDATE
          WHERE serial_number = DATA;

         SELECT COUNT (*)
           INTO countbios
           FROM sfism4.r_nvbios_model_t
          WHERE serial_number = DATA;

         IF countbios > 0
         THEN
            UPDATE sfism4.r_nvbios_model_t
               SET group_name = mygroup,
                   datetime = SYSDATE
             WHERE serial_number = DATA;
         END IF;

         RAISE station_correct;
      END IF;
   END IF;

   IF station = 'OUT'
   THEN
      SELECT COUNT (*)
        INTO countdiag
        FROM sfism4.r_link_t
       WHERE serial_number = DATA AND flag = 'DIAG';

      IF (countdiag = 0) OR (countdiag IS NULL)
      THEN
         INSERT INTO sfism4.r_link_t
                     (serial_number, key_value, available, flag, create_by,
                      create_dt, last_edit_by, last_edit_dt, group_name
                     )
              VALUES (DATA, 'NO_TEST', '0', 'DIAG', SYSDATE,
                      SYSDATE, '', '', mygroup
                     );

--select * from sfism4.r107
         UPDATE sfism4.r_wip_tracking_t
            SET section_name = mygroup,
                group_name = mygroup,
                in_station_time = SYSDATE
          WHERE serial_number = DATA;

         SELECT COUNT (*)
           INTO countbios
           FROM sfism4.r_nvbios_model_t
          WHERE serial_number = DATA;

         IF countbios > 0
         THEN
            UPDATE sfism4.r_nvbios_model_t
               SET group_name = mygroup,
                   datetime = SYSDATE
             WHERE serial_number = DATA;
         END IF;

         RAISE station_correct;
      END IF;
   END IF;

   --- add  by   LY   20200608
   IF station = 'OUT'
   THEN
      SELECT COUNT (*)
        INTO countecid
        FROM sfism4.r_link_t
       WHERE serial_number = DATA AND flag = 'ECID';

      IF countecid > 0
      THEN
         SELECT key_value
           INTO key_ecid
           FROM sfism4.r_link_t
          WHERE serial_number = DATA
            AND flag = 'ECID'
            AND create_dt = (SELECT MAX (create_dt) AS maxtime
                               FROM sfism4.r_link_t
                              WHERE serial_number = DATA AND flag = 'ECID');

         INSERT INTO sfism4.r_link_t
                     (serial_number, key_value, available, flag, create_by,
                      create_dt, last_edit_by, last_edit_dt, group_name
                     )
              VALUES (DATA, key_ecid, '0', 'ECID', SYSDATE,
                      SYSDATE, '', '', mygroup
                     );

         UPDATE sfism4.r_wip_tracking_t
            SET section_name = mygroup,
                group_name = mygroup,
                in_station_time = SYSDATE
          WHERE serial_number = DATA;

         SELECT COUNT (*)
           INTO countbios
           FROM sfism4.r_nvbios_model_t
          WHERE serial_number = DATA;

         IF countbios > 0
         THEN
            UPDATE sfism4.r_nvbios_model_t
               SET group_name = mygroup,
                   datetime = SYSDATE
             WHERE serial_number = DATA;
         END IF;

         RAISE station_correct;
      END IF;
   END IF;

EXCEPTION
   WHEN e_error
   THEN
      res := 'PLEAS INPUT CARTON_NO OR SN!!!';
   WHEN station_error
   THEN
      res := 'PLEAS GO TO OUT OR PACKING!!!';
   WHEN station_correct
   THEN
      res := 'OK';
   WHEN sn_error
   THEN
      res := 'Please enter the correct SN!!!(133)';
   WHEN OTHERS
   THEN
      ROLLBACK;
      res := 'OTHER ERROR';
END;