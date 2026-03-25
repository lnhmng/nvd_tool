PROCEDURE BI_HASS (c_model_name IN VARCHAR2,v_mo_number IN VARCHAR2,V_SN IN VARCHAR2,
RES OUT VARCHAR2) IS
v_batch number(4);
v_ic_marketing  VARCHAR2(25);
v_sn_batch number(4);
v_sample_sn number(3);
v_sample_qty number(3);
v_batch_qty number(6);
v_model_name VARCHAR2(25);
v_total number(6);
v_tartget_qty number(5);
v_use_qty number(5);
temp number(6);
v_prefix1 number(6);
v_prefix2 number(6);
ic_error exception;
mo_error exception;
sn_error exception;
type qty_type is ref cursor;
IC_CURSOR qty_type;
 /*
       1:  model_nam 不存在 和 ic_marketing 的對應關係  SFIS1.c_model_cust_t 
       2.mo target_qty  不存在 SFISM4.r_mo_base_t 
       OTHER ERROR 參數帶空格
       BATCH xxx .IC 批次抽檢數量未設定
       v_sample_sn ERROR :sn BI抽檢數量不足30 
 */
BEGIN 
    select count(target_qty) into temp from SFISM4.r_mo_base_t where mo_number=v_mo_number;
    if(temp<1) then
       res:='2';
       raise mo_error;
    end if;
    
    select target_qty,model_name  into v_tartget_qty,v_model_name from SFISM4.r_mo_base_t where mo_number=v_mo_number;
  
    v_sample_sn:=0;
    select count(*) into temp  from SFIS1.c_model_cust_t WHERE part_no=v_model_name;
    IF(temp<1) then
        res:='1';
        raise ic_error;
    end if;
    select cust_Serial into v_ic_marketing from SFIS1.c_model_cust_t WHERE part_no=v_model_name;
    
  
    --temp = 0 說明該 ic_marketing 是第一次掃描，添加第一批次
    select count(*) into temp  from  SFISM4.r_mnlx_ic_sample where ic_marketing=v_ic_marketing and ROWNUM=1;
    IF(temp>0) then
        select NVL(max(batch),0) into v_batch from sfism4.r_mnlx_ic_sample  where ic_marketing=v_ic_marketing;
        select NVL(max(total),0) into v_total  from sfism4.r_mnlx_ic_sample  where ic_marketing=v_ic_marketing and batch=v_batch and serial_number is null;
       
        select count(*) into temp from sfism4.r_mnlx_ic_sample where mo_number=v_mo_number;
        select substr(min(serial_number),-5) into v_prefix1 from SFISM4.r_wip_tracking_t where mo_number=v_mo_number;
        -- temp>0  mo_number已記入過 TOTAL總數 中
        if (temp>0) then
            select sum(qty) into  v_use_qty from sfism4.r_mnlx_ic_sample where mo_number=v_mo_number and serial_number is null group by mo_number;
            v_tartget_qty:=v_tartget_qty-v_use_qty;
             v_prefix1:=v_prefix1+v_use_qty;
        end if;
    ELSE
        --首次添加IC-MARKETING信息
        v_total:=0;
        v_batch:=1;
        select substr(min(serial_number),-5) into v_prefix1 from SFISM4.r_wip_tracking_t where mo_number=v_mo_number;
    END IF;     
        
    WHILE(v_tartget_qty>0) LOOP
                --未查詢到設定的批次數量則報錯 循環過1次後batch+1
                SELECT COUNT(*) into temp FROM SFIS1.C_MNLX_IC_SETUP WHERE ic_marketing=v_ic_marketing AND batch=v_batch   AND flag='SampleFlag';
                IF(temp>0) then
                
                    SELECT batch_qty,SAMPLE_QTY into v_batch_qty,v_sample_qty FROM SFIS1.C_MNLX_IC_SETUP  WHERE ic_marketing=v_ic_marketing and batch=v_batch and flag='SampleFlag';        
                   
                ELSE
                     --IC未添加設置信息 停止添加，查詢SN 所在批次抽檢數量是否足夠
                    temp:=substr(v_sn,-5);
                    select count(*) into v_use_qty from  sfism4.r_mnlx_ic_sample  where mo_number=v_mo_number and  INFO1<=temp AND INFO2>=temp order by ic_marketing,batch;
                    --針對已存在抽檢批次的SN
                    if(v_use_qty>0) then
                        select batch into v_sn_batch from  sfism4.r_mnlx_ic_sample  where mo_number=v_mo_number and  INFO1<=temp AND INFO2>=temp order by ic_marketing,batch;
                        SELECT SAMPLE_QTY into v_sample_qty FROM SFIS1.C_MNLX_IC_SETUP  WHERE ic_marketing=v_ic_marketing and batch=v_sn_batch and flag='SampleFlag';
                         select count(distinct serial_number) into v_sample_sn from sfism4.r_mnlx_ic_sample where ic_marketing=v_ic_marketing and batch=v_sn_batch;
                            IF(v_sample_sn<v_sample_qty) then
                                res:='ERROR'||v_batch||'#'||v_ic_marketing||'#'||v_sample_sn||'?'||v_sample_qty;
                                raise sn_error;
                            END IF;
                    end if;

                    res:='BATCH:'||v_batch||' '||v_ic_marketing;
                    raise ic_error;        
                END IF;        
                
                --插入 v_tartget_qty 個數量的 v_prefix1 起始SN  v_prefix2結束SN,每個批次總數量設置為 v_batch_qty
                IF(v_total+v_tartget_qty)<v_batch_qty then
                    v_prefix2:=v_prefix1+v_tartget_qty-1;
                    Insert into SFISM4.R_MNLX_IC_SAMPLE (BATCH,IC_MARKETING,MO_NUMBER,SERIAL_NUMBER,MODEL_NAME,INFO1,EMP_NO,TIME,TOTAL,INFO2,QTY) 
                        values (v_batch,v_ic_marketing,v_mo_number,null,v_model_name,v_prefix1,'BI SYSTEM',SYSDATE,(v_total+v_tartget_qty),v_prefix2,v_tartget_qty);
                    v_tartget_qty:=0;
                    exit;
                    
                ELSIF (v_total+v_tartget_qty)=v_batch_qty then
                     v_prefix2:=v_prefix1+v_tartget_qty-1;
                     Insert into SFISM4.R_MNLX_IC_SAMPLE (BATCH,IC_MARKETING,MO_NUMBER,SERIAL_NUMBER,MODEL_NAME,INFO1,EMP_NO,TIME,TOTAL,INFO2,QTY) 
                            values (v_batch,v_ic_marketing,v_mo_number,null,v_model_name,v_prefix1,'BI SYSTEM',SYSDATE,(v_total+v_tartget_qty),v_prefix2,v_tartget_qty);
                    Insert into SFISM4.R_MNLX_IC_SAMPLE (BATCH,IC_MARKETING,MO_NUMBER,SERIAL_NUMBER,MODEL_NAME,INFO1,EMP_NO,TIME,TOTAL,INFO2,QTY) 
                            values (v_batch,v_ic_marketing,null,null,null,null,'BI SYSTEM',SYSDATE,0,null,0);
                    v_tartget_qty:=0;
                    exit;
                    
                ELSE
                    --v_batch_qty=v_total 說明該批次已抽滿，不需要進行以下動作
                    if (v_batch_qty!=v_total) then
                        temp :=v_batch_qty-v_total;
                        v_prefix2:=v_prefix1+temp-1;
                        Insert into SFISM4.R_MNLX_IC_SAMPLE (BATCH,IC_MARKETING,MO_NUMBER,SERIAL_NUMBER,MODEL_NAME,INFO1,EMP_NO,TIME,TOTAL,INFO2,QTY) 
                            values (v_batch,v_ic_marketing,v_mo_number,null,v_model_name,v_prefix1,'BI SYSTEM',SYSDATE,v_batch_qty,v_prefix2,temp); 
                        Insert into SFISM4.R_MNLX_IC_SAMPLE (BATCH,IC_MARKETING,MO_NUMBER,SERIAL_NUMBER,MODEL_NAME,INFO1,EMP_NO,TIME,TOTAL,INFO2,QTY) 
                            values (v_batch,v_ic_marketing,null,null,null,null,'BI SYSTEM',SYSDATE,0,null,0);
                        v_tartget_qty := v_tartget_qty-temp;
                        v_prefix1:= v_prefix2+1;
                    end if;
                END IF;
                v_batch:=v_batch+1;
                v_total:=0;
    END LOOP;

     temp:=substr(v_sn,-5);
     select count(*) into v_use_qty from  sfism4.r_mnlx_ic_sample  where mo_number=v_mo_number and  INFO1<=temp AND INFO2>=temp order by ic_marketing,batch;
     --針對已存在抽檢批次的SN
     if(v_use_qty>0) then
        select batch into v_sn_batch from  sfism4.r_mnlx_ic_sample  where mo_number=v_mo_number and  INFO1<=temp AND INFO2>=temp order by ic_marketing,batch;
        SELECT COUNT(*) into temp FROM SFIS1.C_MNLX_IC_SETUP WHERE ic_marketing=v_ic_marketing AND batch=v_sn_batch   AND flag='SampleFlag';
        IF(temp>0) then
            SELECT SAMPLE_QTY into v_sample_qty FROM SFIS1.C_MNLX_IC_SETUP  WHERE ic_marketing=v_ic_marketing and batch=v_sn_batch and flag='SampleFlag';   
        ELSE
            res:='BATCH:'||v_sn_batch||' '||v_ic_marketing;
            raise ic_error;  
        END IF;
        
        select count(distinct serial_number) into v_sample_sn from sfism4.r_mnlx_ic_sample where ic_marketing=v_ic_marketing and batch=v_sn_batch;
        IF(v_sample_sn<v_sample_qty) then
             res:='ERROR'||v_sn_batch||'#'||v_ic_marketing||'#'||v_sample_sn||'?'||v_sample_qty;
             raise sn_error;
        ELSE
            res:='OK'||v_sn_batch||'#'||v_ic_marketing||'#'||v_sample_sn||'?'||v_sample_qty;
        END IF;
     end if;
     
EXCEPTION
    WHEN ic_error THEN null;
    when mo_error Then null;
    when sn_error THEN null;
    when OTHERS then 
       res:='BI_HASS OTHER ERROR';
       null;
END;