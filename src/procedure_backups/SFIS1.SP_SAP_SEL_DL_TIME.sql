PROCEDURE       sp_sap_sel_dl_time (
   i_function_name   IN       VARCHAR2,
   i_function_id     IN       VARCHAR2,
   i_plant_id        IN       VARCHAR2,
   o_last_dl_time    OUT      DATE
)
IS
   v_str_date   VARCHAR2 (40);
BEGIN
   o_last_dl_time := to_date('18991230 000000', 'YYYYMMDD HH24MISS');

   SELECT last_date
     INTO o_last_dl_time
     FROM erp_d_sap_last_date
    WHERE function_name = i_function_name
      AND function_id = i_function_id
      AND log_system = 'SAP'
      AND plant_id = i_plant_id;
EXCEPTION
   WHEN OTHERS
   THEN
      NULL;
END;
