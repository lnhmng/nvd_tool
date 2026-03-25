PROCEDURE       sp_sap_select_dl_failed_pk (
   i_plant_id        IN       VARCHAR2,
   i_function_name   IN       VARCHAR2,
   i_pk_type         IN       VARCHAR2,
   o_pk_set          OUT      sys_refcursor
)
IS
BEGIN
   OPEN o_pk_set FOR
      SELECT pk
        FROM erp_d_sap_dl_failed_pk
       WHERE plant_id = i_plant_id
         AND function_name = i_function_name
         AND pk_type = i_pk_type
         AND closed = '0'
         AND failed_count <= 1000;
EXCEPTION
   WHEN OTHERS
   THEN
      NULL;
END;
