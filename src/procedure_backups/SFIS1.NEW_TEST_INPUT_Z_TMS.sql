PROCEDURE                   NEW_TEST_INPUT_Z_TMS (
   emp         IN       VARCHAR2,
   line        IN       VARCHAR2,
   section     IN       VARCHAR2,
   w_station   IN       VARCHAR2,
   ec          IN       VARCHAR2,
   DATA        IN       VARCHAR2,
   mygroup     IN       VARCHAR2,  
   zid         IN       VARCHAR2,             
   res         OUT      VARCHAR2
)

AS
   mo             VARCHAR (25);
   ok             VARCHAR (50);
   c_model        VARCHAR (25);
   p_type         VARCHAR (1);
   v_datetime     DATE;
   v_count        NUMBER;
   temp_cust      VARCHAR (25);
   level_grade    VARCHAR (8);
   rev            VARCHAR (25);
   n              NUMBER;
   temp_time      DATE;
   station_time   DATE;
   temp_group     VARCHAR (25);
   v_res          VARCHAR (200);             
BEGIN
   v_datetime := SYSDATE;
   mo := '';
   ok := 'OK';
   check_route (line, mygroup, DATA, ok);

   IF ok <> 'OK'
   THEN
    res := 'JUMP={S0} ' || DATA || ok;
      RETURN;
   END IF;

   IF mygroup LIKE 'SMT INPUT%'
   THEN
      SELECT COUNT (*)
        INTO v_count
        FROM sfism4.r_pcb_datecode_t
       WHERE serial_number = DATA;

      IF v_count < 1
      THEN
         res := 'JUMP={S0}  PCB NOT UNSEAL ';
         RETURN;
      END IF;
   END IF;

   SELECT mo_number, model_name,customer_no,  in_line_time,
          version_code, in_station_time, group_name
     INTO mo, c_model, temp_cust,  temp_time,
          rev, station_time, temp_group
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = DATA AND ROWNUM = 1;


   SELECT mo_number, model_name, customer_no, in_line_time
     INTO mo, c_model, temp_cust, temp_time
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = DATA AND ROWNUM = 1;

   ----ADD BY LILIYI 20090414
   IF mygroup = 'FT SCAN' AND temp_group = 'FT'
   THEN
      IF (v_datetime - station_time) * 24 * 60 > 3
      THEN
         update_r107 (emp,
                      line,
                      'ICT',
                      'ICT',
                      'ICT',
                      mo,
                      DATA,
                      '0',
                      v_datetime
                     );
         res := 'JUMP={S0} ' || 'Must be in 3 minutes Scan';
         RETURN;
      --add by dsy  2010 0925 for TMS--end;
      END IF;
   END IF;

   --add by dsy  2010 0925 for TMS--Begin
   SELECT COUNT (*)
     INTO v_count
     FROM tms.tms_s_scan_station_t
    WHERE model_name = c_model
      AND group_name = mygroup
      AND VERSION = rev
      AND use_flag = '1';

   IF v_count > 0 AND zid = 'N/A'
   THEN
      res := 'JUMP={S1} OK ';
      RETURN;
   END IF;

   IF v_count > 0 AND zid <> 'N/A'
   THEN
      -----BEGIN---------S000000RYD-------Added by BossVee-------------
      SELECT COUNT (*)
        INTO v_count
        FROM tms.tms_s_tool_on_product
       WHERE tool_id = zid AND part_no = c_model;

      IF v_count = 0
      THEN
         res := 'THE MODELS ARE DIFFERENT';
         RETURN;
      END IF;

      -------- END ---------S000000RYD------Added by BossVee------------
      res := 'LINK TOOLS ID ERROR ';
      tms.insert_tms_online_sn (zid,
                                DATA,
                                line,
                                mygroup,
                                'N/A',
                                emp,
                                '1',
                                v_res
                               );

      IF TRIM (v_res) <> 'OK'
      THEN
         res := 'JUMP={S0} ' || v_res;
         RETURN;
      END IF;
   END IF;

   --add by dsy  2010 0925 for TMS--end;
   ----ADD BY LILIYI 20090414
   IF ec = 'N/A'
   THEN
     /* stn_rec_z (line, section, mygroup, w_station, mo, DATA, '0');*/
      update_r107 (emp,
                   line,
                   section,
                   mygroup,
                   w_station,
                   mo,
                   DATA,
                   '0',
                   v_datetime
                  );
      /*update_rlsa (DATA, line, mygroup, mo, ec, res);*/
   ELSE
      SELECT ERROR_TYPE
        INTO p_type
        FROM sfis1.c_error_code_t
       WHERE ERROR_CODE = ec;

     /* stn_rec_z (line, section, mygroup, w_station, mo, DATA, '1');*/

      IF     p_type = 'W'
         AND ((mygroup LIKE 'TOUCH UP%') OR (mygroup LIKE 'MPS INSPECT%'))
      THEN
         update_r107 (emp,
                      line,
                      section,
                      mygroup,
                      w_station,
                      mo,
                      DATA,
                      '0',
                      v_datetime
                     );

         INSERT INTO sfism4.r_repair_t
                     (serial_number, mo_number, test_time, test_code,
                      test_station, test_line, record_type, model_name,
                      repairer, repair_time, reason_code, repair_station,
                      repair_status, duty_type, error_item_code, machine

                     )
              VALUES (DATA, mo, v_datetime, ec,
                      w_station, line, 'T', c_model,
                      w_station, v_datetime, 'ERQ002', w_station,
                      'N', 'W', 'A0000',''
                     );
      ELSE
         update_r107 (emp,
                      line,
                      section,
                      mygroup,
                      w_station,
                      mo,
                      DATA,
                      '1',
                      v_datetime
                     );

         INSERT INTO sfism4.r_repair_t
                     (serial_number, mo_number, test_time, test_code,
                      test_station, test_line, record_type, model_name,
                      machine
                     )
              VALUES (DATA, mo, v_datetime, ec,
                      w_station, line, 'T', c_model,
                      ec
                     );
      END IF;                                                --IF P_TYPE = 'W'

      /*update_rlsa (DATA, line, mygroup, mo, ec, res);*/
   END IF;                                                    -- IF EC = 'N/A'

   --add by dsy  2010 0925 for TMS--Begin
   res := 'JUMP={S0} OK {D01_ON_OFF} ';
--add by dsy  2010 0925 for TMS--end;
EXCEPTION
   WHEN OTHERS
   THEN
      res := 'NO DATA(EC) ';
END;
-- ITDB20101011001 Added by tangyanjun on 2010/10/6 -??EPD3 PTH INPUT ????SN ???ID??????- END