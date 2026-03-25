PROCEDURE             CHECK_PKG_TEST_V1    --Create by Steven Hu on 2008/09/24 for TAS-080924-02
(
STATION_NUM  IN    VARCHAR2,
EMP          IN    VARCHAR2,
LINE         IN    VARCHAR2,
MYGROUP      IN    VARCHAR2,
PPN          IN    VARCHAR2,
PKG          IN    VARCHAR2,
RES          OUT   VARCHAR2
)
AS

C_KPN              VARCHAR2(30);
V_TEMP_KP          VARCHAR2(32);
C_MACHINE          VARCHAR2(32);
C_LINE             VARCHAR2(32);
C_COUNT            NUMBER;
C_COUNT1           NUMBER;
C_COUNT4           NUMBER;
C_COUNT10          NUMBER;
C_COUNT11          NUMBER;
C_COUNT12          NUMBER;
C_COUNT_1          NUMBER;
C_COUNT_2          NUMBER;
C_COUNT_11         NUMBER;
v_COUNT1           NUMBER;
v_COUNT2           NUMBER;
V_GRN_NO           VARCHAR2(20);
V_LOT_NO           VARCHAR2(100);
S_FLAG             VARCHAR2(1);
V_VENDOR_NO        VARCHAR2(100);
V_DATECODE         VARCHAR2(40);

E_ERROR            EXCEPTION;

