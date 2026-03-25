PROCEDURE       CHECK_OBA_NEW(DATA IN VARCHAR2,EMP IN VARCHAR2,RES OUT VARCHAR2) AS 
    cou  VARCHAR2(25);
    snnum int;
    statu VARCHAR2(25);
    sn  VARCHAR2(25);
    errorQty int;
   C_TargetQty INT;
   C_CheckNum INT;
    E_ERROR     EXCEPTION;
    type cur_type is ref cursor;
    sn_cur  cur_type; 
BEGIN
   --按NVD流程，DFMS之前不能再按棧板號抽檢
    select count(*) into snnum from SFISM4.R_WIP_TRACKING_T where pallet_no=data and rownum=1;
    if(snnum<=0) then
        res:='ERROR:棧板號:'||DATA||'不存在,請確認';
        raise E_ERROR;
    end if;
   
    --檢查路由
    open sn_cur for select distinct serial_number from SFISM4.R_WIP_TRACKING_T where PALLET_NO=DATA;
    loop
                fetch sn_cur into sn;
                exit when sn_cur%notfound;
                    CHECK_ROUTE('','OBA',sn,res);
                    IF res!='OK' THEN
                        res:='產品'||sn||' ERROR:'||res;
                        raise E_ERROR;
                    END IF;    
    end loop;
     
    select count(*) into cou  from SFISM4.R_WIP_TRACKING_T where PALLET_NO=data and (error_flag=1  or fail_qty=1) AND rownum=1;
    if(cou>=1) then
      
        res:='ERROR:棧板號'||DATA|| '存在fail sn,請確認';
        raise E_ERROR;
    end if;
            
    --檢查抽檢
     select count(*) into errorQty from SFISM4.oba_sample_detail where serial_number in(
                select distinct serial_number from SFISM4.R_WIP_TRACKING_T where pallet_no=DATA
            ) and status='1' and serial_number not in(
                 select serial_number  from SFISM4.oba_sample_detail where serial_number in(
                select distinct serial_number from SFISM4.R_WIP_TRACKING_T where pallet_no=DATA
                ) and status='0'
            );
           
         if(errorQty<=0) then
            null;
         else
            res:='ERR:棧板#'||DATA||'#中有Fail產品還未抽檢PASS!';
            raise E_ERROR;
         end if;
         
      
     --返回抽檢情況
    select count(DISTINCT serial_number) into snnum from SFISM4.oba_sample_detail where serial_number in(
                select distinct serial_number from SFISM4.R_WIP_TRACKING_T where pallet_no=DATA
            );
    SELECT COUNT(*) INTO  C_TargetQty FROM   SFISM4.R_WIP_TRACKING_T where pallet_no=DATA;
                            if(C_TargetQty between 1 and 125)
                             then C_CheckNum:=C_TargetQty;
                            elsif (C_TargetQty between 125 and 3200)
                             then C_CheckNum:=125;
                            elsif (C_TargetQty between 3201 and 10000)
                             then C_CheckNum:=192;
                            elsif (C_TargetQty between 10001 and 150000)
                             then C_CheckNum:=294;
                            elsif (C_TargetQty between 150001 and 500000)
                             then C_CheckNum:=345;
                            else
                               C_CheckNum:=435;  
                            end if;
                            
     if(snnum<C_CheckNum) THEN
       res:='OK#'||DATA||'#'||C_TargetQty||'#'||C_CheckNum||'#'||snnum;
     ELSE
         if(errorQty<=0) then
            select count(*) into cou from SFISM4.oba_sample_detail where serial_number=DATA;
                   IF(cou<=0) THEN
                        insert into SFISM4.OBA_SAMPLE_DETAIL (SERIAL_NUMBER,MODEL_NAME,MO_NUMBER,STATUS,ERROR_CODE,DESCRIPTION,location,EMP_NO,TIME,event_pass) 
                        SELECT PALLET_NO,MODEL_NAME,MO_NUMBER,'0' as status ,'' as ERROR_CODE,C_CheckNum||'#'||snnum as DESCRIPTION,'' as location,emp as emp_no,sysdate,1
                        from SFISM4.R_WIP_TRACKING_T where pallet_NO=DATA AND rownum=1;
                        
                        --並且過站
                        UPDATE sfism4.r_wip_tracking_t
                        SET section_name='OBA',group_name='OBA',station_name='OBA1',in_station_time = sysdate,PASS_QTY=1,ERROR_FLAG=0,FAIL_QTY=0
                        WHERE pallet_no=DATA;
                        
                        update  SFISM4.OBA_SAMPLE_DETAIL set event_pass=1 where serial_number in( select distinct serial_number from SFISM4.R_WIP_TRACKING_T where PALLET_NO=DATA);
                   END IF;
         end if;   
        res:='OK#'||DATA||'#'||C_TargetQty||'#'||C_CheckNum||'#'||snnum;
     end if;
     
EXCEPTION
     when E_ERROR
        then
        NULL;
     WHEN OTHERS THEN 
         res :=  SQLERRM;
END;