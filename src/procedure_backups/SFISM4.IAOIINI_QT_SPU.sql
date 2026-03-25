PROCEDURE                                    IAOIINI_QT_SPU
/*********************************************
Author : Alex Wang                          **
Date   : 2010-10-26                         **
Description: To act on the *.ini file       **
**********************************************/
(
  MACHINE_CODE    IN  VARCHAR2,
  RESERVE1        IN  VARCHAR2,
  BOARD_NAME      IN  VARCHAR2,
  BARCODE         IN  VARCHAR2,
  TESTDATE        IN  VARCHAR2,
  TESTTIME        IN  VARCHAR2,
  RESULT          IN  VARCHAR2,
  RESERVE2        IN  VARCHAR2,
  RESERVE3        IN  VARCHAR2,
  EMP             IN  VARCHAR2,
  RESERVE4        IN  VARCHAR2,
  RESERVE5        IN  VARCHAR2,
  RESERVE6        IN  VARCHAR2,
  RETEST          IN  VARCHAR2,
  FAILDESC        IN  VARCHAR2,
  END_FLAG        IN  VARCHAR2,
   o_flag         OUT      VARCHAR2,  
  RES            OUT  VARCHAR2
)
AS

CHECKRES        VARCHAR2(50);
AOITEST_RES     VARCHAR2(200);
v_RESULT        VARCHAR2(2);
p_GROUP         VARCHAR2(16);

EC_CNT          NUMBER(3,0);
EC_LIST         ECLIST;

e_CHECK_ERROR   EXCEPTION;
e_AOITEST_ERROR EXCEPTION;
e_FILE_ERROR    EXCEPTION;
e_EC_ERROR      EXCEPTION;

BEGIN
   o_flag := '-1';
  IF ( TRIM(END_FLAG) <> '**END**') THEN
    RAISE e_FILE_ERROR;
  END IF;
  EC_CNT := 0;

  COMMON_CHECK(TRIM(BARCODE),TRIM(MACHINE_CODE),EMP,CHECKRES);
  IF CHECKRES <> 'OK' THEN
    RAISE e_CHECK_ERROR;
  END IF;

  IF UPPER(TRIM(RESULT)) = 'FAIL' OR UPPER(TRIM(RESULT)) = 'F' THEN
    v_RESULT := 'F';
  ELSIF UPPER(TRIM(RESULT)) = 'PASS' OR UPPER(TRIM(RESULT)) = 'P' THEN
    v_RESULT := 'P';
  END IF;

  IF v_RESULT = 'F' THEN
    EC_TRANSACTION_INI(TRIM(FAILDESC),
                       EC_CNT,
                       EC_LIST);
    IF EC_CNT = 0 THEN
      RAISE e_EC_ERROR;
    END IF;
  END IF;

  ----AOI or TAOI---Begin
  SELECT GROUP_NAME
  INTO p_GROUP
  FROM SFIS1.C_ICT_STATION_T
  WHERE STATION_CODE = MACHINE_CODE;
  --Modified by Alex Wang on 2011/02/14 for 36GQ-110214-01 the next row(cause: AOIIN-->API     AOIOUT-->AOI)
  IF (SUBSTR(p_GROUP,1,3)='AOI') OR (SUBSTR(p_GROUP,1,3)='API') THEN
      IAOITEST_V1(TRIM(BARCODE),
                  UPPER(TRIM(MACHINE_CODE)),
                  TRIM(EMP),
                  TRIM(FAILDESC),
                  v_RESULT,
                  RETEST,
                  EC_CNT,
                  EC_LIST,
                  AOITEST_RES);
  --Modified by Alex Wang on 2011/04/02 for 3QVE-110402-01 the next row(cause: TAOI-->900_AOI)                  
  --ELSIF SUBSTR(p_GROUP,1,4)='TAOI' THEN
  ELSIF (SUBSTR(p_GROUP,1,4)='TAOI') OR (SUBSTR(p_GROUP,1,7)='900_AOI') THEN
      IAOITEST_V2(TRIM(BARCODE),
                  UPPER(TRIM(MACHINE_CODE)),
                  TRIM(EMP),
                  TRIM(FAILDESC),
                  v_RESULT,
                  RETEST,
                  EC_CNT,
                  EC_LIST,
                  AOITEST_RES);
  END IF;

  IF AOITEST_RES <> 'OK' THEN
    RAISE e_AOITEST_ERROR;
  END IF;
  ----AOI or TAOI---End

  RES := 'OK'||'\n'||'**END**';
   o_flag := '0';
EXCEPTION

  WHEN e_FILE_ERROR THEN
    RES := 'WRONG FILE FORMAT!'||'\n'||'**END**';

  WHEN e_CHECK_ERROR THEN
    RES := CHECKRES||'\n'||'**END**';

  WHEN e_EC_ERROR THEN
    RES := 'ERROR CODE ERROR'||'\n'||'**END**';

  WHEN e_AOITEST_ERROR THEN
    RES := AOITEST_RES||'\n'||'**END**';

  WHEN OTHERS THEN
    RES := 'IAOIINI_V1 OTHER ERROR'||'\n'||'**END**';

END ;