BEGIN
    C_MACHINE:=MYGROUP;
       /*SELECT MODEL_NAME
    INTO      C_PPN
    FROM      SFISM4.R_WIP_TRACKING_T
    WHERE    SERIAL_NUMBER = SN;*/
       SELECT COUNT(*)
    INTO C_COUNT1
    FROM IQC.R_KPN_INCOMING_T
    WHERE  PKG_ID=TRIM(PKG);
       IF C_COUNT1<1 THEN
        RES:='PKG NG ERROR 1';
        RAISE E_ERROR;
    END IF;

    --Added by Cassie Bai on 2009/07/30 for S05-090729-01 Begin--
    --Modified by Toly Lee on 2010/04/21 for 1R72-100421-01 Begin--
    SELECT NVL(COUNT(*),0)
    INTO   v_COUNT1
    FROM   SMTINFO.R_PKG_SN_QTY_T
    WHERE  PKG_ID=TRIM(PKG);

    --Modified by Alex Wang on 2011/04/12 for 3SMK-110412-01 next two lines
    --SELECT SUBSTR(LINE,1,3) INTO C_LINE FROM DUAL;
    --IF C_LINE ='F20' THEN
    SELECT SUBSTR(LINE,1,4) INTO C_LINE FROM DUAL;
    IF C_LINE ='NVPD' THEN
        IF v_COUNT1 > 150 THEN
            RES:='ERROR 2:THE PKG ID USED';
            RAISE E_ERROR;
        END IF;
    ELSE
        IF v_COUNT1 > 500 THEN
            RES:='ERROR 2:THE PKG ID USED';
            RAISE E_ERROR;
        END IF;
    END IF;
    --Modified by Toly Lee on 2010/04/21 for 1R72-100421-01 End--
    --Added by Cassie Bai on 2009/07/30 for S05-090729-01 End--

    SELECT STATE_FLAG,GRN_NO,LOT_NO,HH_PN,MFG_PN,DATE_CODE
    INTO S_FLAG,V_GRN_NO,V_LOT_NO,C_KPN,V_VENDOR_NO,V_DATECODE
    FROM IQC.R_KPN_INCOMING_T
    WHERE PKG_ID=TRIM(PKG);  --TAS-070806-01   HUWEI
    /*SELECT COUNT(HH_PN)
    INTO C_COUNT5
    FROM IQC.C_HHPN_SPEC_T
    WHERE HH_PN=C_KPN;
    IF C_COUNT5<1 THEN
        RES:='NO HH.PN ERROR 5';
        RAISE E_ERROR;
    END IF;*/

    SELECT COUNT(*)
    INTO   C_COUNT10
    FROM   IQC.R_LOT_RESULT_T
    WHERE  GRN_NO=V_GRN_NO
           AND LOT_NO=V_LOT_NO
           AND DEAL_FLAG='R';
    IF C_COUNT10>0 THEN
        RES:='GRN REJECT ERROR 7';
        RAISE E_ERROR;
    END IF ;

    /*SELECT COUNT(*)
    INTO      C_COUNT12
    FROM      IQC.R_LOT_RESULT_T
    WHERE      GRN_NO=V_GRN_NO
             AND LOT_NO=V_LOT_NO
             AND (DEAL_FLAG='A' OR DEAL_FLAG='W') ;
    IF C_COUNT12<1 THEN
        RES:='GRN DOES NOT INSPECT ERROR 8';
        RAISE E_ERROR;
    END IF ;*/
    SELECT COUNT(*)
    INTO   C_COUNT12
    FROM   IQC.R_LOT_RESULT_T
    WHERE  GRN_NO=V_GRN_NO
           AND (DEAL_FLAG='A' OR DEAL_FLAG='W') ;
    IF C_COUNT12<1 THEN
        RES:='GRN DOES NOT INSPECT ERROR 8';
        RAISE E_ERROR;
    END IF ;

    V_TEMP_KP:=C_KPN;

    SELECT COUNT(*)
    INTO   C_COUNT_1
    FROM   SFIS1.C_SMT_KP_T
    WHERE  KEY_PART_NO = V_TEMP_KP
           AND KP_DISTINCT = '1' ;
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

        SELECT KEY_PART_NO
        INTO   V_TEMP_KP
        FROM   SFIS1.C_SMT_KP_T
        WHERE  KEY_PART_NO =C_KPN
               AND KP_DISTINCT = '1'
               AND ROWNUM = 1;
    END IF;

    SELECT COUNT(*)
    INTO   C_COUNT11
    FROM   SFIS1.C_SMT_BOM_T BOM,SFISM4.R_SMT_PROD_BOM_T PROD,SFIS1.KPN_SPN_MODEL_V SPARE
    WHERE  BOM.FEEDER_NO = '001'
           AND (BOM.KEY_PART_NO = V_TEMP_KP OR (SPARE.SPARE_KEY_PART_NO=V_TEMP_KP
                                                    AND SPARE.MODEL_NAME=PPN
                                                AND SPARE.VALID_DATE>=SYSDATE))
           AND BOM.KEY_PART_NO=SPARE.KEY_PART_NO(+)
           AND BOM.BOM_NO = PROD.BOM_NO
           AND PROD.PRODUCT_NO = PPN
           AND PROD.VER = 'N/A'
           AND BOM.MACHINE_CODE = C_MACHINE;
    IF C_COUNT11<1 THEN
        RES:='KPN NG ERROR 2';
        RAISE E_ERROR;
    END IF;
    IF S_FLAG = 'P' THEN
        RES:='OK';
    END IF;

    IF S_FLAG='F' THEN
        RES:='PKG FAIL ERROR 3';
        RAISE E_ERROR;
    END IF;

    IF S_FLAG='0' THEN
        SELECT COUNT(HH_PN)
        INTO   C_COUNT4
        FROM   IQC.C_KPN_SPEC_T
        WHERE  HH_PN=C_KPN
               AND TEST_FLAG=1;
        IF C_COUNT4>0 THEN
            RES:='GOTO LCR ERROR 4';
            RAISE E_ERROR;
        ELSE
            RES:='OK';
        END IF;
    END IF;
    IF RES='OK' THEN
        INSERT INTO SFISM4.R_SMT_LOG_T
        (
            STATION_NUMBER,
            MACHINE_CODE,
            PRODUCT_NO,
            VER,
            EMP_NO,
            FEEDER_NO,
            KEY_PART_NO,
            WORK_TIME,
            SN,
            LINE_NAME,
            LOT_NO
        )
        VALUES
        (
            STATION_NUM,
            C_MACHINE,
            PPN,
            'N/A',
            EMP,
            '001',
            PKG,
            SYSDATE,
            'N/A',
            LINE,
            V_LOT_NO
        );

        SELECT COUNT(*)
        INTO   C_COUNT
        FROM   SMTINFO.R_SMT_PKGID_LOG_T
        WHERE  MACHINE_CODE=C_MACHINE
               AND PRODUCT_NO=PPN
               AND  TRAIL_NO='001'
               AND STATE_FLAG='N'
               AND LINE_NAME = LINE;
        IF C_COUNT>0 THEN
            UPDATE SMTINFO.R_SMT_PKGID_LOG_T
            SET    STATE_FLAG='Y',
                   END_TIME=SYSDATE
            WHERE  MACHINE_CODE=C_MACHINE
                   AND PRODUCT_NO=PPN
                   AND TRAIL_NO='001'
                   AND STATE_FLAG='N'
                   AND LINE_NAME = LINE;
        END IF;

        INSERT INTO SMTINFO.R_SMT_PKGID_LOG_T
        (
            STATION_NUMBER,
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
            FEEDER_STATE
        )
         VALUES
        (
            STATION_NUM,
            C_MACHINE,
            PPN,
            EMP,
            '001',
            '001',
            C_KPN,
            SYSDATE,
            '',
            LINE,
            PKG,
            'N',
            ''
        );
        COMMIT;
    END IF;
EXCEPTION
    WHEN E_ERROR THEN NULL;
    WHEN OTHERS THEN
        ROLLBACK;
        RES:='OTHER ERROR '||SUBSTR(SQLERRM,1,10);
END;