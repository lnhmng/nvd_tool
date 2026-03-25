PROCEDURE                                                             IAUTOTEST_TEST(
p_SN                   IN  VARCHAR2,
p_STATION_ID           IN  VARCHAR2,----Now is the MACHINE_CODE
p_BASIC_TESTTIME_BEGIN IN  VARCHAR2,
p_BASIC_TESTTIME_END   IN  VARCHAR2,
p_RESULT               IN  VARCHAR2,
p_ERROR_CODE           IN  VARCHAR2,
p_MODEL_NAME           IN  VARCHAR2,----Now is Model_name + ';' + BIOS
p_STATION_TYPE         IN  VARCHAR2,
p_WORK_STATION         IN  NUMBER,
p_OPERATORID           IN  VARCHAR2,
p_RETEST               IN  VARCHAR2,
p_FAILDESC             IN  VARCHAR2,
p_DIAG                 IN  VARCHAR2,
p_ECID                 IN  VARCHAR2,
p_MARKETNAME           IN  VARCHAR2,
p_MEM_VENDOR           IN  VARCHAR2,
p_MEM_PART             IN  VARCHAR2,
p_MEM_DATECODE         IN  VARCHAR2,
p_MAC                  IN  VARCHAR2,
p_PLX                  IN  VARCHAR2,--- this param is add By Derrick Chow for tickets:S000001GKK
RES                    OUT VARCHAR2) AS
---***p_FAILDESC  THIS PARAMETER IS BIOS IN FACT ***
p_CALLRES        VARCHAR2(48);
C_COUNT          NUMBER;
p_lINE           VARCHAR2(16);
p_SECTION        VARCHAR2(32);
p_GROUP          VARCHAR2(32);
p_STATION        VARCHAR2(32);
p_LASTGROUP      VARCHAR2(56);
p_ROUTE          NUMBER(4,0);
p_NEXTGROUP      VARCHAR2(32);
P_NEXTSTATION    VARCHAR2(16);
p_STATE          VARCHAR2(1);
p_STATIONNAME    VARCHAR2(10);--
p_TEMP_EC        VARCHAR2(32);
P_TEMP_GROUP     VARCHAR2(32);
v_GROUPRES       VARCHAR2(32);
p_MODEL          VARCHAR2(32);
p_MO             VARCHAR2(32);
p_PASSQTY        NUMBER(1,0);
p_FAILQTY        NUMBER(1,0);
p_CHECKSUM       VARCHAR2(20);
p_ROUTETYPE      VARCHAR2(25);
p_DATE           DATE;
p_WORKDATE       VARCHAR2(8);
p_WORKSECT       NUMBER(2,0);
p_WORKTIME       VARCHAR2(6);
p_LASTSTNTYPE    VARCHAR2(20);
p_STNTYPE        VARCHAR2(20);
p_MAXTESTTIME    VARCHAR2(20);
p_LASTSTNNUM     NUMBER(10);
p_MYRETEST       VARCHAR2(2);

v_INITSN         VARCHAR2(25);
v_INITSNCNT      NUMBER(2,0);
v_BIOS_COUNT     NUMBER(2,0);
v_MAXDATE        DATE;

v_BIOS_MATCH     NUMBER(2,0);
v_BIOS_MATCH1    NUMBER(2,0);
V_CHECKSUM_MATCH NUMBER(2,0);
v_MODEL_NAME     VARCHAR2(40);
p_BIOS           VARCHAR2(16);
--V_CHECKSUM        VARCHAR2(20);
v_SEPPOS         NUMBER(2,0);
v_BIOSSET        NUMBER(2,0);  -- ADD FOR BIOS CONTROL
v_BIOSCNT        NUMBER(2,0);  -- ADD FOR BIOS CONTROL
v_SEC_BIOS       VARCHAR2(20); --- ADD By Derrick 2012-11-19
v_SNCNT          NUMBER(3,0);  --Modified by Alex Wang for 3UZ9-110519-01
v_STNCNT         NUMBER(2,0);
v_DUPERR         NUMBER(3,0);
v_COUNT          NUMBER;
COUNT11          NUMBER;

--TTE-070813-01--
v_FIXID          VARCHAR2(16);
iPOS             NUMBER(2,0);
v_FIXRES         VARCHAR2(50);
--TTE-070813-01--
v_DARES          VARCHAR2(50);
v_DIAGRES        VARCHAR2(50);
v_DIAGCHECKRES    VARCHAR2(50);
v_ECIDRES        VARCHAR2(50);
v_MACRES         VARCHAR2(50);
v_CKMACRES       VARCHAR2(100);


e_MODELNAME_ERROR EXCEPTION;
e_NO_FLASHROM     EXCEPTION;
e_BIOS_MODELNAME  EXCEPTION;
e_ACCESS_DENIED   EXCEPTION;     -- REMOVE THE ACCESS CONTROL
e_NO_EC           EXCEPTION;    -- REMOVE THE DEFECT CODE CHECK
e_NO_SN           EXCEPTION;
e_NO_STATION      EXCEPTION;
e_ROUTE_ERROR     EXCEPTION;
e_CHECKSUM_ERROR  EXCEPTION;
--TTE-070813-01--
e_NO_FIX          EXCEPTION;
e_FIX_ERROR       EXCEPTION;
--TTE-070813-01--
e_NULL            EXCEPTION;
--------------e_SCRAP       EXCEPTION;

BEGIN


v_SNCNT:=0;
v_STNCNT:=0;
p_NEXTGROUP:='';
p_DATE:=SYSDATE;
v_DUPERR:=0;

v_SEPPOS:=INSTR(p_MODEL_NAME,';');
p_BIOS:=SUBSTR(p_MODEL_NAME,v_SEPPOS+1,LENGTH(p_MODEL_NAME)-v_SEPPOS);
v_MODEL_NAME:=SUBSTR(p_MODEL_NAME,1,v_SEPPOS-1);


p_STNTYPE:=p_STATION_TYPE;
--TTE-070813-01--
--p_CHECKSUM:=p_RETEST;
--TTE-070813-01--
p_MYRETEST:='0';

p_WORKDATE:=TO_CHAR(p_DATE,'YYYYMMDD');
p_WORKSECT:=TO_NUMBER(TO_CHAR(p_DATE,'HH24'));
p_WORKTIME:=TO_CHAR(p_DATE,'HH24MISS');
--CHECK THE SERIAL NUMBER EXSISTANCE

SELECT COUNT(SERIAL_NUMBER)
INTO v_SNCNT
FROM SFISM4.R_WIP_TRACKING_T
WHERE SERIAL_NUMBER=p_SN;

IF v_SNCNT=0 THEN
   RAISE e_NO_SN;
END IF;

--Modified by Steven Hu on 2008-03-19 for TTE-080318-01 Begin
--p_STATIONNAME:=SUBSTR(p_STATION_ID,-4,4);
p_STATIONNAME:=p_STATION_ID;
--Modified by Steven Hu on 2008-03-19 for TTE-080318-01 End
SELECT COUNT(*)
INTO v_STNCNT
FROM  SFIS1.C_ICT_STATION_T
WHERE STATION_CODE=p_STATIONNAME;

IF v_STNCNT=0 THEN
    RAISE e_NO_STATION;
END IF;

IF p_RESULT='P' THEN
    p_TEMP_EC:='N/A';
ELSE
--------- add by Derrick  begin 2012/02/20  begin
     if  substr(p_ERROR_CODE,1,1) ='E' or substr(p_ERROR_CODE,1,2)='98' THEN
     if substr(p_ERROR_CODE,1,2)='98' then
      SELECT COUNT(*) INTO  COUNT11 FROM SFIS1.C_ERROR_CODE_T
      WHERE ERROR_CODE = p_ERROR_CODE
      GROUP BY ERROR_CODE;
       IF COUNT11< 1 THEN
       RES :=p_ERROR_CODE||''||'NOT EXIST';
       RAISE e_NULL;
      END IF;
     else
     res:='OK';
     end if;
     
     else
      RES:='EC error';
      RAISE e_NULL;
     end if;
---------- add by Derrick end  2012/02/20  end;   
    p_TEMP_EC:=p_ERROR_CODE;
END IF;

SELECT MODEL_NAME,MO_NUMBER,NVL(PASS_QTY,0),NVL(FAIL_QTY,0),GROUP_NAME,SPECIAL_ROUTE,ERROR_FLAG,NEXT_STATION
INTO p_MODEL,p_MO,p_PASSQTY,p_FAILQTY,p_LASTGROUP,p_ROUTE,p_STATE,P_NEXTSTATION
FROM SFISM4.R_WIP_TRACKING_T
WHERE SERIAL_NUMBER=p_SN;

-- GET THE STATION TYPE OF THE LAST TEST STATION

SELECT COUNT(SERIAL_NUMBER)
INTO   v_SNCNT
FROM   SFISM4.R_TEST_TEMP_T
WHERE  SERIAL_NUMBER=p_SN;

IF v_SNCNT<>0 THEN

    SELECT MAX(TEST_DATE || TEST_TIME)
    INTO p_MAXTESTTIME
    FROM   SFISM4.R_TEST_TEMP_T
    WHERE  SERIAL_NUMBER=p_SN;

    SELECT STATION_TYPE,WORK_STATION
    INTO   p_LASTSTNTYPE,p_LASTSTNNUM
    FROM   SFISM4.R_TEST_TEMP_T
    WHERE  SERIAL_NUMBER=p_SN AND (TEST_DATE || TEST_TIME) = p_MAXTESTTIME AND ROWNUM=1;

    SELECT GROUP_NAME
    INTO   p_GROUP
    FROM   SFIS1.C_ICT_STATION_T
    WHERE  STATION_CODE=p_STATIONNAME;

    IF SUBSTR(p_LASTSTNTYPE,1,3)='ICT' THEN
        p_LASTSTNTYPE:=SUBSTR(p_LASTSTNTYPE,1,3);
    ELSE
    p_LASTSTNTYPE:=p_LASTSTNTYPE;
    END IF;

    IF (p_GROUP<>p_LASTGROUP) THEN 
    
--    --------********************** add by Derrick Chow 2012/05/10 begin***********************-------------------
--     if (p_LASTSTNTYPE='ICT' OR p_LASTSTNTYPE='OQA' OR p_LASTSTNTYPE='COQA' OR p_LASTSTNTYPE='OBA' OR p_LASTSTNTYPE='OBAT') then
--     if  p_LASTSTNTYPE= p_GROUP then
--        p_LASTSTNTYPE := p_LASTSTNTYPE;
--        else
--        p_LASTSTNTYPE:=p_LASTGROUP;
--        end if;
--     else
--    ------********************** add by Derrick Chow 2012/05/10 end***********************-------------------
        p_LASTSTNTYPE:=p_LASTGROUP;
