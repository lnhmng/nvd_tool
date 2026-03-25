PROCEDURE                                    iaoi3dx_v7_SPU
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
   o_flag         OUT      VARCHAR2,   
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
   ec_list           eclist;
   sn_count2         NUMBER;
   p_count           INTEGER;
   W_MEM1     VARCHAR2(100);
BSN      VARCHAR2(50);
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
BEGIN
   o_flag := '-1';
   ec_cnt := 0;
   common_check (TRIM (barcode), TRIM (machine_code), emp, checkres);

   IF checkres <> 'OK'
   THEN
      RAISE e_check_error;
   END IF;

--Add by LSC in order to ADD AOI MEM LOCATION INFO;
  IF(MEMCODE IS NOT NULL)
  THEN
  W_TEMP_MEM:=MEMCODE;
        WHILE(INSTR(W_TEMP_MEM,',')>0)
       LOOP
            W_MEM1:=SUBSTR(W_TEMP_MEM,1,INSTR(W_TEMP_MEM,',')-1);
            IF(INSTR(W_MEM1,':')>0)
            THEN
            LOC:=SUBSTR(W_MEM1,1,INSTR(W_MEM1,':')-1);
            BSN:=SUBSTR(W_MEM1,INSTR(W_MEM1,':')+1);
            insert into SFISM4.AOIMEM_T values(BARCODE,LOC,BSN,sysdate);
                   COMMIT;
           END IF;
            W_TEMP_MEM:=SUBSTR(W_TEMP_MEM,INSTR(W_TEMP_MEM,',')+1);
       END LOOP; 
   IF(INSTR(W_TEMP_MEM,',')=0)
   THEN
      IF(INSTR(W_TEMP_MEM,':')>0)
            THEN
            LOC:=SUBSTR(W_TEMP_MEM,1,INSTR(W_TEMP_MEM,':')-1);
            BSN:=SUBSTR(W_TEMP_MEM,INSTR(W_TEMP_MEM,':')+1);
            insert into SFISM4.AOIMEM_T values(BARCODE,LOC,BSN,sysdate);
                   COMMIT;
           END IF;      
  END IF;
  END IF;

   IF UPPER (TRIM (RESULT)) = 'FAIL' OR UPPER (TRIM (RESULT)) = 'F'
   THEN
      v_result := 'F';
   ELSIF    UPPER (TRIM (RESULT)) = 'PASS'
         OR UPPER (TRIM (RESULT)) = 'GOOD'
         OR UPPER (TRIM (RESULT)) = 'P'
   THEN
      v_result := 'P';
   END IF;

   IF v_result = 'F'
   THEN
      ec_transaction_3dx (TRIM (ERROR_CODE), ec_cnt, ec_list);

      IF ec_cnt = 0
      THEN
         RAISE e_ec_error;
      END IF;
   END IF;

   ----AOI or TAOI---Begin
   SELECT station_name, line_name, section_name, group_name
     INTO p_station, p_line, p_section, p_group
     FROM sfis1.c_ict_station_t
    WHERE station_code = machine_code;

------- ---- Add By Derrick Chow Begin 2012-0831---------
   IF (SUBSTR (p_group, 1, 3) = 'AOI')
   THEN
      smtinfo.check_bind_route_v2 (TRIM (barcode),
                                   p_section,
                                   p_group,
                                   'N/A',
                                   p_line,
                                   productres,
                                   checkres
                                  );

      IF checkres <> 'OK'
      THEN
         RAISE e_check_error;
      END IF;
   END IF;

