PROCEDURE                                                                              ADD_DA_WITH_MO (
   MO        IN       VARCHAR2,
   DA        IN       VARCHAR2,
   A_GROUP   IN       VARCHAR2,
   EMP       IN       VARCHAR2,
   RES       OUT      VARCHAR2
)
IS 
   HAVE             NUMBER;
   A_COUNT             NUMBER;
   V_SN             varchar(200);
   E_ERROR          EXCEPTION;
   cursor data_cursor
   is 
   select serial_number from sfism4.r_wip_tracking_t where MO_NUMBER= MO;
BEGIN

  SELECT COUNT(*) INTO HAVE FROM SFISM4.r_mo_base_t WHERE MO_NUMBER=MO AND close_flag IN ('2','3');
  IF HAVE<1 THEN
  RES :='NO MO OR MO NOT ONLINE';
  RAISE E_ERROR;
  END IF;

  DELETE SFISM4.r_link_t WHERE SERIAL_NUMBER IN (SELECT SERIAL_NUMBER FROM SFISM4.r_wip_tracking_t WHERE MO_NUMBER= MO) AND group_name=A_GROUP AND FLAG='DA';
  open data_cursor;
  loop
    fetch data_cursor into V_SN;
    exit when data_cursor%notfound;

    Insert into SFISM4.R_LINK_T(SERIAL_NUMBER,KEY_VALUE,AVAILABLE,FLAG,create_by,create_dt,GROUP_NAME)
    VALUES (V_SN,DA,'0','DA',EMP,SYSDATE,A_GROUP);


  END LOOP;
  RES :='Add or update successfully';
exception  
   when E_ERROR then NULL;
   WHEN OTHERS THEN 
   RES:='OTHER ERROR';
END;