--      END IF;
    end if;
    
ELSE
    p_LASTSTNTYPE:=p_LASTGROUP;
END IF;

IF SUBSTR(p_STNTYPE,1,3)='ICT' THEN
    p_STNTYPE:=SUBSTR(p_STNTYPE,1,3);
ELSE
    p_STNTYPE:=p_STNTYPE;
END IF;

SELECT STATION_NAME,LINE_NAME,SECTION_NAME,GROUP_NAME
INTO   p_STATION,p_LINE,p_SECTION,p_GROUP
FROM   SFIS1.C_ICT_STATION_T
WHERE  STATION_CODE=p_STATIONNAME;
----------------******add by Derrick Chow 2012-05-11 begin ***********----------
if (P_NEXTSTATION='N/A')or(P_NEXTSTATION is null) then
res:='OK';
ELSE
   IF P_NEXTSTATION =p_GROUP THEN
    RES:='OK';
  ELSE
    RES:='GOTO'||P_NEXTSTATION||'RETEST';
    RAISE e_NULL;
   END IF;
END IF;
----------------******add by Derrick Chow 2012-05-11 end ***********----------

--Add by Jason Liu for TTE-090219-01 ON 2009-2-19.
SFIS1.CHECK_LINE_STOP(p_LINE,p_GROUP,p_SECTION,p_SN,RES); --GET LAST SN by LINE and GROUP--


--TTE-070813-01--
--ICT Menu : TR8001 should not be controled--
IF INSTR(UPPER(p_GROUP),'ICT') > 0 THEN
    p_CHECKSUM := p_RETEST;
ELSE
    iPOS := INSTR(p_RETEST,';');
    IF iPOS = 0 THEN
        p_CHECKSUM := p_RETEST;
    ELSE
        p_CHECKSUM := SUBSTR(p_RETEST, 1, iPOS - 1);
        v_FIXID := SUBSTR(p_RETEST, iPOS + 1, LENGTH(p_RETEST) - iPOS);
        SFIS1.CHECK_FIXTURE_NV(v_FIXID,v_FIXRES);
        IF v_FIXRES <> 'OK' THEN
            RAISE e_FIX_ERROR;
        END IF;
        INSERT INTO SFISM4.R_SN_FIXTURE_T(SERIAL_NUMBER
                  ,FIXID
          ,GROUP_NAME
          ,STATION_NAME
          ,STATION_CODE
          ,EMP
          ,IN_STATION_TIME)
            VALUES(p_SN
            ,v_FIXID
          ,p_GROUP
          ,p_STATION
          ,p_STATIONNAME
          ,p_OPERATORID
          ,p_DATE);
        COMMIT;
    END IF;
END IF;
--TTE-070813-01--

p_TEMP_GROUP:=p_GROUP;

SFISM4.Sn_Station_Test(p_STNTYPE,p_LASTSTNTYPE,p_STATE,p_ROUTE,v_GROUPRES);
p_NEXTGROUP:=v_GROUPRES;
/* IF (p_STNTYPE='OBA') OR (p_STNTYPE='OQA') OR (p_STNTYPE='COQA') OR (p_STNTYPE='5XOQA') THEN
   IF (p_LASTSTNTYPE='OBA') OR (p_LASTSTNTYPE='OQA') OR (p_LASTSTNTYPE='COQA') OR (p_LASTSTNTYPE='5XOQA') THEN
      SELECT NVL(GROUP_NEXT,'FINISHED') INTO p_NEXTGROUP FROM SFIS1.C_ROUTE_CONTROL_T
      WHERE GROUP_NAME=p_LASTGROUP AND STATE_FLAG=p_STATE AND ROUTE_CODE=p_ROUTE AND ROWNUM=1;
   ELSE
      SELECT NVL(GROUP_NEXT,'FINISHED') INTO p_NEXTGROUP FROM SFIS1.C_ROUTE_CONTROL_T
      WHERE GROUP_NAME=p_LASTGROUP AND STATE_FLAG=p_STATE AND ROUTE_CODE=p_ROUTE AND GROUP_NEXT=p_STNTYPE AND ROWNUM=1;
   END IF;
--Add by Steven Hu on 2008/03/24 for TTE-080318-01 Begin
*/
--Modified by Eric Guo for TTE-090113-01 Begin
--Modify by Kassi Bai on 2009/02/20 for TTE-090220-01 begin-------------------------------------------
/*IF (p_STNTYPE='OBA') OR (p_STNTYPE='OBAT') OR (p_STNTYPE='OQA') OR (p_STNTYPE='COQA') OR (p_STNTYPE='5XOQA') THEN
   IF (p_LASTSTNTYPE='OBA') OR (p_LASTSTNTYPE='OBAT') OR (p_LASTSTNTYPE='OQA') OR (p_LASTSTNTYPE='COQA') OR (p_LASTSTNTYPE='5XOQA') THEN*/
/*IF (p_STNTYPE='OBA') OR (p_STNTYPE='OQA') OR (p_STNTYPE='COQA') OR (p_STNTYPE='5XOQA') THEN
   IF (p_LASTSTNTYPE='OQA') OR (p_LASTSTNTYPE='HDCP') OR (p_LASTSTNTYPE='HDMI') OR (p_LASTSTNTYPE='OBA')
 OR (p_LASTSTNTYPE='OQA') OR (p_LASTSTNTYPE='COQA') OR (p_LASTSTNTYPE='5XOQA') THEN
--Modify by Kassi Bai on 2009/02/20 for TTE-090220-01 end----------------------------------------------
      SELECT NVL(GROUP_NEXT,'FINISHED') INTO p_NEXTGROUP FROM SFIS1.C_ROUTE_CONTROL_T
      WHERE GROUP_NAME=p_LASTGROUP AND STATE_FLAG=p_STATE AND ROUTE_CODE=p_ROUTE AND ROWNUM=1;
   ELSE
      SELECT NVL(GROUP_NEXT,'FINISHED') INTO p_NEXTGROUP FROM SFIS1.C_ROUTE_CONTROL_T
      WHERE GROUP_NAME=p_LASTGROUP AND STATE_FLAG=p_STATE AND ROUTE_CODE=p_ROUTE AND GROUP_NEXT=p_STNTYPE AND ROWNUM=1;
   END IF;
--Modified by Eric Guo for TTE-090113-01  End
--Modify by Kassi Bai on 2009/03/28 for TTE-090328-01 Begin---------------------
ELSIF (P_STNTYPE = 'REFLASHROM') THEN
   IF (p_LASTSTNTYPE='HDCP') OR (p_LASTSTNTYPE='OQA') OR (p_LASTSTNTYPE='OBA')THEN
      SELECT NVL(GROUP_NEXT,'FINISHED') INTO p_NEXTGROUP FROM SFIS1.C_ROUTE_CONTROL_T
      WHERE GROUP_NAME=p_LASTGROUP AND STATE_FLAG=p_STATE AND ROUTE_CODE=p_ROUTE AND GROUP_NEXT=p_STNTYPE AND ROWNUM=1;
   ELSE
   SELECT NVL(GROUP_NEXT,'FINISHED') INTO p_NEXTGROUP FROM SFIS1.C_ROUTE_CONTROL_T
      WHERE GROUP_NAME=p_LASTGROUP AND STATE_FLAG=p_STATE AND ROUTE_CODE=p_ROUTE AND ROWNUM=1;
   END IF;
ELSIF (P_STNTYPE = 'TVI') THEN
   IF (p_LASTSTNTYPE='HDCP') OR (p_LASTSTNTYPE='OQA') OR (p_LASTSTNTYPE='OBA') OR (p_LASTSTNTYPE='REFLASHROM') OR (p_LASTSTNTYPE='CCRT')THEN
      SELECT NVL(GROUP_NEXT,'FINISHED') INTO p_NEXTGROUP FROM SFIS1.C_ROUTE_CONTROL_T
      WHERE GROUP_NAME=p_LASTGROUP AND STATE_FLAG=p_STATE AND ROUTE_CODE=p_ROUTE AND GROUP_NEXT=p_STNTYPE AND ROWNUM=1;
   ELSE
   SELECT NVL(GROUP_NEXT,'FINISHED') INTO p_NEXTGROUP FROM SFIS1.C_ROUTE_CONTROL_T
      WHERE GROUP_NAME=p_LASTGROUP AND STATE_FLAG=p_STATE AND ROUTE_CODE=p_ROUTE AND ROWNUM=1;
   END IF;
--Modify by Kassi Bai on 2009/03/28 for TTE-090328-01 End---------------------
ELSIF (P_STNTYPE = 'CCRT') THEN
   IF (p_LASTSTNTYPE='OQA') OR (p_LASTSTNTYPE='REFLASHROM') OR (p_LASTSTNTYPE='BIOSCHECK') OR (p_LASTSTNTYPE='OBA') OR (p_LASTSTNTYPE='HDCP')THEN
      SELECT NVL(GROUP_NEXT,'FINISHED') INTO p_NEXTGROUP FROM SFIS1.C_ROUTE_CONTROL_T
      WHERE GROUP_NAME=p_LASTGROUP AND STATE_FLAG=p_STATE AND ROUTE_CODE=p_ROUTE AND GROUP_NEXT=p_STNTYPE AND ROWNUM=1;
   ELSE
   SELECT NVL(GROUP_NEXT,'FINISHED') INTO p_NEXTGROUP FROM SFIS1.C_ROUTE_CONTROL_T
      WHERE GROUP_NAME=p_LASTGROUP AND STATE_FLAG=p_STATE AND ROUTE_CODE=p_ROUTE AND ROWNUM=1;
   END IF;
--Add by Steven Hu on 2008/03/24 for TTE-080318-01 End
--Add by Kassi Bai on 2009/02/20 for TTE-090220-01 begin-----------------------------
ELSIF (P_STNTYPE = 'OBAT') THEN
    IF p_LASTSTNTYPE='OBAT' THEN
      SELECT NVL(GROUP_NEXT,'FINISHED') INTO p_NEXTGROUP FROM SFIS1.C_ROUTE_CONTROL_T
      WHERE GROUP_NAME=p_LASTGROUP AND STATE_FLAG=p_STATE AND ROUTE_CODE=p_ROUTE AND GROUP_NEXT='OBA'AND ROWNUM=1;
 ELSE
   SELECT NVL(GROUP_NEXT,'FINISHED') INTO p_NEXTGROUP FROM SFIS1.C_ROUTE_CONTROL_T
      WHERE GROUP_NAME=p_LASTGROUP AND STATE_FLAG=p_STATE AND ROUTE_CODE=p_ROUTE AND ROWNUM=1;
 END IF;
--Add by Kassi Bai on 2009/02/20 for TTE-090220-01 end-------------------------------
--Add by kassi bai on 2008/11/07 for TTE-081104-01 begin
ELSIF (P_STNTYPE = 'BIOSCHECK') THEN
    IF p_LASTSTNTYPE='BIOSCHECK' THEN
      SELECT NVL(GROUP_NEXT,'FINISHED') INTO p_NEXTGROUP FROM SFIS1.C_ROUTE_CONTROL_T
      WHERE GROUP_NAME=p_LASTGROUP AND STATE_FLAG=p_STATE AND ROUTE_CODE=p_ROUTE AND GROUP_NEXT='CCRT'AND ROWNUM=1;
 ELSE
   SELECT NVL(GROUP_NEXT,'FINISHED') INTO p_NEXTGROUP FROM SFIS1.C_ROUTE_CONTROL_T
      WHERE GROUP_NAME=p_LASTGROUP AND STATE_FLAG=p_STATE AND ROUTE_CODE=p_ROUTE AND ROWNUM=1;
 END IF;
--Add by kassi bai on 2008/11/07 for TTE-081104-01 end
ELSE
    --Add by Eric Guo on 2009/02/25 for TTE-090225-01 begin
    SELECT COUNT(*) INTO C_COUNT FROM SFIS1.C_ROUTE_CONTROL_T
   WHERE GROUP_NAME=p_LASTGROUP AND STATE_FLAG=p_STATE AND ROUTE_CODE=p_ROUTE AND ROWNUM=1;
   IF C_COUNT = 0 THEN
      P_NEXTGROUP:='FINISHED';
   ELSE
     SELECT NVL(GROUP_NEXT,'FINISHED') INTO p_NEXTGROUP FROM SFIS1.C_ROUTE_CONTROL_T
     WHERE GROUP_NAME=p_LASTGROUP AND STATE_FLAG=p_STATE AND ROUTE_CODE=p_ROUTE AND ROWNUM=1;
   END IF;

  --Add by Eric Guo on 2009/02/25 for TTE-090225-01 end
   --SELECT NVL(GROUP_NEXT,'FINISHED') INTO p_NEXTGROUP FROM SFIS1.C_ROUTE_CONTROL_T
   --WHERE GROUP_NAME=p_LASTGROUP AND STATE_FLAG=p_STATE AND ROUTE_CODE=p_ROUTE AND ROWNUM=1;
END IF;*/
---*******Below Source code add By Derrick For tickets:S000001GKK 2013-11-19 9:05:26*********--- 
  if (p_PLX<>'0') THEN
   if  SUBSTR(p_STNTYPE,1,8)='FLASHROM' OR SUBSTR(p_STNTYPE,1,10)='REFLASHROM' or p_STNTYPE='BIOSCHECK' then
       IF p_MODEL<>v_MODEL_NAME THEN
           RAISE e_MODELNAME_ERROR;
          END IF;
       
        SFIS1.CHECK_PLX_T(p_STNTYPE , p_LINE,p_SN,p_PLX, p_GROUP, v_MODEL_NAME, P_CHECKSUM, p_CALLRES );
        if  p_CALLRES<>'OK' then
         res:=p_CALLRES;
         raise e_NULL;
        -- Raise NULL;
        end if;
      end if;
    END IF;
 
