PROCEDURE                         sp_get_mellanox_b2b
(
   v_dn        IN       VARCHAR2,
   pono        IN       VARCHAR2,
   res         OUT      VARCHAR2
)
AS
   v_sn          VARCHAR2 (100);
   v_vehicle_no    VARCHAR2(30);
   v_count       INTEGER;
   curr_date     DATE;
   SHIPPINGTIME DATE;

   CURSOR snlist
    IS
   -- SELECT DISTINCT C.SERIAL_NUMBER FROM
   -- SFISM4.R_SHIPPING_T A, 
   -- SFISM4.R_WIP_TRACKING_T C,
   -- SFIS1.C_MODEL_DESC_T D
   -- WHERE A.CONTAINER_NO=C.CONTAINER_NO AND    
   -- C.MODEL_NAME=D.MODEL_NAME AND C.VERSION_CODE=D.REV AND
   -- A.CONTAINER_NO=v_dn ORDER BY C.SERIAL_NUMBER;


    SELECT DISTINCT CARTON_NO FROM SFISM4.R_WIP_TRACKING_T WHERE CONTAINER_NO IN (SELECT CONTAINER_NO FROM SFISM4.R_SHIPPING_T WHERE PO_NUMBER=v_dn) ORDER BY CARTON_NO;

BEGIN

  curr_date := SYSDATE; 


  FOR SNINFO IN snlist
    LOOP
           v_sn:=SNINFO.CARTON_NO;     

           sp_get_mellanox_b2b_detail(v_sn,v_dn,pono,res); 

           IF res <> 'OK' THEN

               res:='Err SFISM4.B2B_D_DETAIL Error';
               RETURN;

             END IF;



    END LOOP;

    COMMIT;
    res:='OK!';


EXCEPTION
   WHEN OTHERS
   THEN
      rollback;

      res:='Err,'||substr(sqlerrm,1,80);


END;