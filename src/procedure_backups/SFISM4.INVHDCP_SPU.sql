PROCEDURE                                    INVHDCP_SPU
(MACHINE_CODE   IN VARCHAR2,
 MODEL_NAME     IN VARCHAR2,----MODEL_NAME
 BARCODE        IN VARCHAR2,
 TESTTIME_BEGIN IN VARCHAR2,
 TESTTIME_END   IN VARCHAR2,
 RESULT         IN VARCHAR2,
 RETEST         IN VARCHAR2,
 AKEY           IN VARCHAR2,-----A KEY--
 WORKSCHED      IN VARCHAR2,----BIOS
 EMP            IN VARCHAR2,
 ERRORCODE      IN VARCHAR2,----Error_code
 END_FLAG       IN VARCHAR2,
 DIAG           IN VARCHAR2,
 DISPLAY        IN VARCHAR2,----Information of display
 TEST_LOGNAME       IN     VARCHAR2,  ------BY luoyang 2019-05-27  ADD 測試LOGNAME  
 DISPOSITION  IN VARCHAR2,   ----BY   LY   2019-11-06   DISPOSITION
   o_flag         OUT      VARCHAR2, 
 RES            OUT VARCHAR2) IS

p_MODATE            VARCHAR2(8);
p_DATETIME          VARCHAR2(16);
p_WSECTION          VARCHAR2(2);
p_MACHINECODE       VARCHAR2(10);
p_MODEL_NAME        VARCHAR2(50);

p_STATION           VARCHAR2(16);
p_LINE              VARCHAR2(10);
p_SECTION           VARCHAR2(16);
p_GROUP             VARCHAR2(16);
p_FLAG              VARCHAR2(2);

AKEY1               VARCHAR2(20);
AKEY2               VARCHAR2(20);
CHECK_AKEY_FLAG     VARCHAR2(2);

STNCNT              NUMBER(2,0);
ECNP            NUMBER(2,0); 
ECNF            NUMBER(2,0);
P_MO            VARCHAR2(30);
p_DATE          date;
V_LINE          VARCHAR2(30);
V_GROUP         VARCHAR2(30);

EMPRES              VARCHAR2(20);

ROUTERES            VARCHAR2(30);
PRORES              VARCHAR2(30);
H1RES               VARCHAR2(30);

HRES                VARCHAR2(20);
AKEYRES             VARCHAR2(100);
INPUTRES            VARCHAR2(100);


e_FILE_ERROR        EXCEPTION;
e_H1_ERROR          EXCEPTION;
e_STN_DUP           EXCEPTION;
e_NO_STN            EXCEPTION;
e_EMP_ERROR         EXCEPTION;
e_AKEY_ERROR        EXCEPTION;
e_INPUT_ERROR       EXCEPTION;
e_AKEY_LEN_ERROR    EXCEPTION;
e_NULL              EXCEPTION;

