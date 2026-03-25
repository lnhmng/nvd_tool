PROCEDURE                   check_assy_sn (
   DATA      IN       VARCHAR2,
   mygroup   IN       VARCHAR2,
   line      IN       VARCHAR2,
   res       OUT      VARCHAR2
)
IS
     
   c_id  NUMBER;  
  -- c_id            VARCHAR2 (25);
   c_900id         VARCHAR2 (25);
   c_model         VARCHAR (25);
   c_nextgroup     VARCHAR (25);
   p_callres       VARCHAR (25);
   e_error         EXCEPTION;
   c_error         EXCEPTION;
   e_ok            EXCEPTION;
   e_route_error   EXCEPTION;
BEGIN
   SELECT   COUNT (serial_number)
       INTO c_id
       FROM sfism4.r_wip_tracking_t
      WHERE serial_number = DATA;

   IF c_id <= 0
   THEN
      RAISE e_error;
   ELSE
      IF mygroup like 'CHECK_ASSY_%'
      THEN
         INSERT INTO sfis1.c_assy_ontrast_t
              VALUES (DATA, line, mygroup, SYSDATE);
      END IF;

      sfis1.check_route (line, mygroup, DATA, p_callres);

      IF p_callres <> 'OK'
      THEN
         RAISE e_route_error;
      ELSE
         res := p_callres;
      END IF;

    
   END IF;

   res :='OK';
EXCEPTION
   WHEN e_error
   THEN
      res := ' NO SN ';
   WHEN e_route_error
   THEN
      res := p_callres;
   WHEN c_error
   THEN
      res := 'OTHENR ERROR';
END;