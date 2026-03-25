PROCEDURE                         input_pcb_open_info (
   line          IN       VARCHAR2,   
   MACHINEID     IN       VARCHAR2,
   PRO_NAME           IN       VARCHAR2,
   GROUPID          IN       VARCHAR2,
   PUID          IN       VARCHAR2,
   Quantity      IN       NUMBER,  
   SN        IN       VARCHAR2,
 --  PCB_OPEN_TIME         IN       DATE,
   EMP           IN       VARCHAR2,   
 
 --  TIMESTAMP   IN        VARCHAR2,
   res           OUT      VARCHAR2
)
IS
  
   c_machine       VARCHAR2 (32);
   C_MO_NUMBER       VARCHAR2 (32);
   c_count0        NUMBER; 
   c_count2       NUMBER;   
   erri            NUMBER(2,0);
   ARRAY_LENGTH    INTEGER;   

   TEMP_ERROR      VARCHAR2(1000);
   TEMP      VARCHAR2(1000);
   ERROR_CODE      VARCHAR2(1000);   
   e_error         EXCEPTION;
BEGIN

  res := 'OK';

  ERROR_CODE := SN;
  TEMP:='';
  ARRAY_LENGTH := 0;

  SELECT COUNT (*)
     INTO c_count2
     FROM sfis1.c_asm_sfc_machinecode
    WHERE asm_code =TRIM(MACHINEID);

   IF c_count2 > 0
   THEN
      SELECT sfc_code
        INTO c_machine
        FROM sfis1.c_asm_sfc_machinecode
       WHERE asm_code =TRIM(MACHINEID);
   ELSE
      res := 'sfis1.c_asm_sfc_machinecode no sfc machine code';
      RAISE e_error;
   END IF;


  IF (ERROR_CODE<>'') OR (ERROR_CODE IS NOT NULL) THEN    

     CHECK_PCB_SN_EXIST(LINE,TRIM(ERROR_CODE),RES);

    IF RES <>'OK' THEN
      RAISE e_error;

    ELSE

     BEGIN


       WHILE (INSTR(ERROR_CODE,';')>0)
         LOOP
          erri:=INSTR(ERROR_CODE,';');
          TEMP_ERROR:=SUBSTR(ERROR_CODE,1,erri-1);
          ARRAY_LENGTH := ARRAY_LENGTH +1;

          TEMP:=TEMP_ERROR;  

         SELECT MO_NUMBER INTO C_MO_NUMBER FROM SFISM4.R_WIP_TRACKING_T WHERE SERIAL_NUMBER=TRIM(TEMP);      

         SELECT COUNT (*) INTO c_count0 FROM SFISM4.R_PCB_DATECODE_T WHERE SERIAL_NUMBER=TRIM(TEMP);

          IF c_count0 < 1
           THEN

            Insert into SFISM4.R_PCB_DATECODE_T
              (PKG_ID, SERIAL_NUMBER, LINE_NAME, IN_STATION_TIME, ERROR_CODE, 
               REPAIRED_TIME, INPUT_FLAG, GROUP_ID,EMP_NO)
               Values
               (PUID, TEMP, line, SYSDATE, '','', '0', GROUPID,EMP);                    

               UPDATE_R107(EMP,LINE,'SMT','PCB_OPEN','PCB_OPEN1',C_MO_NUMBER,TEMP,'0',SYSDATE); 

              IF Quantity<>1 THEN 


                 UPDATE_R107(EMP,LINE,'SMT','SN_BINDING','SN_BINDING1',C_MO_NUMBER,TEMP,'0',SYSDATE);    

               END IF;


           ELSE
                res := 'SN HAS USES ';
               RAISE e_error;
           END IF;

          ERROR_CODE := SUBSTR(ERROR_CODE,INSTR(ERROR_CODE,';')+1,LENGTH(ERROR_CODE)-erri);

        END LOOP;


        IF (ERROR_CODE <> '') OR (ERROR_CODE IS NOT NULL) THEN
          ARRAY_LENGTH := ARRAY_LENGTH +1;
          TEMP := ERROR_CODE;


          SELECT MO_NUMBER INTO C_MO_NUMBER FROM SFISM4.R_WIP_TRACKING_T WHERE SERIAL_NUMBER=TRIM(TEMP);                 

          SELECT COUNT (*) INTO c_count0 FROM SFISM4.R_PCB_DATECODE_T WHERE SERIAL_NUMBER=TRIM(TEMP);

           IF c_count0 < 1
           THEN

            Insert into SFISM4.R_PCB_DATECODE_T
              (PKG_ID, SERIAL_NUMBER, LINE_NAME, IN_STATION_TIME, ERROR_CODE, 
               REPAIRED_TIME, INPUT_FLAG, GROUP_ID,EMP_NO)
               Values
               (PUID, TEMP, line, SYSDATE, '','', '0', GROUPID,EMP);                     

               UPDATE_R107(EMP,LINE,'SMT','PCB_OPEN','PCB_OPEN',C_MO_NUMBER,TEMP,'0',SYSDATE);  

              IF Quantity<>1 THEN 


                  UPDATE_R107(EMP,LINE,'SMT','SN_BINDING','SN_BINDING1',C_MO_NUMBER,TEMP,'0',SYSDATE);    

               END IF;

          ELSE
               res := 'SN HAS USES  ';
              RAISE e_error;
          END IF;


          END IF;


        END;


     END IF;


   ELSE
      res := 'PCB_OPEN NO SN -->ERROR';
      RAISE e_error;
   END IF;

EXCEPTION
   WHEN e_error
   THEN
      NULL;
       --INSERT_ERROR_MES(STATION_NUM,C_MACHINE,PPN,VER,EMP,C_LOC,PKG,LOC,LINE,RES);
   WHEN OTHERS
   THEN
      ROLLBACK;
      res := 'OTHER ERROR ' || SUBSTR (SQLERRM, 1, 50);
       --INSERT_ERROR_MES(STATION_NUM,C_MACHINE,PPN,VER,EMP,C_LOC,PKG,LOC,LINE,RES);
END;