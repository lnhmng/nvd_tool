PROCEDURE             CHECK_900MODEL_PAC (
   SN       IN     VARCHAR2,
   LP_900   IN     VARCHAR2,
   RES         OUT VARCHAR2)
IS
   tmpVar        NUMBER;
   C_COUNT2      NUMBER;
   C_COUNT3      NUMBER;
   C_COUNT4      NUMBER;
   C_INITSN      VARCHAR2 (25);
   C_OLDSN       VARCHAR2 (25);
   C_LASTMODEL   VARCHAR2 (25);

   e_NULL        EXCEPTION;
/******************************************************************************
   NAME:       CHECK_900MODEL_PAC
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        2012/7/24   Derrick Chow        1. Created this procedure.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     CHECK_900MODEL_PAC
      Sysdate:         2012/7/24
      Date and Time:   2012/7/24, ???? 04:37:45, and 2012/7/24 ???? 04:37:45
      Username:        Administrator (set in TOAD Options, Procedure Editor)
      Table Name:       (set in the "New PL/SQL Object" dialog)

******************************************************************************/
BEGIN
   tmpVar := 0;

   IF SUBSTR (LP_900, 0, 3) = '900'
   THEN
      SELECT COUNT (last_model_name)
        INTO tmpVar
        FROM sfism4.r_nvbios_model_t
       WHERE last_model_name = LP_900 AND serial_number = SN;

      IF tmpVar = 0
      THEN
         SELECT COUNT (*)
           INTO C_COUNT2
           FROM SFISM4.R_SN_LINK_T
          WHERE NEW_SN = SN;

         IF C_COUNT2 = 0
         THEN
            RES := 'sfis1.CHECK_900MODEL_PAC ERROR1:900 MODEL_NAME ERROR';
            RAISE e_null;
         END IF;

         SELECT INIT_SN, OLD_SN
           INTO C_INITSN, C_OLDSN
           FROM SFISM4.R_SN_LINK_T
          WHERE NEW_SN = SN;

         SELECT COUNT (*)
           INTO C_COUNT4
           FROM SFISM4.R_NVBIOS_MODEL_T
          WHERE SERIAL_NUMBER = C_OLDSN;

         IF C_COUNT4  > 0
         THEN
            SELECT last_model_name
              INTO C_LASTMODEL
              FROM SFISM4.R_NVBIOS_MODEL_T
             WHERE SERIAL_NUMBER = C_OLDSN;

            IF C_LASTMODEL = LP_900
            THEN
               RES := 'OK';
            ELSE
               RES := 'sfis1.CHECK_900MODEL_PAC ERROR2:900 MODEL_NAME ERROR';
               RAISE e_null;
            END IF;
         ELSE
            SELECT COUNT (*)
              INTO C_COUNT3
              FROM SFISM4.R_NVBIOS_MODEL_T
             WHERE SERIAL_NUMBER = C_INITSN AND last_model_name = LP_900;

            IF C_COUNT3 > 0
            THEN
               res := 'OK';
            ELSE
               RES := 'sfis1.CHECK_900MODEL_PAC ERROR3:900 MODEL_NAME ERROR';
               RAISE e_null;
            END IF;
         END IF;
      ELSE
         RES := 'OK';
      END IF;
   ELSE
      RES := 'OK';
   END IF;
EXCEPTION
   WHEN NO_DATA_FOUND
   THEN
      NULL;
   WHEN e_NULL
   THEN
      NULL;
   WHEN OTHERS
   THEN
      -- Consider logging the error and then re-raise
      RAISE;
END CHECK_900MODEL_PAC;