---*****************  BELOW ADD FOR REFLASHROM  2004 12 7 *******************************
IF (p_BIOS<>'0') THEN
    IF SUBSTR(p_STNTYPE,1,8)='FLASHROM' OR SUBSTR(p_STNTYPE,1,10)='REFLASHROM'THEN
       --Modified by Alex Wang on 2010/07/27 for 26DH-100727-01 Begin--
       SFIS1.CHECK_ROUTE(p_LINE, 'REFLASHROM',p_SN,p_CALLRES);
       IF SUBSTR(p_STNTYPE,1,10)='REFLASHROM' AND p_CALLRES='OK' THEN
           p_GROUP:='REFLASHROM';
           p_STNTYPE:='REFLASHROM';
           p_SECTION:='REFLASHROM';
           p_STATION:='REFLASHROM';
           p_NEXTGROUP:='REFLASHROM';
       END IF;

       IF p_MODEL<>v_MODEL_NAME THEN
           RAISE e_MODELNAME_ERROR;
       END IF;

       SELECT COUNT(*)
       INTO v_BIOSCNT
       FROM SFISM4.R_NVBIOS_MODEL_T
       WHERE SERIAL_NUMBER=p_SN;

       IF v_BIOSCNT=0 THEN
           IF (LENGTH(p_CHECKSUM)>1 AND TRIM(P_CHECKSUM)<>'0') THEN
               INSERT INTO SFISM4.R_NVBIOS_MODEL_T(SERIAL_NUMBER, INIT_MODEL_NAME, FIRST_BIOS,
                   SECOND_BIOS, LAST_MODEL_NAME, DATETIME, RESERVE1, RESERVE2, FLAG, GROUP_NAME)
               VALUES(p_SN,v_MODEL_NAME,p_BIOS,'','',SYSDATE,p_CHECKSUM,'','0',p_GROUP);
           ELSE
               INSERT INTO SFISM4.R_NVBIOS_MODEL_T(SERIAL_NUMBER, INIT_MODEL_NAME, FIRST_BIOS,
                   SECOND_BIOS, LAST_MODEL_NAME, DATETIME, RESERVE1, RESERVE2, FLAG, GROUP_NAME)
               VALUES(p_SN,v_MODEL_NAME,p_BIOS,'','',SYSDATE,'','','0',p_GROUP);
           END IF;
       END IF;

       IF v_BIOSCNT>0 THEN
           IF (LENGTH(p_CHECKSUM)>1 AND TRIM(P_CHECKSUM)<>'0') THEN
               UPDATE SFISM4.R_NVBIOS_MODEL_T
               SET   SECOND_BIOS=p_BIOS,DATETIME=SYSDATE,FLAG='1',GROUP_NAME=p_GROUP,RESERVE2=p_CHECKSUM
               WHERE SERIAL_NUMBER=p_SN;
           ELSE
               UPDATE SFISM4.R_NVBIOS_MODEL_T
               SET   SECOND_BIOS=p_BIOS,DATETIME=SYSDATE,FLAG='1',GROUP_NAME=p_GROUP,RESERVE2=''
               WHERE SERIAL_NUMBER=p_SN;
           END IF;
       END IF;

       SELECT COUNT(*)
       INTO v_BIOSSET
       FROM SFIS1.C_NV_MODESC_T
       WHERE (CUSTOMER_PN=v_MODEL_NAME OR L600_690_PN=v_MODEL_NAME) AND BIOS_VERSION=p_BIOS;

       IF v_BIOSSET=0 THEN
           RAISE e_BIOS_MODELNAME;
       END IF;

       IF (LENGTH(p_CHECKSUM)>1 AND TRIM(P_CHECKSUM)<>'0') THEN
           SELECT COUNT(*)
           INTO v_COUNT
           FROM SFIS1.C_NV_MODESC_T
           WHERE (CUSTOMER_PN=v_MODEL_NAME OR L600_690_PN=v_MODEL_NAME) AND BIOS_VERSION=p_BIOS AND INSTR(CHECK_SUM,P_CHECKSUM)>0;

           IF (V_COUNT<=0) THEN
           RAISE e_CHECKSUM_ERROR;
           END IF;
       END IF;
       --Modified by Alex Wang on 2010/07/27 for 26DH-100727-01 End--
    ELSIF (p_STNTYPE<>'ICT') AND (p_STNTYPE<>'ICT_GR') AND (p_STNTYPE<>'ICT_TR') AND (p_STNTYPE<>'SLI')  THEN

        IF p_MODEL<>v_MODEL_NAME THEN
            RAISE e_MODELNAME_ERROR;
        END IF;

        SELECT COUNT(*)
        INTO v_BIOSCNT
        FROM SFISM4.R_NVBIOS_MODEL_T
        WHERE SERIAL_NUMBER=p_SN;

        IF v_BIOSCNT=0 THEN
            -----------------Modified by Alex Wang on 2010/04/28 for 1SXG-100428-01 Begin
            SELECT COUNT(*) INTO v_INITSNCNT
            FROM SFISM4.R_SN_LINK_T
            WHERE NEW_SN = p_SN;
            IF v_INITSNCNT = 0 THEN
                RES := 'CURRENT SN HAS NO BIOS;SN NOT LINK';
                RAISE e_NULL;
            ELSE
                SELECT INIT_SN INTO v_INITSN
                FROM SFISM4.R_SN_LINK_T
                WHERE NEW_SN = p_SN;
            END IF;

            SELECT COUNT(*) INTO v_BIOS_COUNT
            FROM   SFISM4.R_NVBIOS_MODEL_T A,SFISM4.R_SN_LINK_T B
            WHERE  A.SERIAL_NUMBER = B.OLD_SN AND B.INIT_SN = v_INITSN;
            IF v_BIOS_COUNT = 0 THEN
                RAISE e_NO_FLASHROM;
            ELSE
                SELECT MAX(A.DATETIME) INTO v_MAXDATE
                FROM SFISM4.R_NVBIOS_MODEL_T A,SFISM4.R_SN_LINK_T B
                WHERE A.SERIAL_NUMBER = B.OLD_SN AND B.INIT_SN = v_INITSN;

                SELECT B.MODEL_NAME INTO v_MODEL_NAME             --Find the right Model_Name
                FROM SFISM4.R_NVBIOS_MODEL_T A,SFISM4.R_SN_LINK_T B
                WHERE A.SERIAL_NUMBER = B.OLD_SN AND B.INIT_SN = v_INITSN AND A.DATETIME = v_MAXDATE;
            END IF;
            -----------------Modified by Alex Wang on 2010/04/28 for 1SXG-100428-01 End
        END IF;

            IF v_BIOSCNT<>0 THEN
            
            SELECT COUNT(*)
            INTO v_BIOS_MATCH
            FROM sfism4.R_NVBIOS_MODEL_T
            WHERE (FIRST_BIOS=p_BIOS or SECOND_BIOS=p_BIOS) AND  SERIAL_NUMBER=p_SN;
            
