PROCEDURE               test_lga (
   ecid        IN       VARCHAR2,
   sn          IN       VARCHAR2,
   testtime    IN       VARCHAR2,
   RESULT      IN       VARCHAR2,
   ec          IN       VARCHAR2,
   test_ecid   IN       VARCHAR2,
   res         OUT      VARCHAR2
)
IS
   v_cnt     NUMBER (3, 0);
   v_sncnt   NUMBER (3, 0);
   v_flg     VARCHAR2 (3);
   v_res     VARCHAR2 (20);
   v_date    DATE;
   v_pos     NUMBER (3, 0);
   v_ecid    VARCHAR2 (40);
   v_ecida   VARCHAR2 (40);
   p_upres   VARCHAR2 (100);
   e_null    EXCEPTION;

   --the procedure is used to update data to database
   PROCEDURE update_lga_result (
      sn         IN       VARCHAR2,
      ecid       IN       VARCHAR2,
      e_result   IN       VARCHAR2,
      e_time     IN       VARCHAR2,
      res        OUT      VARCHAR2
   )
   IS
      p_ecid0   VARCHAR2 (40);
      p_ecid1   VARCHAR2 (40);
      e_null    EXCEPTION;
   BEGIN
      res := 'OK';

      SELECT NVL (ecid0, 'N/A'), NVL (ecid1, 'N/A')
        INTO p_ecid0, p_ecid1
        FROM sfism4.r_bga_t
       WHERE serial_number = sn
         AND bga_time = (SELECT MAX (bga_time)
                           FROM sfism4.r_bga_t
                          WHERE serial_number = sn)
         AND ROWNUM = 1;

      CASE ecid
         WHEN 'SINGLE'
         THEN
            --if ECID0=null upload data
            --else raise error
            IF p_ecid0 = 'N/A'
            THEN
               UPDATE sfism4.r_bga_t
                  SET ecid0_lga_result = e_result,
                      ecid0_lga_time = e_time,
                      ecid0 = 'NONE'
                WHERE serial_number = sn
                  AND bga_time = (SELECT MAX (bga_time)
                                    FROM sfism4.r_bga_t
                                   WHERE serial_number = sn);
            ELSE
               res := 'LGA TEST DUPLICATED0!';
               RAISE e_null;
            END IF;
         WHEN 'DOUBLE'
         THEN
            --if ecid0 is null upload data
            --else if ecid1 is null upload data
            --else error
            IF p_ecid0 = 'N/A'
            THEN
               UPDATE sfism4.r_bga_t
                  SET ecid0_lga_result = e_result,
                      ecid0_lga_time = e_time,
                      ecid0 = 'NONE'
                WHERE serial_number = sn
                  AND bga_time = (SELECT MAX (bga_time)
                                    FROM sfism4.r_bga_t
                                   WHERE serial_number = sn);
            ELSE
               IF p_ecid1 = 'N/A'
               THEN
                  UPDATE sfism4.r_bga_t
                     SET ecid1_lga_result = e_result,
                         ecid1_lga_time = e_time,
                         ecid1 = 'NONE'
                   WHERE serial_number = sn
                     AND bga_time = (SELECT MAX (bga_time)
                                       FROM sfism4.r_bga_t
                                      WHERE serial_number = sn);
               ELSE
                  res := 'LGA TEST DUPLICATED1!';
                  RAISE e_null;
               END IF;
            END IF;
         ELSE
            --if ecid0 is null upload data
            --else if ecid0=ecid then error
            --else if ecid1 is null upload data
            --else error
            IF p_ecid0 = 'N/A'
            THEN
               UPDATE sfism4.r_bga_t
                  SET ecid0_lga_result = e_result,
                      ecid0_lga_time = e_time,
                      ecid0 = ecid
                WHERE serial_number = sn
                  AND bga_time = (SELECT MAX (bga_time)
                                    FROM sfism4.r_bga_t
                                   WHERE serial_number = sn);
            ELSE
               --CHECK IF THE ECID HAS BEEN UPLOADED BEFORE
               IF p_ecid0 = ecid
               THEN
                  res := 'LGA TEST DUPLICATED2!';
                  RAISE e_null;
               END IF;

               IF p_ecid1 = 'N/A'
               THEN
                  UPDATE sfism4.r_bga_t
                     SET ecid1_lga_result = e_result,
                         ecid1_lga_time = e_time,
                         ecid1 = ecid
                   WHERE serial_number = sn
                     AND bga_time = (SELECT MAX (bga_time)
                                       FROM sfism4.r_bga_t
                                      WHERE serial_number = sn);
               ELSE
                  res := 'LGA TEST DUPLICATED3!';
                  RAISE e_null;
               END IF;
            END IF;
      END CASE;

      COMMIT;
   EXCEPTION
      WHEN e_null
      THEN
         ROLLBACK;
      WHEN OTHERS
      THEN
         ROLLBACK;
         res := 'LGA TEST ERROR:' || SUBSTR (SQLERRM, 1, 50);
   -- MAC LAST CHAR MUST BE 0 ~ F
   END;
