PROCEDURE       sp_sap_close_dl_failed_pk (
   i_plant_id        IN       VARCHAR2,
   i_function_name   IN       VARCHAR2,
   i_pk_type         IN       VARCHAR2,
   i_pk              IN       VARCHAR2,
   o_error_detail    OUT      VARCHAR2
)
IS
BEGIN
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
      SET closed = '1'
    WHERE plant_id = i_plant_id
      AND function_name = i_function_name
      AND pk_type = i_pk_type
      AND pk = i_pk;

   o_error_detail := '';
EXCEPTION
   WHEN OTHERS
   THEN
      o_error_detail :=
            'SP_SAP_CLOSE_DL_FAILED_PK: '
         || o_error_detail
         || '. ['
         || SQLERRM
         || ']';
END;
