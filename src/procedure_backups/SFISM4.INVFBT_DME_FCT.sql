PROCEDURE                             INVFBT_DME_FCT(
                                           MACHINE_CODE     IN     VARCHAR2,
                                           FUNCTION_TEST    IN     VARCHAR2,
                                           BARCODE          IN     VARCHAR2,
                                           MAC              IN     VARCHAR2, 
                                           TESTTIME         IN     VARCHAR2,
                                           RESULT_CODE      IN     VARCHAR2,
                                           ERRORCODE        IN     VARCHAR2,
                                           EMP              IN     VARCHAR2,
                                           RES                 OUT VARCHAR2)                                            
                                           

IS

    P_TESTTIME      DATE;
    P_RESULT_CODE   VARCHAR2 (10);--0 PASS 1 FAIL
    p_MACHINECODE   VARCHAR2 (10);
    p_MAC           VARCHAR2 (30);
    V_MODEL         VARCHAR2 (32);

    p_STATION       VARCHAR2 (16);
    p_LINE          VARCHAR2 (10);
    p_SECTION       VARCHAR2 (16);
    p_GROUP         VARCHAR2 (16);
    STNCNT          NUMBER (2, 0);
    STNCNT2         NUMBER (2, 0);

    EMPRES          VARCHAR2 (20);
    INPUTRES        VARCHAR2 (100);
    H1RES           VARCHAR2 (30);
    HRES            VARCHAR2 (20);

    TEST_RES        VARCHAR2 (100);   

    e_FILE_ERROR    EXCEPTION;
    e_H1_ERROR      EXCEPTION;
    e_STN_DUP       EXCEPTION;
    e_NO_STN        EXCEPTION;
    e_EMP_ERROR     EXCEPTION;
    e_INPUT_ERROR   EXCEPTION;
    e_NULL          EXCEPTION;
BEGIN

    TEST_RES:='1';

    --DME MACHINE CODE LIST
    SELECT COUNT(1) INTO STNCNT2 FROM sfis1.C_PARAMETER_INI t WHERE PRG_NAME ='DME_MACHINE_CODE' AND VR_NAME=MACHINE_CODE;

    IF STNCNT2 = 0
    THEN
     RAISE e_NO_STN;
    END IF;

    IF STNCNT2 > 1
    THEN
     RAISE e_STN_DUP;
    END IF;

    SELECT VR_VALUE INTO p_MACHINECODE FROM sfis1.C_PARAMETER_INI t WHERE PRG_NAME ='DME_MACHINE_CODE' AND 
VR_NAME=MACHINE_CODE;

    SELECT COUNT (*)
    INTO STNCNT
    FROM SFIS1.C_ICT_STATION_T
    WHERE STATION_CODE = p_MACHINECODE;

      IF STNCNT = 0
      THEN
         RAISE e_NO_STN;
      END IF;

      IF STNCNT > 1
      THEN
         RAISE e_STN_DUP;
      END IF;

      TEST_RES:='2';

      SELECT STATION_NAME,
             LINE_NAME,
             SECTION_NAME,
             GROUP_NAME
        INTO p_STATION,
             p_LINE,
             p_SECTION,
             p_GROUP
        FROM SFIS1.C_ICT_STATION_T
       WHERE STATION_CODE = p_MACHINECODE;

       TEST_RES:='3';

      SFIS1.Check_Lsa_H1 (EMP,
                          p_LINE,
                          p_GROUP,
                          H1RES);
      TEST_RES:='4';                    

      IF H1RES <> 'OK'
      THEN
         RAISE e_H1_ERROR;
      END IF;

      -------------------EMP VERIFY
      SFIS1.CHECK_EMP_V3 (EMP, p_GROUP, EMPRES);

      TEST_RES:='5';

      IF EMPRES <> 'OK'
      THEN
         RAISE e_EMP_ERROR;      
      END IF;

      P_TESTTIME := TO_DATE(TO_CHAR(TO_DATE(TESTTIME,'YYMMDDHH24MI'),'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS');

      IF RESULT_CODE=0 THEN

        P_RESULT_CODE:='P';

      ELSE 

        P_RESULT_CODE:='F';

      END IF;

       SELECT 
          MODEL_NAME
     INTO V_MODEL
     FROM SFISM4.R_WIP_TRACKING_T
     WHERE SERIAL_NUMBER = BARCODE;

      --IO TK DON'T RECORD MAC
      IF V_MODEL='1022298-01' THEN

        p_MAC:=MAC;

      ELSE

        p_MAC:='N/A';

      END IF;

      TEST_RES:='6';

      SFISM4.IAUTOTEST_DME (
                                           p_MACHINECODE    ,
                                           FUNCTION_TEST    ,
                                           BARCODE          ,
                                           p_MAC            , 
                                           P_TESTTIME       ,
                                           P_RESULT_CODE    ,
                                           ERRORCODE        ,
                                           EMP              ,
                                           INPUTRES);

      TEST_RES:='7';

      IF INPUTRES <> '0'
      THEN
         RAISE e_INPUT_ERROR;
      END IF;

      TEST_RES:='8';

      RES := INPUTRES || '\n' || '**END**';


      SFIS1.Check_Lsa_H (EMP,
                         p_LINE,
                         p_GROUP,
                         HRES);
      TEST_RES:='9';

      IF HRES <> 'OK'
      THEN
         RES := HRES || '\n' || '**END**';
      END IF;



EXCEPTION
   WHEN e_FILE_ERROR
   THEN
      RES := 'WRONG FILE FORMAT!' || '\n' || '**END**';
   WHEN e_NO_STN
   THEN
      RES := 'NO Station' || '\n' || '**END**';
   WHEN e_STN_DUP
   THEN
      RES := 'Station DUPLICATED' || '\n' || '**END**';
   WHEN e_EMP_ERROR
   THEN
      RES := EMPRES || '\n' || '**END**';
   WHEN e_INPUT_ERROR
   THEN
      RES := INPUTRES || '\n' || '**END**';
   WHEN e_H1_ERROR
   THEN
      RES := H1RES || '\n' || '**END**';
   WHEN e_NULL
   THEN
      NULL;
   WHEN OTHERS
   THEN
      RES := TEST_RES|| 'OTHERS ERROR' || '\n' || '**END**';
END;