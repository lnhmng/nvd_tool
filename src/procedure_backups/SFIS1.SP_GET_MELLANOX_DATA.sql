PROCEDURE                                                       sp_get_mellanox_data
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
  --  SELECT DISTINCT C.SERIAL_NUMBER FROM
  --  SFISM4.R_SHIPPING_T A,
  --  SFISM4.R_SHIP_detail_T B,
  --  SFISM4.R_WIP_TRACKING_T C,
  --  SFIS1.C_MODEL_DESC_T D
  --  WHERE A.PO_NUMBER=B.DN_NO AND 
  --  B.PALLET_NO=C.PALLET_NO AND
  --  C.MODEL_NAME=D.MODEL_NAME AND 
  --  A.CUSTOMER='MELLANOX' AND 
  --  A.PO_NUMBER=v_dn ORDER BY C.SERIAL_NUMBER;

   -- PO_NUMBER='2010000131'

    SELECT DISTINCT C.SERIAL_NUMBER FROM
    SFISM4.R_SHIPPING_T A, 
    SFISM4.R_WIP_TRACKING_T C,
    SFIS1.C_MODEL_DESC_T D
    WHERE A.PO_NUMBER=SUBSTR(C.CONTAINER_NO,1,10) AND    
    C.MODEL_NAME=D.MODEL_NAME AND C.VERSION_CODE=D.REV AND
    A.PO_NUMBER=v_dn ORDER BY C.SERIAL_NUMBER;




BEGIN

    curr_date := SYSDATE; 

    select count(0) INTO v_count from SFISM4.R_SHIPPING_T where PO_NUMBER=v_dn;

    IF v_count>0 then
       select SHIPPING_TIME,VEHICLE_NO INTO SHIPPINGTIME,v_vehicle_no from SFISM4.R_SHIPPING_T where PO_NUMBER=v_dn;
      --  select DISTINCT(VEHICLE_NO) INTO v_vehicle_no from SFISM4.R_SHIPPING_T where PO_NUMBER=v_dn;

  END IF;


  FOR SNINFO IN snlist
    LOOP
        v_sn:=SNINFO.SERIAL_NUMBER;     


           SP_GET_MELLANOX_SHIP_HEAD_SN(v_sn,v_dn,v_VEHICLE_NO,res);

           IF res <> 'OK' THEN

               res:='Err_B2B_MELL_SHIP_HEAD_T';
               RETURN;

             END IF;



           SFIS1.SP_GET_MELLANOX_SHIP_DETAIL_SN(v_sn,v_dn,v_VEHICLE_NO,res);

           IF res <> 'OK' THEN

              res:='Err_B2B_MELL_SHIP_DETAIL_T';
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