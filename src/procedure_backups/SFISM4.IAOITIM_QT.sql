PROCEDURE                                           IAOITIM_QT

/*********************************************
Author : LingMingke                          **
Date   : 2025-04-08                         **
Description: To act on the *.3dx file       **
**********************************************/
(
  BARCODE       IN  VARCHAR2,
  MACHINE_CODE  IN  VARCHAR2,
  EMP           IN  VARCHAR2,
  BIOS              IN  VARCHAR2,
  RESULT        IN  VARCHAR2,
  STARTTIME      IN  VARCHAR2,
  ENDTIME      IN  VARCHAR2,
  RETEST        IN  VARCHAR2,
  ERROR_FLAG    IN  VARCHAR2,
  ERROR_CODE    IN  VARCHAR2,
  RES           OUT VARCHAR2
)
AS

CHECKRES        VARCHAR2(50);
AOITEST_RES     VARCHAR2(200);
v_RESULT        VARCHAR2(2);
p_GROUP         VARCHAR2(16);

EC_CNT            NUMBER(3,0);
EC_LIST            ECLIST;

e_CHECK_ERROR   EXCEPTION;
e_EC_ERROR        EXCEPTION;
e_AOITEST_ERROR EXCEPTION;

BEGIN

  EC_CNT := 0;

  IF UPPER(TRIM(RESULT)) = 'FAIL' OR UPPER(TRIM(RESULT)) = 'F' THEN
    v_RESULT := 'F';
  ELSIF UPPER(TRIM(RESULT)) = 'PASS' OR UPPER(TRIM(RESULT)) = 'GOOD' OR UPPER(TRIM(RESULT)) = 'P' THEN
    v_RESULT := 'P';
  END IF;

  IF v_RESULT = 'F' THEN
    RAISE e_CHECK_ERROR;
  END IF;

  IF v_RESULT = 'P' THEN 
  INSERT INTO SFISM4.R_QT_TIM (KP_SN,STATIONID,EMP_NO,START_TIME,END_TIME) VALUES (BARCODE,MACHINE_CODE,EMP,STARTTIME,ENDTIME);
  END IF;

  RES := 'OK'||'\n'||'**END**';

EXCEPTION

  WHEN e_CHECK_ERROR THEN
    RES := '**FAIL**';

  WHEN OTHERS THEN
    RES := 'OTHER ERROR'||'\n'||'**END**';
END IAOITIM_QT;