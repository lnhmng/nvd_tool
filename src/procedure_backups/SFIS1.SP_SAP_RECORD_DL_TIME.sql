PROCEDURE       sp_sap_record_dl_time (
   i_function_name   IN       VARCHAR2,
   i_function_id     IN       VARCHAR2,
   i_plant_id        IN       VARCHAR2,
   i_last_dl_time    IN       DATE,
   i_op_id           IN       VARCHAR2,
   o_error_detail    OUT      VARCHAR2
)
IS
   v_record_count   INTEGER;
BEGIN
   o_error_detail := '';

   SELECT COUNT (0)
     INTO v_record_count
     FROM erp_d_sap_last_date
    WHERE function_name = i_function_name
      AND function_id = i_function_id
      AND log_system = 'SAP'
      AND plant_id = i_plant_id;

   IF v_record_count = 0
   THEN
      o_error_detail :=
            'Fail to insert into erp_d_sap_last_date (function_name, function_id, log_system, plant_id,
                   last_date
                  )
           VALUES ('
         || i_function_name
         || ', '
         || i_function_id
         || ', SAP, '
         || i_plant_id
         || ','
         || i_last_dl_time
         || '
                  )';

      INSERT INTO erp_d_sap_last_date
                  (function_name, function_id, log_system, plant_id,
                   last_date, updater
                  )
           VALUES (i_function_name, i_function_id, 'SAP', i_plant_id,
                   i_last_dl_time, i_op_id
                  );
   ELSE
      o_error_detail :=
            'Fail to update erp_d_sap_last_date
         set last_date = '
         || i_last_dl_time
         || '
       where function_name = '
         || i_function_name
         || '
         and function_id = '
         || i_function_id
         || '
         and log_system = SAP
         and plant_id = '
         || i_plant_id;

      UPDATE erp_d_sap_last_date
         SET last_date = i_last_dl_time
       WHERE function_name = i_function_name
         AND function_id = i_function_id
         AND log_system = 'SAP'
         AND plant_id = i_plant_id;
   END IF;

   o_error_detail := '';
EXCEPTION
   WHEN OTHERS
   THEN
      o_error_detail :=
         'SP_SAP_RECORD_DL_TIME: ' || o_error_detail || '[' || SQLERRM || ']';
END;
