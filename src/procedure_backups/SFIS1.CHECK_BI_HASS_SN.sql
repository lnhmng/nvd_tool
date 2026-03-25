PROCEDURE CHECK_BI_HASS_SN(
SN      IN       VARCHAR2,
RES     OUT      VARCHAR2)
IS
C_MO VARCHAR2(25);
C_MODEL VARCHAR2(25);
C_Route VARCHAR2(25);
C_Customer VARCHAR2(25);
C_MOType  VARCHAR2(25);
C_MOStartDate VARCHAR2(25);
v_batch VARCHAR2(6);
v_temp1 VARCHAR2(15);
v_sample VARCHAR2(3);
C_RouteQty INT;
C_TargetQty INT;
C_CheckBiNum INT;
C_CheckNum INT;
C_BINum INT;
C_HassNum INT;
C_FINISH INT;
TEMP NUMBER(4);
e_bi_error   EXCEPTION;
e_bi_new_error   EXCEPTION;
e_hass_error   EXCEPTION;
E_ERROR          EXCEPTION;
BEGIN

/*
       OTHER ERROR 出現的可能情況：SN含空格/SN不存在
*/
select MO_NUMBER,special_route,customer_no,model_name INTO C_MO,C_Route,C_Customer,C_MODEL  from SFISM4.r_wip_tracking_t where SERIAL_NUMBER = SN;
select MO_TYPE,TO_CHAR(mo_start_date,'YYYY-MM-DD') into c_motype,C_MOStartDate from sfism4.r_mo_base_t where mo_number=C_MO;

if(C_Customer='MELLANOX' and c_motype in ('NORMAL','NEW_ITEM')AND C_MOStartDate>='2022-08-08')
    then
    
        select count(*) into C_RouteQty from sfis1.c_route_control_t where route_code= C_Route and group_name='BURN_IN' and group_next IN ('ICT1','FCT1','690_VI');
       
         if(C_RouteQty>=1)
            then
                    IF(C_MOStartDate<'2022-10-02')
                    THEN
                        SELECT TARGET_QTY into C_TargetQty  FROM SFISM4.r_mo_base_t WHERE MO_NUMBER = C_MO;
                        select a.num+b.num  INTO C_BINum from 
                          (SELECT count(distinct serial_number) as num FROM  SFISM4.r_sn_detail_t  where mo_number= C_MO and group_name='BURN_IN' )a,  
                         ( select count(distinct serial_number) as num from SFISM4.r_WIP_TRACKING_T where mo_number = C_MO and NEXT_STATION='BURN_IN') b ; 
                        
                        if(C_TargetQty between 2 and 8)
                        then C_CheckBiNum:=2;
                            elsif (C_TargetQty between 9 and 15)
                             then C_CheckBiNum:=3;
                            elsif (C_TargetQty between 16 and 25)
                             then C_CheckBiNum:=5;
                            elsif (C_TargetQty between 26 and 50)
                             then C_CheckBiNum:=8;
                            elsif (C_TargetQty between 51 and 90)
                             then C_CheckBiNum:=13;
                            elsif (C_TargetQty between 91 and 150)
                             then C_CheckBiNum:=20;
                            elsif (C_TargetQty between 151 and 280)
                             then C_CheckBiNum:=32;
                            elsif (C_TargetQty between 281 and 500)
                             then C_CheckBiNum:=50;
                            elsif (C_TargetQty between 501 and 1200)
                             then C_CheckBiNum:=80;
                            elsif (C_TargetQty between 1201 and 3200)
                             then C_CheckBiNum:=125;
                            elsif (C_TargetQty between 3201 and 10000)
                             then C_CheckBiNum:=200;
                            elsif (C_TargetQty between 10001 and 35000)
                             then C_CheckBiNum:=315;
                            else
                               C_CheckBiNum:=0;  
                        end if;
                        
                        
                        if(C_BINum<C_CheckBiNum) then
                            SELECT COUNT(*) INTO C_FINISH FROM SFISM4.r_bi_hass_full WHERE  FINISH_FLAG=1 AND MO_NUMBER=C_MO;
                            IF(C_FINISH>=1)
                            THEN 
                                RES:='OK';
                            ELSE
                                RAISE e_bi_error;
                            end if;
                        else
                          --  Insert into SFISM4.R_BI_HASS_FULL (MO_NUMBER,FINISH_FLAG,OPERATOR,REMARKS) values (c_mo,'1','system','舊規則抽檢數量達標');
                             RES:='OK';
                        end if;
                        
                    ELSE --(C_MOStartDate>='2022-10-02') 100-02后的抽檢規則
                         --check bi
                        BI_HASS(C_MODEL,c_mo,SN,RES);
                        if INSTR(RES,'OK')<1 then
                            raise e_bi_new_error;
                        end if;
                        
                        SELECT COUNT(*) INTO C_FINISH FROM SFISM4.r_bi_hass_full WHERE  FINISH_FLAG=1 AND MO_NUMBER=C_MO;
                        IF(C_FINISH>=1)
                        THEN 
                                RES:='OK';
                        ELSE
                        
                            --check hass
                            SELECT TARGET_QTY into C_TargetQty  FROM SFISM4.r_mo_base_t WHERE MO_NUMBER = C_MO;
                            select a.num+b.num  INTO C_HassNum from 
                                  (SELECT count(distinct serial_number) as num FROM  SFISM4.r_sn_detail_t  where mo_number=C_MO and group_name='HASS' )a,  
                                 ( select count(distinct serial_number) as num from SFISM4.r_WIP_TRACKING_T where mo_number=C_MO and NEXT_STATION='HASS') b ;
                            
                            if(C_TargetQty between 2 and 8)
                                then C_CheckNum:=2;
                            elsif (C_TargetQty between 9 and 15)
                             then C_CheckNum:=3;
                            elsif (C_TargetQty between 16 and 25)
                             then C_CheckNum:=5;
                            elsif (C_TargetQty between 26 and 50)
                             then C_CheckNum:=8;
                            elsif (C_TargetQty between 51 and 90)
                             then C_CheckNum:=13;
                            elsif (C_TargetQty between 91 and 150)
                             then C_CheckNum:=20;
                            elsif (C_TargetQty between 151 and 280)
                             then C_CheckNum:=32;
                            elsif (C_TargetQty between 281 and 500)
                             then C_CheckNum:=50;
                            elsif (C_TargetQty between 501 and 1200)
                             then C_CheckNum:=80;
                            elsif (C_TargetQty between 1201 and 3200)
                             then C_CheckNum:=125;
                            elsif (C_TargetQty between 3201 and 10000)
                             then C_CheckNum:=200;
                            elsif (C_TargetQty between 10001 and 35000)
                             then C_CheckNum:=315;
                            else
                               C_CheckNum:=0;  
                            end if;
                            
                            if(C_HassNum<C_CheckNum) THEN
                                 RAISE e_hass_error;
                            ELSE
                                 Insert into SFISM4.R_BI_HASS_FULL (MO_NUMBER,FINISH_FLAG,OPERATOR,REMARKS) values (c_mo,'1','system','抽檢數量達標');
                                 RES:='OK';
                            end if;
                        end if;
                    --層級C_MOStartDate
                    END IF;
            ELSE 
                RES:='OK';
            --層級C_RouteQty
            END IF;
