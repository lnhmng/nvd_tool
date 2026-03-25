PROCEDURE             P_Sync_r_sn_tracking_log_t (
   i_serial_number   IN     VARCHAR2,
   i_IN_STATION_TIME IN     VARCHAR2,
   i_MACHINE_CODE  IN       VARCHAR2,
   i_FEEDER_FLAG  IN        VARCHAR2,
   i_SECTION_NAME  IN       VARCHAR2,
   i_PRODUCT_NO  IN         VARCHAR2,
   o_res        OUT         VARCHAR2
) 
IS
  -- p_serial_number   VARCHAR2 (30);
   p_count     NUMBER;


BEGIN



  o_res := 'THIS SERIAL_NUMBER IS EXIST，CHECK PLEASE';

   select count(*) into p_count from smtinfo.r_sn_tracking_log_t where SERIAL_NUMBER=i_serial_number and MACHINE_CODE=i_machine_code;

     IF p_count <=0  THEN

          o_res := 'Insert  smtinfo.r_sn_tracking_log_t error';

          Insert into smtinfo.r_sn_tracking_log_t
           (SERIAL_NUMBER,IN_STATION_TIME,MACHINE_CODE,FEEDER_FLAG,SECTION_NAME,PRODUCT_NO)                                 
            Values
           (i_serial_number,TO_DATE(i_IN_STATION_TIME,'YYYYMMDDHH24MISS'),i_MACHINE_CODE,i_FEEDER_FLAG,i_SECTION_NAME,i_PRODUCT_NO);

        commit;    
            
      END IF; 


     o_res:='OK';

EXCEPTION
   WHEN OTHERS
   THEN
      o_res := o_res;
      ROLLBACK;
END;