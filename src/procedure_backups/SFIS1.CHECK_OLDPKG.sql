PROCEDURE            CHECK_OLDPKG --create by maggie for S000003611
(
CHAN                              IN         VARCHAR2,
STATION_NUM                      IN         VARCHAR2,
MACHINE                  IN         VARCHAR2,
PPN                              IN         VARCHAR2,
VER                              IN         VARCHAR2,
EMP                              IN         VARCHAR2,
LOC                           IN         VARCHAR2,
OLDPKG                          IN         VARCHAR2,
LINE                           IN         VARCHAR2,
RES                           OUT     VARCHAR2
) IS
C_KPN                         VARCHAR2(32);
C_OLDPKG                     VARCHAR2(32);
V_TEMP_KP                     VARCHAR2(32);
S_FLAG                         VARCHAR2(1);
C_COUNT1                     NUMBER;
C_COUNT4                     NUMBER;
C_COUNT11                     NUMBER;
C_COUNT_1                     NUMBER;
C_COUNT_2                     NUMBER;
C_COUNT_3                     NUMBER;
C_COUNT_4                     NUMBER;
C_OUTPUT                     VARCHAR(64);

ISTRPOSITION                 INTEGER;
C_MACHINE                     VARCHAR2(32);
C_LOC                         VARCHAR2(32);

E_ERROR                     EXCEPTION;

BEGIN

    IF (CHAN = 'CHANGE LINE' AND OLDPKG <> 'N/A') THEN
        RES:='NO PKG ID';
        RAISE E_ERROR;
    END IF;

   C_MACHINE:=MACHINE;
   C_LOC:=LOC;

    SELECT COUNT(*)
    INTO   C_COUNT1
    FROM   IQC.R_KPN_INCOMING_T
    WHERE  PKG_ID=TRIM(OLDPKG);
       IF C_COUNT1<1 THEN
        RES:='OLD PKG NG ERROR 1';
        RAISE E_ERROR;
    END IF;

    SELECT STATE_FLAG,HH_PN
    INTO   S_FLAG,C_KPN
    FROM   IQC.R_KPN_INCOMING_T
    WHERE  PKG_ID=TRIM(OLDPKG);

    IF (CHAN = 'N/A') THEN
           SELECT PKG_ID
        INTO   C_OLDPKG
        FROM   SMTINFO.R_SMT_PKGID_LOG_T
        WHERE  MACHINE_CODE = C_MACHINE
               AND TRAIL_NO = C_LOC
               AND PRODUCT_NO = PPN
               AND BEGIN_TIME = (SELECT MAX(BEGIN_TIME)
                                        FROM     SMTINFO.R_SMT_PKGID_LOG_T
                                WHERE     MACHINE_CODE = C_MACHINE
                                        AND TRAIL_NO = C_LOC
                                        AND PRODUCT_NO = PPN);
           IF (OLDPKG <> C_OLDPKG) THEN
              RES:='PLEASE INPUT OLD PKG';
               RAISE E_ERROR;
             END IF;
    END IF;

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
        SELECT COUNT(*)
        INTO   C_COUNT_3
        FROM   SFIS1.C_KPN_T
        WHERE  P_PART=C_KPN
               AND FLAG = '1';
        IF (C_COUNT_3=0) THEN
            RES:='NO CONFIM BY QA';
              RAISE E_ERROR;
        END IF;
        SELECT HH_PART
        INTO   C_KPN
        FROM   SFIS1.C_KPN_T
        WHERE  P_PART=C_KPN
               AND FLAG = '1';
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
               AND KP_DISTINCT = '1'
               AND ROWNUM = 1;
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

    RES:='OK';

EXCEPTION
    WHEN E_ERROR THEN NULL;
        --INSERT_ERROR_MES(STATION_NUM,C_MACHINE,PPN,VER,EMP,C_LOC,OLDPKG,LOC,LINE,RES);
    WHEN OTHERS THEN
        RES:='OTHER ERROR ' || SUBSTR(SQLERRM,1,50);
         --INSERT_ERROR_MES(STATION_NUM,C_MACHINE,PPN,VER,EMP,C_LOC,OLDPKG,LOC,LINE,RES);
END;