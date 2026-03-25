PROCEDURE                      iaoi3dx_v1
/*********************************************
Author : Alex Wang                          **
Date   : 2010-10-26                         **
Description: To act on the *.3dx file       **
update: ShiChang Liu                        **
Date:2020-11-25                             **
Description:TO ADD AOI MEM LOCATION INFO    **
**********************************************/
(
   barcode        IN       VARCHAR2,
   machine_code   IN       VARCHAR2,
   emp            IN       VARCHAR2,
   RESULT         IN       VARCHAR2,
   testdate       IN       VARCHAR2,
   testtime       IN       VARCHAR2,
   error_flag     IN       VARCHAR2,
   MEMCODE        IN       VARCHAR2,
   retest         IN       VARCHAR2,
   ERROR_CODE     IN       VARCHAR2,
   error_code2    IN       VARCHAR2,
   error_code3    IN       VARCHAR2,
   error_code4    IN       VARCHAR2,
   error_code5    IN       VARCHAR2,
   res            OUT      VARCHAR2
)
AS
   checkres          VARCHAR2 (50);
   productres        VARCHAR2 (50);
   aoitest_res       VARCHAR2 (200);
   v_result          VARCHAR2 (2);
   p_group           VARCHAR2 (16);
   p_station         VARCHAR2 (16);
   p_line            VARCHAR2 (16);
   bpmodel           VARCHAR2 (20);
   countsn           VARCHAR2 (20);
   newsn             VARCHAR2 (20);
   route             VARCHAR2 (20);
   groupnext         VARCHAR2 (20);
   p_section         VARCHAR2 (16);
   c_model           VARCHAR2 (25);
   product_no        VARCHAR2 (30);
   ec_cnt            NUMBER (3, 0);
   sn_link_qty       number;  --SFISM4.R_PCB_DATECODE_T ??group_id?????? 20230218 cz
   p_sn              VARCHAR2 (50);  --SFISM4.R_PCB_DATECODE_T ??group_id?????? 20230218 cz
   ec_list           eclist;
   c_count			 NUMBER;
   sn_count2         NUMBER;
   p_count           INTEGER;
   W_MEM1     VARCHAR2(100);
   BSN      VARCHAR2(50);
   SN1      VARCHAR2(50);
   LOC      varchar2(60);
   W_TEMP_MEM VARCHAR2(400);
   --ADD BY LLF FOR 2016-11-25 FOR MULTI BORDS AOIFAIL SCAN AOI_CHECK STATION
   p_count1          INTEGER;
   --ADD BY LLF FOR 2016-11-25 FOR MULTI BORDS AOIFAIL SCAN AOI_CHECK STATION
   p_count2          INTEGER;
   e_check_error     EXCEPTION;
   e_ec_error        EXCEPTION;
   e_aoitest_error   EXCEPTION;
   e_multi_fail      EXCEPTION;
   --ADD BY LLF FOR 2016-11-25 FOR MULTI BORDS AOIFAIL SCAN AOI_CHECK STATION
   e_sn_repair       EXCEPTION;
    --ADD BY LLF FOR 2016-11-25 FOR MULTI BORDS AOIFAIL SCAN AOI_CHECK STATION
   CURSOR data_cursor IS-----add for cz 20230218  SFISM4.R_PCB_DATECODE_T ??group_id??????
    SELECT SERIAL_NUMBER FROM SFISM4.R_PCB_DATECODE_T
    WHERE GROUP_ID IN(SELECT GROUP_ID FROM SFISM4.R_PCB_DATECODE_T WHERE SERIAL_NUMBER=BARCODE);
BEGIN
   ec_cnt := 0;
   --common_check (TRIM (barcode), TRIM (machine_code), emp, checkres);

   SELECT count(SERIAL_NUMBER) into sn_link_qty FROM SFISM4.R_PCB_DATECODE_T
    WHERE GROUP_ID IN(SELECT GROUP_ID FROM SFISM4.R_PCB_DATECODE_T WHERE SERIAL_NUMBER=BARCODE);--??????

   IF checkres <> 'OK'
   THEN
      RAISE e_check_error;
   END IF;

  SELECT  group_name
     INTO  p_group
     FROM sfis1.c_ict_station_t
    WHERE station_code = machine_code;
   SN1 :=BARCODE;
