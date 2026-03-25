PROCEDURE       sp_sap_record_dl_failed_pk (
   i_plant_id        IN       VARCHAR2,
   i_function_name   IN       VARCHAR2,
   i_pk_type         IN       VARCHAR2,
   i_pk              IN       VARCHAR2,
   o_error_detail    OUT      VARCHAR2
)
IS
   v_record_count   INTEGER;
BEGIN
   SELECT COUNT (0)
     INTO v_record_count
     FROM erp_d_sap_dl_failed_pk
    WHERE plant_id = i_plant_id
      AND function_name = i_function_name
      AND pk_type = i_pk_type
      AND pk = i_pk;

   IF v_record_count <= 0
   THEN
      o_error_detail :=
            'Insert record. plant_id='
         || i_plant_id
         || ',function_name='
         || i_function_name
         || ',pk_type='
         || i_pk_type
         || ',pk='
         || i_pk;

      INSERT INTO erp_d_sap_dl_failed_pk
                  (plant_id, function_name, pk_type, pk
                  )
           VALUES (i_plant_id, i_function_name, i_pk_type, i_pk
                  );
   ELSE
      o_error_detail :=
            'Update record. plant_id='
         || i_plant_id
         || ',function_name='
         || i_function_name
         || ',pk_type='
         || i_pk_type
         || ',pk='
         || i_pk;

      UPDATE erp_d_sap_dl_failed_pk
         SET failed_count = failed_count + 1,
             closed = '0'
       WHERE plant_id = i_plant_id
         AND function_name = i_function_name
         AND pk_type = i_pk_type
         AND pk = i_pk;
   END IF;

   o_error_detail := '';
EXCEPTION
   WHEN OTHERS
   THEN
      o_error_detail :=
            'SP_SAP_RECORD_DL_FAILED_PK: '
         || o_error_detail
         || '. ['
         || SQLERRM
         || ']';
END;
