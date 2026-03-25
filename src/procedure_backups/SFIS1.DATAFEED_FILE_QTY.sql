PROCEDURE               DATAFEED_FILE_QTY
is
    i int;
    total_count int;
     temp_count int;
    da_eco_count int;
    process_count int;
    fa_count int;
    material_count int;
    ship_count int;
    order_count int;
    trandate VARCHAR(50);
    start_time date;
    end_time date;
    c_count int;
    res    VARCHAR2(50);

      cursor file_time is 
             select date_time,da_qty,process_qty,order_qty,material_qty,ship_qty,fa_qty,total_qty from  sfis1.c_datafeed_dashboard_t where total_qty<'288';

BEGIN
    i:=1;
    for i in 1..7 loop
    start_time:= to_char(TRUNC(SYSDATE-i),'yyyy-mm-dd') ;
    end_time:=TRUNC(SYSDATE-i-1);
    trandate:=to_char(TRUNC(SYSDATE-i),'yyyy-mm-dd') ;
    
   SELECT count(start_time) into total_count   FROM SFISM4.r_datafeed_log_t WHERE TRAN_TYPE='UPLOAD SFC FILES' AND 
         FILEtype='FXLH' AND TRAN_dATE>= TRUNC(SYSDATE-i-1) and TRAN_dATE< TRUNC(SYSDATE-i)  ;       
    SELECT count(start_time)  into da_eco_count FROM SFISM4.r_datafeed_log_t WHERE TRAN_TYPE='UPLOAD SFC FILES' AND 
         FILEtype='FXLH' AND TRAN_dATE>= TRUNC(SYSDATE-i-1) and TRAN_dATE< TRUNC(SYSDATE-i)  and UPPER(Filename) like '%DA%' ;
    SELECT count(start_time) into process_count  FROM SFISM4.r_datafeed_log_t WHERE TRAN_TYPE='UPLOAD SFC FILES' AND 
         FILEtype='FXLH' AND TRAN_dATE>= TRUNC(SYSDATE-i-1) and TRAN_dATE< TRUNC(SYSDATE-i)    and upper(Filename) like '%PROCESS%' ;
    SELECT count(start_time) into material_count  FROM SFISM4.r_datafeed_log_t WHERE TRAN_TYPE='UPLOAD SFC FILES' AND 
         FILEtype='FXLH' AND TRAN_dATE>= TRUNC(SYSDATE-i-1) and TRAN_dATE< TRUNC(SYSDATE-i) and upper(Filename) like '%MATERIAL%' ;
    SELECT count(start_time) into  order_count  FROM SFISM4.r_datafeed_log_t WHERE TRAN_TYPE='UPLOAD SFC FILES' AND 
         FILEtype='FXLH' AND TRAN_dATE>= TRUNC(SYSDATE-i-1) and TRAN_dATE< TRUNC(SYSDATE-i) and upper(Filename) like '%ORDER%' ;
    SELECT count(start_time) into fa_count  FROM SFISM4.r_datafeed_log_t WHERE TRAN_TYPE='UPLOAD SFC FILES' AND 
         FILEtype='FXLH' AND TRAN_dATE>= TRUNC(SYSDATE-i-1) and TRAN_dATE< TRUNC(SYSDATE-i) and upper(Filename) like '%FA%' ;
    SELECT count(start_time)  into ship_count  FROM SFISM4.R_DATAFEED_LOG_T  WHERE TRAN_TYPE='UPLOAD SFC FILES' AND 
         FILEtype='FXLH' AND TRAN_dATE>= TRUNC(SYSDATE-i-1) and TRAN_dATE< TRUNC(SYSDATE-i) and upper(Filename) like '%SHIP%' ;        
      res := 'insert c_datafeed_t error';
     select NVL(sum(total_qty),0) into c_count from  c_datafeed_dashboard_t where date_time=trandate ;
     if c_count=288
     then
            CONTINUE;
    elsif c_count>=0
    then
        delete from c_datafeed_dashboard_t where date_time=trandate ;
        INSERT INTO c_datafeed_dashboard_t (date_time,da_qty,process_qty,order_qty,material_qty,ship_qty,fa_qty,total_qty) 
        values( trandate,da_eco_count,process_count,order_count,material_count,ship_count,fa_count,total_count);
        commit;
    else
        INSERT INTO c_datafeed_dashboard_t (date_time,da_qty,process_qty,order_qty,material_qty,ship_qty,fa_qty,total_qty) 
        values( trandate,da_eco_count,process_count,order_count,material_count,ship_count,fa_count,total_count);
        commit;
    end if;
    end loop; 
     res := 'loop c_dashboard error';
    open file_time;
    loop 
    fetch file_time into  trandate,da_eco_count,process_count,order_count,material_count,ship_count,fa_count,total_count;
    exit when file_time%notfound;
         SELECT count(start_time) into temp_count   FROM SFISM4.r_datafeed_log_t WHERE TRAN_TYPE='UPLOAD SFC FILES' AND 
         FILEtype='FXLH' AND   to_char(tran_date,'yyyy-mm-dd')=trandate ;     
         if temp_count=288
         then
                update c_datafeed_dashboard_t set da_qty=48,process_qty=48,order_qty=48,material_qty=48,ship_qty=48,fa_qty=48,total_qty=288  where date_time=trandate;
                commit;
        end if;    
                    
    end loop;
   

    commit;

EXCEPTION
    WHEN OTHERS THEN
        insert into SMTINFO.R_DML_COUNT(result,count,end_time) values(res,5,sysdate); 
END;