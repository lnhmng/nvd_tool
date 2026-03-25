PROCEDURE                   CHECK_PN (
   DATA        IN       VARCHAR2,
   RES         OUT      VARCHAR2)
IS
   M_QTY            NUMBER;
   E_ERROR          EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO M_QTY FROM SFIS1.c_model_desc_t
    WHERE MODEL_NAME= DATA;
    IF M_QTY <1 THEN
    RES :='NO PN(MODEL NAME)';
    RAISE E_ERROR;
    END IF;

  RES :='OK';
exception  
   when E_ERROR then NULL;
   WHEN OTHERS THEN 
   RES:='OTHER ERROR';
END;