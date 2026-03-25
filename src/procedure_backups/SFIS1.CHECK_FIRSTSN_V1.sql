PROCEDURE             CHECK_FIRSTSN_V1 ( DATA   IN     VARCHAR2,
                                                  EMP    IN     VARCHAR2,
                                                  RES    OUT    VARCHAR2)
IS
   FIR_SN         VARCHAR2 (25);
   C_MODEL    	  VARCHAR2 (25);
   NUM            NUMBER (2);
   e_ERROR        EXCEPTION;               
BEGIN  


   SELECT SERIAL_NUMBER,MODEL_NAME
   INTO FIR_SN,C_MODEL
   FROM SFISM4.R_WIP_TRACKING_T
   WHERE SERIAL_NUMBER = SUBSTR(DATA,1,13);

   IF FIR_SN >=0  THEN
   RES :='OK';
   end if;

   select count(*) into NUM from SFISM4.R_SAME_SN_T where serial_number = SUBSTR(DATA,1,13);
   if NUM >=1 then
   res :='OK';
   else
    INSERT INTO SFISM4.R_SAME_SN_T(SERIAL_NUMBER,SECOND_SN,THIRD_SN,FOURTH_SN,FIFTH_SN,SIXTH_SN,EMP_NO,CREATE_DATE,BIDUI_DATE,MODEL_NAME) 
    VALUES(FIR_SN,'N/A','N/A','N/A','N/A','N/A',EMP,SYSDATE,'',C_MODEL);
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      RES := 'NO SN';
END;