----------- modefied by Derrick 2012-1119 begin
            IF v_BIOS_MATCH=0 THEN             
                RAISE e_BIOS_MODELNAME;
                
              else 
                SELECT SECOND_BIOS
                INTO  v_SEC_BIOS 
               FROM sfism4.R_NVBIOS_MODEL_T
               WHERE  SERIAL_NUMBER=p_SN; 
              
              if (v_SEC_BIOS is not null ) then
                 if v_SEC_BIOS<>p_BIOS then
                   RAISE e_BIOS_MODELNAME;
                 end if; 
              end if;
                
            END IF;
 ----------- modefied by Derrick 2012-1119 end           

            IF (LENGTH(p_CHECKSUM)>1 AND TRIM(P_CHECKSUM)<>'0') THEN
                SELECT COUNT(*)
                INTO V_CHECKSUM_MATCH
                FROM sfism4.R_NVBIOS_MODEL_T
                WHERE (RESERVE1=p_CHECKSUM OR RESERVE2=p_CHECKSUM) AND SERIAL_NUMBER=P_SN;

                IF (V_CHECKSUM_MATCH=0) THEN
                    RAISE e_CHECKSUM_ERROR;
                END IF;
            END IF;
        END IF;

        SELECT COUNT(*)
        INTO v_BIOSSET
        FROM SFIS1.C_NV_MODESC_T
        WHERE (CUSTOMER_PN=v_MODEL_NAME OR L600_690_PN=v_MODEL_NAME) AND BIOS_VERSION=p_BIOS;

        IF v_BIOSSET=0 THEN
            RAISE e_BIOS_MODELNAME;
        END IF;

        IF (LENGTH(p_CHECKSUM)>1 AND TRIM(P_CHECKSUM)<>'0') THEN
            SELECT COUNT(*)
            INTO v_COUNT
            FROM SFIS1.C_NV_MODESC_T
            WHERE (CUSTOMER_PN=v_MODEL_NAME OR L600_690_PN=v_MODEL_NAME) AND BIOS_VERSION=p_BIOS AND INSTR(CHECK_SUM,P_CHECKSUM)>0;

            IF (V_COUNT<=0) THEN
                RAISE e_CHECKSUM_ERROR;
            END IF;
        END IF;
    END IF;
END IF;

--Added by Alex Wang on 2011/2/18 for 2A3B-110218-01 (For 'Car') Begin
    --upload on Station"MAC_FLASH"     check on Station"FCT_TEST"
--IF (p_STNTYPE='MAC_FLASH') OR (p_STNTYPE='FCT_TEST') THEN 
--    IF p_MAC='N/A' THEN
--        RES := 'MAC CAN NOT BE NULL!';
--        RAISE e_NULL;
--    ELSE       
--        IF (p_STNTYPE='MAC_FLASH') THEN
--            IF p_MAC<>'0' THEN
--                SFISM4.FBT_MAC_V1(p_STATION_ID,p_MAC,p_SN,'','',p_RESULT,p_OPERATORID,'0',v_CKMACRES);
--                IF v_CKMACRES<>'OK' THEN
--                    RES := v_CKMACRES||'(ERROR IN SFISM4.FBT_MAC_V1)';
--                    RAISE e_NULL;
--                END IF;
--            END IF;
--        ELSIF (p_STNTYPE='FCT_TEST') THEN
--            SELECT COUNT(0) 
--            INTO v_COUNT
--            FROM COMPAQ.COMPAQ_R_MACADDR_T 
--            WHERE FLASH_FLAG= 'MAC' AND MAC_ADDR = p_MAC AND BAR_CODE = p_SN;
--            IF (V_COUNT<=0) THEN
--                RES := 'MAC ERROR(NOT MATCH THE FIRST MAC)';
--                RAISE e_NULL;
--            END IF; 
--        END IF;
--    END IF;
--END IF;

IF (p_STNTYPE='MAC_FLASH') OR (p_STNTYPE='FCT_TEST') THEN 
    IF p_MAC='N/A' THEN
        RES := 'MAC CAN NOT BE NULL!';
        RAISE e_NULL;
    ELSE       
        IF (p_STNTYPE='MAC_FLASH') THEN
            IF p_MAC<>'0' THEN
                SFIS1.MAC_CHECK_STANDARD(p_MAC,v_CKMACRES);
                IF v_CKMACRES<>'OK' THEN
                    RES := v_CKMACRES;
                    RAISE e_NULL;
                ELSE    
                    SELECT COUNT(0) 
                    INTO v_COUNT
                    FROM SFISM4.R_LINK_T 
                    WHERE KEY_VALUE = p_MAC AND FLAG='MAC';
                    IF (v_COUNT>0) THEN--be used
                        RES := 'MAC IS USED ONCE!';
                        RAISE e_NULL;
                    ELSE--not be used
                        SFISM4.DATALINK(p_OPERATORID,p_SN,p_MAC,'N/A','MAC',v_MACRES);
                        IF (v_MACRES<>'OK') THEN
                            RES := v_MACRES||'(RUN SFISM4.DATALINK ERROR)';
                            RAISE e_NULL;
                        END IF;                                    
                    END IF;
                END IF;    
            END IF;
        ELSIF (p_STNTYPE='FCT_TEST') THEN
            IF p_MAC<>'0' THEN
                SFIS1.MAC_CHECK_STANDARD(p_MAC,v_CKMACRES);
                IF v_CKMACRES<>'OK' THEN
                    RES := v_CKMACRES;
                    RAISE e_NULL;
                ELSE    
                    SELECT COUNT(0) 
                    INTO v_COUNT
                    FROM SFISM4.R_LINK_T 
                    WHERE KEY_VALUE = p_MAC AND FLAG='MAC' AND SERIAL_NUMBER=p_SN;
                    IF (v_COUNT=0) THEN--NOT MATCH THE OLD ONE
                        RES := 'MAC DOESN''T MATCH THE OLD ONE(UPLOAD IN MAC_FLASH)!';
                        RAISE e_NULL;                                  
                    END IF;
                END IF;                                    
            ELSE
                SELECT COUNT(0)
                INTO v_COUNT
                FROM SFISM4.R_LINK_T
                WHERE SERIAL_NUMBER=p_SN AND FLAG='MAC';
                IF (v_COUNT>0) THEN
                    RES := 'MAC WAS BE UPLOADED ON "MAC_FLASH",IT MUST BE UPLOADED ON "FCT_TEST" TOO!';
                    RAISE e_NULL;
                END IF;        
            END IF; 
        END IF;
    END IF;
END IF;



--Added by Alex Wang on 2011/2/18 for 2A3B-110218-01 (For 'Car') End
        
--Added by Steven Hu on 2008/12/29 for TTE-081229-01 Begin
----------***********modefied by Derrick Chow 2012/05/11 begin*******-------------
--IF (P_NEXTSTATION<>'N/A' AND P_NEXTSTATION IS NOT NULL) THEN
--   RES:=P_NEXTSTATION;
--   RAISE e_NULL;
--END IF;
----------***********modefied by Derrick Chow 2012/05/11 endn*******-------------

--Added by Steven Hu on 2008/12/29 for TTE-081229-01 End
---**************************************************************************************
--Modified by Steven Hu for TTE-080318-01 Begin
--SELECT ROUTE_DESC INTO p_ROUTETYPE FROM SFIS1.C_ROUTE_NAME_T WHERE ROUTE_CODE=p_ROUTE;
--IF TRIM(p_ROUTETYPE)='AUTOTEST' THEN
--Modified by Steven Hu for TTE-080318-01 End
IF (p_LASTSTNTYPE='FBT')  THEN
    IF  p_STNTYPE='FBT' THEN
        RAISE e_ROUTE_ERROR;
    ELSIF p_STNTYPE<>'FBT' THEN
        IF p_GROUP=p_NEXTGROUP THEN
            BEGIN
                RES:='OK';
                IF p_RESULT='P' THEN
                    UPDATE SFISM4.R_WIP_TRACKING_T
                    SET PASS_QTY=1,FAIL_QTY=0
                    WHERE SERIAL_NUMBER=p_SN;
                ELSIF p_RESULT='F' THEN
                    UPDATE SFISM4.R_WIP_TRACKING_T
                    SET PASS_QTY=0,FAIL_QTY=1
                    WHERE SERIAL_NUMBER=p_SN;
                END IF;

            COMMIT;
            END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----***********************************************************************************************
----***********************************************************************************************
--add by kassi bai on 2008-11-04 for TTE-081104-01 begin
ELSIF (p_LASTSTNTYPE='BIOSCHECK') THEN
    IF  p_STNTYPE='BIOSCHECK' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REFLASHROOM BIOS CHECK
    ELSIF p_STNTYPE<>'BIOSCHECK' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;

              COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
-- add by kassi bai on 2008-11-04 for TTE-081104-01 end
----***********************************************************************************************
----***********************************************************************************************
ELSIF (p_LASTSTNTYPE='SCREEN') THEN
    IF  p_STNTYPE='SCREEN' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'SCREEN' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;

            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----************************************************************************************************
----************************************************************************************************
ELSIF (p_LASTSTNTYPE='CRT') THEN
    IF  p_STNTYPE='CRT' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'CRT' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----********************************************************************************
----********************************************************************************
ELSIF (p_LASTSTNTYPE='CCRT') THEN
    IF p_STNTYPE='CCRT' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'CCRT' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----********************************************************************************
--Added by Alex Wang on 2010/4/8 for 1NY8-100408-01 Begin
----********************************************************************************
ELSIF (p_LASTSTNTYPE='BAT_THERMA') THEN
    IF  p_STNTYPE='BAT_THERMA' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'BAT_THERMA' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----********************************************************************************
----********************************************************************************
ELSIF (p_LASTSTNTYPE='BOARD_TUNE') THEN
    IF  p_STNTYPE='BOARD_TUNE' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'BOARD_TUNE' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----********************************************************************************
----********************************************************************************
ELSIF (p_LASTSTNTYPE='MEMORY_TUNE') THEN
    IF  p_STNTYPE='MEMORY_TUNE' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'MEMORY_TUNE' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----********************************************************************************
----********************************************************************************
ELSIF (p_LASTSTNTYPE='CHILFLASH') THEN
    IF  p_STNTYPE='CHILFLASH' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'CHILFLASH' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----********************************************************************************
----********************************************************************************
ELSIF (p_LASTSTNTYPE='FUNCTIONAL_TEST') THEN
    IF  p_STNTYPE='FUNCTIONAL_TEST' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'FUNCTIONAL_TEST' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----********************************************************************************
----********************************************************************************
ELSIF (p_LASTSTNTYPE='NOISE') THEN
    IF  p_STNTYPE='NOISE' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'NOISE' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----********************************************************************************
--Added by Alex Wang on 2010/4/8 for 1NY8-100408-01 End
--Added by Alex Wang on 2010/3/30 for 1MF5-100330-01 Begin
----********************************************************************************
ELSIF (p_LASTSTNTYPE='BI') THEN
    IF p_STNTYPE='BI' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'BI' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----********************************************************************************
