PROCEDURE                   FAISN (
   SN      IN        VARCHAR2,
   RES       OUT       VARCHAR2)
IS
   FAI_SN       VARCHAR2 (25);
   FAI_ROUTE         VARCHAR2 (25);
   CT   INT;
   e_ERROR      EXCEPTION;         

BEGIN

   SELECT COUNT(*) INTO FAI_SN FROM SFISM4.R_WIP_TRACKING_T WHERE SERIAL_NUMBER=SN;
   IF FAI_SN =0 THEN
       RES:='NO SN/'|| SN;
   ELSE
         
         
          RES :='OK';
   END IF;

   
           

exception
   when others then
      RES:='ERROR,PLS CHECK INPUT';
END;