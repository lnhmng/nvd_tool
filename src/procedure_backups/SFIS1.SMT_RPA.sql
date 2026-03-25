PROCEDURE       SMT_RPA
AS
   MO              VARCHAR2 (100 BYTE);
   SECTION1        VARCHAR2 (100 BYTE);
   MODEL1          VARCHAR2 (100 BYTE);
   section_count   INT;

   CURSOR pwd_cursor
   IS
      SELECT DISTINCT (model_name) FROM SFIS1.RPA_MODEL;

BEGIN
   
 DELETE FROM SFIS1.RPA_TOTALNUM;
   DELETE FROM SFIS1.RPA_MODEL;
   COMMIT;
        INSERT INTO SFIS1.RPA_MODEL
        SELECT DISTINCT(MODEL_NAME) FROM SFISM4.R_WIP_tRACKING_t WHERE IN_STATION_TIME  between
                     (TRUNC (SYSDATE - 1) + 8 / 24)
              AND  (TRUNC (SYSDATE) + 8 / 24);

   OPEN pwd_cursor;

   LOOP
      FETCH pwd_cursor INTO MODEL1;

      EXIT WHEN pwd_cursor%NOTFOUND;

      SELECT COUNT (*)
        INTO SECTION_count
        FROM SFIS1.RPA_TESTSECTION
       WHERE MODEL_NAME = MODEL1;

     

      IF section_count = 1
      THEN
         SELECT END_SECTION
           INTO SECTION1
           FROM SFIS1.RPA_TESTSECTION
          WHERE MODEL_NAME = MODEL1;

         INSERT INTO SFIS1.RPA_TOTALNUM
            SELECT MODEL1,
                   nvl(fx.smt_count,0),
                   nvl(fx.pth_count,0),
                   nvl(fx.pk_count,0),
                   nvl(fg.test_count,0)
              FROM    (SELECT MODEL1 AS model_name,
                              d.smt_count,
                              c.pth_count,
                              c.pk_count
                         FROM    (SELECT MODEL1 AS model_name,
                                         A.PTH_COUNT,
                                         B.PK_COUNT
                                    FROM    (  SELECT MODEL1 AS model_name,
                                                      group_name PTH,
                                                      COUNT (serial_number)
                                                         PTH_COUNT
                                                 FROM sfism4.r_sn_detail_t partition(SYS_P2845)
                                                WHERE     model_name = MODEL1
                                                      AND group_name IN ('AVI')
                                                      AND  IN_STATION_TIME  between
                     (TRUNC (SYSDATE - 1) + 8 / 24)
              AND  (TRUNC (SYSDATE) + 8 / 24)
                                             GROUP BY group_name, model_name) a
                                         FULL JOIN
                                            (  SELECT MODEL1 AS model_name,
                                                      group_name PK,
                                                      COUNT (serial_number)
                                                         PK_COUNT
                                                 FROM sfism4.r_sn_detail_t partition(SYS_P2845)
                                                WHERE     model_name = MODEL1
                                                      AND group_name IN
                                                             ('690_VI')
                                                     AND  IN_STATION_TIME  between
                     (TRUNC (SYSDATE - 1) + 8 / 24)
              AND  (TRUNC (SYSDATE) + 8 / 24)
                                             GROUP BY group_name, model_name) b
                                         ON a.model_name = b.model_name) c
                              FULL JOIN
                                 (  SELECT MODEL1 AS model_name,
                                           group_name SMT,
                                           COUNT (serial_number) SMT_COUNT
                                      FROM sfism4.r_sn_detail_t  partition(SYS_P2845)
                                     WHERE     model_name = MODEL1
                                           AND group_name IN ('S_VI_T')
                                          AND  IN_STATION_TIME  between
                     (TRUNC (SYSDATE - 1) + 8 / 24)
              AND  (TRUNC (SYSDATE) + 8 / 24)
                                  GROUP BY group_name, model_name) d
                              ON c.model_name = d.model_name) fx
                   FULL JOIN
                      (  SELECT MODEL1 AS model_name,
                                group_name TEST,
                                COUNT (serial_number) TEST_COUNT
                           FROM sfism4.r_sn_detail_t partition(SYS_P2845)
                          WHERE     model_name = MODEL1
                                AND group_name = SECTION1
                               AND  IN_STATION_TIME  between
                     (TRUNC (SYSDATE - 1) + 8 / 24)
              AND  (TRUNC (SYSDATE) + 8 / 24)
                       GROUP BY group_name, model_name) fg
                   ON fx.model_name = fg.model_name;
      ELSE
         INSERT INTO SFIS1.RPA_TOTALNUM
            SELECT MODEL1,
                   nvl(fx.smt_count,0),
                   nvl(fx.pth_count,0),
                   nvl(fx.pk_count,0),
                   '0'
              FROM (SELECT MODEL1 AS model_name,
                           d.smt_count,
                           c.pth_count,
                           c.pk_count
                      FROM    (SELECT a.model_name, A.PTH_COUNT, B.PK_COUNT
                                 FROM    (  SELECT MODEL1 AS model_name,
                                                   group_name PTH,
                                                   COUNT (serial_number)
                                                      PTH_COUNT
                                              FROM sfism4.r_sn_detail_t partition(SYS_P2845)
                                             WHERE     model_name = MODEL1
                                                   AND group_name IN ('AVI')
                                                  AND  IN_STATION_TIME  between
                     (TRUNC (SYSDATE - 1) + 8 / 24)
              AND  (TRUNC (SYSDATE) + 8 / 24)
                                          GROUP BY group_name, model_name) a
                                      FULL JOIN
                                         (  SELECT MODEL1 AS model_name,
                                                   group_name PK,
                                                   COUNT (serial_number)
                                                      PK_COUNT
                                              FROM sfism4.r_sn_detail_t partition(SYS_P2845)
                                             WHERE     model_name = MODEL1
                                                   AND group_name IN ('690_VI')
                                                   AND  IN_STATION_TIME  between
                     (TRUNC (SYSDATE - 1) + 8 / 24)
              AND  (TRUNC (SYSDATE) + 8 / 24)
                                          GROUP BY group_name, model_name) b
                                      ON a.model_name = b.model_name) c
                           FULL JOIN
                              (  SELECT MODEL1 AS model_name,
                                        group_name SMT,
                                        COUNT (serial_number) SMT_COUNT
                                   FROM sfism4.r_sn_detail_t partition(SYS_P2845)
                                  WHERE     model_name = MODEL1
                                        AND group_name IN ('S_VI_T')
                                       AND  IN_STATION_TIME  between
                     (TRUNC (SYSDATE - 1) + 8 / 24)
              AND  (TRUNC (SYSDATE) + 8 / 24)
                               GROUP BY group_name, model_name) d
                           ON c.model_name = d.model_name) fx;

         COMMIT;
      END IF;
   END LOOP;
END;