else
   RES:='OK';
end if;
  
exception 
    when e_bi_error
        then
        RES:='BI NUM '||C_BINum ||' ERROR,NEED '||C_CheckBiNum;
    when e_hass_error
        then
         RES:='HASS NUM '||C_HassNum ||' ERROR,NEED '||C_CheckNum;
    when e_bi_new_error
        then
            if(RES='1') THEN 
                RES:='MODEL_NAME'||C_MODEL||'NO IC-MARKETING';
                
            ELSIF (RES='2') THEN 
                RES:='MO_NUMBER'||c_mo||'NOT EXISTS';
                
            ELSIF (INSTR(RES,'BATCH')=1) THEN
                RES:=RES||' SAMPLE QTY NOT SET';
                
            ELSIF (INSTR(RES,'ERROR')=1) THEN 
            --BATCH 10 BI NUM -19 ERROR,NEED 30 ERROR10#ConnectX?-5#3?5
                temp:= instr(RES,'#',-1)+1; --最後一個#出現的位置,取sample SN開始的位置
                v_sample:=instr(RES,'?',-1)-temp; --sample sn長度
                v_sample:=substr(RES,temp,v_sample); --取sample sn
                v_batch:= substr(RES,6,instr(RES,'#')-6);  --從第6位batch開始，截取 #-6個長度
                temp:=instr(RES,'?',-1)+1;
                v_temp1:=substr(RES,temp);
                RES:='BATCH '||v_batch||' BI NUM '||v_sample||' ERROR,NEED '||v_temp1;
            ELSE NULL;
        END IF;
    
   WHEN OTHERS THEN 
   RES:= 'OTHER ERROR[CHECK_BI_HASS_SN]';
END;