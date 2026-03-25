PROCEDURE               iM93FBT01_SPU
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

p_FLAG          VARCHAR2(5);
P_ERRORFLAG   VARCHAR2(1);

STNCNT          NUMBER(2,0);

H1RES           VARCHAR2(20);
SNRES          VARCHAR2(20);
EMPRES          VARCHAR2(20);
MACRES          VARCHAR2(50);
LENGTHRES     VARCHAR2(50);
ICSNRES       VARCHAR2(50);
FBTRES        VARCHAR2(30);
HRES          VARCHAR2(50);
ECRES         VARCHAR2(20);
BIOSRES       VARCHAR2(50);
ROUTE_RES     VARCHAR2(50);

v_MACHINE_ID  VARCHAR2(20);


e_File_ERROR    EXCEPTION;
e_MAC_ERROR        EXCEPTION;
e_LENGTH_ERROR  EXCEPTION;
e_ICSN_ERROR    EXCEPTION;
e_BIOS_ERROR    EXCEPTION;
e_NO_SN         EXCEPTION;
e_H1_ERROR        EXCEPTION;
e_EMP_ERROR        EXCEPTION;
e_STN_DUP        EXCEPTION;
e_NO_STN        EXCEPTION;
e_EC_ERROR      EXCEPTION;
e_ROUTE_ERROR   EXCEPTION;
BEGIN
   o_flag := '-1';
    IF END_FLAG<>'DONE' THEN
       RAISE e_File_ERROR;
    END IF;


    IF (LENGTH(MAC) <> 12 AND LENGTH(MAC) <> 25) THEN
       LENGTHRES := 'THE LENGTH OF MACADDRESS IS WRONG';
       RAISE e_LENGTH_ERROR;
    END IF;

    P_FLAG := '0';
    P_RESULT := RESULT;
    TEMP_EC := ERROR_CODE;

    SFIS1.CHECK_SN( TRIM(BARCODE), SNRES );
    IF SNRES <> 'OK' THEN
      RAISE e_NO_SN;
    END IF;

    --********************CHECK_STATION*******************--
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
    --********************END CHECK_STATION***************--



    --********************CHECK_LINE**********************--
         SELECT STATION_NAME,LINE_NAME,SECTION_NAME,GROUP_NAME
      INTO p_STATION,p_LINE,p_SECTION,p_GROUP
      FROM SFIS1.C_ICT_STATION_T
      WHERE STATION_CODE = v_MACHINE_ID;

         SFIS1.Check_Lsa_H1(EMP,p_LINE,p_GROUP,H1RES);
         IF H1RES<>'OK' THEN
           RAISE e_H1_ERROR;
         END IF;
    --********************END CHECK_LINE******************--



    --********************CHECK_EMP***********************--
      SFIS1.CHECK_EMP_V3(EMP,p_GROUP,EMPRES);
      IF EMPRES<>'OK' THEN
        RAISE e_EMP_ERROR;
      END IF;
    --********************END CHECK_EMP*******************--



    --********************CHECK_MAC***********************--
      SFISM4.FBT_MAC_V1( v_MACHINE_ID, TRIM(MAC), TRIM(BARCODE),
                               TESTDATE, TESTTIME, RESULT, TRIM(EMP), RESERVE2, MACRES );
      IF MACRES <> 'OK' THEN
        RAISE e_MAC_ERROR;
      END IF;
    --********************END CHECK_MAC*******************--



    --********************CHECK_1394**********************--
      IF ( LENGTH(TRIM(CODE1394)) > 1 ) AND ( TRIM(CODE1394)<>'0' ) AND ( TRIM(CODE1394) IS NOT NULL )THEN
        SFISM4.FBT_1394_V1( v_MACHINE_ID, TRIM(CODE1394), TRIM(BARCODE),
                                TESTDATE, TESTTIME, RESULT, TRIM(EMP), RESERVE2, ICSNRES );
        IF ICSNRES <> 'OK' THEN
          RAISE e_ICSN_ERROR;
        END IF;
      END IF;
    --********************END CHECK_1394******************--



    --********************CHECK_BIOS**********************--
      SFISM4.FBT_BIOS_V1( TRIM(BARCODE), v_MACHINE_ID, TRIM(BIOS_VER), BIOSRES );
      IF BIOSRES <> 'OK' THEN
        RAISE e_BIOS_ERROR;
      END IF;
    --********************END CHECK_BIOS******************--



    --********************CHECK_FBT***********************--
      SFISM4.iTest_Dino_Fbt( TRIM(BARCODE), v_MACHINE_ID, TESTDATE, TESTTIME, RESULT, ERROR_CODE,
                           'FBT', '', EMP, '0', FBTRES);
     /* IF FBTRES = '0' THEN
        RES := 'OK'||'\nDONE';
      ELSIF FBTRES = '2' THEN
        RES := 'THIS BOARD SHOULD RETEST'||'\nDONE';
      ELSIF FBTRES = '3' THEN
        RES := 'THIS BOARD SHOULD REPAIR'||'\nDONE';
      ELSE
        RES := FBTRES||'\nDONE';
      END IF;*/
      RES:=FBTRES||'\nDONE';
    --********************END CHECK_FBT*******************--



    --********************CHECK_LINE**********************--
      SFIS1.Check_Lsa_H(EMP,p_LINE,p_GROUP,HRES);
      IF HRES<>'OK' THEN
        RES := HRES||'\nDONE';
      END IF;
    --********************END CHECK_LINE******************--
   o_flag := '0';

EXCEPTION
    WHEN e_STN_DUP THEN
       BEGIN
          RES:='Station DUPLICATED'||'\nDONE';
       END;
    WHEN e_NO_STN THEN
       BEGIN
          RES:='NO Station'||'\nDONE';
       END;
    WHEN e_File_ERROR THEN
       BEGIN
          RES:='WRONG FILE FORMAT!'||'\nDONE';
       END;
    WHEN e_LENGTH_ERROR THEN
       BEGIN
          RES:=LENGTHRES||'\nDONE';
       END;
    WHEN e_MAC_ERROR THEN
       BEGIN
          RES:=MACRES||'\nDONE';
       END;
    WHEN e_NO_SN THEN
      RES := SNRES||'\nDONE';

    WHEN e_ICSN_ERROR THEN
      RES := ICSNRES||'\nDONE';

    WHEN e_BIOS_ERROR THEN
      RES := BIOSRES||'\nDONE';

    WHEN e_EMP_ERROR THEN
       BEGIN
          RES:=EMPRES||'\nDONE';
       END;
    /*WHEN e_EC_ERROR THEN
       BEGIN
          RES:=ECRES||'\nDONE';
       END;*/

    /*WHEN e_ROUTE_ERROR THEN
      BEGIN
        RES := ROUTE_RES;
      END;*/

    WHEN OTHERS THEN
      RES:='SFC OTHER ERROR'||'\nDONE';
END;