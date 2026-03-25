PROCEDURE                                     Check_Tinsolder_Bottle_v1
(
LINE            IN          VARCHAR2,
MACHINE         IN          VARCHAR2,
QC              IN          VARCHAR2,
BOTTLE          IN          VARCHAR2,
RES             OUT         VARCHAR2
) IS
C_NUM           NUMBER(2);
v_COUNT0        NUMBER;
v_COUNT1        NUMBER;
v_COUNT2        NUMBER;
V_COUNT3        NUMBER;
v_COUNT4        NUMBER;
V_COUNT5        NUMBER;
v_COUNT6        NUMBER;
V_COUNT7        NUMBER;
v_DATE            DATE;
v_DATE1            DATE;
LINKRES            VARCHAR2(30);
v_FLAG          VARCHAR2(10);
v_FLAG1         VARCHAR2(10);
V_CLOSEFLAG        VARCHAR2(1);
V_BOTTLENO        VARCHAR2(30);
v_MODEL            VARCHAR2(25);
V_MODELNO        VARCHAR2(30);
e_NULL          EXCEPTION;
BEGIN

-------------------------------- when scan close --------------------------------------

 IF BOTTLE = 'CLOSE' THEN
----********************************following is to check if the tinsolder is scaned in current line *******************************************
                SELECT COUNT(*)
                INTO V_COUNT7
                FROM SFISM4.R_PCA_QTY_T
                WHERE LINE_NAME = LINE
                        AND FLAG = 'TINSOLDER'
                        AND CLOSE_FLAG = 'N';
                IF V_COUNT7 <= 0 THEN
                    RES := 'TINSOLDER HAD NOT BEEN STARTED!';
                    RAISE E_NULL;
                END IF;
                UPDATE SFISM4.R_PCA_QTY_T
                SET    CLOSE_FLAG = 'Y',CLOSE_DATE = SYSDATE
                WHERE  LINE_NAME = LINE
                          AND FLAG = 'TINSOLDER'
                          AND CLOSE_FLAG = 'N';
-----***********************************************************************************
                UPDATE  SFISM4.R_TINSOLDER_LOG_T
                SET     USE_FLAG = '1',
                        CLOSE_DATE = SYSDATE   --Addded by Cassie Bai on 2009/09/21 for 118C-090818-01
                WHERE   LINE_NAME = LINE
                        AND MACHINE_CODE = MACHINE
                        AND C_DATE = (SELECT MAX(C_DATE) FROM SFISM4.R_TINSOLDER_LOG_T WHERE LINE_NAME = LINE AND MACHINE_CODE = MACHINE);
                RES:='OK';

 END IF;

-------------------------------- when scan normal botton no --------------------------------------
    IF SUBSTR(BOTTLE,1,2) <> 'SP' THEN
        RES:='NO TINSOLDER BOTTLE';
        RAISE e_NULL;
    END IF;


    --For package TMM-20081127-1.Modify by Jason Liu on 2008/11/27.
    SELECT COUNT(*)
    INTO   C_NUM
    FROM   SFISM4.R_TINSOLDER_LOG_T
    WHERE  BOTTLE_NO=BOTTLE
           AND USE_FLAG = '0';
    IF C_NUM>0 THEN
        RES := 'BOTTLE SCANNED!';
        RAISE e_NULL;
    END IF;
-------------------------------- check  bottle must not be used ( must be a linked new bottole or  bottle not used)-------------------------------------
   /* SELECT COUNT(*)
    INTO   C_NUM
    FROM   SFISM4.R_TINSOLDER_LOG_T
    WHERE  BOTTLE_NO=BOTTLE
           AND USE_FLAG = '1';
    IF C_NUM>0 THEN
        RES := 'BOTTLE USED BUT NO LINK!';
        RAISE e_NULL;
    END IF;
    */   --Deleted by Maggie Chang on 2014/7/11 for S0000027UH
    
-------------------------------- check rise 24 H--------------------------------------
        C_NUM:=0;
        --Added By Cassie Bai on 2009/11/19 for 13B3-091117-01 Begin--
        SELECT COUNT(*)
        INTO   v_COUNT0
        FROM   TINSOLDER.TINSOLDERBASIS
        WHERE  BATCH_NO||BOTTLE_NO=BOTTLE
               AND CURRENT_EVENT='2';
        IF v_COUNT0 > 0 THEN
            SELECT MAX(BACKTEMP_BEGINTIME)
            INTO   v_DATE1
            FROM   TINSOLDER.TINSOLDERBASIS
            WHERE  BATCH_NO||BOTTLE_NO=BOTTLE
                      AND CURRENT_EVENT='2';
            SELECT COUNT(*)
            INTO   v_COUNT1
            FROM   TINSOLDER.TINSOLDERBASIS
            WHERE  BATCH_NO||BOTTLE_NO=BOTTLE
                       AND CURRENT_EVENT='2'
                       AND TO_CHAR(ROUND((SYSDATE-TO_DATE(v_DATE,'YYYY-MM-DD'))*24,1)) > 24
                       AND BACKTEMP_BEGINTIME > TO_DATE('2008-12-11 00:00:00','yyyy-mm-dd hh24:mi:ss');
            IF v_COUNT1 > 0 THEN
                RES:= 'BOTTLE rise longer than 24 hours';
                RAISE e_NULL;
            END IF;
        END IF;
