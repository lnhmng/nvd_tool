PROCEDURE             CHECK_FEED_INTEGRITY_V6 (
   SN          IN     VARCHAR2,
   SECTION     IN     VARCHAR2,
   MYGROUP     IN     VARCHAR2,
   W_STATION   IN     VARCHAR2,
   LINE        IN     VARCHAR2,
   RES            OUT VARCHAR2)
AS
   V_MODEL_NAME    VARCHAR (30);
   V_PRODUCT_NO    VARCHAR (30);
   V_COUNT         NUMBER;
   V_KEY_PART_NO   VARCHAR (30);
   V_FEEDER_NO     VARCHAR (30);
   --VV_PRO          VARCHAR (30);
   V_EXCEPTION     EXCEPTION;

   CURSOR CUR1
   IS
      SELECT DISTINCT MACHINE_CODE
        FROM SFISM4.R_SMT_PROD_BOM_T A, SFIS1.C_SMT_BOM_T B
       WHERE     A.BOM_NO = B.BOM_NO
             AND PRODUCT_NO = V_PRODUCT_NO
             AND LINE_NAME = LINE
             AND FEEDER_NO LIKE 'TBL%'
             AND  LINE_NAME =SUBSTR (MACHINE_CODE, 1, LENGTH(MACHINE_CODE)-3);



   ROW1            CUR1%ROWTYPE;

   CURSOR CUR0
   IS
      SELECT KEY_PART_NO, FEEDER_NO
        FROM (SELECT DISTINCT
                     A.KEY_PART_NO, A.FEEDER_NO, B.KEY_PART_NO AS KEY_PART
                FROM (SELECT KEY_PART_NO, FEEDER_NO, MACHINE_CODE
                        FROM SFISM4.R_SMT_PROD_BOM_T A, SFIS1.C_SMT_BOM_T B
                       WHERE     A.BOM_NO = B.BOM_NO
                             AND PRODUCT_NO = V_PRODUCT_NO
                             AND LINE_NAME = LINE
                             AND MACHINE_CODE = ROW1.MACHINE_CODE) A,
                     (SELECT KEY_PART_NO, TRAIL_NO
                        FROM SMTINFO.R_SMT_PKGID_LOG_T
                       WHERE     PRODUCT_NO = V_PRODUCT_NO
                             AND (STATE_FLAG = 'C' OR STATE_FLAG = 'N')
                             AND LINE_NAME = LINE
                             AND MACHINE_CODE = ROW1.MACHINE_CODE) B
               WHERE     A.KEY_PART_NO = B.KEY_PART_NO(+)
                     AND A.FEEDER_NO = B.TRAIL_NO(+))
       WHERE KEY_PART IS NULL;

   ROW0            CUR0%ROWTYPE;
BEGIN
   SELECT MODEL_NAME
     INTO V_MODEL_NAME
     FROM SFISM4.R_WIP_TRACKING_T
    WHERE SERIAL_NUMBER = SN;

   IF SECTION = 'PTH'
   THEN
      V_PRODUCT_NO := V_MODEL_NAME;
   ELSE
      SELECT PRODUCT_NO
        INTO V_PRODUCT_NO
        FROM SMTINFO.C_BIND_CONFIG_T
       WHERE MODEL_NAME = V_MODEL_NAME AND LINE_NAME = LINE AND ROWNUM = 1;
   END IF;

   RES := 'OK';

   OPEN CUR1;

   LOOP
      FETCH CUR1 INTO ROW1;

      EXIT WHEN CUR1%NOTFOUND;

      OPEN CUR0;

      LOOP
         FETCH CUR0 INTO ROW0;

         EXIT WHEN CUR0%NOTFOUND;

      -- select distinct SUBSTR (PRODUCT_NO, 1, LENGTH(PRODUCT_NO)-1) into VV_PRO 
      -- from SMTINFO.R_SMT_PKGID_LOG_T 
      -- where PRODUCT_NO = V_PRODUCT_NO;

         SELECT COUNT (PKG_ID)
           INTO V_COUNT
           FROM SMTINFO.R_SMT_PKGID_LOG_T A, SFIS1.KPN_SPN_MODEL_V B
          WHERE     (   A.KEY_PART_NO = B.KEY_PART_NO
                     OR (    A.KEY_PART_NO = B.SPARE_KEY_PART_NO
                         AND B.MODEL_NAME = V_PRODUCT_NO))
                --AND A.PRODUCT_NO = V_PRODUCT_NO
                --AND A.PRODUCT_NO LIKE SUBSTR (VV_PRO,1, LENGTH(VV_PRO)-1)||'%'
                AND A.PRODUCT_NO LIKE SUBSTR (V_PRODUCT_NO,1, LENGTH(V_PRODUCT_NO)-1)||'%'
                AND TRAIL_NO= ROW0.FEEDER_NO
                AND (STATE_FLAG = 'C' OR STATE_FLAG = 'N');

         IF V_COUNT = 0
         THEN
            RES :=
                  ROW0.KEY_PART_NO
               || '('
               || ROW0.FEEDER_NO
               || ')'
               || ' NOT FOUND!';
            RAISE V_EXCEPTION;
         END IF;
      END LOOP;

      CLOSE CUR0;
   END LOOP;

   CLOSE CUR1;
EXCEPTION
   WHEN V_EXCEPTION
   THEN
      NULL;
   WHEN OTHERS
   THEN
      RES := 'OTHER ERROR ' || SUBSTR (SQLERRM, 1, 100);
END;