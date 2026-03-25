PROCEDURE                         UPDATEATTACHEDSN (
   IN_V_SECTIONNAME    IN     VARCHAR2,
   IN_V_GROUPNAME      IN     VARCHAR2,
   IN_V_STATIONNAME    IN     VARCHAR2,
   IN_V_EMPNO          IN     VARCHAR2,
   IN_V_SERIALNO       IN     VARCHAR2,
   IN_V_DEFAULTMODEL   IN     VARCHAR2,
   RES                    OUT VARCHAR2)
AS
   V_MODELNAME      VARCHAR2 (50);
   V_SERIALNO       VARCHAR2 (50);
   I_RECORDCOUNT    INTEGER;
   V_OLDSN          VARCHAR2 (20);
   V_DATE           VARCHAR2 (10);
   E_NOTFINDDATE    EXCEPTION;
   E_NOTFINDDATE1   EXCEPTION;
   E_NOTFINDDATE2   EXCEPTION;
BEGIN
   SELECT TO_CHAR (SYSDATE, 'YYMMDD') 
     INTO V_DATE 
     FROM DUAL;  --ADDED BY GJ FOR BUG AT TJ 20151210

   SELECT COUNT (A.MODEL_NAME)
     INTO I_RECORDCOUNT
     FROM SFISM4.R_WIP_TRACKING_T A, SFISM4.R_SN_ATTACHMENT_T B
    WHERE     A.SERIAL_NUMBER = B.SERIAL_NUMBER
          AND B.ATTACHMENT_NO = IN_V_SERIALNO;

   IF I_RECORDCOUNT = 0
   THEN
      RAISE E_NOTFINDDATE;
   END IF;

   SELECT A.MODEL_NAME, B.SERIAL_NUMBER
     INTO V_MODELNAME, V_SERIALNO
     FROM SFISM4.R_WIP_TRACKING_T A, SFISM4.R_SN_ATTACHMENT_T B
    WHERE     A.SERIAL_NUMBER = B.SERIAL_NUMBER
          AND B.ATTACHMENT_NO = IN_V_SERIALNO;

   SELECT COUNT (OLD_SN)
     INTO I_RECORDCOUNT
     FROM SFISM4.R_SN_LINK_T
    WHERE NEW_SN = V_SERIALNO;

   IF I_RECORDCOUNT = 0
   THEN
      RAISE E_NOTFINDDATE1;
   ELSE
      SELECT OLD_SN
        INTO V_OLDSN
        FROM SFISM4.R_SN_LINK_T
       WHERE NEW_SN = V_SERIALNO;
   END IF;

   SELECT COUNT (IN_STATION_TIME)
     INTO I_RECORDCOUNT
     FROM SFISM4.R_SN_DETAIL_T
    WHERE SERIAL_NUMBER = V_OLDSN AND GROUP_NAME <> 'BARCODE_LINK';

   IF I_RECORDCOUNT = 0
   THEN
      RAISE E_NOTFINDDATE2;
   END IF;


   IF INSTR (IN_V_DEFAULTMODEL, V_MODELNAME) > 0
   THEN
      UPDATE SFISM4.R_WIP_TRACKING_T
         SET SECTION_NAME = IN_V_SECTIONNAME,
             GROUP_NAME = IN_V_GROUPNAME,
             STATION_NAME = IN_V_STATIONNAME,
             IN_STATION_TIME = SYSDATE,
             EMP_NO = IN_V_EMPNO
       WHERE SERIAL_NUMBER IN (SELECT ATTACHMENT_NO
                                 FROM SFISM4.R_SN_ATTACHMENT_T
                                WHERE SERIAL_NUMBER = V_SERIALNO);

      UPDATE SFISM4.R_SN_ATTACHMENT_T
         SET SERIAL_NUMBER = V_DATE || '~' || SERIAL_NUMBER,
             ATTACHMENT_NO = V_DATE || '~' || ATTACHMENT_NO
       WHERE SERIAL_NUMBER = V_SERIALNO;

      UPDATE sfism4.R_WIP_TRACKING_T
         SET SERIAL_NUMBER = V_DATE || '~' || SERIAL_NUMBER
       WHERE SERIAL_NUMBER = V_OLDSN AND GROUP_NAME = 'BARCODE_LINK';

      UPDATE SFISM4.R_SN_LINK_T
         SET OLD_SN = V_DATE || '~' || OLD_SN, NEW_SN = V_DATE || '~' || NEW_SN
       WHERE OLD_SN = V_OLDSN;

      INSERT INTO SFISM4.R_WIP_TRACKING_T (SERIAL_NUMBER,
                                           SECTION_FLAG,
                                           MO_NUMBER,
                                           MODEL_NAME,
                                           TYPE,
                                           VERSION_CODE,
                                           LINE_NAME,
                                           SECTION_NAME,
                                           GROUP_NAME,
                                           STATION_NAME,
                                           LOCATION,
                                           STATION_SEQ,
                                           ERROR_FLAG,
                                           IN_STATION_TIME,
                                           IN_LINE_TIME,
                                           OUT_LINE_TIME,
                                           SHIPPING_SN,
                                           WORK_FLAG,
                                           FINISH_FLAG,
                                           ENC_CNT,
                                           SPECIAL_ROUTE,
                                           PALLET_NO,
                                           CONTAINER_NO,
                                           QA_NO,
                                           QA_RESULT,
                                           SCRAP_FLAG,
                                           NEXT_STATION,
                                           CUSTOMER_NO,
                                           WORK_DATE,
                                           WORK_SECTION,
                                           PASS_QTY,
                                           FAIL_QTY,
                                           REPASS_QTY,
                                           REFAIL_QTY,
                                           ECN_PASS_QTY,
                                           ECN_FAIL_QTY,
                                           KEY_PART_NO,
                                           CARTON_NO,
                                           WARRANTY_DATE,
                                           BOM_NO,
                                           PO_NO,
                                           EMP_NO,
                                           REWORK_NO)
         SELECT SERIAL_NUMBER,
                SECTION_FLAG,
                MO_NUMBER,
                MODEL_NAME,
                TYPE,
                VERSION_CODE,
                LINE_NAME,
                SECTION_NAME,
                GROUP_NAME,
                STATION_NAME,
                LOCATION,
                STATION_SEQ,
                ERROR_FLAG,
                IN_STATION_TIME,
                IN_LINE_TIME,
                OUT_LINE_TIME,
                SHIPPING_SN,
                WORK_FLAG,
                FINISH_FLAG,
                ENC_CNT,
                SPECIAL_ROUTE,
                PALLET_NO,
                CONTAINER_NO,
                QA_NO,
                QA_RESULT,
                SCRAP_FLAG,
                NEXT_STATION,
                CUSTOMER_NO,
                WORK_DATE,
                WORK_SECTION,
                PASS_QTY,
                FAIL_QTY,
                REPASS_QTY,
                REFAIL_QTY,
                ECN_PASS_QTY,
                ECN_FAIL_QTY,
                KEY_PART_NO,
                CARTON_NO,
                WARRANTY_DATE,
                BOM_NO,
                PO_NO,
                EMP_NO,
                REWORK_NO
           FROM SFISM4.R_SN_DETAIL_T
          WHERE     SERIAL_NUMBER = V_OLDSN
                AND IN_STATION_TIME IN
                       (SELECT MAX (IN_STATION_TIME)
                          FROM SFISM4.R_SN_DETAIL_T
                         WHERE     SERIAL_NUMBER = V_OLDSN
                               AND GROUP_NAME <> 'BARCODE_LINK');
   ELSE
      UPDATE SFISM4.R_WIP_TRACKING_T
         SET SECTION_NAME = IN_V_SECTIONNAME,
             GROUP_NAME = IN_V_GROUPNAME,
             STATION_NAME = IN_V_STATIONNAME,
             IN_STATION_TIME = SYSDATE,
             EMP_NO = IN_V_EMPNO
       WHERE SERIAL_NUMBER = IN_V_SERIALNO;

      DELETE SFISM4.R_SN_ATTACHMENT_T
       WHERE ATTACHMENT_NO = IN_V_SERIALNO;
   END IF;

   COMMIT;
   RES := 'OK';
EXCEPTION
   WHEN E_NOTFINDDATE
   THEN
      RES := 'ERR1：NOT FIND THIS ATTACHED SN';
   WHEN E_NOTFINDDATE1
   THEN
      RES := 'ERR2：NOT FIND LINKED SN RECORD';
   WHEN E_NOTFINDDATE2
   THEN
      RES := 'ERR3:NOT FIND DETAIL RECORD';
   WHEN OTHERS
   THEN
      RES := 'ERR4:ERROR IN UPDATE DATA.';
      ROLLBACK;
END;