-------------------------------- check tinsolder 24H --------------------------------------
        SFIS1.Check_Tinsolder_Link(BOTTLE,'24',LINKRES);
        IF LINKRES <> 'OK' THEN
               RES:=LINKRES;
               RAISE e_NULL;
        END IF;



-------------------------------- main check--------------------------------------
        --Added By Cassie Bai on 2009/11/19 for 13B3-091117-01 End--
        SELECT COUNT(*)
        INTO C_NUM
        FROM TINSOLDER.TINSOLDERBASIS
        WHERE BATCH_NO||BOTTLE_NO=BOTTLE
            AND CURRENT_EVENT='3';
        IF C_NUM>0 THEN
            --Modified by Curitis Xing on 2009/09/14 Begin
            --Added by Cassie Bai on 2009/08/07 for UWQ-090807-01 Begin--
            SELECT  COUNT(*)
            INTO    v_COUNT2
            FROM    SFIS1.C_PTH_T a,TINSOLDER.MODEL_CONFIG b
            WHERE   a.MODEL_NAME = b.MODEL_NAME
                    AND a.LINE_NAME = LINE
                    AND a.C_DATE = (SELECT  MAX(C_DATE)
                                    FROM    SFIS1.C_PTH_T
                                    WHERE   LINE_NAME = LINE);
            --Modified by Curitis Xing on 2009/09/14 End
            IF v_COUNT2 <= 0 THEN
                RES:='ERROR0:NOT FOUND MODEL NAME IN TABLE';--Modified by Curitis Xing
                RAISE e_NULL;
            ELSE
                SELECT  b.LEAD_FLAG,a.MODEL_NAME
                INTO    v_FLAG,v_MODEL
                FROM    SFIS1.C_PTH_T a,TINSOLDER.MODEL_CONFIG b
                WHERE   a.MODEL_NAME = b.MODEL_NAME
                        AND a.LINE_NAME = LINE
                        AND a.C_DATE = (SELECT  MAX(C_DATE)
                                        FROM    SFIS1.C_PTH_T
                                        WHERE   LINE_NAME = LINE);
            END IF;

            SELECT  COUNT(*)
            INTO    v_COUNT3
            FROM    TINSOLDER.TINSOLDERBASIS a,TINSOLDER.TIN_TYPE b
            WHERE   a.BATCH_NO||a.BOTTLE_NO=BOTTLE
                    AND a.MODEL_NO = b.TIN_TYPE_NO;
            IF v_COUNT3 <= 0 THEN
                RES:='PLEASE CONFIG BOTTLE IN TINSOLDER.TINSOLDERBASIS';
                RAISE e_NULL;
            ELSE
                SELECT  b.LEAD_FLAG
                INTO    v_FLAG1
                FROM    TINSOLDER.TINSOLDERBASIS a,TINSOLDER.TIN_TYPE b
                WHERE   a.BATCH_NO||a.BOTTLE_NO=BOTTLE
                        AND a.MODEL_NO = b.TIN_TYPE_NO
                        AND a.IN_TIME = (SELECT MAX(IN_TIME)
                                         FROM   TINSOLDER.TINSOLDERBASIS
                                         WHERE  BATCH_NO||BOTTLE_NO=BOTTLE);
            END IF;

            IF v_FLAG <> v_FLAG1 THEN
                RES:='BOTTLE IS ERROR';
                RAISE e_NULL;
            END IF;
            ----Added by cunkuxing on 2009/12/17 for 19CM-091208-01 begin
            SELECT MODEL_NO
            INTO   v_MODELNO
            FROM   TINSOLDER.TINSOLDERBASIS
            WHERE  BATCH_NO||BOTTLE_NO = BOTTLE;
            IF (TRIM(v_MODEL) = 'IX4012502-01' OR TRIM(v_MODEL) = 'IX4012502-02') THEN
               IF TRIM(v_MODELNO) <> 'Shen Mao Type 4 PF606-P' THEN
                     RES := 'TINSOLDER TYPE IS NOT TYPE4';
                     RAISE e_NULL;
               END IF;
            END IF;
            --Added by cunkuxing on 2009/12/17 for 19CM-091208-01 end