BEGIN
   IF TRIM (ecid) <> 'N/A'
   THEN
      IF LENGTH (ecid) < 12
      THEN
         res := 'ECID IS NO LONGER THAN 12';
         RAISE e_null;
      END IF;

      --for the function that get Sn by ECID
      SELECT COUNT (serial_number)
        INTO v_sncnt
        FROM sfism4.r_link_t
       WHERE available = '0' AND flag = 'ECID' AND key_value = ecid;

      IF v_sncnt > 0
      THEN
         -- one GPU
         --N40588-07_x-2_y01;0
         SELECT serial_number
           INTO res
           FROM (SELECT   serial_number
                     FROM sfism4.r_link_t
                    WHERE available = '0' AND flag = 'ECID'
                          AND key_value = ecid
                 ORDER BY create_dt DESC) a
          WHERE ROWNUM = 1;
      ELSE
         -- two or more GUP
         SELECT COUNT (serial_number)
           INTO v_sncnt
           FROM sfism4.r_link_t
          WHERE available = '0'
            AND flag = 'ECID'
            AND (   key_value LIKE SUBSTR (ecid, 0, 5) || '%' || ecid || '%'
                 OR key_value LIKE ecid || '%'
                )
            AND ROWNUM = 1;

         IF v_sncnt > 0
         THEN
            -- the formate is one GPU directly
            --N40588-07_x-2_y01
            SELECT serial_number
              INTO res
              FROM sfism4.r_link_t
             WHERE available = '0'
               AND flag = 'ECID'
               AND (   key_value LIKE SUBSTR (ecid, 0, 5) || '%' || ecid
                                      || '%'
                    OR key_value LIKE ecid || '%'
                   )
               AND ROWNUM = 1;
         ELSE
            --same formate with one GUP
            --N40588-07_x-2_y01;0
            SELECT INSTR (TRIM (ecid), ';')
              INTO v_pos
              FROM DUAL;

            IF v_pos = 0
            THEN
               res := 'ECID:' || ecid || ' ERROR!';
               RAISE e_null;
            END IF;

            SELECT SUBSTR (TRIM (ecid), 0, v_pos - 1)
              INTO v_ecida
              FROM DUAL;

            --SELECT SUBSTR(TRIM(ECID),v_POS+1,LENGTH(TRIM(ECID))-v_POS) INTO v_ECIDB FROM DUAL;
            SELECT serial_number
              INTO res
              FROM sfism4.r_link_t
             WHERE available = '0'
               AND flag = 'ECID'
               AND (   key_value LIKE SUBSTR (ecid, 0, 5) || '%' || ecid
                                      || '%'
                    OR key_value LIKE ecid || '%'
                   )
               AND ROWNUM = 1;
         END IF;
      END IF;
   ELSE
      --to upload the test log of LGA
      SELECT COUNT (*)
        INTO v_cnt
        FROM sfism4.r_bga_t
       WHERE serial_number = sn;

      IF v_cnt = 0
      THEN
         res := 'NO BGA RECORD!';
         RAISE e_null;
      END IF;

      IF TRIM (RESULT) = 'PASS'
      THEN
         v_res := TRIM (RESULT);                                      -- pass
         v_flg := '0';
      ELSE
         v_res := TRIM (ec);                                           --fail
         v_flg := '1';
      END IF;

      SELECT TO_DATE (testtime, 'YYYYMMDDHH24MISS')
        INTO v_date
        FROM DUAL;

      SELECT INSTR (TRIM (test_ecid), ';')
        INTO v_pos
        FROM DUAL;

      IF v_pos > 0
      THEN
         SELECT SUBSTR (TRIM (test_ecid), 0, v_pos - 1)
           INTO v_ecid
           FROM DUAL;
      ELSE
         v_ecid := TRIM (test_ecid);
      END IF;

      update_lga_result (sn, v_ecid, v_res, v_date, p_upres);

      IF p_upres = 'OK'
      THEN
         res := sn || '\n';
         res := res || v_flg;
      ELSE
         res := sn || '\n';
         res := res || p_upres;
      END IF;
   END IF;
EXCEPTION
   WHEN e_null
   THEN
      NULL;
   WHEN OTHERS
   THEN
      IF TRIM (ecid) <> 'N/A'
      THEN
         res := 'NO ECID RECORD!';
      ELSE
         ROLLBACK;
         res := sn || '\n';
         res := res || 'OTHER ERROR:' || SUBSTR (SQLERRM, 1, 60);
      END IF;
END;
/*
create by rain.liu on 2012-8-31 14:04:26 for S000000GFP
update by rain.liu on 2012-11-8 15:47:09 for S000000LZ3
*/