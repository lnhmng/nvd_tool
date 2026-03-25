PROCEDURE 	                                                            check_modelname (ppn IN VARCHAR2, res OUT VARCHAR2)
IS
   c_num   NUMBER;
BEGIN
   SELECT COUNT (*)
     INTO c_num
     FROM c_model_desc_t
    WHERE model_name = ppn;

   IF c_num > 0
   THEN
      res := 'OK';
   ELSE
      res := '????????';
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      res := 'CHECK_MODELNAME??';
      res := res || SUBSTR (SQLERRM, 1, 80);
END;
--Writed by liuyunjiang 2006-06-23.