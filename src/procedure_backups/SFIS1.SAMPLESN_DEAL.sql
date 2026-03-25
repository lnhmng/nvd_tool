PROCEDURE                   SAMPLESN_DEAL (
    TRANTYPE   in   varchar2,
    SN         in   varchar2,
    SAMPLESN1  in   varchar2,
    SAMPLESN2  in   varchar2,
    SAMPLESN3  in   varchar2,
    GROUPNAME  in   varchar2,
    QTY        in   varchar2,
    UID        in   varchar2,
    RES        OUT  varchar2
)
IS
modelname       varchar2(30);
sample_pn1      varchar2(30);
sample_pn2      varchar2(30);
sample_pn3      varchar2(30);
sample_qty      int;
count1          int;
prefix          varchar2(30);
snlen           int;
p_controltime   int;
p_lastbindsn    varchar2(30);
p_lastbinddate  date;
p_lastmtdate    date;
p_lastECdate    date;
ex    exception;

BEGIN
   RES:='OK';
   
   if TRANTYPE='CHECKSN' THEN
       select count(*) into count1 from sfism4.r_wip_tracking_t where serial_number=SN;
       
       if count1=0 THEN
           RES:='SN NOT EXISTS'; 
           raise ex;
       end if; 
   
       select count(*) into count1 from sfism4.r_wip_tracking_t where serial_number=SN and error_flag='1';
        if count1>0 THEN
           RES:='Should be sent to Repair'; 
           raise ex;
       end if; 
   
       select model_name into  modelname from sfism4.r_wip_tracking_t where serial_number=SN; 
  
       SFIS1.CHECK_ROUTE3('',GROUPNAME,SN,RES);
       IF LENGTH(RES)>0 AND RES<>'OK' THEN
           RES:=RES;
           raise ex;
       END if;
       
       SELECT count(*) into count1 FROM SFIS1.C_SAMPLESN_BIND_SET WHERE PARENTPARTNO= modelname;
       if count1>0 then
          SELECT NVL(PN1,''),NVL(PN2,''),NVL(PN3,''),QTY into sample_pn1, sample_pn2, sample_pn3,sample_qty FROM SFIS1.C_SAMPLESN_BIND_SET WHERE PARENTPARTNO= modelname;
          RES:='OK,'|| sample_pn1||','||sample_pn2||','||sample_pn3||','||sample_qty; 
       else
          RES:='TE not set BIND INFO';
          raise ex;  
       end if;
   end if; 
   
    if TRANTYPE='BIND' THEN
        
        select model_name into  modelname from sfism4.r_wip_tracking_t where serial_number=SN;      
    
        SELECT NVL(PN1,''),NVL(PN2,''),NVL(PN3,''),QTY into sample_pn1, sample_pn2, sample_pn3,sample_qty FROM SFIS1.C_SAMPLESN_BIND_SET WHERE PARENTPARTNO= modelname;
  
        if qty='1' then
            if SAMPLESN1 is null or SAMPLESN1='' then
                RES:='Please Scan Sample SN';
                raise ex; 
            end if;
           
                  
            if GROUPNAME <> 'BBD2' THEN         
            SELECT count(*) into count1 fROM sfism4.R_SAMPLESN_BIND_DETAIL WHERE LASTEDITDT>SYSDATE-30/24/60 and c_sn=SAMPLESN1;
            if count1>0 then
                RES:='Scan Duplicate';
                raise ex;
            end if;
           END IF; 
         
            
            select count(*) into count1 from SFIS1.C_SAMPLESN_REPAIR where sn = SAMPLESN1 and type='NG';
            if count1>0 then
                RES:= SAMPLESN1 || 'is NG!';
                raise ex;
            end if;
            
            select count(*) into count1 from sfis1.C_SAMPLESN_SET where SKUNO=sample_pn1;
            if count1>0 then
                select PREFIX,SNLEN,CONTROL_TIMES INTO prefix,snlen,p_controltime from sfis1.C_SAMPLESN_SET where SKUNO=sample_pn1;
                
                if SUBSTR(SAMPLESN1,1,length(PREFIX))<>PREFIX then
                    RES:='Sample SN '||SAMPLESN1||' prefix not match SN RULE,Contact TE';
                    raise ex;  
                end if;
                
                if length(SAMPLESN1)<>snlen then
                    RES:='Sample SN '||SAMPLESN1||' length not match SN RULE,Contact TE';
                    raise ex;  
                end if;
                
                select count(*) into count1 from SFISM4.R_SAMPLESN_BIND_QTY where sn=SAMPLESN1 and c_qty>=p_controltime;
                if count1>0 then
                    RES:='Sample SN '||SAMPLESN1||' BIND times more than TE set times,Send to maintain';
                    raise ex; 
                end if;
            else
                 RES:='PN1 '||sample_pn1||' TE not set SN RULE,Contact TE';
                 raise ex;  
            end if;
            
         
             
            select count(*) into count1 from SFISM4.R_SAMPLESN_BIND_DETAIL WHERE C_SN=SAMPLESN1 and LASTEDITDT<SYSDATE;
            if count1>0 then
              select count(*) into count1 from SFIS1.C_SAMPLESN_ERRORCODE_SET;
              if count1>0 then
                  select max(lasteditdt) into p_lastbinddate from SFISM4.R_SAMPLESN_BIND_DETAIL WHERE C_SN=SAMPLESN1 and LASTEDITDT<SYSDATE;
                  select p_sn into p_lastbindsn from SFISM4.R_SAMPLESN_BIND_DETAIL WHERE C_SN=SAMPLESN1 and LASTEDITDT=p_lastbinddate;
                  
                  select count(*) into count1 from SFIS1.C_SAMPLESN_REPAIR WHERE SN=SAMPLESN1;
                  if count1>0 then
                    select max(lasteditdt) into p_lastmtdate from SFIS1.C_SAMPLESN_REPAIR WHERE SN=SAMPLESN1;
                    if p_lastmtdate>p_lastbinddate then
                        p_lastbinddate:=p_lastmtdate;
                    end if; 
                  end if;
                                   
                  select count(*) into count1 from SFISM4.R_SAMPLESN_EC_QTY WHERE SN=SAMPLESN1;
                  if count1>0 then
                    select max(lasteditdt) into p_lastECdate from SFISM4.R_SAMPLESN_EC_QTY WHERE SN=SAMPLESN1;
                    if p_lastECdate>p_lastbinddate then
                        p_lastbinddate:=p_lastECdate;
                    end if;
                  end if;
                    
                  --select count(*) into count1 from SFISM4.R_repair_t WHERE serial_number=p_lastbindsn and test_time>=p_lastbinddate and test_code in
                    --( select error_code from SFIS1.C_SAMPLESN_ERRORCODE_SET);
                    select count(*) into count1 from SFIS1.C_SAMPLESN_ERRORCODE_SET WHERE ERROR_CODE NOT IN('ALL','E*');  
                            
                    if count1>0 then
                        select count(*) into count1 from SFISM4.R_SAMPLESN_EC_QTY a,sfis1.C_SAMPLESN_ERRORCODE_SET b where a.SN=SAMPLESN1
                            and a.errorcode like '%'||b.error_code and a.qty>=b.CONTROL_TIMES;
                       
                        if count1>0 then
                             RES:='Sample SN '||SAMPLESN1||' ErrorCode Fail times more than TE set times,Send to maintain 1';
                             raise ex;     
                        end if;    
                    end if;      
                                     
                     select count(*) into count1 from SFISM4.R_SAMPLESN_EC_QTY a,sfis1.C_SAMPLESN_ERRORCODE_SET b where a.SN=SAMPLESN1
                        and b.error_code='ALL' and a.qty>=b.CONTROL_TIMES;
                       
                    if count1>0 then
                         RES:='Sample SN '||SAMPLESN1||' ErrorCode Fail times more than TE set times,Send to maintain 2';
                         raise ex;     
                    end if; 
                    
                    
                 
                  select count(*) into count1 from SFISM4.R_repair_t WHERE serial_number=p_lastbindsn and test_time>=p_lastbinddate   
                  and test_station in(SELECT GROUP_NAME FROM SFIS1.C_ICT_STATION_T WHERE GROUP_NAME NOT LIKE '%AOI%' 
                            AND GROUP_NAME NOT LIKE '%API%' AND GROUP_NAME NOT LIKE '%ICT%' AND GROUP_NAME<>'BIOSCHECK');
                 
                  if count1>0 then
                        --modify by LLF 2017-06-01
                        --update SFISM4.R_SAMPLESN_EC_QTY a set lasteditby=UID,lasteditdt=sysdate, 
                        --qty=qty+( select qty from (select count(1) qty,test_code from SFISM4.R_repair_t b 
                        --WHERE b.serial_number= p_lastbindsn and test_time>=p_lastbinddate and test_code in
                        --(select errorcode from SFISM4.R_SAMPLESN_EC_QTY) group by test_code)b where a.errorcode=b.test_code )
                        --WHERE SN=SAMPLESN1 AND ERRORCODE IN
                        --(select error_code from SFIS1.C_SAMPLESN_ERRORCODE_SET) and exists
                        --(select 1 from SFISM4.R_repair_t b WHERE b.serial_number= p_lastbindsn and b.test_time>=p_lastbinddate and a.errorcode=b.test_code);
                                    
                        --INSERT INTO SFISM4.R_SAMPLESN_EC_QTY
                        --select SAMPLESN1,test_code,count(1),UID,SYSDATE from SFISM4.R_repair_t a WHERE serial_number= p_lastbindsn and test_time>=p_lastbinddate
                        --and not exists
                        --(select 1 from SFISM4.R_SAMPLESN_EC_QTY b where b.sn=SAMPLESN1 and a.test_code=b.errorcode)
                        --and exists
                        --(select 1 from SFIS1.C_SAMPLESN_ERRORCODE_SET c where a.test_code=c.error_code)
                        --GROUP BY test_code;   
                        
                            update SFISM4.R_SAMPLESN_EC_QTY a set lasteditby=UID,lasteditdt=sysdate, 
                            qty=qty+( select qty from (select count(1) qty,test_code from SFISM4.R_repair_t b 
                            WHERE b.serial_number= p_lastbindsn and test_time>=p_lastbinddate 
                            and test_station in(SELECT GROUP_NAME FROM SFIS1.C_ICT_STATION_T WHERE GROUP_NAME NOT LIKE '%AOI%' AND GROUP_NAME NOT LIKE '%API%' AND GROUP_NAME NOT LIKE '%ICT%' AND GROUP_NAME<>'BIOSCHECK')
                            group by test_code)b where a.errorcode=b.test_code )
                            WHERE SN=SAMPLESN1 and exists
                            (select 1 from SFISM4.R_repair_t b WHERE b.serial_number= p_lastbindsn and b.test_time>=p_lastbinddate 
                            and test_station in(SELECT GROUP_NAME FROM SFIS1.C_ICT_STATION_T WHERE GROUP_NAME NOT LIKE '%AOI%' AND GROUP_NAME NOT LIKE '%API%' AND GROUP_NAME NOT LIKE '%ICT%' AND GROUP_NAME<>'BIOSCHECK')
                            and a.errorcode=b.test_code);
                            
                            INSERT INTO SFISM4.R_SAMPLESN_EC_QTY
                            select SAMPLESN1,test_code,count(1),UID,SYSDATE from SFISM4.R_repair_t a WHERE serial_number= p_lastbindsn and test_time>=p_lastbinddate
                            and test_station in(SELECT GROUP_NAME FROM SFIS1.C_ICT_STATION_T WHERE GROUP_NAME NOT LIKE '%AOI%' 
                            AND GROUP_NAME NOT LIKE '%API%' AND GROUP_NAME NOT LIKE '%ICT%' AND GROUP_NAME<>'BIOSCHECK')
                            and not exists
                            (select 1 from SFISM4.R_SAMPLESN_EC_QTY b where b.sn=SAMPLESN1 and a.test_code=b.errorcode)
                            GROUP BY test_code;
                         
                  end if;
              end if;                 
            end if;   
            
            --modify by LLF 2017-06-01
            --select count(*) into count1 from SFISM4.R_SAMPLESN_EC_QTY a,sfis1.C_SAMPLESN_ERRORCODE_SET b where a.SN=SAMPLESN1
                --and a.errorcode='ALL' and a.qty>=b.CONTROL_TIMES;
               
            --if count1>0 then
                 --RES:='Sample SN '||SAMPLESN1||' ErrorCode Fail times more than TE set times,Send to maintain';
                 --raise ex;     
            --end if;
            select count(*) into count1 from SFIS1.C_SAMPLESN_ERRORCODE_SET WHERE ERROR_CODE NOT IN('ALL','E*');  
                            
            if count1>0 then
                select count(*) into count1 from SFISM4.R_SAMPLESN_EC_QTY a,sfis1.C_SAMPLESN_ERRORCODE_SET b where a.SN=SAMPLESN1
                    and a.errorcode like '%'||b.error_code and a.qty>=b.CONTROL_TIMES;
               
                if count1>0 then
                     RES:='Sample SN '||SAMPLESN1||' ErrorCode Fail times more than TE set times,Send to maintain 1';
                     raise ex;     
                end if;    
            end if;  
                                 
             select count(*) into count1 from SFISM4.R_SAMPLESN_EC_QTY a,sfis1.C_SAMPLESN_ERRORCODE_SET b where a.SN=SAMPLESN1
                and b.error_code='ALL' and a.qty>=b.CONTROL_TIMES;
               
            if count1>0 then
                 RES:='Sample SN '||SAMPLESN1||' ErrorCode Fail times more than TE set times,Send to maintain 2';
                 raise ex;     
            end if; 
        end if ;
        
        if qty='2' then
            if SAMPLESN2 is null or SAMPLESN2='' then
                RES:='Please Scan Sample SN';
                raise ex; 
            end if;
            
            SELECT count(*) into count1 fROM sfism4.R_SAMPLESN_BIND_DETAIL WHERE LASTEDITDT>SYSDATE-30/24/60 and c_sn=SAMPLESN2;
            if count1>0 then
                RES:='Scan Duplicate';
                raise ex;
            end if;
            
            select count(*) into count1 from SFIS1.C_SAMPLESN_REPAIR where sn = SAMPLESN2 and type='NG';
            if count1>0 then
                RES:= SAMPLESN2 || 'is NG!';
                raise ex;
            end if;
            
            select count(*) into count1 from sfis1.C_SAMPLESN_SET where SKUNO=sample_pn2;
            if count1>0 then
                select PREFIX,SNLEN,CONTROL_TIMES INTO prefix,snlen,p_controltime from sfis1.C_SAMPLESN_SET where SKUNO=sample_pn2;
                
                if SUBSTR(SAMPLESN2,1,length(PREFIX))<>PREFIX then
                    RES:='Sample SN '||SAMPLESN2||' prefix not match SN RULE,Contact TE';
                    raise ex;  
                end if;
                
                 if length(SAMPLESN2)<>snlen then
                    RES:='Sample SN '||SAMPLESN2||' length not match SN RULE,Contact TE';
                    raise ex;  
                end if;
                
                select count(*) into count1 from SFISM4.R_SAMPLESN_BIND_QTY where sn=SAMPLESN2 and c_qty>=p_controltime;
                if count1>0 then
                    RES:='Sample SN '||SAMPLESN2||' BIND times more than TE set times,Send to maintain';
                    raise ex; 
                end if;
            else
                 RES:='PN2 '||sample_pn2||' TE not set SN RULE,Contact TE';
                 raise ex;  
            end if;  
        
             select count(*) into count1 from SFISM4.R_SAMPLESN_BIND_DETAIL WHERE C_SN=SAMPLESN2 and LASTEDITDT<SYSDATE;
            if count1>0 then
              select count(*) into count1 from SFIS1.C_SAMPLESN_ERRORCODE_SET;
              if count1>0 then
                  select max(lasteditdt) into p_lastbinddate from SFISM4.R_SAMPLESN_BIND_DETAIL WHERE C_SN=SAMPLESN2 and LASTEDITDT<SYSDATE;
                  select p_sn into p_lastbindsn from SFISM4.R_SAMPLESN_BIND_DETAIL WHERE C_SN=SAMPLESN2 and LASTEDITDT=p_lastbinddate;
                  select count(*) into count1 from SFIS1.C_SAMPLESN_REPAIR WHERE SN=SAMPLESN2;
                  if count1>0 then
                    select max(lasteditdt) into p_lastmtdate from SFIS1.C_SAMPLESN_REPAIR WHERE SN=SAMPLESN2;
                    if p_lastmtdate>p_lastbinddate then
                        p_lastbinddate:=p_lastmtdate;
                    end if; 
                  end if;
                  
                  select count(*) into count1 from SFISM4.R_SAMPLESN_EC_QTY WHERE SN=SAMPLESN1;
                  if count1>0 then
                    select max(lasteditdt) into p_lastECdate from SFISM4.R_SAMPLESN_EC_QTY WHERE SN=SAMPLESN2;
                    if p_lastECdate>p_lastbinddate then
                        p_lastbinddate:=p_lastECdate;
                    end if;
                  end if;
                  
                  --select count(*) into count1 from SFISM4.R_repair_t WHERE serial_number=p_lastbindsn and test_time>=p_lastbinddate and test_code in
                    --( select error_code from SFIS1.C_SAMPLESN_ERRORCODE_SET);
                    
                    select count(*) into count1 from SFIS1.C_SAMPLESN_ERRORCODE_SET WHERE ERROR_CODE NOT IN('ALL','E*');  
                            
                    if count1>0 then
                        select count(*) into count1 from SFISM4.R_SAMPLESN_EC_QTY a,sfis1.C_SAMPLESN_ERRORCODE_SET b where a.SN=SAMPLESN2
                            and a.errorcode like '%'||b.error_code and a.qty>=b.CONTROL_TIMES;
                       
                        if count1>0 then
                             RES:='Sample SN '||SAMPLESN2||' ErrorCode Fail times more than TE set times,Send to maintain 1';
                             raise ex;     
                        end if;    
                    end if;
                                           
                     select count(*) into count1 from SFISM4.R_SAMPLESN_EC_QTY a,sfis1.C_SAMPLESN_ERRORCODE_SET b where a.SN=SAMPLESN2
                        and b.error_code='ALL' and a.qty>=b.CONTROL_TIMES;
                       
                    if count1>0 then
                         RES:='Sample SN '||SAMPLESN2||' ErrorCode Fail times more than TE set times,Send to maintain 2';
                         raise ex;     
                    end if;                     
                   
                  select count(*) into count1 from SFISM4.R_repair_t WHERE serial_number=p_lastbindsn and test_time>=p_lastbinddate   
                   and test_station in(SELECT GROUP_NAME FROM SFIS1.C_ICT_STATION_T WHERE GROUP_NAME NOT LIKE '%AOI%' 
                   AND GROUP_NAME NOT LIKE '%API%' AND GROUP_NAME NOT LIKE '%ICT%' AND GROUP_NAME<>'BIOSCHECK');
                   
                  if count1>0 then
                        --update SFISM4.R_SAMPLESN_EC_QTY a set lasteditby=UID,lasteditdt=sysdate, 
                        --qty=qty+( select qty from (select count(1) qty,test_code from SFISM4.R_repair_t b 
                        --WHERE b.serial_number= p_lastbindsn and test_time>=p_lastbinddate and test_code in
                        --(select errorcode from SFISM4.R_SAMPLESN_EC_QTY) group by test_code)b where a.errorcode=b.test_code )
                        --WHERE SN=SAMPLESN2 AND ERRORCODE IN
                        --(select error_code from SFIS1.C_SAMPLESN_ERRORCODE_SET) and exists
                        --(select 1 from SFISM4.R_repair_t b WHERE b.serial_number= p_lastbindsn and b.test_time>=p_lastbinddate and a.errorcode=b.test_code);
                                    
                        --INSERT INTO SFISM4.R_SAMPLESN_EC_QTY
                        --select SAMPLESN2,test_code,count(1),UID,SYSDATE from SFISM4.R_repair_t a WHERE serial_number= p_lastbindsn and test_time>=p_lastbinddate
                        --and not exists
                        --(select 1 from SFISM4.R_SAMPLESN_EC_QTY b where b.sn=SAMPLESN2 and a.test_code=b.errorcode)
                        --and exists
                        --(select 1 from SFIS1.C_SAMPLESN_ERRORCODE_SET c where a.test_code=c.error_code)
                        --GROUP BY test_code;  
                        
                            update SFISM4.R_SAMPLESN_EC_QTY a set lasteditby=UID,lasteditdt=sysdate, 
                            qty=qty+( select qty from (select count(1) qty,test_code from SFISM4.R_repair_t b 
                            WHERE b.serial_number= p_lastbindsn and test_time>=p_lastbinddate 
                            and test_station in(SELECT GROUP_NAME FROM SFIS1.C_ICT_STATION_T WHERE GROUP_NAME NOT LIKE '%AOI%' AND GROUP_NAME NOT LIKE '%API%' AND GROUP_NAME NOT LIKE '%ICT%' AND GROUP_NAME<>'BIOSCHECK')
                            group by test_code)b where a.errorcode=b.test_code )
                            WHERE SN=SAMPLESN2 and exists
                            (select 1 from SFISM4.R_repair_t b WHERE b.serial_number= p_lastbindsn and b.test_time>=p_lastbinddate 
                            and test_station in(SELECT GROUP_NAME FROM SFIS1.C_ICT_STATION_T WHERE GROUP_NAME NOT LIKE '%AOI%' AND GROUP_NAME NOT LIKE '%API%' AND GROUP_NAME NOT LIKE '%ICT%' AND GROUP_NAME<>'BIOSCHECK')
                            and a.errorcode=b.test_code);
                            
                            INSERT INTO SFISM4.R_SAMPLESN_EC_QTY
                            select SAMPLESN2,test_code,count(1),UID,SYSDATE from SFISM4.R_repair_t a WHERE serial_number= p_lastbindsn and test_time>=p_lastbinddate
                            and test_station in(SELECT GROUP_NAME FROM SFIS1.C_ICT_STATION_T WHERE GROUP_NAME NOT LIKE '%AOI%' 
                            AND GROUP_NAME NOT LIKE '%API%' AND GROUP_NAME NOT LIKE '%ICT%' AND GROUP_NAME<>'BIOSCHECK')
                            and not exists
                            (select 1 from SFISM4.R_SAMPLESN_EC_QTY b where b.sn=SAMPLESN2 and a.test_code=b.errorcode)
                            GROUP BY test_code;  
                  end if;
              end if;                 
            end if;   
            
            --select count(*) into count1 from SFISM4.R_SAMPLESN_EC_QTY a,sfis1.C_SAMPLESN_ERRORCODE_SET b where a.SN=SAMPLESN2
                --and a.errorcode=b.error_code and a.qty>=b.CONTROL_TIMES;
               
            --if count1>0 then
                 --RES:='Sample SN '||SAMPLESN1||' ErrorCode Fail times more than TE set times,Send to maintain';
                 --raise ex;     
            --end if;  
            
            select count(*) into count1 from SFIS1.C_SAMPLESN_ERRORCODE_SET WHERE ERROR_CODE NOT IN('ALL','E*');  
                            
            if count1>0 then
                select count(*) into count1 from SFISM4.R_SAMPLESN_EC_QTY a,sfis1.C_SAMPLESN_ERRORCODE_SET b where a.SN=SAMPLESN2
                    and a.errorcode like '%'||b.error_code and a.qty>=b.CONTROL_TIMES;
               
                if count1>0 then
                     RES:='Sample SN '||SAMPLESN2||' ErrorCode Fail times more than TE set times,Send to maintain 1';
                     raise ex;     
                end if;    
            end if;
                                   
             select count(*) into count1 from SFISM4.R_SAMPLESN_EC_QTY a,sfis1.C_SAMPLESN_ERRORCODE_SET b where a.SN=SAMPLESN2
                and b.error_code='ALL' and a.qty>=b.CONTROL_TIMES;
               
            if count1>0 then
                 RES:='Sample SN '||SAMPLESN2||' ErrorCode Fail times more than TE set times,Send to maintain 2';
                 raise ex;     
            end if;      
        end if ;
        
        if qty='3' then
           if SAMPLESN3 is null or SAMPLESN3='' then
                RES:='Please Scan Sample SN';
                raise ex; 
           end if; 
        
           SELECT count(*) into count1 fROM sfism4.R_SAMPLESN_BIND_DETAIL WHERE LASTEDITDT>SYSDATE-30/24/60 and c_sn=SAMPLESN3;
           if count1>0 then
               RES:='Scan Duplicate';
               raise ex;
           end if;
           
           select count(*) into count1 from SFIS1.C_SAMPLESN_REPAIR where sn = SAMPLESN3 and type='NG';
            if count1>0 then
                RES:= SAMPLESN3 || 'is NG!';
                raise ex;
            end if;
           
           select count(*) into count1 from sfis1.C_SAMPLESN_SET where SKUNO=sample_pn3;
            if count1>0 then
                select PREFIX,SNLEN,CONTROL_TIMES INTO prefix,snlen,p_controltime from sfis1.C_SAMPLESN_SET where SKUNO=sample_pn3;
                
                if SUBSTR(SAMPLESN3,1,length(PREFIX))<>PREFIX then
                    RES:='Sample SN '||SAMPLESN3||' prefix not match SN RULE,Contact TE';
                    raise ex;  
                end if;
                
                 if length(SAMPLESN3)<>snlen then
                    RES:='Sample SN '||SAMPLESN3||' length not match SN RULE,Contact TE';
                    raise ex;  
                end if;
                
                select count(*) into count1 from SFISM4.R_SAMPLESN_BIND_QTY where sn=SAMPLESN3 and c_qty>=p_controltime;
                if count1>0 then
                    RES:='Sample SN '||SAMPLESN3||' BIND times more than TE set times,Send to maintain';
                    raise ex; 
                end if;
            else
                 RES:='PN3 '||sample_pn3||' TE not set SN RULE,Contact TE';
                 raise ex;  
            end if;
           
             select count(*) into count1 from SFISM4.R_SAMPLESN_BIND_DETAIL WHERE C_SN=SAMPLESN3 and LASTEDITDT<SYSDATE;
            if count1>0 then
              select count(*) into count1 from SFIS1.C_SAMPLESN_ERRORCODE_SET;
              if count1>0 then
                  select max(lasteditdt) into p_lastbinddate from SFISM4.R_SAMPLESN_BIND_DETAIL WHERE C_SN=SAMPLESN3 and LASTEDITDT<SYSDATE;
                  select p_sn into p_lastbindsn from SFISM4.R_SAMPLESN_BIND_DETAIL WHERE C_SN=SAMPLESN3 and LASTEDITDT=p_lastbinddate;
                  select count(*) into count1 from SFIS1.C_SAMPLESN_REPAIR WHERE SN=SAMPLESN3;
                  if count1>0 then
                    select max(lasteditdt) into p_lastmtdate from SFIS1.C_SAMPLESN_REPAIR WHERE SN=SAMPLESN3;
                    if p_lastmtdate>p_lastbinddate then
                        p_lastbinddate:=p_lastmtdate;
                    end if; 
                  end if;
                  
                  select count(*) into count1 from SFISM4.R_SAMPLESN_EC_QTY WHERE SN=SAMPLESN3;
                  if count1>0 then
                    select max(lasteditdt) into p_lastECdate from SFISM4.R_SAMPLESN_EC_QTY WHERE SN=SAMPLESN3;
                    if p_lastECdate>p_lastbinddate then
                        p_lastbinddate:=p_lastECdate;
                    end if;
                  end if;
                  
                  select count(*) into count1 from SFIS1.C_SAMPLESN_ERRORCODE_SET WHERE ERROR_CODE NOT IN('ALL','E*');  
                            
                    if count1>0 then
                        select count(*) into count1 from SFISM4.R_SAMPLESN_EC_QTY a,sfis1.C_SAMPLESN_ERRORCODE_SET b where a.SN=SAMPLESN3
                            and a.errorcode like '%'||b.error_code and a.qty>=b.CONTROL_TIMES;
                       
                        if count1>0 then
                             RES:='Sample SN '||SAMPLESN3||' ErrorCode Fail times more than TE set times,Send to maintain 1';
                             raise ex;     
                        end if;    
                    end if;
                                           
                     select count(*) into count1 from SFISM4.R_SAMPLESN_EC_QTY a,sfis1.C_SAMPLESN_ERRORCODE_SET b where a.SN=SAMPLESN3
                        and b.error_code='ALL' and a.qty>=b.CONTROL_TIMES;
                       
                    if count1>0 then
                         RES:='Sample SN '||SAMPLESN3||' ErrorCode Fail times more than TE set times,Send to maintain 2';
                         raise ex;     
                    end if; 
                  
                  select count(*) into count1 from SFISM4.R_repair_t WHERE serial_number=p_lastbindsn and test_time>=p_lastbinddate and test_code in
                    ( select error_code from SFIS1.C_SAMPLESN_ERRORCODE_SET);
                  if count1>0 then
                        --update SFISM4.R_SAMPLESN_EC_QTY a set lasteditby=UID,lasteditdt=sysdate, 
                        --qty=qty+( select qty from (select count(1) qty,test_code from SFISM4.R_repair_t b 
                        --WHERE b.serial_number= p_lastbindsn and test_time>=p_lastbinddate and test_code in
                        --(select errorcode from SFISM4.R_SAMPLESN_EC_QTY) group by test_code)b where a.errorcode=b.test_code )
                        --WHERE SN=SAMPLESN3 AND ERRORCODE IN
                        --(select error_code from SFIS1.C_SAMPLESN_ERRORCODE_SET) and exists
                        --(select 1 from SFISM4.R_repair_t b WHERE b.serial_number= p_lastbindsn and b.test_time>=p_lastbinddate and a.errorcode=b.test_code);
                                    
                        --INSERT INTO SFISM4.R_SAMPLESN_EC_QTY
                        --select SAMPLESN3,test_code,count(1),UID,SYSDATE from SFISM4.R_repair_t a WHERE serial_number= p_lastbindsn and test_time>=p_lastbinddate
                        --and not exists
                        --(select 1 from SFISM4.R_SAMPLESN_EC_QTY b where b.sn=SAMPLESN3 and a.test_code=b.errorcode)
                        --and exists
                        --(select 1 from SFIS1.C_SAMPLESN_ERRORCODE_SET c where a.test_code=c.error_code)
                        --GROUP BY test_code; 
                        update SFISM4.R_SAMPLESN_EC_QTY a set lasteditby=UID,lasteditdt=sysdate, 
                            qty=qty+( select qty from (select count(1) qty,test_code from SFISM4.R_repair_t b 
                            WHERE b.serial_number= p_lastbindsn and test_time>=p_lastbinddate 
                            and test_station in(SELECT GROUP_NAME FROM SFIS1.C_ICT_STATION_T WHERE GROUP_NAME NOT LIKE '%AOI%' AND GROUP_NAME NOT LIKE '%API%' AND GROUP_NAME NOT LIKE '%ICT%' AND GROUP_NAME<>'BIOSCHECK')
                            group by test_code)b where a.errorcode=b.test_code )
                            WHERE SN=SAMPLESN3 and exists
                            (select 1 from SFISM4.R_repair_t b WHERE b.serial_number= p_lastbindsn and b.test_time>=p_lastbinddate 
                            and test_station in(SELECT GROUP_NAME FROM SFIS1.C_ICT_STATION_T WHERE GROUP_NAME NOT LIKE '%AOI%' AND GROUP_NAME NOT LIKE '%API%' AND GROUP_NAME NOT LIKE '%ICT%' AND GROUP_NAME<>'BIOSCHECK')
                            and a.errorcode=b.test_code);
                            
                            INSERT INTO SFISM4.R_SAMPLESN_EC_QTY
                            select SAMPLESN3,test_code,count(1),UID,SYSDATE from SFISM4.R_repair_t a WHERE serial_number= p_lastbindsn and test_time>=p_lastbinddate
                            and test_station in(SELECT GROUP_NAME FROM SFIS1.C_ICT_STATION_T WHERE GROUP_NAME NOT LIKE '%AOI%' 
                            AND GROUP_NAME NOT LIKE '%API%' AND GROUP_NAME NOT LIKE '%ICT%' AND GROUP_NAME<>'BIOSCHECK')
                            and not exists
                            (select 1 from SFISM4.R_SAMPLESN_EC_QTY b where b.sn=SAMPLESN3 and a.test_code=b.errorcode)
                            GROUP BY test_code;     
                  end if;
              end if;                 
            end if;   
            
            --select count(*) into count1 from SFISM4.R_SAMPLESN_EC_QTY a,sfis1.C_SAMPLESN_ERRORCODE_SET b where a.SN=SAMPLESN3
                --and a.errorcode=b.error_code and a.qty>=b.CONTROL_TIMES;
               
            --if count1>0 then
                 --RES:='Sample SN '||SAMPLESN3||' ErrorCode Fail times more than TE set times,Send to maintain';
                 --raise ex;     
            --end if; 
            
            select count(*) into count1 from SFIS1.C_SAMPLESN_ERRORCODE_SET WHERE ERROR_CODE NOT IN('ALL','E*');  
                            
            if count1>0 then
                select count(*) into count1 from SFISM4.R_SAMPLESN_EC_QTY a,sfis1.C_SAMPLESN_ERRORCODE_SET b where a.SN=SAMPLESN3
                    and a.errorcode like '%'||b.error_code and a.qty>=b.CONTROL_TIMES;
               
                if count1>0 then
                     RES:='Sample SN '||SAMPLESN3||' ErrorCode Fail times more than TE set times,Send to maintain 1';
                     raise ex;     
                end if;    
            end if;
                                   
             select count(*) into count1 from SFISM4.R_SAMPLESN_EC_QTY a,sfis1.C_SAMPLESN_ERRORCODE_SET b where a.SN=SAMPLESN3
                and b.error_code='ALL' and a.qty>=b.CONTROL_TIMES;
               
            if count1>0 then
                 RES:='Sample SN '||SAMPLESN3||' ErrorCode Fail times more than TE set times,Send to maintain 2';
                 raise ex;     
            end if;      
        end if ;
        
        
       if sample_qty=1 then
                --SELECT qty into sample_qty,PN1 into sample_pn1,PN2 into sample_pn2,PN3 into sample_pn3 FROM SFIS1.C_SAMPLESN_BIND_SET WHERE PARENTPARTNO= modelname;
                 
                if qty='1' then                
                     select count(*) into count1 from sfism4.R_SAMPLESN_BIND_DETAIL where p_sn=SN and flag='1';
                     if count1>0 then
                        update sfism4.R_SAMPLESN_BIND_DETAIL set flag='0' where p_sn=SN and flag='1';
                        COMMIT;
                     end if;
                
                     insert into sfism4.R_SAMPLESN_BIND_DETAIL(P_SN,P_PN,C_SN,C_PN, FLAG,LASTEDITBY,LASTEDITDT,GROUP_NAME)
                     VALUES(SN,modelname,SAMPLESN1,sample_pn1,'1',UID,SYSDATE,GROUPNAME);
                     COMMIT;
                     
                     select count(*) into count1 from sfism4.R_SAMPLESN_BIND_QTY where sn=SAMPLESN1;
                     
                     if count1>0 then
                        update sfism4.R_SAMPLESN_BIND_QTY set t_qty=t_qty+1,c_qty=c_qty+1,lasteditdt=sysdate where sn=SAMPLESN1;
                        COMMIT;
                     else
                        insert into sfism4.R_SAMPLESN_BIND_QTY(SN,T_QTY,C_QTY,LASTEDITBY,LASTEDITDT)
                        values(SAMPLESN1,1,1,UID,sysdate);
                     end if;
                                                              
                     update sfism4.r_wip_tracking_t set group_name=GROUPNAME,station_name=GROUPNAME,IN_STATION_TIME=SYSDATE,EMP_NO=UID where serial_number=SN;
                     COMMIT;
                     
                     RES:='PASS,SCAN PASS';     
                end if; 
      
        elsif sample_qty=2 then
            if qty='1' then
                select count(*) into count1 from sfism4.R_SAMPLESN_BIND_DETAIL where p_sn=SN and flag='1';
                 if count1>0 then
                    update sfism4.R_SAMPLESN_BIND_DETAIL set flag='0' where p_sn=SN and flag='1';
                    COMMIT;
                 end if;                
            end if ;
            
            if qty='2' then
                 insert into sfism4.R_SAMPLESN_BIND_DETAIL(P_SN,P_PN,C_SN,C_PN, FLAG,LASTEDITBY,LASTEDITDT,GROUP_NAME)
                 VALUES(SN,modelname,SAMPLESN1,sample_pn1,'1',UID,SYSDATE,GROUPNAME);
                 COMMIT;
                 
                 insert into sfism4.R_SAMPLESN_BIND_DETAIL(P_SN,P_PN,C_SN,C_PN, FLAG,LASTEDITBY,LASTEDITDT,GROUP_NAME)
                 VALUES(SN,modelname,SAMPLESN2,sample_pn2,'1',UID,SYSDATE,GROUPNAME);
                 COMMIT;
                 
                 select count(*) into count1 from sfism4.R_SAMPLESN_BIND_QTY where sn=SAMPLESN1;
                     
                 if count1>0 then
                    update sfism4.R_SAMPLESN_BIND_QTY set t_qty=t_qty+1,c_qty=c_qty+1,lasteditdt=sysdate where sn=SAMPLESN1;
                    COMMIT;
                 else
                    insert into sfism4.R_SAMPLESN_BIND_QTY(SN,T_QTY,C_QTY,LASTEDITBY,LASTEDITDT)
                    values(SAMPLESN1,1,1,UID,sysdate);
                    COMMIT;
                 end if;
                 
                 select count(*) into count1 from sfism4.R_SAMPLESN_BIND_QTY where sn=SAMPLESN2;
                     
                 if count1>0 then
                    update sfism4.R_SAMPLESN_BIND_QTY set t_qty=t_qty+1,c_qty=c_qty+1,lasteditdt=sysdate where sn=SAMPLESN2;
                    COMMIT;
                 else
                    insert into sfism4.R_SAMPLESN_BIND_QTY(SN,T_QTY,C_QTY,LASTEDITBY,LASTEDITDT)
                    values(SAMPLESN2,1,1,UID,sysdate);
                    COMMIT;
                 end if;
                     
                 update sfism4.r_wip_tracking_t set group_name=GROUPNAME,station_name=GROUPNAME,IN_STATION_TIME=SYSDATE,EMP_NO=UID where serial_number=SN;
                 COMMIT; 
                 
                 RES:='PASS,SCAN PASS';
            end if;
        else
             if qty='1' then
                select count(*) into count1 from sfism4.R_SAMPLESN_BIND_DETAIL where p_sn=SN and flag='1';
                 if count1>0 then
                    update sfism4.R_SAMPLESN_BIND_DETAIL set flag='0' where p_sn=SN and flag='1';
                    COMMIT;
                 end if;                
            end if ;
            
            if qty='3' then
                 insert into sfism4.R_SAMPLESN_BIND_DETAIL(P_SN,P_PN,C_SN,C_PN, FLAG,LASTEDITBY,LASTEDITDT,GROUP_NAME)
                 VALUES(SN,modelname,SAMPLESN1,sample_pn1,'1',UID,SYSDATE,GROUPNAME);
                 COMMIT;
                 
                 insert into sfism4.R_SAMPLESN_BIND_DETAIL(P_SN,P_PN,C_SN,C_PN, FLAG,LASTEDITBY,LASTEDITDT,GROUP_NAME)
                 VALUES(SN,modelname,SAMPLESN2,sample_pn2,'1',UID,SYSDATE,GROUPNAME);
                 COMMIT; 
                 
                 insert into sfism4.R_SAMPLESN_BIND_DETAIL(P_SN,P_PN,C_SN,C_PN, FLAG,LASTEDITBY,LASTEDITDT,GROUP_NAME)
                 VALUES(SN,modelname,SAMPLESN3,sample_pn3,'1',UID,SYSDATE,GROUPNAME);
                 COMMIT;
                 
                 select count(*) into count1 from sfism4.R_SAMPLESN_BIND_QTY where sn=SAMPLESN1;
                     
                 if count1>0 then
                    update sfism4.R_SAMPLESN_BIND_QTY set t_qty=t_qty+1,c_qty=c_qty+1,lasteditdt=sysdate where sn=SAMPLESN1;
                    COMMIT;
                 else
                    insert into sfism4.R_SAMPLESN_BIND_QTY(SN,T_QTY,C_QTY,LASTEDITBY,LASTEDITDT)
                    values(SAMPLESN1,1,1,UID,sysdate);
                    COMMIT;
                 end if;
                 
                 select count(*) into count1 from sfism4.R_SAMPLESN_BIND_QTY where sn=SAMPLESN2;
                     
                 if count1>0 then
                    update sfism4.R_SAMPLESN_BIND_QTY set t_qty=t_qty+1,c_qty=c_qty+1,lasteditdt=sysdate where sn=SAMPLESN2;
                    COMMIT;
                 else
                    insert into sfism4.R_SAMPLESN_BIND_QTY(SN,T_QTY,C_QTY,LASTEDITBY,LASTEDITDT)
                    values(SAMPLESN2,1,1,UID,sysdate);
                    COMMIT;
                 end if;
                 
                 select count(*) into count1 from sfism4.R_SAMPLESN_BIND_QTY where sn=SAMPLESN3;
                     
                 if count1>0 then
                    update sfism4.R_SAMPLESN_BIND_QTY set t_qty=t_qty+1,c_qty=c_qty+1,lasteditdt=sysdate where sn=SAMPLESN3;
                    COMMIT;
                 else
                    insert into sfism4.R_SAMPLESN_BIND_QTY(SN,T_QTY,C_QTY,LASTEDITBY,LASTEDITDT)
                    values(SAMPLESN3,1,1,UID,sysdate);
                    COMMIT;
                 end if;
                 
                 update sfism4.r_wip_tracking_t set group_name=GROUPNAME,station_name=GROUPNAME,IN_STATION_TIME=SYSDATE,EMP_NO=UID where serial_number=SN;
                 COMMIT; 
                 
                 RES:='PASS,SCAN PASS';
            end if;
        end if;                               
   END IF ; 

   EXCEPTION
    WHEN ex
    then RES:=RES;
     WHEN OTHERS
   THEN NULL;
END;