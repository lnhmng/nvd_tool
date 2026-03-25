PROCEDURE       CHECK_PACKINGSN_V1 (DATA     IN     VARCHAR2,
                                                     EMP       IN  VARCHAR2,
                                                     LINE IN VARCHAR2, 
                                                     MYGROUP IN VARCHAR2,
                                           RES       OUT VARCHAR2)
IS
   C_ID       VARCHAR2 (25);
   NUM      NUMBER (2);                 --S0000WDY0,SN 比對 19/12/03 add by lyc
   E_ERROR   EXCEPTION;               
BEGIN  


   SELECT SERIAL_NUMBER
   INTO C_ID
   FROM SFISM4.R_WIP_TRACKING_T
   WHERE SERIAL_NUMBER = SUBSTR(DATA,1,13)
   GROUP BY SERIAL_NUMBER;

   IF C_ID >=0  THEN
   RES :='OK';
   END IF;

  ---------20230601 add by lyc begin-------
   SELECT COUNT(*) INTO NUM FROM SFISM4.R_BIDUI_SN_T WHERE SERIAL_NUMBER = SUBSTR(DATA,1,13) AND GROUP_NAME = MYGROUP;
   IF NUM >=1 THEN
   --RES :='SN IS USED';    --undo SN without bidui , allow to use in next scan by update  --liujiang20240314
   
     SELECT COUNT(*) INTO NUM FROM SFISM4.R_BIDUI_SN_T WHERE SERIAL_NUMBER = SUBSTR(DATA,1,13) AND GROUP_NAME = MYGROUP and BIDUI_SN <>'null' ;
     if NUM>=1 then
       RES :='SN IS USED';
     else 
       UPDATE SFISM4.R_BIDUI_SN_T set EMP_NO=EMP, CREATE_DATE=SYSDATE, LINE_NAME=LINE where SERIAL_NUMBER = SUBSTR(DATA,1,13) AND GROUP_NAME = MYGROUP;
     end if ;
    
   ELSE
    INSERT INTO SFISM4.R_BIDUI_SN_T(SERIAL_NUMBER,BIDUI_SN,EMP_NO,CREATE_DATE,BIDUI_DATE,LINE_NAME,GROUP_NAME) 
    VALUES(C_ID,'null',EMP,SYSDATE,'',LINE,MYGROUP);
   END IF;
  ---------20230601 add by lyc end-------
EXCEPTION
   WHEN OTHERS THEN
      RES := 'NO SN OR  SN HAS BIDUIED /';
END;