----********************************************************************************
ELSIF (p_LASTSTNTYPE='EFT') THEN
    IF p_STNTYPE='EFT' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'EFT' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----********************************************************************************
----********************************************************************************
ELSIF (p_LASTSTNTYPE='OTC') THEN
    IF p_STNTYPE='OTC' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'OTC' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----********************************************************************************
    --Added by Alex Wang on 2010/3/30 for 1MF5-100330-01 Begin
----********************************************************************************
ELSIF (p_LASTSTNTYPE='LCD') THEN
    IF p_STNTYPE='LCD' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'LCD' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----********************************************************************************
----********************************************************************************
ELSIF (p_LASTSTNTYPE='SLI') THEN
    IF p_STNTYPE='SLI' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'SLI' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----********************************************************************************
----********************************************************************************
ELSIF (p_LASTSTNTYPE='LCD8030') THEN
    IF p_STNTYPE='LCD8030' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'LCD8030' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----***************************************************************************************
----***************************************************************************************
ELSIF (p_LASTSTNTYPE='LCD7020') THEN
    IF p_STNTYPE='LCD7020' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'LCD7020' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----******************************************************************************************
----******************************************************************************************
ELSIF (p_LASTSTNTYPE='HDTV') THEN
    IF p_STNTYPE='HDTV' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'HDTV' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----*********************************************************************************************
----*********************************************************************************************
ELSIF (p_LASTSTNTYPE='HDCP') THEN
    IF p_STNTYPE='HDCP' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'HDCP' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----**********************************************************************************************
----**********************************************************************************************
ELSIF (p_LASTSTNTYPE='IDT') THEN
    IF p_STNTYPE='IDT' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'IDT' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----**********************************************************************************************
----**********************************************************************************************
ELSIF (p_LASTSTNTYPE='DUAL LINK') THEN
    IF p_STNTYPE='DUAL LINK' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'DUAL LINK' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----**********************************************************************************************
----**********************************************************************************************
ELSIF (p_LASTSTNTYPE='SINGLE LINK') THEN
    IF p_STNTYPE='SINGLE LINK' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'SINGLE LINK' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----**********************************************************************************************
----**********************************************************************************************
ELSIF (p_LASTSTNTYPE='40XGL') THEN
    IF p_STNTYPE='40XGL' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'40XGL' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----*********************************************************************************************
--Added by Kassi Bai on 2009/06/03 for PM5-090603-01 Begin
----**********************************************************************************************
ELSIF (p_LASTSTNTYPE='INFOROM') THEN
    IF p_STNTYPE='INFOROM' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'INFOROM' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----*********************************************************************************************
--Added by Kassi Bai on 2009/06/03 for PM5-090603-01 End
----*********************************************************************************************
--Added by Cunku Xing on 2009/09/08 for Y3L-090908-01 Begin
ELSIF (p_LASTSTNTYPE='INFOROM WRITE') THEN
    IF p_STNTYPE='INFOROM WRITE' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'INFOROM WRITE' THEN
        IF p_GROUP=p_NEXTGROUP THEN
            BEGIN
                RES:='OK';
                IF p_RESULT='P' THEN
                    UPDATE SFISM4.R_WIP_TRACKING_T
                    SET PASS_QTY=1,FAIL_QTY=0
                    WHERE SERIAL_NUMBER=p_SN;
                ELSIF p_RESULT='F' THEN
                    UPDATE SFISM4.R_WIP_TRACKING_T
                    SET PASS_QTY=0,FAIL_QTY=1
                    WHERE SERIAL_NUMBER=p_SN;
                END IF;

                COMMIT;
            END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----*********************************************************************************************
----*********************************************************************************************
ELSIF (p_LASTSTNTYPE='INFOROM CHECK') THEN
    IF p_STNTYPE='INFOROM CHECK' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'INFOROM CHECK' THEN
        IF p_GROUP=p_NEXTGROUP THEN
            BEGIN
                RES:='OK';
                IF p_RESULT='P' THEN
                    UPDATE SFISM4.R_WIP_TRACKING_T
                    SET PASS_QTY=1,FAIL_QTY=0
                    WHERE SERIAL_NUMBER=p_SN;
                ELSIF p_RESULT='F' THEN
                    UPDATE SFISM4.R_WIP_TRACKING_T
                    SET PASS_QTY=0,FAIL_QTY=1
                    WHERE SERIAL_NUMBER=p_SN;
                END IF;

                COMMIT;
            END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----*********************************************************************************************
--Added by Cunku Xing on 2009/09/08 for Y3L-090908-01 End
--Added by Alex Wang on 2011/01/24 for 36G9-110124-01 Begin
----********************************************************************************
ELSIF (p_LASTSTNTYPE='FM') THEN
    IF p_STNTYPE='FM' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'FM' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----********************************************************************************
----********************************************************************************
ELSIF (p_LASTSTNTYPE='GN') THEN
    IF p_STNTYPE='GN' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'GN' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----********************************************************************************
----********************************************************************************
ELSIF (p_LASTSTNTYPE='NC') THEN
    IF p_STNTYPE='NC' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'NC' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----********************************************************************************
--Added by Alex Wang on 2011/01/24 for 36G9-110124-01 End
--Added by Alex Wang on 2011/06/10 for 34NA8-110610-01 Begin
----********************************************************************************
ELSIF (p_LASTSTNTYPE='POWER_CAPPING') THEN
    IF p_STNTYPE='POWER_CAPPING' THEN
        RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
    ELSIF p_STNTYPE<>'POWER_CAPPING' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
        ELSE
            RAISE e_ROUTE_ERROR;
        END IF;
    END IF;
----********************************************************************************
--Added by Alex Wang on 2011/06/10 for 34NA8-110610-01 End
----*********************************************************************************************

-------------**********************************************---------------------------
  --- modefied by Derrick for 5X station  2012/04/05 begin
  -------------*********************************************---------------------------

--ELSIF (p_LASTSTNTYPE='5XOQA') THEN
--  IF p_STNTYPE='5XOQA' THEN
--     IF (p_FAILQTY=1) OR (p_PASSQTY=5 AND p_FAILQTY=0) THEN -- FAIED ONCE
--    RAISE e_ROUTE_ERROR;
--  END IF;
--  IF (p_PASSQTY<5 AND p_FAILQTY=0) THEN
--     BEGIN
--    RES:='OK';
--    IF p_RESULT='P' THEN
--    UPDATE SFISM4.R_WIP_TRACKING_T
--   SET PASS_QTY=PASS_QTY+1
--   WHERE SERIAL_NUMBER=p_SN;
--       ELSIF p_RESULT='F' THEN
--    UPDATE SFISM4.R_WIP_TRACKING_T
--   SET FAIL_QTY=FAIL_QTY+1
--   WHERE SERIAL_NUMBER=p_SN;
--       END IF;
--      COMMIT;
--    END;
--  END IF;
--  ELSIF p_STNTYPE<>'5XOQA' THEN
--   IF p_GROUP=p_NEXTGROUP THEN
--   BEGIN
--    RES:='OK';
--    IF p_RESULT='P' THEN
--    UPDATE SFISM4.R_WIP_TRACKING_T
--   SET PASS_QTY=1,FAIL_QTY=0
--   WHERE SERIAL_NUMBER=p_SN;
--    ELSIF p_RESULT='F' THEN
--    UPDATE SFISM4.R_WIP_TRACKING_T
--   SET PASS_QTY=0,FAIL_QTY=1
--   WHERE SERIAL_NUMBER=p_SN;
--    END IF;
--
--      COMMIT;
--   END;
-- ELSE
--    RAISE e_ROUTE_ERROR;
-- END IF;
--  END IF;
  ELSIF (substr (p_LASTSTNTYPE,1,2)='5X') THEN
  IF p_STNTYPE= p_LASTSTNTYPE THEN
     IF (p_FAILQTY=1) OR (p_PASSQTY=5 AND p_FAILQTY=0) THEN -- FAIED ONCE
    RAISE e_ROUTE_ERROR;
  END IF;
  IF (p_PASSQTY<5 AND p_FAILQTY=0) THEN
     BEGIN
    RES:='OK';
    IF p_RESULT='P' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET PASS_QTY=PASS_QTY+1
   WHERE SERIAL_NUMBER=p_SN;
       ELSIF p_RESULT='F' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET FAIL_QTY=FAIL_QTY+1
   WHERE SERIAL_NUMBER=p_SN;
       END IF;
      COMMIT;
    END;
  END IF;
  ELSIF p_STNTYPE<> p_LASTSTNTYPE THEN
   IF p_GROUP=p_NEXTGROUP THEN
   BEGIN
    RES:='OK';
    IF p_RESULT='P' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET PASS_QTY=1,FAIL_QTY=0
   WHERE SERIAL_NUMBER=p_SN;
    ELSIF p_RESULT='F' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET PASS_QTY=0,FAIL_QTY=1
   WHERE SERIAL_NUMBER=p_SN;
    END IF;

      COMMIT;
   END;
 ELSE
    RAISE e_ROUTE_ERROR;
 END IF;
  END IF;
  -------------****************---------------------------
 --- modefied by Derrick for 5X station  2012/04/05 end
 -------------****************---------------------------
 
 
----*********************************************************************************************
----*********************************************************************************************
ELSIF (p_LASTSTNTYPE='OQA') THEN
    IF  p_STNTYPE='OQA' THEN
       IF p_PASSQTY=0 THEN
           IF p_FAILQTY=1 THEN -- FAIED ONCE
           BEGIN
               RES:='OK';
               IF p_RESULT='P' THEN
                   UPDATE SFISM4.R_WIP_TRACKING_T
                   SET PASS_QTY=p_PASSQTY+1
                   WHERE SERIAL_NUMBER=p_SN;
               ELSIF p_RESULT='F' THEN
                   UPDATE SFISM4.R_WIP_TRACKING_T
                   SET FAIL_QTY=p_FAILQTY+1
                   WHERE SERIAL_NUMBER=p_SN;
               END IF;
               COMMIT;
               p_MYRETEST:='1';
           END;
           ELSE         -- FAILED MORE THAN ONCE, NEED TO BE REPAIRED
               RAISE e_ROUTE_ERROR;
           END IF;
        ELSIF p_PASSQTY=1 THEN
            IF p_FAILQTY=0 THEN
                RAISE e_ROUTE_ERROR;  -- PASS ALREADLY
            ELSIF p_FAILQTY=1 THEN   -- PASS ONCE, AND FAIL ONCE
            BEGIN
                RES:='OK';
                IF p_RESULT='P' THEN
                    UPDATE SFISM4.R_WIP_TRACKING_T
                    SET PASS_QTY=p_PASSQTY+1
                    WHERE SERIAL_NUMBER=p_SN;
                ELSIF p_RESULT='F' THEN
                    UPDATE SFISM4.R_WIP_TRACKING_T
                    SET FAIL_QTY=p_FAILQTY+1
                    WHERE SERIAL_NUMBER=p_SN;
                END IF;
                COMMIT;
                p_MYRETEST:='1';
            END;
        ELSIF p_FAILQTY=2 THEN      -- PASS ONCE, FAIL TWICE
            RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
            END IF;
        ELSIF p_PASSQTY=2 THEN
            RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
        END IF;
    ELSIF p_STNTYPE<>'OQA' THEN
        IF ( p_PASSQTY=0 AND p_FAILQTY=1) OR (p_PASSQTY=1 AND p_FAILQTY=1) THEN
            p_NEXTGROUP:='OQA RETEST';
            RAISE e_ROUTE_ERROR;
        ELSIF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
    ELSE
        RAISE e_ROUTE_ERROR;
    END IF;
