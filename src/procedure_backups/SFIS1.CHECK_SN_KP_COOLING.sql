PROCEDURE       CHECK_SN_KP_COOLING (EMP IN VARCHAR2,SECTION IN VARCHAR2,W_STATION IN VARCHAR2,MYGROUP IN VARCHAR2,DATA IN VARCHAR2,
RES OUT VARCHAR2) IS
c_count VARCHAR2(25);

BEGIN

   RES:='OK';

   IF (LENGTH(TRIM(DATA)) = 24 AND SUBSTR(TRIM(DATA),1,3) = '110') or (LENGTH(TRIM(DATA)) = 17 AND SUBSTR(TRIM(DATA),1,2) = 'HS') THEN
       BEGIN

        SELECT COUNT(*) INTO c_count FROM SFISM4.R_COOLING_T WHERE COOLING_SN =TRIM(DATA)  AND GROUP_NAME=MYGROUP AND KP_FLAG='1';

        IF c_count <=0 THEN

                 Insert into SFISM4.R_COOLING_T (COOLING_SN, TYPE, GROUP_NAME, TIME_VALUE, KP_FLAG,SCAN_DATE, END_DATE, CREATE_TIME, EMP_ID,SERIAL_NUMBER)
                    Values (TRIM(DATA), 'COOLING_SN', MYGROUP, '', '1', 
                     SYSDATE,'', SYSDATE, EMP,'');


                 RES:='OK';

           ELSE

               RES:='SN HAS EXIST!，請去BBH工站作業？';
             --  RETURN;

            END IF;

       END;

   ELSE
     BEGIN

         RES:='NO SN  OR SN 規則異常!!! ';

     END; 


    END IF;  

 -- exception

  -- when others then




END;
