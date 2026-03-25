PROCEDURE                         GROUP_SN_OPEN_V1 (
   SN          IN     VARCHAR2,
   LINE        IN     VARCHAR2,
   SECTION     IN     VARCHAR2,
   W_STATION   IN     VARCHAR2,
   DATETIME    IN     DATE,
   MO_DATE     IN     VARCHAR2,
   W_SECTION   IN     NUMBER,
   MYGROUP     IN     VARCHAR2,
   EMP         IN     VARCHAR2,
   GQTY        IN     NUMBER,
   ORD         IN     VARCHAR2,
   RES            OUT VARCHAR2)
AS
   MAXSN         VARCHAR2 (25);
   LASTSN        VARCHAR2 (25);
   CDATE         VARCHAR2 (8);
   SGROUP        VARCHAR2 (20);
   TEMPSN        VARCHAR2 (25);
   MAXMODEL      VARCHAR2 (25);
   SNMODEL       VARCHAR2 (25);
   SNMONU        VARCHAR2 (25);
   MAXSNMONU     VARCHAR2 (25);
   VSUFFIX       VARCHAR2 (4);
   COUNTGROUP    NUMBER;
   COUNT0        NUMBER;
   COUNT1        NUMBER;
   COUNT2        NUMBER;
   COUNT3        NUMBER;
   COUNT4        NUMBER;
   VITEM         NUMBER;
   CBASIS        VARCHAR2 (50);
   NO_SN         EXCEPTION;
   CLEAR         EXCEPTION;
   DUP_SN        EXCEPTION;
   WEEK_ERROR    EXCEPTION;
   SN_ERROR      EXCEPTION;
   MODEL_ERROR   EXCEPTION;
   SN_DUP        EXCEPTION;
   E_NULL        EXCEPTION;
   EPRIFIX       EXCEPTION;