END IF;
----***********************************************************************************************
----***********************************************************************************************
ELSIF (p_LASTSTNTYPE='COQA') THEN
  IF  p_STNTYPE='COQA' THEN
   IF p_PASSQTY=0 THEN
      IF p_FAILQTY=1 THEN -- FAIED ONCE
    BEGIN
   RES:='OK';
   IF p_RESULT='P' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET PASS_QTY=p_PASSQTY+1
   WHERE SERIAL_NUMBER=p_SN;
   ELSIF p_RESULT='F' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET FAIL_QTY=p_FAILQTY+1
   WHERE SERIAL_NUMBER=p_SN;
   END IF;
      COMMIT;
   p_MYRETEST:='1';
    END;
   ELSE         -- FAILED MORE THAN ONCE, NEED TO BE REPAIRED
     RAISE e_ROUTE_ERROR;
   END IF;
   ELSIF p_PASSQTY=1 THEN
        IF p_FAILQTY=0 THEN
     RAISE e_ROUTE_ERROR;  -- PASS ALREADLY
     ELSIF p_FAILQTY=1 THEN   -- PASS ONCE, AND FAIL ONCE
      BEGIN
     RES:='OK';
   IF p_RESULT='P' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET PASS_QTY=p_PASSQTY+1
   WHERE SERIAL_NUMBER=p_SN;
   ELSIF p_RESULT='F' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET FAIL_QTY=p_FAILQTY+1
   WHERE SERIAL_NUMBER=p_SN;
   END IF;
   COMMIT;
   p_MYRETEST:='1';
  END;
   ELSIF p_FAILQTY=2 THEN      -- PASS ONCE, FAIL TWICE
     RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
   END IF;
 ELSIF p_PASSQTY=2 THEN
    RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
   END IF;

  ELSIF p_STNTYPE<>'COQA' THEN
 IF ( p_PASSQTY=0 AND p_FAILQTY=1) OR (p_PASSQTY=1 AND p_FAILQTY=1) THEN
    p_NEXTGROUP:='COQA RETEST';
    RAISE e_ROUTE_ERROR;
   ELSIF p_GROUP=p_NEXTGROUP THEN
   BEGIN
    RES:='OK';
    IF p_RESULT='P' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET PASS_QTY=1,FAIL_QTY=0
   WHERE SERIAL_NUMBER=p_SN;
   ELSIF p_RESULT='F' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET PASS_QTY=0,FAIL_QTY=1
   WHERE SERIAL_NUMBER=p_SN;
   END IF;
      COMMIT;
   END;
 ELSE
    RAISE e_ROUTE_ERROR;
 END IF;
  END IF;
----***********************************************************************************************
----***********************************************************************************************
ELSIF (p_LASTSTNTYPE='OBA') THEN
  IF  p_STNTYPE='OBA' THEN

   IF p_PASSQTY=0 THEN
      IF p_FAILQTY=1 THEN -- FAIED ONCE
    BEGIN

   RES:='OK';
   IF p_RESULT='P' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET PASS_QTY=p_PASSQTY+1
   WHERE SERIAL_NUMBER=p_SN;
   ELSIF p_RESULT='F' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET FAIL_QTY=p_FAILQTY+1
   WHERE SERIAL_NUMBER=p_SN;
   END IF;
      COMMIT;
   p_MYRETEST:='1';
    END;
   ELSE         -- FAILED MORE THAN ONCE, NEED TO BE REPAIRED
     RAISE e_ROUTE_ERROR;
   END IF;
      ELSIF p_PASSQTY=1 THEN
        IF p_FAILQTY=0 THEN
     RAISE e_ROUTE_ERROR;  -- PASS ALREADLY
     ELSIF p_FAILQTY=1 THEN   -- PASS ONCE, AND FAIL ONCE
      BEGIN
     RES:='OK';
   IF p_RESULT='P' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET PASS_QTY=p_PASSQTY+1
   WHERE SERIAL_NUMBER=p_SN;
   ELSIF p_RESULT='F' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET FAIL_QTY=p_FAILQTY+1
   WHERE SERIAL_NUMBER=p_SN;
   END IF;
   COMMIT;
   p_MYRETEST:='1';
  END;
   ELSIF p_FAILQTY=2 THEN      -- PASS ONCE, FAIL TWICE
     RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
   END IF;
 ELSIF p_PASSQTY=2 THEN
    RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
   END IF;

ELSIF p_STNTYPE<>'OBA' THEN
 IF ( p_PASSQTY=0 AND p_FAILQTY=1) OR (p_PASSQTY=1 AND p_FAILQTY=1) THEN
    p_NEXTGROUP:='OBA RETEST';
    RAISE e_ROUTE_ERROR;
   ELSIF p_GROUP=p_NEXTGROUP THEN
   BEGIN
    RES:='OK';
    IF p_RESULT='P' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET PASS_QTY=1,FAIL_QTY=0
   WHERE SERIAL_NUMBER=p_SN;
   ELSIF p_RESULT='F' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET PASS_QTY=0,FAIL_QTY=1
   WHERE SERIAL_NUMBER=p_SN;
   END IF;
      COMMIT;
   END;
 ELSE
    RAISE e_ROUTE_ERROR;
 END IF;
  END IF;
----***********************************************************************************************
----***********************************************************************************************
--Add by Eric Guo for TTE-20090113-01 Begin
ELSIF (p_LASTSTNTYPE='OBAT') THEN
  IF  p_STNTYPE='OBAT' THEN

   IF p_PASSQTY=0 THEN
      IF p_FAILQTY=1 THEN -- FAIED ONCE
    BEGIN

   RES:='OK';
   IF p_RESULT='P' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET PASS_QTY=p_PASSQTY+1
   WHERE SERIAL_NUMBER=p_SN;
   ELSIF p_RESULT='F' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET FAIL_QTY=p_FAILQTY+1
   WHERE SERIAL_NUMBER=p_SN;
   END IF;
      COMMIT;
   p_MYRETEST:='1';
    END;
   ELSE         -- FAILED MORE THAN ONCE, NEED TO BE REPAIRED
     RAISE e_ROUTE_ERROR;
   END IF;
      ELSIF p_PASSQTY=1 THEN
        IF p_FAILQTY=0 THEN
     RAISE e_ROUTE_ERROR;  -- PASS ALREADLY
     ELSIF p_FAILQTY=1 THEN   -- PASS ONCE, AND FAIL ONCE
      BEGIN
     RES:='OK';
   IF p_RESULT='P' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET PASS_QTY=p_PASSQTY+1
   WHERE SERIAL_NUMBER=p_SN;
   ELSIF p_RESULT='F' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET FAIL_QTY=p_FAILQTY+1
   WHERE SERIAL_NUMBER=p_SN;
   END IF;
   COMMIT;
   p_MYRETEST:='1';
  END;
   ELSIF p_FAILQTY=2 THEN      -- PASS ONCE, FAIL TWICE
     RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
   END IF;
 ELSIF p_PASSQTY=2 THEN
    RAISE e_ROUTE_ERROR;      -- NEEDED TO BE REPAIRED
   END IF;

ELSIF p_STNTYPE<>'OBAT' THEN
 IF ( p_PASSQTY=0 AND p_FAILQTY=1) OR (p_PASSQTY=1 AND p_FAILQTY=1) THEN
    p_NEXTGROUP:='OBAT RETEST';
    RAISE e_ROUTE_ERROR;
   ELSIF p_GROUP=p_NEXTGROUP THEN
   BEGIN
    RES:='OK';
    IF p_RESULT='P' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET PASS_QTY=1,FAIL_QTY=0
   WHERE SERIAL_NUMBER=p_SN;
   ELSIF p_RESULT='F' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET PASS_QTY=0,FAIL_QTY=1
   WHERE SERIAL_NUMBER=p_SN;
   END IF;
      COMMIT;
   END;
 ELSE
    RAISE e_ROUTE_ERROR;
 END IF;
  END IF;
--Add by Eric Guo for TTE-20090113-01 End
----***********************************************************************************************
----***********************************************************************************************
--Modified by Alex Wang on 2010/05/13 for 1V4A-100513-01 Begin
ELSIF (p_LASTSTNTYPE='OSOI')  THEN
    IF  p_STNTYPE='OSOI' THEN
        RAISE e_ROUTE_ERROR;
    ELSIF p_STNTYPE<>'OSOI' THEN
        IF p_GROUP=p_NEXTGROUP THEN
        BEGIN
            RES:='OK';
            IF p_RESULT='P' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=1,FAIL_QTY=0
                WHERE SERIAL_NUMBER=p_SN;
            ELSIF p_RESULT='F' THEN
                UPDATE SFISM4.R_WIP_TRACKING_T
                SET PASS_QTY=0,FAIL_QTY=1
                WHERE SERIAL_NUMBER=p_SN;
            END IF;
            COMMIT;
        END;
    ELSE
        RAISE e_ROUTE_ERROR;
    END IF;
