PROCEDURE             SP_TEST_CHECK_ROUTE 
(LINE IN VARCHAR2, MYGROUP IN VARCHAR2, DATA IN VARCHAR2,
   RES OUT VARCHAR2)
IS
CURRENT_G VARCHAR2(25);
G VARCHAR2(25);
R_CODE NUMBER;
MO VARCHAR2(25);
/******************************************************************************
   NAME:       SP_TEST_CHECK_ROUTE
   PURPOSE:  for tickets S000003M3Z  

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0      2015/12/26   maggiechang       1. Created this procedure.

******************************************************************************/
BEGIN

   SELECT
      NEXT_STATION INTO CURRENT_G
   FROM
      SFISM4.R_WIP_TRACKING_T
   WHERE
      SERIAL_NUMBER = DATA;

   IF (CURRENT_G = 'N/A') OR (CURRENT_G IS NULL) THEN
      CHECK_ROUTE3(LINE,MYGROUP,DATA,RES);

   ELSIF CURRENT_G = MYGROUP THEN
      RES := 'OK';

   ELSE
      RES := CURRENT_G;

   END IF;

exception
   when others then
   RES := 'SP_TEST_CHECK_ROUTE ERROR';
END SP_TEST_CHECK_ROUTE;