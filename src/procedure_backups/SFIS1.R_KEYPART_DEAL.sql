PROCEDURE             R_KEYPART_DEAL (
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
sample_pn1_temp varchar2(30);
sample_pn2_temp varchar2(30);
sample_pn3_temp varchar2(30);
sample_qty      int;
count1          int;
prefix          varchar2(15);
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
       
       SELECT count(*) into count1 FROM SFIS1.C_KEYPART_BIND_SET WHERE PARENTPARTNO= modelname;
       if count1>0 then
          SELECT NVL(PN1,''),NVL(PN2,''),NVL(PN3,''),QTY into sample_pn1, sample_pn2, sample_pn3,sample_qty FROM SFIS1.C_KEYPART_BIND_SET WHERE PARENTPARTNO= modelname;
          RES:='OK,'|| sample_pn1||','||sample_pn2||','||sample_pn3||','||sample_qty; 
       else
          RES:='TE not set BIND INFO';
          raise ex;  
       end if;
    end if; 
   
    if TRANTYPE='BIND' THEN
        
        select model_name into  modelname from sfism4.r_wip_tracking_t where serial_number=SN;      
    
        SELECT NVL(PN1,''),NVL(PN2,''),NVL(PN3,''),QTY into sample_pn1, sample_pn2, sample_pn3,sample_qty FROM SFIS1.C_KEYPART_BIND_SET WHERE PARENTPARTNO= modelname;
  
        if qty='1' then
            if SAMPLESN1 is null or SAMPLESN1='' then
                RES:='Please Scan Sample SN';
                raise ex; 
            end if;
            
            SELECT count(*) into count1 fROM sfism4.R_KEYPART_BIND_DETAIL WHERE LASTEDITDT>SYSDATE-5/24/60 and c_sn=SAMPLESN1;
            if count1>0 then
                RES:='Scan Duplicate';
                raise ex;
            end if;
            
            
            select count(*) into count1 From sfism4.r_wip_tracking_t where serial_number=SAMPLESN1;
            
            if(count1>0) then
                select model_name into sample_pn1_temp From sfism4.r_wip_tracking_t where serial_number=SAMPLESN1;
                      
                if sample_pn1<> sample_pn1_temp then
                     RES:='小板料號與配置的料號不匹配';
                    raise ex;
                end if;
            else
                RES:='小板SN1不存在';
                raise ex;            
            end if;

        end if ;
        
        if qty='2' then
            if SAMPLESN2 is null or SAMPLESN2='' then
                RES:='Please Scan Sample SN';
                raise ex; 
            end if;
            
            SELECT count(*) into count1 fROM sfism4.R_KEYPART_BIND_DETAIL WHERE LASTEDITDT>SYSDATE-5/24/60 and c_sn=SAMPLESN2;
            if count1>0 then
                RES:='Scan Duplicate';
                raise ex;
            end if;
            
            select count(*) into count1 From sfism4.r_wip_tracking_t where serial_number=SAMPLESN2;
            
            if(count1>0) then
                select model_name into sample_pn2_temp From sfism4.r_wip_tracking_t where serial_number=SAMPLESN2;
                      
                if sample_pn2<> sample_pn2_temp then
                     RES:='小板料號與配置的料號不匹配';
                    raise ex;
                end if;
            else
                RES:='小板SN2不存在';
                raise ex;            
            end if;
                                          
        end if;   
            
          
      
        
        if qty='3' then
           if SAMPLESN3 is null or SAMPLESN3='' then
                RES:='Please Scan Sample SN';
                raise ex; 
           end if; 
        
           SELECT count(*) into count1 fROM sfism4.R_KEYPART_BIND_DETAIL WHERE LASTEDITDT>SYSDATE-5/24/60 and c_sn=SAMPLESN3;
           if count1>0 then
               RES:='Scan Duplicate';
               raise ex;
           end if; 
           
            select count(*) into count1 From sfism4.r_wip_tracking_t where serial_number=SAMPLESN3;
            
            if(count1>0) then
                select model_name into sample_pn3_temp From sfism4.r_wip_tracking_t where serial_number=SAMPLESN3;
                      
                if sample_pn3<> sample_pn3_temp then
                     RES:='小板料號與配置的料號不匹配';
                    raise ex;
                end if;
            else
                RES:='小板SN3不存在';
                raise ex;            
            end if;
                          
        END IF; 
            
       if sample_qty=1 then
               
                 
                if qty='1' then                
                     select count(*) into count1 from sfism4.R_KEYPART_BIND_DETAIL where p_sn=SN and flag='1';
                     if count1>0 then
                        update sfism4.R_KEYPART_BIND_DETAIL set flag='0' where p_sn=SN and flag='1';
                        COMMIT;
                     end if;
                
                     insert into sfism4.R_KEYPART_BIND_DETAIL(P_SN,P_PN,C_SN,C_PN, FLAG,LASTEDITBY,LASTEDITDT,GROUP_NAME)
                     VALUES(SN,modelname,SAMPLESN1,sample_pn1,'1',UID,SYSDATE,GROUPNAME);
                     COMMIT;
                     
                    
                                                              
                     update sfism4.r_wip_tracking_t set group_name=GROUPNAME,station_name=GROUPNAME,IN_STATION_TIME=SYSDATE,EMP_NO=UID where serial_number=SN;
                     COMMIT;
                     
                     RES:='PASS,SCAN PASS';     
                end if; 
      
        elsif sample_qty=2 then
            if qty='1' then
                select count(*) into count1 from sfism4.R_KEYPART_BIND_DETAIL where p_sn=SN and flag='1';
                 if count1>0 then
                    update sfism4.R_KEYPART_BIND_DETAIL set flag='0' where p_sn=SN and flag='1';
                    COMMIT;
                 end if;                
            end if ;
            
            if qty='2' then
                 insert into sfism4.R_KEYPART_BIND_DETAIL(P_SN,P_PN,C_SN,C_PN, FLAG,LASTEDITBY,LASTEDITDT,GROUP_NAME)
                 VALUES(SN,modelname,SAMPLESN1,sample_pn1,'1',UID,SYSDATE,GROUPNAME);
                 COMMIT;
                 
                 insert into sfism4.R_KEYPART_BIND_DETAIL(P_SN,P_PN,C_SN,C_PN, FLAG,LASTEDITBY,LASTEDITDT,GROUP_NAME)
                 VALUES(SN,modelname,SAMPLESN2,sample_pn2,'1',UID,SYSDATE,GROUPNAME);
                 COMMIT;
                 
                 
                     
                 update sfism4.r_wip_tracking_t set group_name=GROUPNAME,station_name=GROUPNAME,IN_STATION_TIME=SYSDATE,EMP_NO=UID where serial_number=SN;
                 COMMIT; 
                 
                 RES:='PASS,SCAN PASS';
            end if;
        else
             if qty='1' then
                select count(*) into count1 from sfism4.R_KEYPART_BIND_DETAIL where p_sn=SN and flag='1';
                 if count1>0 then
                    update sfism4.R_KEYPART_BIND_DETAIL set flag='0' where p_sn=SN and flag='1';
                    COMMIT;
                 end if;                
            end if ;
            
            if qty='3' then
                 insert into sfism4.R_KEYPART_BIND_DETAIL(P_SN,P_PN,C_SN,C_PN, FLAG,LASTEDITBY,LASTEDITDT,GROUP_NAME)
                 VALUES(SN,modelname,SAMPLESN1,sample_pn1,'1',UID,SYSDATE,GROUPNAME);
                 COMMIT;
                 
                 insert into sfism4.R_KEYPART_BIND_DETAIL(P_SN,P_PN,C_SN,C_PN, FLAG,LASTEDITBY,LASTEDITDT,GROUP_NAME)
                 VALUES(SN,modelname,SAMPLESN2,sample_pn2,'1',UID,SYSDATE,GROUPNAME);
                 COMMIT; 
                 
                 insert into sfism4.R_KEYPART_BIND_DETAIL(P_SN,P_PN,C_SN,C_PN, FLAG,LASTEDITBY,LASTEDITDT,GROUP_NAME)
                 VALUES(SN,modelname,SAMPLESN3,sample_pn3,'1',UID,SYSDATE,GROUPNAME);
                 COMMIT;
                 
                 
                 
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