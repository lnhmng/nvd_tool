PROCEDURE             GET_SN_DETAIL_INFO (
   SN     IN       VARCHAR2,
   p_ref  OUT      sys_refcursor
)
IS                             
   V_RES VARCHAR2(25);
BEGIN
    V_RES:='';    

    open p_ref for
    SELECT SERIAL_NUMBER,GROUP_NAME,IN_STATION_TIME,LINE_NAME,EMP_NO FROM     
    SFISM4.R_SN_DETAIL_T WHERE SERIAL_NUMBER= SN;
    
end;