---Add By    LY   2019-11-13    
   IF (SUBSTR (p_group, 1, 7) = '690_AOI') AND (v_result = 'F')
   THEN
      SELECT model_name
        INTO bpmodel
        FROM sfism4.r_wip_tracking_t
       WHERE serial_number = barcode;

      IF bpmodel = 'BP0000'
      THEN
         SELECT COUNT (serial_number)
           INTO countsn
           FROM sfis1.c_bp_product_t
          WHERE bp_sn = barcode;
        IF countsn > 0
         THEN
            SELECT serial_number
              INTO newsn
              FROM sfis1.c_bp_product_t
             WHERE in_station_time = (SELECT MAX (in_station_time)
                                        FROM sfis1.c_bp_product_t
                                       WHERE bp_sn = barcode);

            SELECT special_route
              INTO route
              FROM sfism4.r_wip_tracking_t
             WHERE serial_number = newsn;

            SELECT group_name
              INTO groupnext
              FROM sfis1.c_route_control_t
             WHERE route_code = route AND group_next = '690_AOI';


            IF groupnext is not null
            THEN
               UPDATE sfism4.r_wip_tracking_t
                  SET section_name = groupnext,
                      group_name = groupnext,
                      station_name = groupnext,
                      in_station_time = SYSDATE
                WHERE serial_number = newsn;
            END IF;


        END IF;
      END IF;
   END IF;

   ------- ---- Add By Drrick Chow end 2012-0831---------
   IF (SUBSTR (p_group, 1, 3) = 'API')
   THEN                                                   --add by wh 20180410
      SELECT COUNT (1)
        INTO p_count2
        FROM sfism4.r_wip_tracking_t
       WHERE serial_number IN (
                      SELECT serial_number
                        FROM sfism4.r_pcb_datecode_t
                       WHERE GROUP_ID IN (
                                          SELECT GROUP_ID
                                            FROM sfism4.r_pcb_datecode_t
                                           WHERE serial_number =
                                                                TRIM (barcode)))
         AND error_flag = '1';

      IF p_count2 > 0
      THEN
         res := 'Need to send to Repair!';
         RAISE e_sn_repair;
      END IF;
   END IF;

   --ADD BY LLF 2016-11-25 BEGIN
   IF SUBSTR (p_group, 1, 4) IN ('AOI_') AND v_result = 'F'
   THEN
      SELECT COUNT (1)
        INTO p_count
        FROM sfism4.r_pcb_datecode_t
       WHERE GROUP_ID IN (SELECT GROUP_ID
                            FROM sfism4.r_pcb_datecode_t
                           WHERE serial_number = TRIM (barcode));

      IF p_count > 0
      THEN
         res :=
            'MultiBoard ' || p_group
            || ' FAIL,Please scan AOI_CHECK STATION!';
         RAISE e_multi_fail;
      ELSE
         SELECT COUNT (1)
           INTO p_count1
           FROM sfism4.r_wip_tracking_t
          WHERE serial_number IN (
                      SELECT serial_number
                        FROM sfism4.r_pcb_datecode_t
                       WHERE GROUP_ID IN (
                                          SELECT GROUP_ID
                                            FROM sfism4.r_pcb_datecode_t
                                           WHERE serial_number =
                                                                TRIM (barcode)))
            AND error_flag = '1';

         IF p_count1 > 0
         THEN
            res := 'Need to send to Repair!';
            RAISE e_sn_repair;
         END IF;
      END IF;
   ELSIF SUBSTR (p_group, 1, 4) IN ('AOI_') AND v_result = 'P'
   THEN                                               ---ADD BY LLF 2017-10-14
      SELECT COUNT (1)
        INTO p_count1
        FROM sfism4.r_pcb_datecode_t
       WHERE serial_number = TRIM (barcode) AND GROUP_ID IS NOT NULL;

      IF (p_count1 > 0)
      THEN
         SELECT COUNT (1)
           INTO p_count1
           FROM sfism4.r_wip_tracking_t
          WHERE serial_number IN (
                      SELECT serial_number
                        FROM sfism4.r_pcb_datecode_t
                       WHERE GROUP_ID IN (
                                          SELECT GROUP_ID
                                            FROM sfism4.r_pcb_datecode_t
                                           WHERE serial_number =
                                                                TRIM (barcode)))
            AND error_flag = '1';

         IF p_count1 > 0
         THEN
            res := 'Need to send to Repair!';
            RAISE e_sn_repair;
         END IF;
      END IF;
   END IF;

   --ADD BY LLF 2016-11-25 END

   --Modified by Alex Wang on 2011/02/14 for 36GQ-110214-01 the next row(cause: AOIIN-->API     AOIOUT-->AOI)
   IF (SUBSTR (p_group, 1, 3) = 'AOI') OR (SUBSTR (p_group, 1, 3) = 'API')
   THEN
      iaoitest_v1 (TRIM (barcode),
                   UPPER (TRIM (machine_code)),
                   TRIM (emp),
                   TRIM (ERROR_CODE),
                   v_result,
                   retest,
                   ec_cnt,
                   ec_list,
                   aoitest_res
                  );
   --Modified by Alex Wang on 2011/04/02 for 3QVE-110402-01 the next row(cause: TAOI-->900_AOI)
   --ELSIF SUBSTR(p_GROUP,1,4)='TAOI' THEN
   ELSIF    (SUBSTR (p_group, 1, 4) = 'TAOI')
         OR (SUBSTR (p_group, 1, 7) = '900_AOI')
         OR (SUBSTR (p_group, 1, 7) = '690_AOI')
   THEN
      iaoitest_v2 (TRIM (barcode),
                   UPPER (TRIM (machine_code)),
                   TRIM (emp),
                   TRIM (ERROR_CODE),
                   v_result,
                   retest,
                   ec_cnt,
                   ec_list,
                   aoitest_res
                  );
   END IF;

   IF aoitest_res <> 'OK'
   THEN
      RAISE e_aoitest_error;
   END IF;

   ----AOI or TAOI---End
   res := 'OK' || '\n' || '**END**';
   o_flag := '0';   
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
END iaoi3dx_v7_SPU;