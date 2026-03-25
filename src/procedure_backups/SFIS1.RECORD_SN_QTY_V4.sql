PROCEDURE       RECORD_SN_QTY_V4 (LINE   IN     VARCHAR2,
                                                    EMP    IN     VARCHAR2,
                                                    SN     IN     VARCHAR2,
                                                    RES       OUT VARCHAR2)
IS
   V_COUNT0       NUMBER;
   V_COUNT1       NUMBER;
   V_COUNT2       NUMBER;
   V_COUNT3       NUMBER;
   V_COUNT4       NUMBER;
   V_COUNT5       NUMBER;
   ALARM_QTY      NUMBER;
   SCRAP_QTY      NUMBER;
   LOOP_QTY       NUMBER;
   I_COUNT        NUMBER;
   V_VERSION      VARCHAR2 (10);
   V_MODEL        VARCHAR2 (25);
   V_STEEL        VARCHAR2 (25);
   V_SCRAPER      VARCHAR2 (25);
   V_SCRAPERB     VARCHAR2 (25);
   V_BOTTLENO     VARCHAR2 (30);
   V_FLAG         VARCHAR2 (1);
   V_QTY1         NUMBER;
   V_QTY2         NUMBER;
   V_QTY3         NUMBER;
   V_QTY4         NUMBER;
   V_COUNTGROUP   NUMBER;
   V_COUNTA       NUMBER;
   V_COUNTB       NUMBER;
   V_COUNT6       NUMBER;
   V_COUNT7       NUMBER;
   E_NULL         EXCEPTION;

   CURSOR CUR1
   IS
      SELECT SERIAL_NUMBER
        FROM SFISM4.R_PCB_DATECODE_T
       WHERE GROUP_ID IN (SELECT GROUP_ID
                            FROM SFISM4.R_PCB_DATECODE_T
                           WHERE SERIAL_NUMBER = SN);

   ROW1           CUR1%ROWTYPE;
BEGIN
   SELECT COUNT (SERIAL_NUMBER)
     INTO V_COUNT6
     FROM SFISM4.R_PCB_DATECODE_T
    WHERE GROUP_ID IN (SELECT GROUP_ID
                         FROM SFISM4.R_PCB_DATECODE_T
                        WHERE SERIAL_NUMBER = SN);

   V_COUNTGROUP := 1;

   ----------------------FOLLOWING IS LINK THE SN AND TINSOLDER BOTTLE_NO---


   SELECT SERIAL_NUMBER
     INTO V_BOTTLENO
     FROM SFISM4.R_PCA_QTY_T
    WHERE     LINE_NAME = LINE
          AND CLOSE_FLAG = 'N'
          AND FLAG = 'TINSOLDER'
          AND START_DATE = (SELECT MAX (START_DATE)
                              FROM SFISM4.R_PCA_QTY_T
                             WHERE LINE_NAME = LINE AND FLAG = 'TINSOLDER');


   SELECT NVL (QTY, 0)
     INTO V_QTY2
     FROM SFISM4.R_PCA_QTY_T
    WHERE SERIAL_NUMBER = V_BOTTLENO AND LINE_NAME =LINE AND CLOSE_FLAG = 'N';

   IF V_COUNT6 > 0
   THEN
      OPEN CUR1;

      LOOP
         FETCH CUR1 INTO ROW1;

         EXIT WHEN CUR1%NOTFOUND;

         SELECT COUNT (*)
           INTO V_COUNT5
           FROM SFISM4.R_SNLINKPCA_T
          WHERE     SERIAL_NUMBER = ROW1.SERIAL_NUMBER
                AND FLAG = 'TINSOLDER'
                AND LINE_NAME = LINE;

         IF V_COUNT5 > 0
         THEN
            UPDATE SFISM4.R_SNLINKPCA_T
               SET PCA = V_BOTTLENO, EMP_NO = EMP, EDIT_DATE = SYSDATE
             WHERE     SERIAL_NUMBER = ROW1.SERIAL_NUMBER
                   AND FLAG = 'TINSOLDER'
                   AND LINE_NAME = LINE;
         ELSE
            INSERT INTO SFISM4.R_SNLINKPCA_T (SERIAL_NUMBER,
                                              MODEL_NAME,
                                              PCA,
                                             FLAG,
                                              EMP_NO,
                                              EDIT_DATE,
                                              LINE_NAME)
                 VALUES (ROW1.SERIAL_NUMBER,
                         V_MODEL,
                         V_BOTTLENO,
                         'TINSOLDER',
                         EMP,
                         SYSDATE,
                         LINE);
         END IF;
      END LOOP;

      CLOSE CUR1;
   ELSE
      SELECT COUNT (*)
        INTO V_COUNT5
        FROM SFISM4.R_SNLINKPCA_T
       WHERE SERIAL_NUMBER = SN AND FLAG = 'TINSOLDER' AND LINE_NAME = LINE ;

      IF V_COUNT5 > 0
      THEN
         UPDATE SFISM4.R_SNLINKPCA_T
            SET PCA = V_BOTTLENO, EMP_NO = EMP, EDIT_DATE = SYSDATE
          WHERE     SERIAL_NUMBER = SN
                AND FLAG = 'TINSOLDER'
                AND LINE_NAME = LINE;
      ELSE
         INSERT INTO SFISM4.R_SNLINKPCA_T (SERIAL_NUMBER,
                                              MODEL_NAME,
                                              PCA,
                                             FLAG,
                                              EMP_NO,
                                              EDIT_DATE,
                                              LINE_NAME)
                 VALUES (SN,
                         V_MODEL,
                         V_BOTTLENO,
                         'TINSOLDER',
                         EMP,
                         SYSDATE,
                         LINE);
      END IF;
   END IF;

   UPDATE SFISM4.R_PCA_QTY_T
      SET QTY = V_QTY2 + V_COUNTGROUP
    WHERE SERIAL_NUMBER = V_BOTTLENO AND  LINE_NAME=LINE AND CLOSE_FLAG = 'N';




   ---------------------------------------GULE----------------------------------------

   COMMIT;
   RES := 'OK';

EXCEPTION
   WHEN E_NULL
   THEN
      NULL;
   WHEN OTHERS
   THEN
      ROLLBACK;
      RES := 'OTHER ERROR:' || SUBSTR (SQLERRM, 1, 100);
END;