BEGIN
   o_flag := '-1';
    IF END_FLAG<>'**END**' THEN
       RAISE e_FILE_ERROR;
    END IF;

    p_FLAG := '0';
    --Modified by Steven Hu on 2008-03-19 for TTE-080318-01 Begin
    --p_MACHINECODE := SUBSTR(TRIM(MACHINE_CODE),-4,4);
    p_MACHINECODE := MACHINE_CODE;
    --Modified by Steven Hu on 2008-03-19 for TTE-080318-01 End
    CHECK_AKEY_FLAG := '0';

    SELECT TO_CHAR(SYSDATE,'YYYYMMDD'),TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS'),TO_CHAR(SYSDATE,'HH24')
    INTO  p_MODATE,p_DATETIME,p_WSECTION
    FROM DUAL;

    IF (LENGTH(TRIM(AKEY)) = 1) AND (TRIM(AKEY) = '0') THEN
      CHECK_AKEY_FLAG := '1';
    END IF;

    IF CHECK_AKEY_FLAG = '0' THEN
       IF LENGTH(TRIM(AKEY)) = 10 THEN
            AKEY1 := TRIM(AKEY);
         AKEY2 := '';
       ELSIF LENGTH(TRIM(AKEY)) = 21 THEN
         AKEY1 := SUBSTR(TRIM(AKEY),1,10);
         AKEY2 := SUBSTR(TRIM(AKEY),12,21);
       ELSE
         p_FLAG := '13';
         RAISE e_AKEY_LEN_ERROR;
       END IF;

       IF AKEY1 = AKEY2 THEN
             p_FLAG := '14';
          RAISE e_AKEY_LEN_ERROR;
       END IF;

       COMPAQ.TEST_AKEY_V1(p_MACHINECODE,
                           TRIM(BARCODE),
                           TRIM(RESULT),
                           TRIM(EMP),
                           '1',
                           p_FLAG,
                           AKEY1,
                           AKEY2,
                           AKEYRES);
        IF AKEYRES <> '0' THEN
              RAISE e_AKEY_ERROR;
        END IF;
    END IF;

    SELECT COUNT(*)
    INTO STNCNT
    FROM SFIS1.C_ICT_STATION_T
    WHERE STATION_CODE=p_MACHINECODE;

    IF STNCNT=0 THEN
       RAISE e_NO_STN;
    END IF;

    IF STNCNT>1 THEN
       RAISE e_STN_DUP;
    END IF;

    SELECT STATION_NAME,LINE_NAME,SECTION_NAME,GROUP_NAME
    INTO p_STATION,p_LINE,p_SECTION,p_GROUP
    FROM SFIS1.C_ICT_STATION_T
    WHERE STATION_CODE=p_MACHINECODE;

    SFIS1.Check_Lsa_H1(EMP,p_LINE,p_GROUP,H1RES);
    IF H1RES<>'OK' THEN
       RAISE e_H1_ERROR;
    END IF;

    -------------------EMP VERIFY
    SFIS1.CHECK_EMP_V3(EMP,p_GROUP,EMPRES);
    IF EMPRES<>'OK' THEN
       RAISE e_EMP_ERROR;--------------------------------EMP Exception
    END IF;

    p_MODEL_NAME:=MODEL_NAME||';'||WORKSCHED;

    ------- -- this source code desgin for all group test twinces------------------------

        --------***********************ADD BY Derrick Chow 2012-1-3 begin ************----------

         IF (p_GROUP<>'ICT'AND p_GROUP <>'5XOQA' AND p_GROUP <>'OQA'
            AND p_GROUP <>'COQA' AND p_GROUP <>'OBA'AND p_GROUP <>'OBAT') THEN


            SELECT  ECN_PASS_QTY,ECN_FAIL_QTY ,line_name,GROUP_NAME INTO ECNP,ECNF,V_LINE,V_GROUP
            FROM  SFISM4.R_WIP_TRACKING_T WHERE SERIAL_NUMBER =BARCODE;

            --SFIS1.CHECK_ROUTE(p_LINE,p_GROUP, BARCODE,RES);   --deleted by maggie on 2015/12/26  for S000003M3Z
            SFIS1.SP_TEST_CHECK_ROUTE(p_LINE,p_GROUP, BARCODE,RES);   --added by maggie on 2015/12/26  for S000003M3Z            
            IF RES<>'OK' THEN

              RES:=RES||'\n'||'**END**';
              RAISE e_NULL;

            END IF;

            IF  RESULT='P' THEN
              IF  ECNP IS NULL  THEN
               if ECNF is null  then

                  UPDATE SFISM4.R_WIP_TRACKING_T
                  SET ECN_PASS_QTY=1,ECN_FAIL_QTY=0
                  WHERE SERIAL_NUMBER=BARCODE;
                else

                 UPDATE SFISM4.R_WIP_TRACKING_T
                 SET ECN_PASS_QTY=1
                 WHERE SERIAL_NUMBER=BARCODE;

               end if;

              ELSE
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET ECN_PASS_QTY=ECN_PASS_QTY+1
                WHERE SERIAL_NUMBER=BARCODE;

              END IF ;

            END  IF ;



              IF  RESULT='F' THEN
              IF  ECNF IS NULL  THEN

                  IF ECNP IS NULL then

                  UPDATE SFISM4.R_WIP_TRACKING_T
                  SET ECN_FAIL_QTY=1,ECN_PASS_QTY =0
                  WHERE SERIAL_NUMBER=BARCODE;

                 ELSE

                   UPDATE SFISM4.R_WIP_TRACKING_T
                   SET ECN_FAIL_QTY=1
                  WHERE SERIAL_NUMBER=BARCODE;
                 end if;

              ELSE
                  UPDATE SFISM4.R_WIP_TRACKING_T
                  SET ECN_FAIL_QTY=ECN_FAIL_QTY+1
                  WHERE SERIAL_NUMBER=BARCODE;

              END IF ;

            END  IF ;
            COMMIT;

            SELECT ECN_PASS_QTY,ECN_FAIL_QTY,MO_NUMBER  INTO ECNP,ECNF,P_MO
            FROM  SFISM4.R_WIP_TRACKING_T WHERE SERIAL_NUMBER =BARCODE;

            if (ECNP=1 ) then
               res:='OK'; 
             ELSIF (ECNF=2) then
                res:='OK';

             ELSIF  (ECNP=0 and ECNF=1) then
                  INSERT INTO SFISM4.H_REPAIR_T(SERIAL_NUMBER,MO_NUMBER,TEST_TIME,
                    TEST_CODE,TEST_STATION,TEST_LINE,RECORD_TYPE,MODEL_NAME)
                   VALUES(BARCODE,P_MO,sysdate,ERRORCODE,p_GROUP,p_LINE,'H',MODEL_NAME);
                   COMMIT;
                  res:='First test fail,need retest to confirm'||'\n'||'**END**';
                  raise e_NULL;
             ELSE
                 RES:= 'Route ERROR for twince test '||'\n'||'**END**';
                  raise e_NULL;
            end if;

         END IF;


    --Modified by Alex Wang on 2010/7/5 for 22H1-100705-01 Begin
    SFISM4.iAUTOTEST(BARCODE,MACHINE_CODE,TESTTIME_BEGIN,TESTTIME_END,RESULT,ERRORCODE,p_MODEL_NAME,
             p_GROUP,'0',EMP,RETEST,'', DIAG ,DISPLAY,'N/A','N/A','N/A','N/A','0',TEST_LOGNAME,DISPOSITION,INPUTRES);
    --Modified by Alex Wang on 2010/7/5 for 22H1-100705-01 End

    IF INPUTRES<>'0' THEN
       ------ -- this source code desgin for all group test twinces------------------------
        --------***********************ADD BY Derrick Chow 2012-1-3 begin ************----------
        ------- -- this source code desgin for all group test twinces------------------------
        --------***********************ADD BY Derrick Chow 2012-2-15 begin ************----------
         IF (p_GROUP<>'ICT'AND p_GROUP <>'5XOQA' AND p_GROUP <>'OQA'
            AND p_GROUP <>'COQA' AND p_GROUP <>'OBA'AND p_GROUP <>'OBAT') THEN
            if INPUTRES<>'1'and INPUTRES<>'2' then

             if result ='F' THEN

               UPDATE SFISM4.R_WIP_TRACKING_T
                  SET ECN_FAIL_QTY=ECN_FAIL_QTY-1
                  WHERE SERIAL_NUMBER=BARCODE; 
               COMMIT;
              END IF;

              if result ='P' THEN

               UPDATE SFISM4.R_WIP_TRACKING_T
                  SET ECN_PASS_QTY=ECN_PASS_QTY-1
                  WHERE SERIAL_NUMBER=BARCODE; 
               COMMIT;
              END IF;

               RAISE e_INPUT_ERROR;

             else

               UPDATE SFISM4.R_WIP_TRACKING_T
                  SET ECN_FAIL_QTY=0,ECN_PASS_QTY =0
                  WHERE SERIAL_NUMBER=BARCODE; 

                COMMIT;

              end if ;


            end if;  
         ELSE
            UPDATE SFISM4.R_WIP_TRACKING_T
                  SET ECN_FAIL_QTY=0,ECN_PASS_QTY =0
                  WHERE SERIAL_NUMBER=BARCODE; 
             COMMIT;

        --------********************************************************************----------
        --------*****************************************************************----------
        -----***********************ADD BY Derrick Chow 2012-2-15 end ************----------
    END IF;

    RES:=INPUTRES||'\n'||'**END**';

    -------------------CHECK IF SHOULD BE STOP LINE
    SFIS1.Check_Lsa_H(EMP,p_LINE,p_GROUP,HRES);
    IF HRES<>'OK' THEN
       RES:=HRES||'\n'||'**END**';
    END IF;
   o_flag := '0';