BEGIN
   --±??YCLEAR ?M°?R_SN_GROUP_T
   IF SN = 'CLEAR'
   THEN
      DELETE SFISM4.R_SN_GROUP_T
       WHERE LINE_NAME = LINE;

      COMMIT;
      RAISE CLEAR;
   END IF;

   CDATE := TO_CHAR (SYSDATE, 'YYYYMMDD');

   --§P?_????
   SELECT COUNT (*)
     INTO COUNT0
     FROM SFISM4.R_PCB_DATECODE_T
    WHERE SERIAL_NUMBER = SN AND PKG_ID <> 'DEFECT';

   --SELECT COUNT(*) INTO COUNT0 FROM SFISM4.R_WIP_TRACKING_T WHERE SERIAL_NUMBER=SN ;
   IF COUNT0 = 0
   THEN
      RAISE NO_SN;
   END IF;

   SELECT COUNT (*)
     INTO COUNT1
     FROM SFISM4.R_PCB_DATECODE_T
    WHERE SERIAL_NUMBER = SN AND TRIM (GROUP_ID) IS NOT NULL;

   IF COUNT1 > 0
   THEN
      SELECT GROUP_ID
        INTO SGROUP
        FROM SFISM4.R_PCB_DATECODE_T
       WHERE SERIAL_NUMBER = SN;

      RAISE DUP_SN;
   END IF;

   CHECK_ROUTE (LINE,
                MYGROUP,
                SN,
                RES);

   IF RES <> 'OK'
   THEN
      RAISE E_NULL;
   END IF;

   SELECT MODEL_NAME, MO_NUMBER
     INTO SNMODEL, SNMONU
     FROM SFISM4.R_WIP_TRACKING_T
    WHERE SERIAL_NUMBER = SN;

   SELECT COUNT (SERIAL_NUMBER)
     INTO COUNT1
     FROM SFISM4.R_SN_GROUP_T
    WHERE LINE_NAME = LINE;

   IF COUNT1 > 0
   THEN
      --§P?_?÷??
      SELECT ITEM, MODEL_NAME
        INTO COUNT3, MAXMODEL
        FROM SFISM4.R_SN_GROUP_T
       WHERE     ITEM = (SELECT MAX (ITEM)
                           FROM SFISM4.R_SN_GROUP_T
                          WHERE LINE_NAME = LINE)
             AND LINE_NAME = LINE;

      IF COUNT3 >= 1
      THEN
         IF SNMODEL <> MAXMODEL
         THEN
            RAISE MODEL_ERROR;
         END IF;
      END IF;

      SELECT MAX (SERIAL_NUMBER)
        INTO MAXSN
        FROM SFISM4.R_SN_GROUP_T
       WHERE LINE_NAME = LINE;

      SELECT MO_NUMBER
        INTO MAXSNMONU
        FROM SFISM4.R_WIP_TRACKING_T
       WHERE SERIAL_NUMBER = MAXSN;

      IF (SNMONU <> MAXSNMONU)
      THEN
         RES := 'ERROR 12:MO NUMBER IS NOT SAME';
         RAISE E_NULL;
      END IF;

      --§P?_?S??
      IF ORD = 'ORDER'
      THEN
         --§P?_SN ?P§O
         /*IF SUBSTR(MAXSN,-5,2) <> SUBSTR(SN,-5,2) THEN
                  RAISE WEEK_ERROR;
               END IF;*/
         --§P?_?S??
         CBASIS := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
         VSUFFIX := SUBSTR (MAXSN, -4, 4);

         IF (SN <= MAXSN)
         THEN
            RAISE SN_ERROR;
         END IF;

         IF SUBSTR (MAXSN, 1, LENGTH (MAXSN) - 4) <>
               SUBSTR (SN, 1, LENGTH (SN) - 4)
         THEN
            RAISE EPRIFIX;
         END IF;

         LOOP
            IF VSUFFIX = 'ZZZZ'
            THEN
               RES := 'ERROR 1:SN EXCEED MAX SCALE';
               RAISE E_NULL;
            END IF;

            VSUFFIX := SFIS1.SN_INC (VSUFFIX, CBASIS, RES);
            LASTSN := SUBSTR (MAXSN, 1, LENGTH (MAXSN) - 4) || VSUFFIX;
            SFIS1.CHECK_SN (LASTSN, RES);

            IF RES = 'OK'
            THEN
               EXIT;
            END IF;
         END LOOP;

         IF LASTSN <> SN
         THEN
            RAISE SN_ERROR;
         END IF;
      ELSE
         SELECT COUNT (*)
           INTO COUNT0
           FROM SFISM4.R_SN_GROUP_T
          WHERE SERIAL_NUMBER = SN;

         IF COUNT0 > 0
         THEN
            RAISE SN_DUP;
         END IF;
      END IF;
   END IF;

   --°O??SN ??BUFF ??
   SELECT NVL (MAX (ITEM) + 1, 1)
     INTO VITEM
     FROM SFISM4.R_SN_GROUP_T
    WHERE LINE_NAME = LINE;

   INSERT INTO SFISM4.R_SN_GROUP_T (ITEM,
                                    SERIAL_NUMBER,
                                    MODEL_NAME,
                                    LINE_NAME)
        VALUES (VITEM,
                SN,
                SNMODEL,
                LINE);

   COMMIT;

   SELECT MAX (ITEM)
     INTO COUNT0
     FROM SFISM4.R_SN_GROUP_T
    WHERE LINE_NAME = LINE;

   IF COUNT0 >= GQTY
   THEN
      --???????JGROUP ID
      --Modified by Steven Hu on 2009/7/22 Begin
      --SELECT NVL(LPAD(MAX(SUBSTR(GROUP_ID,-4,4))+1,4,'0'),'0001') INTO SGROUP FROM SFISM4.R_PCB_DATECODE_T
      --    WHERE TO_CHAR(IN_STATION_TIME,'YYYYMMDD') = CDATE AND LINE_NAME = LINE;
      SELECT /*+INDEX (ISTATIONTIME_PCB_DATECODE)*/
            NVL (LPAD (MAX (SUBSTR (GROUP_ID, -4, 4)) + 1, 4, '0'), '0001')
        INTO SGROUP
        FROM SFISM4.R_PCB_DATECODE_T
       WHERE     IN_STATION_TIME BETWEEN TO_DATE (CDATE || '000000',
                                                  'YYYYMMDDHH24MISS')
                                     AND TO_DATE (CDATE || '235959',
                                                  'YYYYMMDDHH24MISS')
             AND LINE_NAME = LINE;

      --Modified by Steven Hu on 2009/7/22 End
      SGROUP := LINE || CDATE || SGROUP;
      COUNT2 := 1;

      --°O?????O?H?§
      FOR COUNT2 IN 1 .. GQTY
      LOOP
         SELECT SERIAL_NUMBER
           INTO TEMPSN
           FROM SFISM4.R_SN_GROUP_T
          WHERE ITEM = COUNT2 AND LINE_NAME = LINE;

         --------------------------------------------TAS-070507-02 by Steven Hu-----------------------------------------------
         UPDATE SFISM4.R_PCB_DATECODE_T
            SET LINE_NAME = LINE,
                GROUP_ID = SGROUP,
                REPAIRED_TIME = IN_STATION_TIME,
                IN_STATION_TIME = SYSDATE
          WHERE SERIAL_NUMBER = TEMPSN AND PKG_ID <> 'DEFECT';

         ---------------------------------------------------------------------------------------------------------------------
         COMMIT;
         /*INSERT INTO SFISM4.R_PCB_DATECODE_T(PKG_ID,SERIAL_NUMBER,LINE_NAME,IN_STATION_TIME,GROUP_ID)
              VALUES('FZB',TEMPSN,LINE,SYSDATE,SGROUP);*/
         TEST_INPUT_Z (EMP,
                       LINE,
                       SECTION,
                       W_STATION,
                       DATETIME,
                       'N/A',
                       TEMPSN,
                       MO_DATE,
                       W_SECTION,
                       MYGROUP,
                       RES);
      END LOOP;

      --?M°?BUFF
      DELETE SFISM4.R_SN_GROUP_T
       WHERE LINE_NAME = LINE;

      INSERT INTO SFISM4.R_SN_GROUP_T (ITEM,
                                       SERIAL_NUMBER,
                                       MODEL_NAME,
                                       LINE_NAME)
           VALUES (0,
                   SN,
                   SNMODEL,
                   LINE);

      COMMIT;
      RES := 'OK.BIND!' || SGROUP;
   ELSE
      -- RES := '??±??Y??'||COUNT0+1||'???O';
      RES := 'OK';
   --RES := 'ERROR';
   END IF;
EXCEPTION
   WHEN E_NULL
   THEN
      NULL;
   WHEN NO_SN
   THEN
      RES := 'ERROR 3:SN HAS INPUTED OR DOSE NOT EXIST';
   WHEN CLEAR
   THEN
      RES := 'CLEAR OK';
   WHEN MODEL_ERROR
   THEN
      RES := 'ERROR 4:MODEL NAME IS DIFFERENT' || MAXMODEL;
   WHEN DUP_SN
   THEN
      RES := 'ERROR5:SN HAS BINDED' || SGROUP;
   WHEN WEEK_ERROR
   THEN
      RES := 'ERROR 6:WEED CODE IS DIFFERENT';
   WHEN SN_ERROR
   THEN
      RES := 'ERROR 7:SN IS NOT ORDER';
   WHEN SN_DUP
   THEN
      RES := 'ERROR 8:SN IS DUPLICATE';
   WHEN EPRIFIX
   THEN
      RES := 'ERROR 10:THE PREFIX IS NOT SAME';
   WHEN OTHERS
   THEN
      RES := 'ERROR 9:SP[GROUP_SN]ERROR';
END;