END IF;
--Modified by Alex Wang on 2010/05/13 for 1V4A-100513-01 End
----***********************************************************************************************
----***********************************************************************************************
ELSIF (p_LASTSTNTYPE='ICT') THEN      -- PROCESS THE ICT GROUP, IT'S DIFFERENT FROM FBT
  IF p_STNTYPE='ICT' THEN
   IF (p_PASSQTY=0 AND p_FAILQTY=1) THEN
     BEGIN
       RES:='OK';
       IF p_RESULT='P' THEN
        UPDATE SFISM4.R_WIP_TRACKING_T
        SET PASS_QTY=p_PASSQTY+1
     WHERE SERIAL_NUMBER=p_SN;

     ELSIF p_RESULT='F' THEN
        UPDATE SFISM4.R_WIP_TRACKING_T
        SET FAIL_QTY=p_FAILQTY+1
     WHERE SERIAL_NUMBER=p_SN;
     END IF;
     COMMIT;
    p_MYRETEST:='1';
   END;
  ELSE
   RAISE e_ROUTE_ERROR;
  END IF;

 ELSE
  IF (p_PASSQTY=0 AND p_FAILQTY=1) THEN
     BEGIN
       p_NEXTGROUP:='ICT RETEST';
    RAISE e_ROUTE_ERROR;
     END;
  ELSE
   IF (p_GROUP=p_NEXTGROUP) THEN
      BEGIN
       RES:='OK';
    IF p_RESULT='P' THEN
        UPDATE SFISM4.R_WIP_TRACKING_T
       SET PASS_QTY=1,FAIL_QTY=0
       WHERE SERIAL_NUMBER=p_SN;

     ELSIF p_RESULT='F' THEN
           UPDATE SFISM4.R_WIP_TRACKING_T
       SET PASS_QTY=0,FAIL_QTY=1
       WHERE SERIAL_NUMBER=p_SN;
     END IF;
     COMMIT;

    END;
   ELSE
      RAISE e_ROUTE_ERROR;
   END IF;
  END IF;

 END IF;

ELSE
   IF p_NEXTGROUP<> p_GROUP THEN
        RAISE e_ROUTE_ERROR;
   ELSE
    BEGIN
     RES:='OK';
   IF p_RESULT='P' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET PASS_QTY=1,FAIL_QTY=0
   WHERE SERIAL_NUMBER=p_SN;
   ELSIF p_RESULT='F' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T
   SET PASS_QTY=0,FAIL_QTY=1
   WHERE SERIAL_NUMBER=p_SN;
   END IF;
   COMMIT;
    END;

   END IF;
END IF;
--Modified by Steven Hu for TTE-080318-01 Begin
/*ELSE---IF THE ROUTE TYPE IS NOT SPECIAL

 SFIS1.CHECK_ROUTE(p_LINE, p_GROUP,p_SN,p_CALLRES);
 IF p_CALLRES<>'OK' THEN
       RAISE e_ROUTE_ERROR;
 ELSE
    BEGIN
      RES:=p_CALLRES;
   IF p_RESULT='P' THEN
       UPDATE SFISM4.R_WIP_TRACKING_T
      SET PASS_QTY=1,FAIL_QTY=0
      WHERE SERIAL_NUMBER=p_SN;

    ELSIF p_RESULT='F' THEN
       UPDATE SFISM4.R_WIP_TRACKING_T
      SET PASS_QTY=0,FAIL_QTY=1
      WHERE SERIAL_NUMBER=p_SN;
    END IF;

    COMMIT;
    END;
 END IF;
END IF;*/
--Modified by Steven Hu for TTE-080318-01 End


--Modified by Alex Wang on 2010/7/5 for 22H1-100705-01 Begin
INSERT INTO SFISM4.R_TEST_TEMP_T(SERIAL_NUMBER,STATION_ID,TEST_DATE,TEST_TIME,RESULT,ERROR_CODE,
    MODEL_NAME,STATION_TYPE,WORK_STATION,OPERATOR,RETEST,FAILDESC,MO_NUMBER,MARKET_NAME,MEM_VENDOR_ID,MEM_PART_ID,MEM_DC,BASIC_TESTTIME_BEGIN,BASIC_TESTTIME_END)
VALUES (p_SN,1000,p_WORKDATE,p_WORKTIME,p_RESULT,p_ERROR_CODE,
    p_MODEL,p_STNTYPE,p_WORK_STATION,p_OPERATORID,p_MYRETEST,p_FAILDESC,p_MO,p_MARKETNAME,p_MEM_VENDOR,p_MEM_PART,p_MEM_DATECODE,p_BASIC_TESTTIME_BEGIN,p_BASIC_TESTTIME_END);
COMMIT;
--Modified by Alex Wang on 2010/7/5 for 22H1-100705-01 End
--Added by Alex Wang on 2010/05/24 for 1TFE-100524-01 Begin
SFISM4.DA_LINK(p_OPERATORID,p_SN,p_STNTYPE,v_DARES);
IF v_DARES<>'OK' THEN
   RES:= 'DA_LINK ERROR:' || v_DARES;
   RAISE e_NULL;
END IF;
--Added by Alex Wang on 2010/05/24 for 1TFE-100524-01 End
--Added by Alex Wang on 2010/5/28 for 1U13-100528-01 Begin

---------*************modefy by Derrick Chow*********------------
/*IF p_DIAG <> 'N/A' THEN
    -- add by Derrick  on 2011/08/30 begin----
     SFIS1.CHECK_DIAGS_VERSION_T ( p_SN,p_DIAG,p_BIOS,p_GROUP, v_DIAGCHECKRES);
     
      IF v_DIAGCHECKRES<>'OK' THEN
        RES:= 'DIAG CHECK ERROR:' ||v_DIAGCHECKRES;
        RAISE e_NULL;
    END IF;
    ----add by Derrick on 2011/08/30 end ------
    

    SFISM4.DATALINK(p_OPERATORID,p_SN,p_DIAG,p_GROUP,'DIAG',v_DIAGRES);
    IF v_DIAGRES<>'OK' THEN
        RES:= 'DIAG DATA_LINK ERROR:' || v_DIAGRES;
        RAISE e_NULL;
    END IF;
END IF;
*/
SFIS1.check_diagsbygroup(p_SN,p_DIAG,p_BIOS,p_GROUP,p_OPERATORID, v_DIAGCHECKRES);
iF v_DIAGCHECKRES<>'OK' THEN
    RES:= 'diags error:' ||v_DIAGCHECKRES;
        RAISE e_NULL;
    END IF;
---------*************modefy by Derrick Chow*********------------

--Added by Alex Wang on 2010/5/28 for 1U13-100528-01 End
--Added by Alex Wang on 2011/2/15 for 38CP-110215-01 Begin
IF p_ECID <> 'N/A' THEN
    SFISM4.DATALINK(p_OPERATORID,p_SN,p_ECID,'N/A','ECID',v_ECIDRES);
    IF v_ECIDRES<>'OK' THEN
        RES:= 'ECID DATA_LINK ERROR:' || v_ECIDRES;
        RAISE e_NULL;
    END IF;
END IF;
--Added by Alex Wang on 2011/2/15 for 38CP-110215-01 End


SELECT PASS_QTY,FAIL_QTY INTO p_PASSQTY,p_FAILQTY
FROM SFISM4.R_WIP_TRACKING_T WHERE SERIAL_NUMBER=P_SN;

IF p_RESULT='P' THEN
  --IF (p_STNTYPE<>'5XOQA') THEN
   IF (SUBSTR(p_STNTYPE,1,2)<>'5X') THEN-------MODEFIED BY Derrick chow 2012/04/05
   IF (p_PASSQTY=1 AND p_FAILQTY=0) OR (p_PASSQTY=2 AND p_FAILQTY=1) THEN

     BEGIN
       SFIS1.STN_REC_Z(p_LINE,p_SECTION,p_GROUP,p_STATION,p_MO,p_SN,p_WORKDATE,p_WORKSECT,'0');
    SFIS1.UPDATE_R107(p_OPERATORID,p_LINE,p_SECTION,p_GROUP,p_STATION,p_MO,p_SN,'0',p_DATE);
    SFIS1.UPDATE_RLSA_H(p_SN,p_LINE,p_TEMP_GROUP,p_MO,p_TEMP_EC,RES);
       RES := 'OK';
     END;
 ELSIF (p_PASSQTY=1 AND p_FAILQTY=1) THEN
    IF p_STNTYPE='ICT' THEN
      BEGIN
       SFIS1.STN_REC_Z(p_LINE,p_SECTION,p_GROUP,p_STATION,p_MO,p_SN,p_WORKDATE,p_WORKSECT,'0');
       SFIS1.UPDATE_R107(p_OPERATORID,p_LINE,p_SECTION,p_GROUP,p_STATION,p_MO,p_SN,'0',p_DATE);
       SFIS1.UPDATE_RLSA_H(p_SN,p_LINE,p_TEMP_GROUP,p_MO,p_TEMP_EC,RES);
          RES := 'OK';
    END;
    END IF;

 END IF;
 ELSE
   IF (p_PASSQTY=5 AND p_FAILQTY=0) THEN
      SFIS1.STN_REC_Z(p_LINE,p_SECTION,p_GROUP,p_STATION,p_MO,p_SN,p_WORKDATE,p_WORKSECT,'0');
         SFIS1.UPDATE_R107(p_OPERATORID,p_LINE,p_SECTION,p_GROUP,p_STATION,p_MO,p_SN,'0',p_DATE);
         SFIS1.UPDATE_RLSA_H(p_SN,p_LINE,p_TEMP_GROUP,p_MO,p_TEMP_EC,RES);
      RES := 'OK';
   ELSIF (p_PASSQTY<5 AND p_FAILQTY=0) THEN
         UPDATE SFISM4.R_WIP_TRACKING_T
      SET LINE_NAME=p_LINE,SECTION_NAME=p_SECTION,GROUP_NAME=p_GROUP,
          STATION_NAME=p_STATION,IN_STATION_TIME = p_DATE,
          NEXT_STATION='N/A', ERROR_FLAG ='0',EMP_NO=p_OPERATORID
      WHERE SERIAL_NUMBER = p_SN;

         DELETE FROM SFISM4.R_SN_DETAIL_T
      WHERE IN_STATION_TIME=p_DATE  AND SERIAL_NUMBER=p_SN;
         COMMIT;
         RES:='OK';
   END IF;
 END IF;

ELSIF p_RESULT='F' THEN
   BEGIN
     --IF (p_STNTYPE<>'5XOQA') THEN
     IF (SUBSTR(p_STNTYPE,1,2)<>'5X') THEN-------MODEFIED BY Derrick chow 2012/04/05
     
  IF (p_FAILQTY=2 AND p_PASSQTY=1) OR (p_FAILQTY=2 AND p_PASSQTY=0) THEN
         SFIS1.STN_REC_Z(p_LINE,p_SECTION,p_GROUP,p_STATION,p_MO,p_SN,p_WORKDATE,p_WORKSECT,'1');
            SFIS1.UPDATE_R107(p_OPERATORID,p_LINE,p_SECTION,p_GROUP,p_STATION,p_MO,p_SN,'1',p_DATE);
         INSERT INTO SFISM4.R_REPAIR_T(SERIAL_NUMBER,MO_NUMBER,TEST_TIME,
               TEST_CODE,TEST_STATION,TEST_LINE,RECORD_TYPE,MODEL_NAME)
         VALUES(p_SN,p_MO,p_DATE,p_ERROR_CODE,p_STATION,p_LINE,'T',p_MODEL);
   COMMIT;
      SFIS1.UPDATE_RLSA_H(p_SN,p_LINE,p_TEMP_GROUP,p_MO,p_TEMP_EC,RES);
  ELSIF (p_FAILQTY=1 AND p_PASSQTY=0) THEN
