PROCEDURE       compare_snn (
   DATA   IN       VARCHAR2,
   osn    IN       VARCHAR2,
   res    OUT      VARCHAR2
)
IS
   c_id           VARCHAR2 (25);
   c_data         VARCHAR2 (25);
   c_model_name   VARCHAR2 (25);
   count1         NUMBER;
BEGIN
   IF INSTR (osn, ',') > 0
   THEN
      SELECT TRIM (SUBSTR (osn, 1, INSTR (osn, ',') - 1))
        INTO c_data
        FROM DUAL;
   ELSE
      c_data := osn;
   END IF;

   IF osn <> '' OR osn <> 'N/A'
   THEN
      SELECT COUNT (*)
        INTO count1
        FROM sfism4.r_wip_tracking_t
       WHERE serial_number = DATA;

       --IF osn <> '' OR osn <> 'N/A'
      -- THEN
       --SELECT COUNT (*)
         --INTO count1
        -- FROM sfis1.c_parameter_ini
        --WHERE vr_name = c_model_name AND prg_name = '900_VI'
            --  AND vr_class = '900_VI';
      IF count1 > 0
      THEN
         IF DATA = c_data
         THEN
            res := 'OK';
         ELSE
            res := 'SN IS DIFFERENT,PLEASE CHECK!';
         END IF;
      ELSE
         res := 'SN IS DIFFERENT,PLEASE CHECK!!!';
      END IF;
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      res := ' NO SN ';
END;