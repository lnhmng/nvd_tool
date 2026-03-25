PROCEDURE       sp_sap_sel_plantcodes (
   o_plants OUT SYS_REFCURSOR
)
IS

BEGIN

   OPEN o_plants FOR
      select plant_id
      from SFIS1.WIP_S_PLANT
      where active_flag = 'Y';

EXCEPTION
   WHEN OTHERS
   THEN
      OPEN o_plants FOR
         SELECT NULL
           FROM DUAL
          WHERE 0 = 1;
END;