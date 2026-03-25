PROCEDURE       check_diags_version_t (
   sn        IN       VARCHAR2,
   diag      IN       VARCHAR2,
   bios      IN       VARCHAR2,
   mygroup   IN       VARCHAR2,
   res       OUT      VARCHAR2
)
IS
   tmpvar           NUMBER;
   count1           NUMBER;
   count2           NUMBER;
   count3           NUMBER;
   c_groupname      VARCHAR2 (16);
   c_specialroute   NUMBER;
   c_diag           VARCHAR2 (100);
   e_null           EXCEPTION;
   c_model_name     VARCHAR2 (25);
   c_bios           VARCHAR2 (25);
   p_diag           VARCHAR2 (100);
   v_diag           VARCHAR2 (100);
/****************** ************************************************************
   NAME:       check_diags_version_t
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
 ---------  ----------  ---------------  ------------------------------------
   1.0        2011/8/30     Derrick zhou     Created this procedure. for check diags

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     check_diags_version_t
      Sysdate:         2011/8/30
      Date and Time:   2011/8/30, 奻敁 09:22:28, and 2011/8/30 奻敁 09:22:28
      Username:         (set in TOAD Options, Procedure Editor)
      Table Name:       (set in the "New PL/SQL Object" dialog)

******************************************************************************/
BEGIN
   tmpvar := 0;
   c_groupname := mygroup;
   c_bios := bios;
   v_diag := diag ;

   SELECT special_route, model_name
     INTO c_specialroute, c_model_name
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = sn;

   SELECT COUNT (0)
     INTO count1
     FROM web.c_diag_config_t
    WHERE group_name = c_groupname
      AND model_name = c_model_name
      AND bios = TRIM (c_bios);

----------------------------CHECK BY MODEL_NAME,BIOS,GROUP_NAME
   IF count1 > 0
   THEN
      SELECT diag
        INTO c_diag
        FROM web.c_diag_config_t
       WHERE group_name = c_groupname
         AND bios = TRIM (c_bios)
         AND model_name = c_model_name;

      tmpvar := INSTR (c_diag, v_diag);

      IF tmpvar < 1
      THEN
         res := 'ERROR1:diag not match';
         RAISE e_null;
      ELSE
         res := 'OK';
      END IF;
   ELSE
      ------------ FOR CHECK  ONLY  BY MODEL_NAME -------------------
      SELECT COUNT (0)
        INTO count3
        FROM web.c_diag_config_t
       WHERE group_name = '0' AND bios = '0' AND model_name = c_model_name;

      IF count3 > 0
      THEN
         SELECT diag
           INTO p_diag
           FROM web.c_diag_config_t
          WHERE group_name = '0' AND bios = '0' AND model_name = c_model_name;

         tmpvar := INSTR (p_diag, v_diag);

         IF tmpvar < 1
         THEN
            res := 'ERROR2:diag not match';
            RAISE e_null;
         ELSE
            res := 'OK';
         END IF;
      ELSE
         res := 'OK';
      END IF;
   END IF;
EXCEPTION
   WHEN e_null
   THEN
      NULL;
   WHEN OTHERS
   THEN
      -- Consider logging the error and then re-raise
      res := 'ERROR:sfis1.check_diags_version_t' || '\n' || '**END**';
END;