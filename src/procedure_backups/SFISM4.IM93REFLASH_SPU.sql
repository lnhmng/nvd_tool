PROCEDURE               iM93REFLASH_SPU
(
 BARCODE      IN VARCHAR2,
 MACHINE_CODE IN VARCHAR2,
 EMP          IN VARCHAR2,
 MAC          IN VARCHAR2,
 TESTDATE      IN VARCHAR2,
 TESTTIME      IN VARCHAR2,
 BIOS_VER     IN VARCHAR2,
 CODE1394      IN VARCHAR2,
 RESERVE2      IN VARCHAR2,
 RESULT          IN VARCHAR2,
 ERROR_CODE      IN VARCHAR2,
 END_FLAG      IN VARCHAR2,
  o_flag         OUT      VARCHAR2,
 RES           OUT VARCHAR2) IS


p_STATION      VARCHAR2(20);
p_LINE          VARCHAR2(20);
p_SECTION      VARCHAR2(20);
p_GROUP          VARCHAR2(20);
TEMP_EC       VARCHAR2(10);

p_RESULT      VARCHAR2(1);
p_MODATE      VARCHAR2(8);
p_WSECTION    VARCHAR2(2);

p_MAC_FLAG      VARCHAR2(5);
p_ICSN_FLAG   VARCHAR2(5);
P_ERRORFLAG   VARCHAR2(1);

STNCNT          NUMBER(2,0);

H1RES           VARCHAR2(20);
SNRES          VARCHAR2(20);
EMPRES          VARCHAR2(20);
LENGTHRES      VARCHAR2(50);
ICSNRES       VARCHAR2(50);
FBTRES        VARCHAR2(30);
HRES          VARCHAR2(50);
ECRES         VARCHAR2(20);
BIOSRES       VARCHAR2(50);
REFLASHRES    VARCHAR2(50);
INPUTRES      VARCHAR2(50);


v_0CNT          NUMBER(2,0);
v_FCNT          NUMBER(2,0);
v_RES          VARCHAR2(50);
v_RES1        VARCHAR2(50);
MAC1          VARCHAR2(20);
MAC2          VARCHAR2(20);
ICSN1         VARCHAR2(50);
ICSN2         VARCHAR2(50);

v_MACHINE_ID  VARCHAR2(20);


e_File_ERROR              EXCEPTION;
e_LENGTH_ERROR              EXCEPTION;
e_ICSN_ERROR              EXCEPTION;
e_BIOS_ERROR              EXCEPTION;
e_NO_SN                   EXCEPTION;
e_H1_ERROR                  EXCEPTION;
e_EMP_ERROR                  EXCEPTION;
e_STN_DUP                  EXCEPTION;
e_NO_STN                  EXCEPTION;

BEGIN
   o_flag := '-1';
    IF END_FLAG<>'DONE' THEN
       RAISE e_File_ERROR;
    END IF;

    IF (LENGTH(MAC) <> 12 AND LENGTH(MAC)<>25) THEN
       LENGTHRES := 'THE LENGTH OF MACADDRESS IS WRONG';
       RAISE e_LENGTH_ERROR;
    END IF;

    p_MAC_FLAG := '0';
    p_ICSN_FLAG := '0';
    P_RESULT := RESULT;
    TEMP_EC := ERROR_CODE;

    SFIS1.CHECK_SN( TRIM(BARCODE), SNRES );
    IF SNRES <> 'OK' THEN
      RAISE e_NO_SN;
    END IF;


    v_MACHINE_ID := SUBSTR( TRIM(MACHINE_CODE), -4, 4 );
    SELECT COUNT(*)
    INTO STNCNT
    FROM SFIS1.C_ICT_STATION_T
    WHERE STATION_CODE = v_MACHINE_ID;

    IF STNCNT = 0 THEN
      RAISE e_NO_STN;
    END IF;

    IF STNCNT > 1 THEN
      RAISE e_STN_DUP;
    END IF;



    --******************CHECK_FBT*************************--
      SFISM4.iCHECK_MAC_1394_V1( TRIM(BARCODE), v_MACHINE_ID, EMP, TRIM(MAC),
                           TESTDATE, TESTTIME, CODE1394, '','',RESULT, ERROR_CODE, END_FLAG, INPUTRES);
      RES:=INPUTRES;
    --******************END CHECK_FBT*********************--


    --********************CHECK_BIOS**********************--
      SFISM4.FBT_BIOS_V1( TRIM(BARCODE), v_MACHINE_ID, TRIM(BIOS_VER), BIOSRES);
      IF (BIOSRES<>'OK') THEN
         RAISE e_BIOS_ERROR;
      END IF;
    --********************END CHECK_BIOS******************--

    --********************CHECK_LINE**********************--
    SFIS1.Check_Lsa_H(EMP,p_LINE,p_GROUP,HRES);
    IF HRES<>'OK' THEN
       RES := HRES||'\nDONE';
    END IF;
    --********************END CHECK_LINE******************--
   o_flag := '0';

EXCEPTION
    WHEN e_STN_DUP THEN
          RES:='Station DUPLICATED'||'\nDONE';
    WHEN e_NO_STN THEN
          RES:='NO Station'||'\nDONE';
    WHEN e_File_ERROR THEN
          RES:='WRONG FILE FORMAT!'||'\nDONE';
    WHEN e_LENGTH_ERROR THEN
          RES:=LENGTHRES||'\nDONE';
    WHEN e_NO_SN THEN
      RES := SNRES||'\nDONE';
    WHEN e_ICSN_ERROR THEN
      RES := ICSNRES||'\nDONE';
    WHEN e_EMP_ERROR THEN
          RES:=EMPRES||'\nDONE';
    WHEN e_BIOS_ERROR THEN
          RES := BIOSRES||'\nDONE';

    WHEN OTHERS THEN
      RES:='SFC OTHER ERROR'||'\nDONE';
END;