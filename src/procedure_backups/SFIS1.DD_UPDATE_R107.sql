PROCEDURE DD_UPDATE_R107(EMP IN VARCHAR2,
                                LINE IN VARCHAR2,
                                SECTION IN VARCHAR2,
                                MYGROUP IN VARCHAR2,
                                W_STATION IN VARCHAR2,
                                MO IN VARCHAR2,
                                DATA IN VARCHAR2,
                                F_FLAG IN VARCHAR2,
                                DATETIME IN DATE) AS

BEGIN

   UPDATE SFISM4.R_WIP_TRACKING_T
      SET LINE_NAME=LINE,
          SECTION_NAME=SECTION,
          GROUP_NAME=MYGROUP,
          STATION_NAME=W_STATION,
          ERROR_FLAG = F_FLAG,
          IN_STATION_TIME = DATETIME,
          NEXT_STATION='N/A',
          EMP_NO=EMP
      WHERE SERIAL_NUMBER = DATA;

   INSERT_R121(DATA, MYGROUP,DATETIME,MO);

END;