--Add by LSC in order to ADD AOI MEM LOCATION INFO;
  IF(MEMCODE IS NOT NULL)
  THEN
  	SELECT COUNT(*) INTO c_count FROM SFISM4.R_AOI_MEMORY_T WHERE SERIAL_NUMBER=SN1 AND GROUP_NAME=p_group;--Ruanshiqiao ADD 20240817 
		 IF c_count>0 THEN	 
		 DELETE FROM  SFISM4.R_AOI_MEMORY_T WHERE SERIAL_NUMBER=SN1 AND GROUP_NAME=p_group;
		 END IF;
  W_TEMP_MEM:=MEMCODE;
        WHILE(INSTR(W_TEMP_MEM,';')>0)
       LOOP
            W_MEM1:=SUBSTR(W_TEMP_MEM,1,INSTR(W_TEMP_MEM,';')-1);
            IF(INSTR(W_MEM1,',')>0)
            THEN
                LOC:=SUBSTR(W_MEM1,1,INSTR(W_MEM1,',')-1);
                BSN:=SUBSTR(W_MEM1,INSTR(W_MEM1,',')+1);
                if(sn_link_qty <2) then--??2???????
                    insert into SFISM4.AOIMEM_T values(BARCODE,LOC,BSN,sysdate);
                   INSERT INTO SFISM4.R_AOI_MEMORY_T (SERIAL_NUMBER, LOCATION, BARCODE, GROUP_NAME, IN_STATION_TIME)
											   VALUES(BARCODE, LOC, BSN, p_group,sysdate);--Add by Ruanshiqiao 20240815 to insert SFISM4.R_AOI_MEMORY_T
                else
                    open data_cursor;
                    loop
                    fetch data_cursor into p_sn;
                    exit when data_cursor%notfound;
                        insert into SFISM4.AOIMEM_T values(p_sn,LOC,BSN,sysdate);
                        INSERT INTO SFISM4.R_AOI_MEMORY_T (SERIAL_NUMBER, LOCATION, BARCODE, GROUP_NAME, IN_STATION_TIME)
											   VALUES(p_sn, LOC, BSN, p_group,sysdate);--Add by Ruanshiqiao 20240815 to insert SFISM4.R_AOI_MEMORY_T
                    end loop;
                    close data_cursor;
                end if;
                COMMIT;
           END IF;
            W_TEMP_MEM:=SUBSTR(W_TEMP_MEM,INSTR(W_TEMP_MEM,';')+1);
       END LOOP; 
   IF(INSTR(W_TEMP_MEM,';')=0)
   THEN
      IF(INSTR(W_TEMP_MEM,',')>0)
            THEN
            LOC:=SUBSTR(W_TEMP_MEM,1,INSTR(W_TEMP_MEM,',')-1);
            BSN:=SUBSTR(W_TEMP_MEM,INSTR(W_TEMP_MEM,',')+1);
            if(sn_link_qty <2) then
                    insert into SFISM4.AOIMEM_T values(BARCODE,LOC,BSN,sysdate);
                    INSERT INTO SFISM4.R_AOI_MEMORY_T (SERIAL_NUMBER, LOCATION, BARCODE, GROUP_NAME, IN_STATION_TIME)
											   VALUES(BARCODE, LOC, BSN, p_group,sysdate);--Add by Ruanshiqiao 20240815 to insert SFISM4.R_AOI_MEMORY_T
                else
                    open data_cursor;
                    loop
                    fetch data_cursor into p_sn;
                    exit when data_cursor%notfound;
                        insert into SFISM4.AOIMEM_T values(p_sn,LOC,BSN,sysdate);
                       INSERT INTO SFISM4.R_AOI_MEMORY_T (SERIAL_NUMBER, LOCATION, BARCODE, GROUP_NAME, IN_STATION_TIME)
											   VALUES(p_sn, LOC, BSN, p_group,sysdate);--Add by Ruanshiqiao 20240815 to insert SFISM4.R_AOI_MEMORY_T
                    end loop;
                    close data_cursor;
                end if;
                COMMIT;
           END IF;      
  END IF;
  END IF;
  
 
 EXCEPTION
   WHEN e_check_error
   THEN
      res := checkres || '\n' || '**END**';
   WHEN e_ec_error
   THEN
      res := 'ERROR CODE ERROR' || '\n' || '**END**';
   WHEN e_aoitest_error
   THEN
      res := aoitest_res || '\n' || '**END**';
   WHEN e_multi_fail
   THEN
      res := res || '\n' || '**END**';
   WHEN e_sn_repair
   THEN
      res := res || '\n' || '**END**';
   WHEN OTHERS
   THEN
      res := 'IAOI3DX_V1 OTHER ERROR' || '\n' || '**END**';
END iaoi3dx_v1;