----***************************following is to check the info. in table sfism4.r_pca_qty_t**********************************************************************
            SELECT COUNT(*)
            INTO   V_COUNT4
            FROM   SFISM4.R_PCA_QTY_T
            WHERE  LINE_NAME = LINE
                   AND FLAG = 'TINSOLDER';
            IF V_COUNT4 >0 THEN
                SELECT CLOSE_FLAG,SERIAL_NUMBER
                INTO   V_CLOSEFLAG,V_BOTTLENO
                FROM   SFISM4.R_PCA_QTY_T
                WHERE  LINE_NAME = LINE
                          AND FLAG = 'TINSOLDER'
                          AND START_DATE = (SELECT MAX(START_DATE)
                                            FROM   SFISM4.R_PCA_QTY_T
                                          WHERE  LINE_NAME = LINE
                                                 AND FLAG = 'TINSOLDER');
                IF V_CLOSEFLAG = 'N' THEN
                    UPDATE SFISM4.R_PCA_QTY_T
                    SET       CLOSE_FLAG = 'Y',CLOSE_DATE = SYSDATE,EMP_NO = QC
                    WHERE  SERIAL_NUMBER = V_BOTTLENO;
                END IF;

                SELECT COUNT(*)
                INTO   V_COUNT5
                FROM   SFISM4.R_PCA_QTY_T
                WHERE  SERIAL_NUMBER = BOTTLE AND FLAG = 'TINSOLDER';
                IF V_COUNT5 >0 THEN
                    UPDATE SFISM4.R_PCA_QTY_T
                    SET    CLOSE_FLAG = 'N',LINE_NAME = LINE,START_DATE = SYSDATE,CLOSE_DATE = '',EMP_NO = QC
                    WHERE  SERIAL_NUMBER = BOTTLE AND FLAG = 'TINSOLDER';
                ELSE
                    INSERT INTO SFISM4.R_PCA_QTY_T
                       (
                             SERIAL_NUMBER,
                      QTY,
                      FLAG,
                      START_DATE,
                      CLOSE_DATE,
                     CLOSE_FLAG,
                      ALARM_FLAG,
                      ALARM_TIME,
                      EMP_NO,
                     LINE_NAME
                       )
                       VALUES
                       (
                           BOTTLE,
                           0,
                           'TINSOLDER',
                           SYSDATE,
                           '',
                           'N',
                           '',
                     '',
                           QC,
                     LINE
                       );
                END IF;
            ELSE
                SELECT COUNT(*)
                INTO   V_COUNT6
                FROM   SFISM4.R_PCA_QTY_T
                WHERE  SERIAL_NUMBER = BOTTLE AND FLAG = 'TINSOLDER';
                IF V_COUNT6 >0 THEN
                    UPDATE SFISM4.R_PCA_QTY_T
                    SET    CLOSE_FLAG = 'N',LINE_NAME = LINE,START_DATE = SYSDATE,CLOSE_DATE = '',EMP_NO = QC
                    WHERE  SERIAL_NUMBER = BOTTLE AND FLAG = 'TINSOLDER';
                ELSE
                    INSERT INTO SFISM4.R_PCA_QTY_T
                       (
                             SERIAL_NUMBER,
                      QTY,
                      FLAG,
                      START_DATE,
                      CLOSE_DATE,
                     CLOSE_FLAG,
                      ALARM_FLAG,
                      ALARM_TIME,
                      EMP_NO,
                     LINE_NAME
                       )
                       VALUES
                       (
                           BOTTLE,
                           0,
                           'TINSOLDER',
                           SYSDATE,
                           '',
                           'N',
                           '',
                     '',
                           QC,
                     LINE
                       );
                END IF;
            END IF;


--*****************************************************************************************************
            --Added by Cassie Bai on 2009/08/07 for UWQ-090807-01 End--
            --Modify by Kassi Bai on 2009/04/30 Begin------
            UPDATE  SFISM4.R_TINSOLDER_LOG_T
            SET     USE_FLAG = '1',
                    CLOSE_DATE = SYSDATE  --Addded by Cassie Bai on 2009/09/21 for 118C-090818-01
            WHERE   LINE_NAME = LINE
                    AND MACHINE_CODE = MACHINE
                    AND C_DATE = (SELECT MAX(C_DATE) FROM SFISM4.R_TINSOLDER_LOG_T WHERE LINE_NAME = LINE AND MACHINE_CODE = MACHINE);
            INSERT INTO SFISM4.R_TINSOLDER_LOG_T
            (
                LINE_NAME,
                MACHINE_CODE,
                EMP_NO,
                BOTTLE_NO,
                MODEL_NAME,
                C_DATE,
                USE_FLAG,
                ALARM_FLAG,
                ALARM_TIME,
                CLOSE_DATE   --Addded by Cassie Bai on 2009/09/21 for 118C-090818-01
            )
            VALUES
            (
                LINE,
                MACHINE,
                QC,
                BOTTLE,
                v_MODEL,
                SYSDATE,
                '0',
                '0',
                '',
                SYSDATE    --Addded by Cassie Bai on 2009/09/21 for 118C-090818-01
            );
            --Modify by Kassi Bai on 2009/04/30 End------
            RES := 'OK';
        ELSE

            RES:='NO BOTTLE NO.';

        END IF;

EXCEPTION
    WHEN e_NULL THEN NULL;
    WHEN OTHERS THEN
        ROLLBACK;
        RES := 'OTHER ERROR '||SUBSTR(SQLERRM,1,10);
END;
-- Writed by liuyunjiang 2005-10-27 for TINSOLDER Bottle No. Input  Scan .
-- Update by liuyunjiang 2008-11-27 for TINSOLDER Bottle No. Input  Scan .
-- updated by songFengLiu 2011-7-28 16:46:06          closed bottle must be linked before use