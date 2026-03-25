PROCEDURE                         CHECK_DIAGS_VERSION_ALL (
   DATA   IN       VARCHAR2,
   res    OUT      VARCHAR2
)
AS
   p_diag         VARCHAR2 (50);
   v_diag         VARCHAR2 (50);
   v_model_name   VARCHAR2 (25);
   v_route        VARCHAR2 (25);
   v_group        VARCHAR2 (25);
   tmpvar         NUMBER;
   count1         NUMBER;
   count2         NUMBER;
   v_date         DATE;
   e_null         EXCEPTION;

   CURSOR all_diag
   IS
      SELECT   group_name, MAX (create_dt)
          FROM sfism4.r_link_t
         WHERE serial_number = DATA AND flag = 'DIAG'
      GROUP BY group_name;
BEGIN
   SELECT model_name, special_route
     INTO v_model_name, v_route
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = DATA;
    
     SELECT count(*)
     INTO count1
     FROM web.c_diag_config_t
    WHERE group_name = '0' AND bios = '0' AND model_name = v_model_name;
    
    if count1>0 then
    
   SELECT diag
     INTO p_diag
     FROM web.c_diag_config_t
    WHERE group_name = '0' AND bios = '0' AND model_name = v_model_name;
    select count(*)  into count2  from sfism4.r_link_t  where serial_number = DATA and flag = 'DIAG';
    
    if  count2<1 then
     
      res:='no flashrom diags ' ;
      RAISE e_null;
      
    end if;

   OPEN all_diag;

   LOOP
      FETCH all_diag
       INTO v_group, v_date;
       
        EXIT WHEN all_diag%NOTFOUND;
       

      SELECT key_value
        INTO v_diag
        FROM sfism4.r_link_t
       WHERE create_dt = v_date
         AND group_name = v_group
         AND flag = 'DIAG'
         AND serial_number = DATA;

      tmpvar := INSTR (v_diag, p_diag);

      IF tmpvar < 1
      THEN
         res := v_group || ' ' || ':ERROR2:diag not match';
         RAISE e_null;
      ELSE
         res := 'OK';
      END IF;
      
     

   END LOOP;

   CLOSE all_diag;
   
  else
   res:='OK';
 
  end if;
EXCEPTION
   WHEN e_null
   THEN
      NULL;
   WHEN OTHERS
   THEN
      res := 'ERROR:sfis1.check_diags_version_all' || '\n' || '**END**';
END;