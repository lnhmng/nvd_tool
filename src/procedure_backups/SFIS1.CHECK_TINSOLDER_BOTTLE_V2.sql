PROCEDURE       CHECK_TINSOLDER_BOTTLE_V2 (
   LINE      IN     VARCHAR2,
   MACHINE   IN     VARCHAR2,
   EMP       IN     VARCHAR2,
   BOTTLE    IN     VARCHAR2,
   RES          OUT VARCHAR2)
IS
   C_NUM         NUMBER (2);
   V_COUNT0      NUMBER;
   V_COUNT1      NUMBER;
   V_COUNT2      NUMBER;
   V_COUNT3      NUMBER;
   V_COUNT4      NUMBER;
   V_COUNT5      NUMBER;
   V_COUNT6      NUMBER;
   V_COUNT7      NUMBER;
   V_COUNT8      NUMBER;
   V_COUNT9      NUMBER;
   V_DATE        DATE;
   V_DATE1       DATE;
   LINKRES       VARCHAR2 (30);
   V_FLAG        VARCHAR2 (10);
   V_FLAG1       VARCHAR2 (10);
   V_CLOSEFLAG   VARCHAR2 (1);
   V_BOTTLENO    VARCHAR2 (30);
   V_MODEL       VARCHAR2 (25);
   V_MODELNO     VARCHAR2 (30);
   E_NULL        EXCEPTION;