--Modified by Alex Wang on 2010/03/22 for 1MG4-100324-01 Begin
   IF (p_STNTYPE='ICT' OR p_STNTYPE='OQA' OR p_STNTYPE='COQA' OR p_STNTYPE='OBA' OR p_STNTYPE='OBAT') THEN
--Modified by Alex Wang on 2010/03/22 for 1MG4-100324-01 End
---     ************ -Modified by  Derrick Chow 2012/05/10 begin for 0000005PFSFS******************* ------------
          UPDATE SFISM4.R_WIP_TRACKING_T
           SET LINE_NAME=p_LINE,SECTION_NAME=p_SECTION,GROUP_NAME=p_GROUP,
                  STATION_NAME=p_STATION,IN_STATION_TIME = p_DATE,
              -- NEXT_STATION='N/A',
               NEXT_STATION=p_STNTYPE,
               EMP_NO=p_OPERATORID
           WHERE MO_NUMBER=p_MO AND  SERIAL_NUMBER = p_SN;
       COMMIT;
       DELETE FROM SFISM4.R_SN_DETAIL_T
           WHERE IN_STATION_TIME=p_DATE  AND SERIAL_NUMBER=p_SN  ;
--       COMMIT;
---     ************ -Modified by  Derrick Chow 2012/05/10 end for 0000005PFSFS******************* ------------

       -- ADD BY derrick for0 000005QBK 2012/01/06---------
       INSERT INTO SFISM4.H_REPAIR_T(SERIAL_NUMBER,MO_NUMBER,TEST_TIME,
                    TEST_CODE,TEST_STATION,TEST_LINE,RECORD_TYPE,MODEL_NAME)
             VALUES(p_SN,p_MO,p_DATE,p_ERROR_CODE,p_STATION,p_LINE,'T',p_MODEL);
             SFIS1.UPDATE_RLSA_H(p_SN,p_LINE,p_TEMP_GROUP,p_MO,p_TEMP_EC,RES);
             COMMIT;
       -- ADD BY derrick for0 000005QBK 2012/01/06---------
   ELSE
          SFIS1.STN_REC_Z(p_LINE,p_SECTION,p_GROUP,p_STATION,p_MO,p_SN,p_WORKDATE,p_WORKSECT,'1');
    SFIS1.UPDATE_R107(p_OPERATORID,p_LINE,p_SECTION,p_GROUP,p_STATION,p_MO,p_SN,'1',p_DATE);
          INSERT INTO SFISM4.R_REPAIR_T(SERIAL_NUMBER,MO_NUMBER,TEST_TIME,
                    TEST_CODE,TEST_STATION,TEST_LINE,RECORD_TYPE,MODEL_NAME)
             VALUES(p_SN,p_MO,p_DATE,p_ERROR_CODE,p_STATION,p_LINE,'T',p_MODEL);
             SFIS1.UPDATE_RLSA_H(p_SN,p_LINE,p_TEMP_GROUP,p_MO,p_TEMP_EC,RES);
   END IF;

   COMMIT;

  END IF;
  RES:='OK';
  ELSE
    IF (p_FAILQTY=1) THEN
       SFIS1.STN_REC_Z(p_LINE,p_SECTION,p_GROUP,p_STATION,p_MO,p_SN,p_WORKDATE,p_WORKSECT,'1');
    SFIS1.UPDATE_R107(p_OPERATORID,p_LINE,p_SECTION,p_GROUP,p_STATION,p_MO,p_SN,'1',p_DATE);
          INSERT INTO SFISM4.R_REPAIR_T(SERIAL_NUMBER,MO_NUMBER,TEST_TIME,
                    TEST_CODE,TEST_STATION,TEST_LINE,RECORD_TYPE,MODEL_NAME)
          VALUES(p_SN,p_MO,p_DATE,p_ERROR_CODE,p_STATION,p_LINE,'T',p_MODEL);
             SFIS1.UPDATE_RLSA_H(p_SN,p_LINE,p_TEMP_GROUP,p_MO,p_TEMP_EC,RES);
    COMMIT;
  END IF;
  RES:='OK';
  END IF;
   END;
END IF;

IF RES='OK' THEN
 -- IF (p_STNTYPE<>'5XOQA') THEN
  IF (SUBSTR(p_STNTYPE,1,2)<>'5X') THEN-------MODEFIED BY Derrick chow 2012/04/05
   IF (p_PASSQTY=1 AND p_FAILQTY=0) THEN
      RES:='0';
   ELSIF p_PASSQTY=1 AND p_FAILQTY=1 THEN
      IF p_STNTYPE='ICT' THEN
     RES:='0';
--Modified by Alex Wang on 2010/03/22 for 1MG4-100324-01 Begin

   ELSIF p_STNTYPE='OQA' OR p_STNTYPE='COQA' OR p_STNTYPE='OBA' OR p_STNTYPE='OBAT' THEN

--Modified by Alex Wang on 2010/03/22 for 1MG4-100324-01 End
      RES:='2';
   ELSE
     RES:='0';
   END IF;

   ELSIF p_PASSQTY=1 AND p_FAILQTY=2 THEN
      RES:='1';             -- IT SHOULD BE FBT FAIL,NOT ICT, ICT NEEDS 2 TIMES TEST  AT MOST
   ELSIF p_PASSQTY=2 AND p_FAILQTY=1 THEN
      RES:='0';             -- SHOULD PASS WHEN PASS 2 TIMES TEST
   ELSIF p_PASSQTY=0 AND p_FAILQTY=1 THEN
      --Modified by Alex Wang on 2010/03/22 for 1MG4-100324-01 Begin
      IF (p_STNTYPE='ICT' OR p_STNTYPE='OQA' OR p_STNTYPE='COQA' OR p_STNTYPE='OBA' OR p_STNTYPE='OBAT') THEN
      --Modified by Alex Wang on 2010/03/22 for 1MG4-100324-01 End
         RES:='2';
   ELSE
    RES:='1';
   END IF;
   ELSIF p_PASSQTY=0 AND p_FAILQTY=2 THEN
      RES:='1';
   END IF;
  ELSE
   IF (p_PASSQTY=5 AND p_FAILQTY=0) THEN
      RES:='0';
   END IF;
   IF (p_PASSQTY<5 AND p_FAILQTY=0) THEN
      RES:='2';
   END IF;
   IF (p_FAILQTY=1) THEN
      RES:='1';
   END IF;
  END IF;
END IF;
EXCEPTION
    WHEN e_NULL THEN NULL;
    WHEN e_MODELNAME_ERROR THEN
        BEGIN
        RES:='WRONG MODEL_NAME  PM:' || p_MODEL || '  OM:' || v_MODEL_NAME;
      END;
       WHEN e_NO_FLASHROM THEN
        BEGIN
        RES:='BIOS NOT FLASH';
      END;
    WHEN e_BIOS_MODELNAME THEN
        BEGIN
        RES:='BIOS NOT MATCH MODEL_NAME';
      END;
    WHEN e_CHECKSUM_ERROR THEN
         BEGIN
           RES:='CHECKSUM ERROR';
      END;
    WHEN e_NO_SN THEN
        BEGIN
          RES:='NO SN';
      END;
   --TTE-070813-01--
    WHEN e_NO_FIX THEN
        BEGIN
          RES:='NO FIXTURE';
      END;

    WHEN e_FIX_ERROR THEN
        BEGIN
        RES := v_FIXRES;
      END;
   --TTE-070813-01--

    WHEN e_ACCESS_DENIED THEN
        RES:=p_CALLRES;

    WHEN e_NO_STATION THEN
        BEGIN
        RES:='NO STATION';
      END;
    WHEN e_ROUTE_ERROR THEN
    BEGIN
        IF p_NEXTGROUP='RETEST' THEN
            RES:='2';
         ELSIF SUBSTR(p_NEXTGROUP,1,2)='R_' THEN
            RES:='GOTO-' || p_NEXTGROUP;
        ELSE
        BEGIN
            IF SUBSTR(p_NEXTGROUP,1,4)<>'GOTO' THEN
                p_NEXTGROUP:='GOTO-' || p_NEXTGROUP;
            END IF;

            RES:= p_NEXTGROUP;
        END;
        END IF;
    END;
    WHEN e_NO_EC THEN
        RES:=p_CALLRES;

    WHEN NO_DATA_FOUND THEN
      IF p_NEXTGROUP IS NULL THEN
         RES:='ROUTE ERROR';
      ELSIF p_ROUTETYPE IS NULL THEN
         RES:='NO ROUTE';
      ELSE
         RES:='INPUT ERROR';
      END IF;

    WHEN OTHERS THEN
        RES:=SUBSTR(SQLERRM,1,100);

END;
/* ******************************************************
Revision: 1.4.9
last update date: Jul 13, 2005
reason: Update The BIOS Check Function ,some Flashrom will upload  error model_name
   Now if the model_name uploaded by TEST is different from the model_name in WIP  ,we return Error !!!
by: Anthony Zhang

Revision: 1.4.8
last update date: Dec 1,2004
reason: Add SLI station processing
by: Anthony Zhang

Revision: 1.4.7
last update date: Jul 31,2003
reason: Add OBA station processing
by: Canzhou Huang

Revision: 1.4.6
Last Update Date: Jul 24,2003
reason: Add Alarm function to Nvidia Product
Update by: Canzhou Huang

Revision:1.4.5
Last Update Date: Jul 19,2003
reason: for Nvidia special route CRT,LCD8030,LCD7020
Update by:Huang Canzhou

Revision:1.4.3
CREATED BY: SUN FANRONG
CREATE DATE: SEPT 19,2002
UPDATE DATE: SEPT 27,2002
LAST UPDATE DATE: OCT 24,2002
LAST UPDATE DATE: OCT 29,2002
LAST UPDATE DATE: NOV 14,2002

FOR: TEST MACHINE DATA AUTO TRANSFER

RES:
0- OK
1- REPAIR
2- RETEST
3- BIOS DOES NOT MATCH THE MODEL_NAME
******************************************************** */