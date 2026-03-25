PROCEDURE       CHECK_PKG_SN_V1
(
PKG      IN       VARCHAR2,
SN       IN       VARCHAR2,
EMP      IN       VARCHAR2,
LINE     IN       VARCHAR2,
MYGROUP  IN       VARCHAR2,
RES      OUT      VARCHAR2
) IS

v_COUNT1          NUMBER;
C_LINE            VARCHAR2(32);
C_MACHINE         VARCHAR2(20);
E_ERROR           EXCEPTION;

BEGIN
    SELECT COUNT(*)
    INTO   v_COUNT1
    FROM   SMTINFO.R_PKG_SN_QTY_T
    WHERE  PKG_ID=TRIM(PKG);

    --Modified by Toly Lee on 2010/04/21 for 1R72-100421-01 Begin--
    --Modified by Alex Wang on 2011/04/12 for 3SMK-110412-01 next two lines
    --SELECT SUBSTR(LINE,1,3) INTO C_LINE FROM DUAL;
    --IF C_LINE ='F20' THEN
    SELECT SUBSTR(LINE,1,4) INTO C_LINE FROM DUAL;
    IF C_LINE ='NVPD' THEN
        IF v_COUNT1 >= 150 THEN
            RES:='ERROR 2:PLEASE SCAN NEXT PKG ID';
            RAISE E_ERROR;
        END IF;
    ELSE
        IF v_COUNT1 >= 500 THEN
            RES:='ERROR 2:PLEASE SCAN NEXT PKG ID';
            RAISE E_ERROR;
        END IF;
    END IF;
    --Modified by Toly Lee on 2010/04/21 for 1R72-100421-01 End--

    C_MACHINE:=LINE||MYGROUP;

    INSERT INTO SMTINFO.R_PKG_SN_QTY_T
    (
         PKG_ID,
        SERIAL_NUMBER,
        MACHINE_CODE,
        CREATE_BY,
        CREATE_DT
    )
     VALUES
    (
        PKG,
        SN,
        C_MACHINE,
        EMP,
        SYSDATE
    );

    RES:='OK';

EXCEPTION
    WHEN E_ERROR THEN NULL;
    WHEN OTHERS THEN
        ROLLBACK;
        RES:='OTHER ERROR '||SUBSTR(SQLERRM,1,50);
END; 