PROCEDURE               CHECK_PKG_HIGHT_V5  --added by maggiechang for S000003611 based on SFIS1.CHECK_PKG_HIGHT_V4
(
STATION_NUM        IN         VARCHAR2,
MACHINE                 IN         VARCHAR2,
PPN                         IN         VARCHAR2,
VER                         IN         VARCHAR2,
EMP                         IN         VARCHAR2,
OLDPKG                   IN         VARCHAR2,
LOC                         IN         VARCHAR2,
PKG                         IN         VARCHAR2,
SN                          IN         VARCHAR2,
CHAN                      IN         VARCHAR2,
LINE                       IN          VARCHAR2,
RES                       OUT       VARCHAR2)
 IS
C_KPN                         VARCHAR2(32);
V_TEMP_KP                     VARCHAR2(32);
S_FLAG                         VARCHAR2(1);
C_COUNT                     NUMBER;
C_COUNT0                     NUMBER;
C_COUNT1                     NUMBER;
C_COUNT2                     NUMBER;
C_COUNT3                     NUMBER;
C_COUNT4                     NUMBER;
C_COUNT5                     NUMBER;
C_COUNT6                     NUMBER;
C_COUNT7                     NUMBER;
C_COUNT8                     NUMBER;
C_COUNT9                     NUMBER;
C_COUNT10                     NUMBER;
C_COUNT11                     NUMBER;
C_COUNT12                     NUMBER;
C_COUNT13                     NUMBER;
C_COUNT14                     NUMBER;
C_COUNT15                     NUMBER;
C_COUNT16                     NUMBER;
C_COUNT17                     NUMBER;
C_COUNT18                     NUMBER;
C_COUNT_1                     NUMBER;
C_COUNT_2                     NUMBER;
C_COUNT_3                     NUMBER;
C_COUNT_4                     NUMBER;
C_OUTPUT                     VARCHAR(64);

ISTRPOSITION                 INTEGER;
C_MACHINE                     VARCHAR2(32);
C_MACHINECODE   VARCHAR2 (32);
C_TRAILNO       VARCHAR2 (16);
C_LOC                         VARCHAR2(32);
V_GRN_NO                     VARCHAR2(20);
V_LOT_NO                     VARCHAR2(100);
V_VENDOR_NO              VARCHAR2 (100);
V_DATECODE              VARCHAR2 (40);

E_ERROR                     EXCEPTION;

