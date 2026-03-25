PROCEDURE                   CHECK_PCB_SN_EXIST
/*****************************************************
Author:  Scofield                                    **
Date:    2019-08-21                                  **
Description: To TANZISONG   CHECK PCB SN INSERT      **
*****************************************************/
(
  LINE      IN  VARCHAR2,
  SN      IN  VARCHAR2,
  res           OUT      VARCHAR2

)
IS

c_count0        NUMBER; 
erri            NUMBER(2,0);
ARRAY_LENGTH    INTEGER;

TEMP      VARCHAR2(1000);
TEMP_ERROR      VARCHAR2(1000);
ERROR_CODE      VARCHAR2(1000);
e_error         EXCEPTION;

BEGIN

   res := 'OK';
   ERROR_CODE:=SN;
   TEMP:='';
   ARRAY_LENGTH := 0;

  WHILE (INSTR(ERROR_CODE,';')>0)
    LOOP
      erri:=INSTR(ERROR_CODE,';');
      TEMP_ERROR:=SUBSTR(ERROR_CODE,1,erri-1);
      ARRAY_LENGTH := ARRAY_LENGTH +1;

       TEMP:=TEMP_ERROR;  


         Check_Route(LINE,'PCB_OPEN',TEMP,res);
          IF res <> 'OK' THEN

             res := 'ROUTE ERROR  '; 
             RAISE e_error;  

           END IF;


        SELECT COUNT (*) INTO c_count0 FROM SFISM4.R_PCB_DATECODE_T WHERE SERIAL_NUMBER=TRIM(TEMP);

          IF c_count0 > 1 THEN

             res := 'SN HAS USES ';
             RAISE e_error;
         END IF;



    ERROR_CODE := SUBSTR(ERROR_CODE,INSTR(ERROR_CODE,';')+1,LENGTH(ERROR_CODE)-erri);



  END LOOP;


   IF (ERROR_CODE <> '') OR (ERROR_CODE IS NOT NULL) THEN
     ARRAY_LENGTH := ARRAY_LENGTH +1;
     TEMP := ERROR_CODE;

         Check_Route(LINE,'PCB_OPEN',TEMP,res);
            IF res <> 'OK' THEN

               res := 'ROUTE ERROR  '; 
               RAISE e_error;    

             END IF;  

        SELECT COUNT (*) INTO c_count0 FROM SFISM4.R_PCB_DATECODE_T WHERE SERIAL_NUMBER=TRIM(TEMP);

          IF c_count0 > 1 THEN

             res := 'SN HAS USES ';
             RAISE e_error;
         END IF;

   END IF;
EXCEPTION

  WHEN OTHERS THEN
   RES:='ERROR';


END;