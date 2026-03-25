PROCEDURE       FA_LINEOFF_TEST_DEAL (
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

       /*
       select count(*) into count1 from sfism4.r_wip_tracking_t where serial_number=SN and error_flag='1';
        if count1>0 THEN
           RES:='Should be sent to Repair'; 
           raise ex;
       end if; 
      */
       select model_name into  modelname from sfism4.r_wip_tracking_t where serial_number=SN;   

      /*
       SFIS1.CHECK_ROUTE3('',GROUPNAME,SN,RES);
       IF LENGTH(RES)>0 AND RES<>'OK' THEN
           RES:=RES;
           raise ex;
       END if;
      */


       SELECT count(*) into count1 FROM SFISM4.R_OFF_LINE_MODEL_BIND_SET WHERE PARENTPARTNO= modelname;
       if count1>0 then
          SELECT NVL(PN1,''),NVL(PN2,''),NVL(PN3,''),QTY into sample_pn1, sample_pn2, sample_pn3,sample_qty FROM SFISM4.R_OFF_LINE_MODEL_BIND_SET WHERE PARENTPARTNO= modelname;
          RES:='OK,'|| sample_pn1||','||sample_pn2||','||sample_pn3||','||sample_qty; 
       else
          RES:='TE not set BIND INFO';
          raise ex;  
       end if;
   end if; 

    if TRANTYPE='BIND' THEN

        select model_name into  modelname from sfism4.r_wip_tracking_t where serial_number=SN;      

        SELECT NVL(PN1,''),NVL(PN2,''),NVL(PN3,''),QTY into sample_pn1, sample_pn2, sample_pn3,sample_qty FROM SFISM4.R_OFF_LINE_MODEL_BIND_SET WHERE PARENTPARTNO= modelname;

        if qty='1' then
            if SAMPLESN1 is null or SAMPLESN1='' then
                RES:='Please Scan Sample SN';
                raise ex; 
            end if;

          --  SELECT count(*) into count1 fROM sfism4.R_OFF_LINE_BIND_DETAIL WHERE LASTEDITDT>SYSDATE-30/24/60 and c_sn=SAMPLESN1;
          --  if count1>0 then
          --      RES:='Scan Duplicate';
          --      raise ex;
          --  end if;

            select count(*) into count1 from sfism4.R_OFF_LINE_MODEL_SET where SKUNO=sample_pn1;
            if count1>0 then
                select PREFIX,SNLEN,CONTROL_TIMES INTO prefix,snlen,p_controltime from sfism4.R_OFF_LINE_MODEL_SET where SKUNO=sample_pn1;

                if SUBSTR(SAMPLESN1,1,length(PREFIX))<>PREFIX then
                    RES:='Sample SN '||SAMPLESN1||' prefix not match SN RULE,Contact TE';
                    raise ex;  
                end if;

                if length(SAMPLESN1)<>snlen then
                    RES:='Sample SN '||SAMPLESN1||' length not match SN RULE,Contact TE';
                    raise ex;  
                end if;


                select count(*) into count1 from SFISM4.R_OFF_LINE_BIND_QTY where sn=SAMPLESN1 and c_qty>=p_controltime;
                if count1>0 then
                    RES:='Sample SN '||SAMPLESN1||' BIND times more than TE set times,Send to maintain';
                    raise ex; 
                end if;


                /*
                 select count(*) into count1 from sfism4.R_SAMPLESN_BIND_DETAIL where sn=SAMPLESN1 ;
                  if count1>p_controltime then

                    RES:='Sample SN '||SAMPLESN1||' BIND times more than TE set times,Send to maintain';
                    raise ex; 

                   end if;
                */

            else
                 RES:='PN1 '||sample_pn1||' TE not set SN RULE,Contact TE';
                 raise ex;  
            end if;


        end if ;



       if sample_qty=1 then

                if qty='1' then 


                     insert into sfism4.R_OFF_LINE_BIND_DETAIL(P_SN,P_PN,C_SN,C_PN, FLAG,LASTEDITBY,LASTEDITDT,GROUP_NAME)
                     VALUES(SN,modelname,SAMPLESN1,sample_pn1,'1',UID,SYSDATE,GROUPNAME);
                     COMMIT;

                     select count(*) into count1 from sfism4.R_OFF_LINE_BIND_QTY where sn=SAMPLESN1;

                     if count1>0 then
                        update sfism4.R_OFF_LINE_BIND_QTY set t_qty=t_qty+1,c_qty=c_qty+1,lasteditdt=sysdate where sn=SAMPLESN1;

                     else
                        insert into sfism4.R_OFF_LINE_BIND_QTY(SN,T_QTY,C_QTY,LASTEDITBY,LASTEDITDT)
                        values(SAMPLESN1,1,1,UID,sysdate);
                     end if;

                    -- update sfism4.r_wip_tracking_t set group_name=GROUPNAME,station_name=GROUPNAME,IN_STATION_TIME=SYSDATE,EMP_NO=UID where serial_number=SN;
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