BEGIN
   C_MACHINE := MACHINE;
   C_LOC := LOC;

    IF PKG='CLOSE' THEN
        SFIS1.CHECK_EMP_V3(EMP,'CLOSE_MAC',RES);
        IF RES<>'OK' THEN
            RAISE E_ERROR ;
        END IF;
          UPDATE SMTINFO.R_SMT_PKGID_LOG_T
        SET    STATE_FLAG='Y',
               END_TIME=SYSDATE
        WHERE  MACHINE_CODE=C_MACHINE
               AND PRODUCT_NO=PPN
               AND TRAIL_NO=C_LOC
               AND (STATE_FLAG = 'N' OR STATE_FLAG = 'C');
          RES:='OK';
          RAISE E_ERROR;
       END IF;

       IF PKG='STOP' THEN
        SFIS1.CHECK_EMP_V3(EMP,'STOP_MAC',RES);
          IF RES<>'OK' THEN
            RAISE E_ERROR ;
        END IF;
      ------------------------------------------------------TAS-070921-01  Begin  Steven Hu------------------------------------------------
      --UPDATE SMTINFO.R_SMT_PKGID_LOG_T SET STATE_FLAG='Y',END_TIME=SYSDATE WHERE MACHINE_CODE=C_MACHINE  AND PRODUCT_NO=PPN AND (STATE_FLAG='N' OR STATE_FLAG='C');

          UPDATE SMTINFO.R_SMT_PKGID_LOG_T
        SET    STATE_FLAG='Y',
               END_TIME=SYSDATE
        WHERE    LINE_NAME = LINE
             AND PRODUCT_NO=PPN
               AND (STATE_FLAG = 'N' OR STATE_FLAG = 'C');
          ------------------------------------------------------TAS-070921-01  End-------------------------------------------------------------
          RES:='OK';
          RAISE E_ERROR;
       END IF;

    IF CHAN <> 'CHANGE LINE' THEN
        IF OLDPKG = PKG THEN
            RES:='ERROR:OLD PKG = PKG';
            RAISE E_ERROR;
        END IF;
    END IF;
  
    SELECT COUNT(*)
    INTO   C_COUNT13
    FROM   SMTINFO.R_SMT_PKGID_LOG_T
    WHERE  PKG_ID=TRIM(PKG)
           AND (STATE_FLAG='N' OR STATE_FLAG='C');

    IF C_COUNT13>0 THEN
        UPDATE SMTINFO.R_SMT_PKGID_LOG_T
        SET    STATE_FLAG='Y',
               END_TIME=SYSDATE
        WHERE  PKG_ID=TRIM(PKG)
               AND (STATE_FLAG='N' OR STATE_FLAG='C');
        RES:='OK';
    END IF;
    RES:='OK';

   SELECT COUNT (*)
     INTO C_COUNT0
     FROM SMTINFO.R_SMT_PKGID_LOG_T
    WHERE PKG_ID = TRIM (PKG) AND (STATE_FLAG = 'N' OR STATE_FLAG = 'C');

   IF C_COUNT0 > 0
   THEN
      SELECT MACHINE_CODE, TRAIL_NO
        INTO C_MACHINECODE, C_TRAILNO
        FROM SMTINFO.R_SMT_PKGID_LOG_T
       WHERE (STATE_FLAG = 'N' OR STATE_FLAG = 'C') AND ROWNUM = 1;

      --RES:='THE PKG ID HAS NOT BE CLOSED,PLEASE CLOSED FIRSTLY';
      RES :=
            'PLEASE GOTO MACHINE:'
         || C_MACHINECODE
         || ';TRAIL:'
         || C_TRAILNO
         || ' TO CLOSE FIRST';
      RAISE E_ERROR;
   END IF;
   /*SELECT COUNT(*)   INTO C_COUNT0   FROM SMTINFO.R_SMT_PKGID_LOG_T   WHERE  PKG_ID=TRIM(PKG)   AND PRODUCT_NO= TRIM(PPN);
   IF C_COUNT0>0 THEN
      RES:='THE PKG ID HAS USED';
      RAISE E_ERROR;
   END IF;*/

    SELECT COUNT(*)
    INTO   C_COUNT1
    FROM   IQC.R_KPN_INCOMING_T
    WHERE  PKG_ID=TRIM(PKG);
    IF C_COUNT1<1 THEN
        RES:='PKG NG ERROR 1';
        RAISE E_ERROR;
    END IF;
    

    SELECT STATE_FLAG,GRN_NO,LOT_NO,HH_PN, MFG_PN, DATE_CODE
    INTO   S_FLAG,V_GRN_NO,V_LOT_NO,C_KPN, V_VENDOR_NO, V_DATECODE
    FROM   IQC.R_KPN_INCOMING_T
    WHERE  PKG_ID=TRIM(PKG);
     --TAS-070806-01   HUWEI

   /*SELECT COUNT(HH_PN) INTO C_COUNT5 FROM IQC.C_HHPN_SPEC_T WHERE HH_PN=C_KPN;
   IF C_COUNT5<1 THEN
      RES:='NO HH.PN ERROR 5';
      RAISE E_ERROR;
   END IF;*/
   -------------------------------------------------------TAS-070806-01  BEGIN  BY HUWEI--------------------------------

   SELECT COUNT (HH_NO)
     INTO C_COUNT14
     FROM KITTING.S_E_GOOD_T
    WHERE HH_NO = C_KPN AND STATE1 = '0' AND STATE = '1';

   IF (C_COUNT14 > 0)
   THEN
      RES := 'FACTORY FAIL';
      RAISE E_ERROR;
   END IF;
   
   SELECT COUNT (HH_NO)
     INTO C_COUNT15
     FROM KITTING.S_E_GOOD_T
    WHERE HH_NO = C_KPN AND STATE1 = '0' AND STATE = '2';

   IF (C_COUNT15 > 0)
   THEN
      RES := 'HH_PN FAIL';
      RAISE E_ERROR;
   END IF;

   SELECT COUNT (HH_NO)
     INTO C_COUNT16
     FROM KITTING.S_E_GOOD_T
    WHERE P_NO = V_VENDOR_NO AND STATE1 = '0' AND STATE = '3';

   IF (C_COUNT16 > 0)
   THEN
      RES := 'VENDOR NO. FAIL';
      RAISE E_ERROR;
   END IF;

   SELECT COUNT (HH_NO)
     INTO C_COUNT17
     FROM KITTING.S_E_GOOD_T
    WHERE     P_NO = V_VENDOR_NO
          AND LOT_NO = V_LOT_NO
          AND STATE1 = '0'
          AND STATE = '4';

   IF (C_COUNT17 > 0)
   THEN
      RES := 'LOT NO FAIL';
      RAISE E_ERROR;
   END IF;

   SELECT COUNT (HH_NO)
     INTO C_COUNT18
     FROM KITTING.S_E_GOOD_T
    WHERE     DATE_CODE = V_DATECODE
          AND P_NO = V_VENDOR_NO
          AND STATE1 = '0'
          AND STATE = '5';

   IF (C_COUNT18 > 0)
   THEN
      RES := 'DATE CODE FAIL';
      RAISE E_ERROR;
   END IF;

   -------------------------------------------------------TAS-070806-01  END  BY HUWEI---------------------------------
   
   SELECT COUNT (*)
     INTO C_COUNT10
     FROM IQC.R_LOT_RESULT_T
    WHERE GRN_NO = V_GRN_NO AND LOT_NO = V_LOT_NO AND DEAL_FLAG = 'R';

   IF C_COUNT10 > 0
   THEN
      RES := 'GRN REJECT ERROR 7';
      RAISE E_ERROR;
   END IF;
   
   /*SELECT COUNT(*) INTO C_COUNT12 FROM IQC.R_LOT_RESULT_T WHERE GRN_NO=V_GRN_NO AND LOT_NO=V_LOT_NO AND (DEAL_FLAG='A' OR DEAL_FLAG='W') ;
   IF C_COUNT12<1 THEN
   RES:='GRN DOES NOT INSPECT ERROR 8';
   RAISE E_ERROR;
   END IF ;*/
   SELECT COUNT (*)
     INTO C_COUNT12
     FROM IQC.R_LOT_RESULT_T
    WHERE GRN_NO = V_GRN_NO AND (DEAL_FLAG = 'A' OR DEAL_FLAG = 'W');

   IF C_COUNT12 < 1
   THEN
      RES := 'GRN DOES NOT INSPECT ERROR 8';
      RAISE E_ERROR;
   END IF;     
            
    V_TEMP_KP:=C_KPN;

    SELECT COUNT(*)
    INTO   C_COUNT_1
    FROM   SFIS1.C_SMT_KP_T
    WHERE  KEY_PART_NO = V_TEMP_KP       AND KP_DISTINCT = '1' ;
    
    IF  C_COUNT_1=0 THEN
        SELECT COUNT(*)
        INTO   C_COUNT_2
        FROM   SFIS1.C_KPN_T
        WHERE  P_PART=C_KPN;
        IF (C_COUNT_2=0) THEN
            RES:='NO HH_PART';
              RAISE E_ERROR;
        END IF;        

        SELECT HH_PART
        INTO   C_KPN
        FROM   SFIS1.C_KPN_T
        WHERE  P_PART=C_KPN;
        
        SELECT COUNT(*)
        INTO   C_COUNT_4
        FROM   SFIS1.C_SMT_KP_T
        WHERE  KEY_PART_NO =C_KPN
               AND KP_DISTINCT = '1'
               AND ROWNUM = 1;
        IF (C_COUNT_4 = 0) THEN
            RES:='NO KPN ERROR3';
              RAISE E_ERROR;
        END IF;
        SELECT KEY_PART_NO
        INTO   V_TEMP_KP
        FROM   SFIS1.C_SMT_KP_T
        WHERE  KEY_PART_NO =C_KPN
               AND KP_DISTINCT = '1' AND ROWNUM = 1;
    END IF;
    
    SELECT COUNT(*)
    INTO   C_COUNT11
    FROM   SFIS1.C_SMT_BOM_T BOM,SFISM4.R_SMT_PROD_BOM_T PROD,SFIS1.KPN_SPN_MODEL_V SPARE
    WHERE  BOM.FEEDER_NO = C_LOC
           AND (BOM.KEY_PART_NO = V_TEMP_KP OR (SPARE.SPARE_KEY_PART_NO=V_TEMP_KP
                                                    AND SPARE.MODEL_NAME=PPN
                                            AND SPARE.VALID_DATE>=SYSDATE))
           AND BOM.KEY_PART_NO=SPARE.KEY_PART_NO(+)
           AND BOM.BOM_NO = PROD.BOM_NO  AND PROD.PRODUCT_NO = PPN
           AND PROD.VER = VER AND BOM.MACHINE_CODE = C_MACHINE;
    IF C_COUNT11<1 THEN
        RES:='KPN NG ERROR 2';
        RAISE E_ERROR;
    END IF;
    
   IF S_FLAG = 'P'
   THEN
      RES := 'OK';
   END IF;

   IF S_FLAG = 'F'
   THEN
      RES := 'PKG FAIL ERROR 3';
      RAISE E_ERROR;
   END IF;

   IF S_FLAG = '0'
   THEN
      SELECT COUNT (HH_PN)
        INTO C_COUNT4
        FROM IQC.C_KPN_SPEC_T
       WHERE HH_PN = C_KPN AND TEST_FLAG = 1;

      IF C_COUNT4 > 0
      THEN
         RES := 'GOTO LCR ERROR 4';
         RAISE E_ERROR;
      ELSE
         RES := 'OK';
      END IF;
   END IF;      
   
    SFIS1.CHECK_PKG_MSD(EMP,PKG,LINE,PPN,'N/A',RES);

    IF RES='OK' THEN
        INSERT INTO SFISM4.R_SMT_LOG_T  ( STATION_NUMBER,
            MACHINE_CODE,
            PRODUCT_NO,
            VER,
            EMP_NO,
            FEEDER_NO,
            KEY_PART_NO,
            WORK_TIME,
            SN,
            LINE_NAME,
            LOT_NO )
        VALUES ( STATION_NUM,
            C_MACHINE,
            PPN,
            VER,
            EMP,
            C_LOC,
            PKG,
            SYSDATE,
            'N/A',
            LINE,
            LOC );

          SELECT COUNT(*)
        INTO   C_COUNT
        FROM   SMTINFO.R_SMT_PKGID_LOG_T
        WHERE  MACHINE_CODE=C_MACHINE
               AND PRODUCT_NO=PPN
               AND  TRAIL_NO=C_LOC
               AND STATE_FLAG='N';
         IF C_COUNT>0 THEN
            UPDATE SMTINFO.R_SMT_PKGID_LOG_T
            SET    STATE_FLAG='C',
                   END_TIME=SYSDATE
            WHERE  MACHINE_CODE=C_MACHINE
                   AND PRODUCT_NO=PPN
                   AND TRAIL_NO=C_LOC
                   AND STATE_FLAG='N';
         END IF;

         INSERT INTO SMTINFO.R_SMT_PKGID_LOG_T  (STATION_NUMBER,
            MACHINE_CODE,
            PRODUCT_NO,
            EMP_NO,
            FEEDER_NO,
            TRAIL_NO,
            KEY_PART_NO,
            BEGIN_TIME,
            END_TIME,
              LINE_NAME,
            PKG_ID,
            STATE_FLAG,
            FEEDER_STATE )
           VALUES   (STATION_NUM,
            C_MACHINE,
            PPN,
            EMP,
            C_LOC,
            C_LOC,
            C_KPN,
            SYSDATE,
            '',
            LINE,
            PKG,
            'N',
            '');
       COMMIT;
    END IF;
EXCEPTION
    WHEN E_ERROR THEN NULL;
        --INSERT_ERROR_MES(STATION_NUM,C_MACHINE,PPN,VER,EMP,C_LOC,PKG,LOC,LINE,RES);
    WHEN OTHERS THEN
        ROLLBACK;
        RES:='OTHER ERROR ' || SUBSTR(SQLERRM,1,50);
        --INSERT_ERROR_MES(STATION_NUM,C_MACHINE,PPN,VER,EMP,C_LOC,PKG,LOC,LINE,RES);
END;