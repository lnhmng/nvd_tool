PROCEDURE             DD_TEST_INPUT(LINE IN VARCHAR2,
                              SECTION IN VARCHAR2,
                              W_STATION IN VARCHAR2,
                              DATETIME IN DATE,
                              EC IN VARCHAR2,
                              DATA IN VARCHAR2,
                              MO_DATE IN VARCHAR2,
                              W_SECTION IN NUMBER,
                              MYGROUP IN VARCHAR2,
                              EMP IN VARCHAR2,
                              RES OUT VARCHAR2 ) AS

G VARCHAR2(25);
MO VARCHAR2(25);
OK VARCHAR2(16);
C_MODEL VARCHAR2(25);

BEGIN

   G := '';
   MO := '';
   OK := '';

   SELECT MO_NUMBER,MODEL_NAME
     INTO MO,C_MODEL
   FROM SFISM4.R_WIP_TRACKING_T
   WHERE SERIAL_NUMBER = DATA
   AND ROWNUM = 1;

   if EC = 'N/A' then

      CHECK_ROUTE(LINE,MYGROUP,DATA,OK);

      if OK = 'OK' then

         STN_REC(LINE,SECTION,MYGROUP,W_STATION,MO,DATA,MO_DATE,W_SECTION,'0');

         DD_UPDATE_R107(EMP,LINE,SECTION,MYGROUP,W_STATION,MO,DATA,'0',DATETIME);

         RES := OK;

      else
         RES := OK;

      end if;
   else

      SELECT GROUP_NAME INTO G
       FROM SFISM4.R_WIP_TRACKING_T
        WHERE LINE_NAME = LINE
          and GROUP_NAME = MYGROUP
          and SERIAL_NUMBER = DATA
          AND ROWNUM = 1
          and error_flag = '1';

      INSERT INTO SFISM4.R_REPAIR_T(SERIAL_NUMBER,
                                    MO_NUMBER,
                                    TEST_TIME,
                                    TEST_CODE,
                                    TEST_STATION,
                                    TEST_LINE,
                                    RECORD_TYPE,
                                    MODEL_NAME)

                             VALUES(DATA,
                                    MO,
                                    DATETIME,
                                    EC,
                                    W_STATION,
                                    LINE,
                                    'T',
                                    C_MODEL);

      RES := 'OK';
   end if;

exception

   when others then

      CHECK_ROUTE(LINE,MYGROUP,DATA,OK);

      if OK = 'OK' then

         STN_REC(LINE,SECTION,MYGROUP,W_STATION,MO,DATA,MO_DATE,W_SECTION,'1');

         DD_UPDATE_R107(EMP,LINE,SECTION,MYGROUP,W_STATION,MO,DATA,'1',DATETIME);

         INSERT INTO SFISM4.R_REPAIR_T(SERIAL_NUMBER,
                                       MO_NUMBER,
                                       TEST_TIME,
                                       TEST_CODE,
                                       TEST_STATION,
                                       TEST_LINE,
                                       RECORD_TYPE,
                                       MODEL_NAME)

                                VALUES(DATA,
                                       MO,
                                       DATETIME,
                                       EC,
                                       W_STATION,
                                       LINE,
                                       'T',
                                       C_MODEL);

      end if;

      RES := OK;
END;