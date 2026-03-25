PROCEDURE                               c_test_bp_system (
   --trantype   IN       VARCHAR2,
   sna   IN       VARCHAR2,
   snb   IN       VARCHAR2,
   res   OUT      VARCHAR2
)
AS
   countsn        VARCHAR (10);
   countbpsn      VARCHAR (10);
   countbpsna     VARCHAR (10);
   countbpsnb     VARCHAR (10);
   countbpsnc     VARCHAR (10);
   sn             VARCHAR (2);
   countrepair    VARCHAR (2);
   countrepair1   VARCHAR (2);
   countsna       VARCHAR (2);
   countdetail    VARCHAR (2);
   groupname      VARCHAR (20);
   flag           VARCHAR (5);
   qtys           VARCHAR (2);
   states         VARCHAR (2);
   group_names    VARCHAR (20);
   reapirtime     VARCHAR (2);
   locks          VARCHAR (20);
   e_null         EXCEPTION;
   e_flag         EXCEPTION;
   e_nulls        EXCEPTION;
   e_group        EXCEPTION;
   e_max          EXCEPTION;
   e_scrapt       EXCEPTION;
   e_maxs         EXCEPTION;
   e_not          EXCEPTION;
   e_lock         EXCEPTION;
BEGIN
   res := 'OK';

   SELECT COUNT (serial_number)
     INTO countsn
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = sna;

   IF countsn < 1
   THEN
      RAISE e_null;
   END IF;

   SELECT error_flag
     INTO flag
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = sna;

   IF flag > 0
   THEN
      RAISE e_flag;
   END IF;

   SELECT COUNT (serial_number)
     INTO countsna
     FROM sfis1.c_bp_product_t
    WHERE serial_number = sna;

   IF countsna > 0
   THEN
      RAISE e_maxs;
   END IF;

   SELECT state
     INTO states
     FROM sfis1.c_bp_product_t
    WHERE bp_sn = snb;

   IF states < 1
   THEN
      RAISE e_not;
   END IF;

   SELECT count(lock_unlock)
     INTO locks
     FROM sfis1.c_bp_product_t
    WHERE  bp_sn = snb and  LOCK_UNLOCK='lock'; 

   IF locks>0
   THEN
      RAISE e_lock;
   END IF;

   SELECT COUNT (bp_sn)
     INTO countbpsn
     FROM sfis1.c_bp_product_t
    WHERE bp_sn = snb;

   IF countbpsn < 1
   THEN
      RAISE e_nulls;
   END IF;

   --一次不良,更換連接器
   SELECT scrapt_qty
     INTO countbpsna
     FROM c_bp_product_t
    WHERE in_station_time = (SELECT MAX (in_station_time)
                               FROM c_bp_product_t
                              WHERE bp_sn = snb)
      AND scrapt_qty = '0'
      AND bp_sn = snb;

   IF countbpsna = 0
   THEN
      SELECT COUNT (qty)
        INTO qtys
        FROM sfis1.c_bp_product_t
       WHERE bp_sn = snb AND qty = '50';

      IF qtys > 0
      THEN
         UPDATE sfism4.r_wip_tracking_t
            SET error_flag = '1',
                next_station = 'R_690_AOI',
                in_station_time = SYSDATE
          WHERE serial_number = snb;

         INSERT INTO sfism4.r_repair_t
                     (serial_number, mo_number, model_name, test_time,
                      test_code, test_station, test_line
                     )
              VALUES (snb, 'BP0000001', 'BP0000', SYSDATE,
                      '985760', 'BBD', 'NVP01'
                     );
      END IF;
   END IF;

   SELECT COUNT (serial_number)
     INTO countrepair
     FROM sfism4.r_repair_t
    WHERE serial_number = snb;

   IF countrepair = '1'
   THEN
      SELECT repair_time
        INTO reapirtime
        FROM sfism4.r_repair_t
       WHERE serial_number = snb AND test_time = (SELECT MAX (test_time)
                                                    FROM sfism4.r_repair_t
                                                   WHERE serial_number = snb);

      IF (reapirtime <> '') OR (reapirtime IS NOT NULL)
      THEN
         UPDATE c_bp_product_t
            SET qty = '0',
                scrapt_qty = '1'
          WHERE bp_sn = snb;
      ELSE
         RAISE e_max;
      END IF;
   END IF;

   --二次不良,更換連接器
   SELECT COUNT (scrapt_qty)
     INTO countbpsnb
     FROM c_bp_product_t
    WHERE in_station_time = (SELECT MAX (in_station_time)
                               FROM c_bp_product_t
                              WHERE bp_sn = snb)
      AND scrapt_qty = '1'
      AND bp_sn = snb;

   IF countbpsnb > 0
   THEN
      SELECT COUNT (qty)
        INTO qtys
        FROM sfis1.c_bp_product_t
       WHERE bp_sn = snb AND qty = '50';

      IF qtys > 0
      THEN
         UPDATE sfism4.r_wip_tracking_t
            SET error_flag = '1',
                next_station = 'R_690_AOI',
                in_station_time = SYSDATE
          WHERE serial_number = snb;

         INSERT INTO sfism4.r_repair_t
                     (serial_number, mo_number, model_name, test_time,
                      test_code, test_station, test_line
                     )
              VALUES (snb, 'BP0000001', 'BP0000', SYSDATE,
                      '985760', 'BBD', 'NVP01'
                     );
      END IF;
   END IF;

   SELECT COUNT (serial_number)
     INTO countrepair1
     FROM sfism4.r_repair_t
    WHERE serial_number = snb;

   IF countrepair1 > '1'
   THEN
      SELECT repair_time
        INTO reapirtime
        FROM sfism4.r_repair_t
       WHERE serial_number = snb AND test_time = (SELECT MAX (test_time)
                                                    FROM sfism4.r_repair_t
                                                   WHERE serial_number = snb);

      IF (reapirtime <> '') OR (reapirtime IS NOT NULL)
      THEN
         UPDATE c_bp_product_t
            SET qty = '0',
                scrapt_qty = '2'
          WHERE bp_sn = snb;
      ELSE
         RAISE e_max;
      END IF;
   END IF;

   SELECT COUNT (bp_sn)
     INTO countbpsnc
     FROM sfis1.c_bp_product_t
    WHERE bp_sn = snb AND qty = '50';

   IF countbpsnc > 0
   THEN
      RAISE e_scrapt;
   END IF;

   SELECT error_flag
     INTO flag
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = snb;

   IF flag > 0
   THEN
      RAISE e_flag;
   END IF;

   SELECT COUNT (serial_number)
     INTO countdetail
     FROM sfism4.r_sn_detail_t
    WHERE serial_number = snb;

   IF countdetail > 0
   THEN
      SELECT b.group_name
        INTO group_names
        FROM (SELECT MAX (in_station_time) AS TIME
                FROM sfism4.r_sn_detail_t
               WHERE serial_number = snb) a,
             sfism4.r_sn_detail_t b
       WHERE a.TIME = b.in_station_time;

      IF (SUBSTR (group_names, 1, 7) <> '690_AOI')
      THEN
         RAISE e_group;
      END IF;
   END IF;

   SELECT COUNT (serial_number)
     INTO sn
     FROM sfis1.c_bp_product_t
    WHERE bp_sn = snb;

   IF sn < 1
   THEN
      UPDATE sfis1.c_bp_product_t
         SET serial_number = sna,
             qty = '1',
             in_station_time = SYSDATE;
   ELSE
      INSERT INTO sfis1.c_bp_product_t
         SELECT sna, snb, qtys + 1, '0', 'unlock', model_name, create_date,
                '0', '', SYSDATE, emp
           FROM (SELECT   MAX (qty) AS qtys, create_date, emp, model_name
                     FROM sfis1.c_bp_product_t
                    WHERE bp_sn = snb
                 GROUP BY create_date, emp, model_name) a;

      UPDATE sfism4.r_wip_tracking_t
         SET section_name = 'BBD',
             group_name = 'BBD',
             station_name = 'BBD'
       WHERE serial_number = sna;

      UPDATE sfism4.r_wip_tracking_t
         SET section_name = 'BBD',
             group_name = 'BBD',
             station_name = 'BBD',
             next_station = '690_AOI'
       WHERE serial_number = snb;
   END IF;
EXCEPTION
   WHEN e_null
   THEN
      res := 'NO SN!!!';
   WHEN e_flag
   THEN
      res := 'GO TO REPAIR!!!';
   WHEN e_nulls
   THEN
      res := 'BP Sn does not exist!!!';
   WHEN e_group
   THEN
      res := 'LAST STATION NO AOI!!!';
   WHEN e_max
   THEN
      res := 'Used 50 times PLEASE REPAIR';
   WHEN e_scrapt
   THEN
      res := 'BP_SN IS  E_SCRAPT!!!';
   WHEN e_maxs
   THEN
      res := 'SN IS BOUND !!!';
   WHEN e_not
   THEN
      res := 'E2992 SN  Not on-line!!! ';
   WHEN e_lock
   THEN
      res := 'E2992 SN  IS LOCK !!!';
END;