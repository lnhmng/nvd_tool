PROCEDURE                      check_input_g1
AS
   var_nowtime   DATE;
   var_model     VARCHAR (20);
   serial        VARCHAR (5);

   CURSOR model_name
   IS
      SELECT distinct model_name
        FROM sfism4.r_wip_tracking_t
       WHERE model_name LIKE '150%'
         AND in_station_time >= var_nowtime -60/1440
         AND in_station_time < var_nowtime
         AND GROUP_NAME='P_VI';

   row1          model_name%ROWTYPE;
BEGIN
   var_nowtime := SYSDATE;

   OPEN model_name;

   LOOP
      FETCH model_name
       INTO row1;

      EXIT WHEN model_name%NOTFOUND;

       select serialno,MODEL_NAME into serial,VAR_MODEL from sfism4.r_input_g1_t where model_name=row1.model_name;

       IF LENGTH(SERIAL)>0 
       THEN
             INSERT INTO sfism4.r_wip_tracking_t@g1input(serial_number, section_flag, mo_number, model_name, TYPE,
                   version_code, line_name, section_name, group_name,
                   station_name, LOCATION, station_seq, error_flag,
                   in_station_time, in_line_time, out_line_time, shipping_sn,
                   work_flag, finish_flag, enc_cnt, special_route, pallet_no,
                   container_no, qa_no, qa_result, scrap_flag, next_station,
                   customer_no, work_date, work_section, pass_qty, fail_qty,
                   repass_qty, refail_qty, ecn_pass_qty, ecn_fail_qty,
                   key_part_no, carton_no, warranty_date, bom_no, po_no,
                   emp_no, rework_no, pallet_full_flag, spare_model_name)
              SELECT serial_number, section_flag, mo_number, model_name, TYPE,
                   version_code, line_name, section_name, group_name,
                   station_name, LOCATION, station_seq, error_flag,
                   in_station_time, in_line_time, out_line_time, shipping_sn,
                   work_flag, finish_flag, enc_cnt, special_route, pallet_no,
                   container_no, qa_no, qa_result, scrap_flag, next_station,
                   customer_no, work_date, work_section, pass_qty, fail_qty,
                   repass_qty, refail_qty, ecn_pass_qty, ecn_fail_qty,
                   key_part_no, carton_no, warranty_date, bom_no, po_no,
                   emp_no, rework_no, pallet_full_flag, spare_model_name
              FROM sfism4.r_wip_tracking_t
             WHERE model_name = VAR_MODEL
               AND in_station_time >= var_nowtime -5/24/60
               AND in_station_time < var_nowtime
               AND SUBSTR(SERIAL_NUMBER,1,3)=SERIAL
               AND group_name = 'P_VI'AND error_flag='0' 
               and SERIAL_NUMBER NOT IN(SELECT SERIAL_NUMBER FROM SFISM4.R_WIP_TRACKING_T@G1INPUT WHERE  model_name = VAR_MODEL);

       END IF;
       COMMIT;

   END LOOP;

   CLOSE MODEL_NAME;


   INSERT INTO sfism4.r_mo_base_t@g1input
            (mo_number, mo_type, model_name, version_code, mo_create_date,
             mo_schedule_date, mo_due_date, mo_start_date, mo_target_date,
             mo_close_date, route_code, input_qty, output_qty, turn_out_qty,
             total_scrap_qty, start_sn, end_sn, shipping_start_sn,
             shipping_qty, work_flag, close_flag, default_line, default_group,
             cust_code, order_no, bom_no, master_flag, master_mo, end_group,
             po_no, hw_bom, sw_bom, upc_co, option_desc, key_part_no, sn_rule,
             rework_qty, mo_option, supplier_code)
   SELECT mo_number, mo_type, model_name, version_code, mo_create_date,
          mo_schedule_date, mo_due_date, mo_start_date, mo_target_date,
          mo_close_date, route_code, input_qty, output_qty, turn_out_qty,
          total_scrap_qty, start_sn, end_sn, shipping_start_sn, shipping_qty,
          work_flag, close_flag, default_line, default_group, cust_code,
          order_no, bom_no, master_flag, master_mo, 'SHIPPING' as end_group, po_no, hw_bom,
          sw_bom, upc_co, option_desc, key_part_no, sn_rule, rework_qty,
          mo_option, supplier_code
           FROM sfism4.r_mo_base_t
    WHERE  model_name LIKE '150%'
    AND MO_CREATE_DATE>=TO_DATE('20190101','YYYYMMDD')
      AND mo_number LIKE '0066000%'
       AND mo_number not in (SELECT MO_NUMBER from sfism4.r_mo_base_t@g1input where route_code IN('3172','3407'));
   COMMIT;  
END;