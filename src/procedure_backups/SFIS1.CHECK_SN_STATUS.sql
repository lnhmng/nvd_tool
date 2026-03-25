PROCEDURE       CHECK_SN_STATUS( SN IN VARCHAR2,
RES OUT VARCHAR2) IS
V_MODEL_NAME VARCHAR2(25);
V_MO VARCHAR2(25);
V_VERSION_CODE CHAR(2);
V_ROUTE_CODE VARCHAR2(10);
V_CLOSE_FLAG CHAR(1);
V_ERROR CHAR(1);
V_GROUP_NAME VARCHAR2(10);
V_GROUP_NEXT VARCHAR2(10);
P_SN VARCHAR2(25);
P_ROUTE_CODE VARCHAR2(10);
P_GROUP_NAME VARCHAR2(10);
P_GROUP_NEXT VARCHAR2(10);
P_ERROR CHAR(1);
V_SN_QTY CHAR(1);
V_TEMP_QTY CHAR(1);

type n_sn is ref CURSOR;
SN_CURSOR n_sn;
ERR_MES VARCHAR2(255);
RES_OUT VARCHAR2(10);
SN_ERROR EXCEPTION;
ERR_RAISE EXCEPTION;

BEGIN
    select count(*) into V_TEMP_QTY FROM DUAL WHERE EXISTS(SELECT 1 from sfism4.r_wip_kp_detail_t where serial_number=sn and rownum<=1);
    IF(V_TEMP_QTY>0) THEN
        OPEN SN_CURSOR FOR SELECT KP_SN  FROM sfism4.r_wip_kp_detail_t where serial_number=sn;                       
        loop 
             fetch SN_CURSOR into P_SN; 
             exit when SN_CURSOR%NOTFOUND;
             
                SELECT COUNT(*) INTO V_SN_QTY from SFISM4.r_wip_tracking_t WHERE serial_number=P_SN;
               
                if(V_SN_QTY<>1) then
                    ERR_MES:='NO SN 1';
                    RAISE SN_ERROR;
                else  
                    select a.special_route,a.error_flag,a.group_name
                    into P_ROUTE_CODE,P_ERROR,P_GROUP_NAME
                    from SFISM4.r_wip_tracking_t  a,SFISM4.r_mo_base_t b
                    WHERE a.mo_number=b.mo_number
                    and a.serial_number=P_SN;
                      
                    if P_GROUP_NAME not like '%FINISH%' THEN
                         select group_next into P_GROUP_NEXT from sfis1.c_route_control_t where route_code=P_ROUTE_CODE and group_name=P_GROUP_NAME and state_flag=P_ERROR;
                        ERR_MES:=P_SN||'GO-'||P_GROUP_NEXT;
                        RAISE ERR_RAISE;
                    END IF;
                end if; 
        end loop;
        close SN_CURSOR;
         
        --tracking表只有單行記錄，可以使用傳統查法
        SELECT COUNT(*) INTO V_SN_QTY from SFISM4.r_wip_tracking_t WHERE serial_number=sn;
        if(V_SN_QTY<>1) then
            ERR_MES:='NO SN 2';
            RAISE SN_ERROR;
        else 
            select a.special_route,a.error_flag,a.group_name,b.model_name,b.version_code
                    into V_ROUTE_CODE,V_ERROR,V_GROUP_NAME,V_MODEL_NAME,V_VERSION_CODE
                    from SFISM4.r_wip_tracking_t  a,SFISM4.r_mo_base_t b
                    WHERE a.mo_number=b.mo_number
                    and a.serial_number=sn;
        end if;
    else
         --tracking表只有單行記錄，可以使用傳統查法
        SELECT COUNT(*) INTO V_SN_QTY from SFISM4.r_wip_tracking_t WHERE serial_number=sn;
        if(V_SN_QTY<>1) then
             ERR_MES:='NO SN';
             RAISE SN_ERROR;
        end if;
        select a.special_route,a.error_flag,a.group_name,b.model_name,b.version_code
                    into V_ROUTE_CODE,V_ERROR,V_GROUP_NAME,V_MODEL_NAME,V_VERSION_CODE
                    from SFISM4.r_wip_tracking_t  a,SFISM4.r_mo_base_t b
                    WHERE a.mo_number=b.mo_number
                    and a.serial_number=sn;
    END IF;
    
    select group_next into v_GROUP_NEXT from sfis1.c_route_control_t where route_code=V_ROUTE_CODE and group_name=V_GROUP_NAME and state_flag=V_ERROR;
    RES_OUT:='GO-'||v_GROUP_NEXT;
    RES:=SN||'#'||V_MODEL_NAME||'#'||RES_OUT||'#'||V_VERSION_CODE;
  /*
  commit;
  set TRANSACTION READ WRITE name 'tran';
  --H7106691
  update SFISM4.r_bi_hass_full set operator='X2001526'  where mo_number='006600000823-3';
  
  select mo_number into V_MODEL_NAME from  SFISM4.r_bi_hass_full   where mo_number='006600000823-';
  COMMIT;
*/
EXCEPTION
    WHEN SN_ERROR THEN
        RES:=ERR_MES;
    WHEN ERR_RAISE THEN
        RES:=ERR_MES;
    WHEN OTHERS THEN
     ROLLBACK;
   	  RES:='OTHER ERROR V_TEMP_QTY'||V_TEMP_QTY;     
END CHECK_SN_STATUS;