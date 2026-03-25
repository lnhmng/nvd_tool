PROCEDURE             SP_GET_DATA_G1
AS
   v_sn          VARCHAR2 (100);  

   v_res          VARCHAR2 (100);
   v_start_date   VARCHAR (20);
   v_start_time   VARCHAR (20);
   v_end_date     VARCHAR (20);
   v_end_time     VARCHAR (20);
   v_now_date     VARCHAR (20);
   v_desc         VARCHAR2 (100);
   v_count        NUMBER (2, 0);
   v_mo_count     NUMBER (2, 0);
   ex             EXCEPTION;



   CURSOR snlist
    IS

       SELECT SERIAL_NUMBER FROM SFISM4.R_WIP_TRACKING_T 
         WHERE model_name LIKE '150%' and GROUP_NAME='P_VI' AND error_flag='0' AND in_station_time >=
                 TO_DATE (v_start_time,'YYYY/MM/DD HH24:MI:SS')
             AND in_station_time <
                 TO_DATE (v_end_time,'YYYY/MM/DD HH24:MI:SS');


BEGIN
   v_res := 'Get start_date error!';

   BEGIN
      SELECT TRIM (vr_value)
        INTO v_start_date
        FROM sfis1.C_PARAMETER_INI
       WHERE     PRG_NAME = 'NVD_F20_G1'
             AND vr_class = 'NVD'
             AND VR_ITEM = 'NVD_F20_G1'
             AND vr_name = 'SP_GET_DATA_G1';

      IF v_start_date || 'A' = 'A'
      THEN
         RAISE ex;
      END IF;

     --  SELECT TO_CHAR (TO_DATE (vr_value, 'YYYY/MM/DD HH24:MI:SS')+1, 'YYYYMMDD')
     --  INTO v_start_date
     --  FROM sfis1.C_PARAMETER_INI
     --  WHERE     PRG_NAME = 'NVD_F20_G1'
      --       AND vr_class = 'NVD'
      --       AND VR_ITEM = 'NVD_F20_G1'
      --       AND vr_name = 'SP_GET_DATA_G1';

   EXCEPTION
      WHEN OTHERS
      THEN
         DELETE FROM sfis1.C_PARAMETER_INI
               WHERE     PRG_NAME = 'NVD_F20_G1'
                     AND vr_class = 'NVD'
                     AND VR_ITEM = 'NVD_F20_G1'
                     AND vr_name = 'SP_GET_DATA_G1';

         SELECT TO_CHAR (SYSDATE, 'YYYYMMDD')
           INTO v_start_date
           FROM DUAL;

         INSERT INTO sfis1.C_PARAMETER_INI (PRG_NAME,
                                            vr_class,
                                            VR_ITEM,
                                            vr_name,
                                            vr_value,
                                            LAST_MODIFY_DATE)
              VALUES ('NVD_F20_G1',
                      'NVD',
                      'NVD_F20_G1',
                      'SP_GET_DATA_G1',
                      v_start_date,
                      SYSDATE);
   END;

    SELECT VR_DESC
    INTO v_desc
    FROM sfis1.C_PARAMETER_INI
    WHERE     PRG_NAME = 'NVD_F20_G1'
          AND vr_class = 'NVD'
          AND VR_ITEM = 'NVD_F20_G1'
          AND vr_name = 'SP_GET_DATA_G1';

    IF v_desc <> 'OK'
          THEN
            RAISE ex;
    END IF;

   SELECT TO_CHAR (SYSDATE, 'YYYY/MM/DD HH24:MI:SS') INTO v_now_date FROM DUAL;

   IF TO_DATE (v_start_date, 'YYYY/MM/DD HH24:MI:SS') >
         TO_DATE (v_now_date, 'YYYY/MM/DD HH24:MI:SS')
   THEN
      v_res := 'DATE ERROR';
      RETURN;
   END IF;


   v_end_time :=TO_CHAR (SYSDATE, 'YYYY/MM/DD HH24:MI:SS');


   v_start_time := TO_CHAR (TO_DATE (v_start_date, 'YYYY/MM/DD HH24:MI:SS'), 'YYYY/MM/DD HH24:MI:SS');


      FOR SNINFO IN snlist
        LOOP
          v_sn:=SNINFO.SERIAL_NUMBER;    

            SELECT COUNT(SERIAL_NUMBER) into v_count FROM SFISM4.R_WIP_TRACKING_T@G1INPUT where serial_number=v_sn;

               if v_count<= 0 THEN                

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
                WHERE SERIAL_NUMBER=v_sn;

              END IF;


              SELECT COUNT(MO_number) into v_mo_count FROM SFISM4.R_MO_BASE_T@G1INPUT where MO_NUMBER IN (SELECT MO_NUMBER FROM SFISM4.R_WIP_TRACKING_T@G1INPUT WHERE 

               SERIAL_NUMBER=v_sn);

               if v_mo_count<= 0 THEN                

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
                  WHERE MO_NUMBER IN (SELECT MO_NUMBER FROM SFISM4.R_WIP_TRACKING_T WHERE               
                  SERIAL_NUMBER=v_sn);


              END IF; 


        END LOOP; 


   UPDATE sfis1.C_PARAMETER_INI
    --  SET vr_value = v_end_date, LAST_MODIFY_DATE = SYSDATE,vr_desc='OK'
     SET vr_value = v_end_time, LAST_MODIFY_DATE = SYSDATE,vr_desc='OK'
    WHERE     PRG_NAME = 'NVD_F20_G1'
          AND vr_class = 'NVD'
          AND VR_ITEM = 'NVD_F20_G1'
          AND vr_name = 'SP_GET_DATA_G1';

   COMMIT;
EXCEPTION
   WHEN OTHERS
   THEN
      rollback;
      UPDATE sfis1.C_PARAMETER_INI
         SET VR_DESC = v_res, LAST_MODIFY_DATE = SYSDATE
       WHERE     PRG_NAME = 'NVD_F20_G1'
             AND vr_class = 'NVD'
             AND VR_ITEM = 'NVD_F20_G1'
             AND vr_name = 'SP_GET_DATA_G1';
END;