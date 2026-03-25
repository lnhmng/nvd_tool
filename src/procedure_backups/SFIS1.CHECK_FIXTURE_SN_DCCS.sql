PROCEDURE       CHECK_FIXTURE_SN_DCCS (
   DATA      IN     VARCHAR2,
   MYGROUP   IN     VARCHAR2,
   LINE      IN     VARCHAR2,
   RES          OUT VARCHAR2)
IS
   C_ID            NUMBER;
   C_ID1           NUMBER;
   P_CALLRES       VARCHAR (25);
   C_MODEL         VARCHAR (25);
   E_ERROR         EXCEPTION;
   E_ROUTE_ERROR   EXCEPTION;

-----------------add by lyc 20230817 S0000XRCH-唐偉平-壓彈片手動治具與產品SN進行綁定 ----------
BEGIN
     SELECT COUNT (SERIAL_NUMBER), MODEL_NAME
       INTO C_ID, C_MODEL
       FROM SFISM4.R_WIP_TRACKING_T
      WHERE SERIAL_NUMBER = DATA
   GROUP BY MODEL_NAME;

   IF C_ID <= 0
   THEN
      RAISE E_ERROR;
   END IF;

   SELECT COUNT (*)
     INTO C_ID1
     FROM SFISM4.R_FIXTURE_BINDING_T
    WHERE     SERIAL_NUMBER = DATA
          AND GROUP_NAME = MYGROUP
          AND MODEL_NAME = C_MODEL;

   IF C_ID1 >= 1
   THEN
      UPDATE SFISM4.R_FIXTURE_BINDING_T
         SET FLAG = '0'
       WHERE     SERIAL_NUMBER = DATA
             AND GROUP_NAME = MYGROUP
             AND MODEL_NAME = C_MODEL;
   END IF;

   RES := 'OK';

   SFIS1.CHECK_ROUTE (LINE,
                      MYGROUP,
                      DATA,
                      P_CALLRES);

   IF P_CALLRES <> 'OK'
   THEN
      RAISE E_ROUTE_ERROR;
   ELSE

      INSERT INTO SFISM4.R_FIXTURE_BINDING_T
              VALUES (DATA,
                      C_MODEL,
                      LINE,
                      MYGROUP,
                      NULL,
                      '1',
                      SYSDATE);      
   END IF;

   RES := 'OK';
EXCEPTION
   WHEN E_ERROR
   THEN
      RES := ' NO SN ';
   WHEN E_ROUTE_ERROR
   THEN
      RES := P_CALLRES;
   WHEN OTHERS
   THEN
      RES := 'NO SN';
END;