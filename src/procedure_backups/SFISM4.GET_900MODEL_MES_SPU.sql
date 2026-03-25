PROCEDURE                             get_900model_mes_SPU (
   sn    IN       VARCHAR2,
   o_flag         OUT      VARCHAR2,   
   res   OUT      VARCHAR2
)
IS
   tmpvar        NUMBER;
   v_count1      NUMBER;
   v_count2      NUMBER;
   lp_900model   VARCHAR2 (25);
   c_initsn      VARCHAR2 (25);
   c_count4      NUMBER;
   c_count3      NUMBER;
   c_count2      NUMBER;
   c_count5      NUMBER;
   bios_in900    VARCHAR2 (40);
   c_900model    VARCHAR2 (40);
   ynflag        VARCHAR2 (2);
   e_null        EXCEPTION;
/******************************************************************************
   NAME:       GET_900MODEL_MES
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        2012/7/17   Derrick.Chow       1. Created this procedure.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     GET_900MODEL_MES
      Sysdate:         2012/7/17
      Date and Time:   2012/7/17, 15:22:48, and 2012/7/17 15:22:48
      Username:        Administrator (set in TOAD Options, Procedure Editor)
      Table Name:       (set in the "New PL/SQL Object" dialog)

******************************************************************************/
BEGIN
   o_flag := '-1';
   tmpvar := 0;

   SELECT COUNT (serial_number)
     INTO tmpvar
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = sn;

   IF tmpvar = 0
   THEN
      res := 'NO SN';
      RAISE e_null;
   END IF;

   SELECT COUNT (*)
     INTO c_count5
     FROM sfism4.r_nvbios_comparelist_t
    WHERE serial_number = sn;

   IF c_count5 > 0
   THEN
      SELECT bios_900set, flag, lp_900model
        INTO bios_in900, ynflag, c_900model
        FROM sfism4.r_nvbios_comparelist_t
       WHERE serial_number = sn;
   END IF;

   SELECT COUNT (serial_number)
     INTO v_count1
     FROM sfism4.r_nvbios_model_t
    WHERE serial_number = sn;

   SELECT COUNT (serial_number)
     INTO v_count2
     FROM sfism4.r_nvbios_model_spare_t
    WHERE serial_number = sn;

   IF v_count1 = 0 AND v_count2 = 0
   THEN
      SELECT COUNT (*)
        INTO c_count2
        FROM sfism4.r_sn_link_t
       WHERE new_sn = sn;

      IF c_count2 = 0
      THEN
         res := 0;
         RAISE e_null;
      END IF;

      SELECT old_sn
        INTO c_initsn
        FROM sfism4.r_sn_link_t
       WHERE new_sn = sn;

      SELECT COUNT (*)
        INTO c_count3
        FROM sfism4.r_nvbios_model_t
       WHERE serial_number = c_initsn;

      SELECT COUNT (*)
        INTO c_count4
        FROM sfism4.r_nvbios_model_spare_t
       WHERE serial_number = c_initsn;

      IF c_count3 = 0 AND c_count4 = 0
      THEN
         res := 0;
         RAISE e_null;
      ELSIF c_count3 > 0
      THEN
         SELECT last_model_name
           INTO lp_900model
           FROM sfism4.r_nvbios_model_t
          WHERE serial_number = c_initsn;

         IF lp_900model IS NULL
         THEN
            res := 0;
            RAISE e_null;
         ELSE
            res := lp_900model||'\n'|| BIOS_IN900 ||'\n'||YNFLAG||'\n';
         END IF;
      ELSIF c_count4 > 0
      THEN
         SELECT last_model_name
           INTO lp_900model
           FROM sfism4.r_nvbios_model_spare_t
          WHERE serial_number = c_initsn;

         IF lp_900model IS NULL
         THEN
            res := 0;
            RAISE e_null;
         ELSE
            res := lp_900model||'\n'|| BIOS_IN900 ||'\n'||YNFLAG||'\n';
         END IF;
      END IF;
   ELSE
      IF v_count1 > 0
      THEN
         SELECT last_model_name
           INTO lp_900model
           FROM sfism4.r_nvbios_model_t
          WHERE serial_number = sn;

         IF lp_900model IS NULL
         THEN
            res := 0;
            RAISE e_null;
         ELSE
            res := lp_900model||'\n'|| BIOS_IN900 ||'\n'||YNFLAG||'\n';
         END IF;
      END IF;

      IF v_count2 > 0
      THEN
         SELECT last_model_name
           INTO lp_900model
           FROM sfism4.r_nvbios_model_spare_t
          WHERE serial_number = sn;

         IF lp_900model IS NULL
         THEN
            res := 0;
            RAISE e_null;
         ELSE
            res := lp_900model||'\n'|| BIOS_IN900 ||'\n'||YNFLAG||'\n';
         END IF;
      END IF;
   END IF;
   o_flag := '0';
EXCEPTION
   WHEN NO_DATA_FOUND
   THEN
      NULL;
   WHEN e_null
   THEN
      NULL;
   WHEN OTHERS
   THEN
      -- Consider logging the error and then re-raise
      RAISE;
END get_900model_mes_SPU;