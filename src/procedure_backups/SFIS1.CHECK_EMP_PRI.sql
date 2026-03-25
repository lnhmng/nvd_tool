PROCEDURE       CHECK_EMP_PRI (i_emp   IN     VARCHAR2,
                                                 i_pwd   IN     VARCHAR2,
                                                 o_res      OUT VARCHAR2)
IS
   C_EMP      VARCHAR2 (25);
   v_length   VARCHAR2 (25);
   v_char     VARCHAR2 (25);
   v_flag     BOOLEAN;
   v_count    NUMBER;
   RES        VARCHAR2 (50);
BEGIN
   SELECT COUNT (EMP_NO)
     INTO v_count
     FROM SFIS1.C_EMP_DESC_T
    WHERE EMP_NO = i_emp AND ROWNUM = 1;

   IF v_count = 0
   THEN
      --o_res := 'ERROR - unknown user';
      o_res := 'User was not found in the system';
      RETURN;
   END IF;


   SELECT COUNT (EMP_NO)
     INTO v_count
     FROM SFIS1.C_EMP_DESC_T
    WHERE EMP_NO = i_emp AND EMP_PASSWORD = i_pwd AND ROWNUM = 1;

   IF v_count = 0
   THEN
      --o_res := 'ERROR - user`s password is not correct';
      o_res := 'User`s password is not correct';
      RETURN;
   END IF;


   SELECT COUNT (EMP_NO)
     INTO v_count
     FROM SFIS1.C_EMP_DESC_T
    WHERE     EMP_NO = i_emp
          AND EMP_PASSWORD = i_pwd
          AND STATION_NAME = 'PLMS'
          AND ROWNUM = 1;

   IF v_count = 0
   THEN
      --o_res := 'ERROR - the user is not allowed to report results';
      o_res := 'User is not approved to run at NV-Mellanox production line';
      RETURN;
   END IF;


   o_res := 'OK';   


EXCEPTION
   WHEN OTHERS
   THEN
      o_res := 'CHECK_EMP_PRI ERROR';
END;