EXCEPTION
    WHEN e_FILE_ERROR THEN
       BEGIN
             RES:='WRONG FILE FORMAT!'||'\n'||'**END**';
       END;
    WHEN e_NO_STN THEN
       BEGIN
          RES:='NO Station'||'\n'||'**END**';
       END;
    WHEN e_STN_DUP THEN
       BEGIN
          RES:='Station DUPLICATED'||'\n'||'**END**';
       END;
    WHEN e_EMP_ERROR THEN
       BEGIN
          RES:=EMPRES||'\n'||'**END**';
       END;
    WHEN e_AKEY_LEN_ERROR THEN
       BEGIN
          RES := 'A KEY:'||p_FLAG||'\n'||'**END**';
       END;
    WHEN e_AKEY_ERROR THEN
       BEGIN
             RES := 'A KEY:'||AKEYRES||'\n'||'**END**';
       END;
    WHEN e_INPUT_ERROR THEN
       BEGIN
          RES:=INPUTRES||'\n'||'**END**';
       END;
    WHEN e_H1_ERROR THEN
       BEGIN
          RES:=H1RES||'\n'||'**END**';
       END;
    WHEN e_NULL THEN NULL;
    WHEN OTHERS THEN
      RES:='OTHERS ERROR'||'\n'||'**END**';
END;