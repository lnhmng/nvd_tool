PROCEDURE             CHECK_PACKINGSN (DATA   IN     VARCHAR2,
                                                   EMP       IN  VARCHAR2,
                                           RES       OUT VARCHAR2)
IS
   C_ID       VARCHAR2 (25);
   NUM      NUMBER (2);                 --S0000WDY0,SN 比對 19/12/03,增加檢查
   e_ERROR   EXCEPTION;               --S0000WDY0,SN 比對 19/11/20  
BEGIN  


   SELECT SERIAL_NUMBER
   INTO C_ID
   FROM SFISM4.R_WIP_TRACKING_T
   WHERE SERIAL_NUMBER = SUBSTR(DATA,1,13)
   GROUP BY SERIAL_NUMBER;

   IF C_ID >=0  THEN
   RES :='OK';
   end if;

   select count(*) into NUM from SFISM4.R_BIDUI_SN_T where serial_number = SUBSTR(DATA,1,13);
   if NUM >=1 then
   res :='SN IS USED'; 
   else
    INSERT INTO SFISM4.R_BIDUI_SN_T(SERIAL_NUMBER,BIDUI_SN,EMP_NO,CREATE_DATE,BIDUI_DATE) 
    VALUES(C_ID,'null',EMP,SYSDATE,'');
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      RES := 'NO SN OR  SN HAS BIDUIED /';
END;