BEGIN
   IF BOTTLE = 'CLOSE'
   THEN
      ------**************************FOLLOWING IS TO CHECK IF THE TINSOLDER IS SCANED IN CURRENT MACHINE*******************************************
      SELECT COUNT (*)
        INTO V_COUNT7
        FROM SFISM4.R_PCA_QTY_T
       WHERE LINE_NAME = LINE                    -- AND MACHINE_NAME = MACHINE
                             AND FLAG = 'TINSOLDER' AND CLOSE_FLAG = 'N';

      IF V_COUNT7 <= 0
      THEN
         RES := 'TINSOLDER HAD NOT BEEN STARTED!';
         RAISE E_NULL;
      END IF;

      UPDATE SFISM4.R_PCA_QTY_T
         SET CLOSE_FLAG = 'Y', CLOSE_DATE = SYSDATE
       WHERE LINE_NAME = LINE                    -- AND MACHINE_NAME = MACHINE
                             AND FLAG = 'TINSOLDER' AND CLOSE_FLAG = 'N';

      UPDATE SFISM4.R_TINSOLDER_LOG_T
         SET USE_FLAG = '1', CLOSE_DATE = SYSDATE
       WHERE     LINE_NAME = LINE
             --AND MACHINE_CODE = MACHINE
             AND C_DATE = (SELECT MAX (C_DATE)
                             FROM SFISM4.R_TINSOLDER_LOG_T
                            WHERE LINE_NAME = LINE -- AND MACHINE_CODE = MACHINE
                                                  );

      RES := 'CLOSE IS OK';
      RAISE E_NULL;
   END IF;

   ----------------- WHEN SCAN NORMAL BOTTON NO ----------------------------
   IF SUBSTR (BOTTLE, 1, 2) NOT IN ('SP','HC')
   THEN
      RES := 'NO TINSOLDER BOTTLE';
      RAISE E_NULL;
   END IF;

   SELECT COUNT (*)
     INTO C_NUM
     FROM TINSOLDER.TINSOLDERBASIS
    WHERE BATCH_NO || BOTTLE_NO = BOTTLE;

   IF C_NUM > 0
   THEN
      -------------------------------- CHECK RISE 24 H--------------------------------------
      ---------------------------------------BEGIN--------------------------------------------
      SELECT COUNT (*)
        INTO V_COUNT8
        FROM TINSOLDER.TINSOLDERBASIS
       WHERE BATCH_NO || BOTTLE_NO = BOTTLE AND CURRENT_EVENT = '3';

      IF V_COUNT8 > 0
      THEN
         SELECT MAX (USE_TIME)
           INTO V_DATE
           FROM TINSOLDER.TINSOLDERBASIS
          WHERE BATCH_NO || BOTTLE_NO = BOTTLE AND CURRENT_EVENT = '3';

         SELECT COUNT (*)
           INTO V_COUNT9
           FROM TINSOLDER.TINSOLDERBASIS
          WHERE     BATCH_NO || BOTTLE_NO = BOTTLE
                AND CURRENT_EVENT = '3'
                AND TO_CHAR (
                       ROUND (
                          (SYSDATE - V_DATE) * 24,--(SYSDATE - TO_DATE (V_DATE, 'YYYY-MM-DD')) * 24, DEBUG BY GINA20180411
                          1)) > 24
                AND BACKTEMP_BEGINTIME >
                       TO_DATE ('2008-12-11 00:00:00',
                                'yyyy-mm-dd hh24:mi:ss');

         IF V_COUNT9 > 0
         THEN
            RES := 'BOTTLE rise longer than 24 hours';
            RAISE E_NULL;
         END IF;
      ELSE
         RES := 'BOTTLE Never in use';
         RAISE E_NULL;
      END IF;

      ---------------------------------------END--------------------------------------------
      SELECT COUNT (*)
        INTO V_COUNT4
        FROM SFISM4.R_PCA_QTY_T
       WHERE LINE_NAME = LINE                    -- AND MACHINE_NAME = MACHINE
                             AND FLAG = 'TINSOLDER' AND CLOSE_FLAG = 'N';

      IF V_COUNT4 > 0
      THEN
         RES := 'PLEASE Close  TINSOLDER BOTTLE';
         RAISE E_NULL;
      END IF;


      SELECT COUNT (*)
        INTO V_COUNT6
        FROM SFISM4.R_PCA_QTY_T
       WHERE     SERIAL_NUMBER = BOTTLE
             AND FLAG = 'TINSOLDER'
             AND LINE_NAME = LINE;

      IF V_COUNT6 > 0
      THEN
         UPDATE SFISM4.R_PCA_QTY_T
            SET CLOSE_FLAG = 'N',CLOSE_DATE  =NULL
          WHERE     SERIAL_NUMBER = BOTTLE
                AND FLAG = 'TINSOLDER'
                AND LINE_NAME = LINE;
      ELSE
         INSERT INTO SFISM4.R_PCA_QTY_T (SERIAL_NUMBER,
                                         QTY,
                                         FLAG,
                                         START_DATE,
                                         CLOSE_DATE,
                                         CLOSE_FLAG,
                                         ALARM_FLAG,
                                         ALARM_TIME,
                                         EMP_NO,
                                         LINE_NAME            --, MACHINE_NAME
                                                  )
              VALUES (BOTTLE,
                      0,
                      'TINSOLDER',
                      SYSDATE,
                      '',
                      'N',
                      '',
                      '',
                      EMP,
                      LINE                                         --, MACHINE
                          );
      END IF;



      UPDATE SFISM4.R_TINSOLDER_LOG_T
         SET USE_FLAG = '1', CLOSE_DATE = SYSDATE
       WHERE     LINE_NAME = LINE
             AND MACHINE_CODE = MACHINE
             AND C_DATE = (SELECT MAX (C_DATE)
                             FROM SFISM4.R_TINSOLDER_LOG_T
                            WHERE LINE_NAME = LINE ----  AND MACHINE_CODE = MACHINE
                                                  );

      INSERT INTO SFISM4.R_TINSOLDER_LOG_T (LINE_NAME,
                                            MACHINE_CODE,
                                            EMP_NO,
                                            BOTTLE_NO,
                                            MODEL_NAME,
                                            C_DATE,
                                            USE_FLAG,
                                            ALARM_FLAG,
                                            ALARM_TIME,
                                            CLOSE_DATE)
           VALUES (LINE,
                   MACHINE,
                   EMP,
                   BOTTLE,
                   V_MODEL,
                   SYSDATE,
                   '0',
                   '0',
                   '',
                   ''  --ADDDED BY CASSIE BAI ON 2009/09/21 FOR 118C-090818-01
                     );


      COMMIT;
      ----MODIFY BY KASSI BAI ON 2009/04/30 END------
      RES := 'OK';
   ELSE
      RES := 'NO BOTTLE NO.';
   END IF;
EXCEPTION
   WHEN E_NULL
   THEN
      NULL;
   WHEN OTHERS
   THEN
      ROLLBACK;
      RES := 'OTHER ERROR ' || SUBSTR (SQLERRM, 1, 10);
END;