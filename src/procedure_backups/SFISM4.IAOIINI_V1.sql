PROCEDURE                                                  IAOIINI_V1
/*********************************************
Author : Alex Wang                          **
Date   : 2010-10-26                         **
Description: To act on the *.ini file       **
**********************************************/

 (MACHINE_CODE    IN  VARCHAR2,
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
  RES            OUT  VARCHAR2
)
AS

CHECKRES        VARCHAR2(50);
PRODUCTRES      VARCHAR2(50);
AOITEST_RES     VARCHAR2(200);
v_RESULT        VARCHAR2(2);
p_GROUP         VARCHAR2(16);
p_STATION       VARCHAR2(16);

p_LINE          VARCHAR2(16);
p_SECTION       VARCHAR2(16);
c_model         VARCHAR2(25);
PRODUCT_NO      VARCHAR2(30);


EC_CNT          NUMBER(3,0);
EC_LIST         ECLIST;

p_COUNT         INTEGER;  --ADD BY LLF FOR 2016-11-25 FOR MULTI BORDS AOIFAIL SCAN AOI_CHECK STATION
P_COUNT1        INTEGER;  --ADD BY LLF FOR 2016-11-25 FOR MULTI BORDS AOIFAIL SCAN AOI_CHECK STATION
P_COUNT2        INTEGER;

e_CHECK_ERROR   EXCEPTION;
e_AOITEST_ERROR EXCEPTION;
e_FILE_ERROR    EXCEPTION;
e_EC_ERROR      EXCEPTION;
e_MULTI_FAIL    EXCEPTION; --ADD BY LLF FOR 2016-11-25 FOR MULTI BORDS AOIFAIL SCAN AOI_CHECK STATION
e_SN_REPAIR     EXCEPTION; --ADD BY LLF FOR 2016-11-25 FOR MULTI BORDS AOIFAIL SCAN AOI_CHECK STATION

BEGIN

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
    ----AOI or TAOI---Begin

  SELECT STATION_NAME,LINE_NAME,SECTION_NAME,GROUP_NAME
  INTO p_STATION,p_LINE,p_SECTION,p_GROUP
  FROM SFIS1.C_ICT_STATION_T
  WHERE STATION_CODE=MACHINE_CODE;

------- ---- Add By Derrick Chow Begin 2012-0831---------
 if (SUBSTR(p_GROUP,1,3)='AOI') then
    SMTINFO.CHECK_BIND_ROUTE_V2(TRIM(BARCODE),p_SECTION,p_GROUP,'N/A',p_LINE, PRODUCTRES ,CHECKRES);
    IF CHECKRES <> 'OK' THEN
     raise e_CHECK_ERROR;
   END IF;
 end if;
 ------- ---- Add By Drrick Chow end 2012-0831---------
 
   if (SUBSTR(p_GROUP,1,3)='API') then --add by wh 20180410
       SELECT COUNT(1) INTO p_COUNT2 FROM SFISM4.R_WIP_TRACKING_T WHERE SERIAL_NUMBER IN
       (SELECT SERIAL_NUMBER FROM SFISM4.R_PCB_DATECODE_T WHERE GROUP_ID IN
       (SELECT GROUP_ID FROM SFISM4.R_PCB_DATECODE_T WHERE SERIAL_NUMBER=TRIM(BARCODE)))
       AND ERROR_FLAG='1'; 
    if p_COUNT2 >0 THEN
        RES := 'Need to send to Repair!';
        RAISE e_SN_REPAIR;
    END IF;
  END IF;
 
 --ADD BY LLF 2016-11-25 BEGIN
    IF SUBSTR(p_GROUP,1,4) IN ('AOI_') and v_RESULT = 'F' THEN
          SELECT COUNT(1) INTO p_COUNT FROM SFISM4.R_PCB_DATECODE_T WHERE GROUP_ID IN
            (SELECT GROUP_ID FROM SFISM4.R_PCB_DATECODE_T WHERE SERIAL_NUMBER=TRIM(BARCODE)); 
            
           if p_COUNT>0 then
            RES := 'MultiBoard '||p_GROUP||' FAIL,Please scan AOI_CHECK STATION!';
            RAISE e_MULTI_FAIL;
          else 
            SELECT COUNT(1) INTO p_COUNT1 FROM SFISM4.R_WIP_TRACKING_T WHERE SERIAL_NUMBER IN
            (SELECT SERIAL_NUMBER FROM SFISM4.R_PCB_DATECODE_T WHERE GROUP_ID IN
              (SELECT GROUP_ID FROM SFISM4.R_PCB_DATECODE_T WHERE SERIAL_NUMBER=TRIM(BARCODE)))
               AND ERROR_FLAG='1'; 
             
            if p_COUNT1>0 then
              RES := 'Need to send to Repair!';
              RAISE e_SN_REPAIR;  
            end if;         
          end if;  
    elsif SUBSTR(p_GROUP,1,4) IN ('AOI_') and v_RESULT = 'P' THEN  ---ADD BY LLF 2017-10-14
          SELECT COUNT(1) INTO p_COUNT1 FROM SFISM4.R_PCB_DATECODE_T WHERE SERIAL_NUMBER=TRIM(BARCODE) AND GROUP_ID IS NOT NULL;
          if(p_COUNT1>0) then
              SELECT COUNT(1) INTO p_COUNT1 FROM SFISM4.R_WIP_TRACKING_T WHERE SERIAL_NUMBER IN
                (SELECT SERIAL_NUMBER FROM SFISM4.R_PCB_DATECODE_T WHERE GROUP_ID IN
                  (SELECT GROUP_ID FROM SFISM4.R_PCB_DATECODE_T WHERE SERIAL_NUMBER=TRIM(BARCODE)))
                   AND ERROR_FLAG='1'; 
             
                if p_COUNT1>0 then
                  RES := 'Need to send to Repair!';
                  RAISE e_SN_REPAIR;  
                end if;  
          end if;
    END IF;
  --ADD BY LLF 2016-11-25 END

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
  ELSIF (SUBSTR(p_GROUP,1,4)='TAOI') OR (SUBSTR(p_GROUP,1,7)='900_AOI') OR (SUBSTR(p_GROUP,1,7)='690_AOI')  THEN
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

EXCEPTION

  WHEN e_FILE_ERROR THEN
    RES := 'WRONG FILE FORMAT!'||'\n'||'**END**';

  WHEN e_CHECK_ERROR THEN
    RES := CHECKRES||'\n'||'**END**';

  WHEN e_EC_ERROR THEN
    RES := 'ERROR CODE ERROR'||'\n'||'**END**';

  WHEN e_AOITEST_ERROR THEN
    RES := AOITEST_RES||'\n'||'**END**';
    
  WHEN e_MULTI_FAIL THEN
    RES := RES||'\n'||'**END**';
    
  WHEN e_SN_REPAIR THEN
    RES := RES||'\n'||'**END**';

  WHEN OTHERS THEN
    RES := 'IAOIINI_V1 OTHER ERROR'||'\n'||'**END**';

END IAOIINI_V1;