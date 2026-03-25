PROCEDURE                   SAMPLESN_DEAL_CHECK (
   SAMPLESN1   IN     VARCHAR2,
   RES            OUT VARCHAR2)
IS
   vc_pn           VARCHAR2 (30);
   count1          INT;
   count2          INT;
   prefix          VARCHAR2 (15);
   snlen           INT;
   p_controltime   INT;
    p_lastbindsn    varchar2(30);
    p_lastbinddate  date;
    p_lastmtdate    date;
    p_lastECdate    date;
   ex              EXCEPTION;
BEGIN
   RES := 'OK';

   IF SAMPLESN1 IS NULL OR SAMPLESN1 = ''
   THEN
      RES := 'Please Scan Sample SN';
      RAISE ex;
   END IF;

   SELECT COUNT(*)
     INTO count1
     FROM SFISM4.R_SAMPLESN_BIND_DETAIL
    WHERE c_sn = SAMPLESN1; 
    
    IF count1>0
    THEN 
        SELECT c_pn INTO vc_pn
         FROM SFISM4.R_SAMPLESN_BIND_DETAIL
            WHERE c_sn = SAMPLESN1 AND rownum=1;
    --modify by LLF 2017-07-11
    ELSE 
          select count(1) into count1 FROM sfis1.C_SAMPLESN_SET 
            WHERE prefix=SUBSTR(SAMPLESN1,1,LENGTH(PREFIX)) and snlen=length(SAMPLESN1);
            
          if count1>0 then  
              RES := 'OK'; 
              raise ex;
          else
              RES := 'Sample SN (' || SAMPLESN1 || ') Not match the SN rule!';
              raise ex;   
          end if;
            --    RES := 'Sample SN (' || SAMPLESN1 || ') Not exist!';
            --    raise ex;
    END IF ;

   SELECT COUNT (*)
     INTO count2
     FROM sfis1.C_SAMPLESN_SET
    WHERE SKUNO = vc_pn;

   IF count2 > 0
   THEN
      SELECT PREFIX, SNLEN, CONTROL_TIMES
        INTO prefix, snlen, p_controltime
        FROM sfis1.C_SAMPLESN_SET
       WHERE SKUNO = vc_pn;

      IF SUBSTR (SAMPLESN1, 1, LENGTH (PREFIX)) <> PREFIX
      THEN
         RES :=
               'Sample SN '
            || SAMPLESN1
            || ' prefix not match SN RULE,Contact TE';
         RAISE ex;
      END IF;

      IF LENGTH (SAMPLESN1) <> snlen
      THEN
         RES :=
               'Sample SN '
            || SAMPLESN1
            || ' length not match SN RULE,Contact TE';
         RAISE ex;
      END IF;

      SELECT COUNT (*)
        INTO count1
        FROM SFISM4.R_SAMPLESN_BIND_QTY
       WHERE sn = SAMPLESN1 AND c_qty >= p_controltime;

      IF count1 > 0
      THEN
         RES :=
               'Sample SN '
            || SAMPLESN1
            || ' BIND times more than TE set times,Send to maintain';
         RAISE ex;
      END IF;
   ELSE
      RES := 'PN1 (' || vc_pn || ') TE not set SN RULE,Contact TE';
      RAISE ex;
   END IF;


   --check fail qty
   
   SELECT COUNT (*)
     INTO count1
     FROM SFIS1.C_SAMPLESN_ERRORCODE_SET
    WHERE ERROR_CODE NOT IN ('ALL', 'E*');
    

   IF count1 > 0
   THEN
      SELECT COUNT (*)
        INTO count1
        FROM SFISM4.R_SAMPLESN_EC_QTY a, sfis1.C_SAMPLESN_ERRORCODE_SET b
       WHERE a.SN = SAMPLESN1
             AND a.errorcode LIKE '%' || b.ERROR_CODE AND B.ERROR_CODE <>'ALL'
             AND a.qty >= b.CONTROL_TIMES;
      
      IF count1 > 0
      THEN
         RES :=
               'Sample SN '
            || SAMPLESN1
            || ' ErrorCode Fail times more than TE set times,Send to maintain 1';
         RAISE ex;
      END IF;
   END IF;

   SELECT COUNT (*)
     INTO count1
     FROM SFISM4.R_SAMPLESN_EC_QTY a, (SELECT *fROM sfis1.C_SAMPLESN_ERRORCODE_SET WHERE ERROR_CODE='ALL') b
    WHERE  a.SN = SAMPLESN1
          AND a.qty >= b.CONTROL_TIMES;

   IF count1 > 0
   THEN
      RES :=
            'Sample SN '
         || SAMPLESN1
         || ' ErrorCode Fail times more than TE set times,Send to maintain 2';
      RAISE ex;
   END IF;
   
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
   
EXCEPTION
   WHEN ex
   THEN
      RES := RES;
   WHEN OTHERS
   THEN
      NULL;
END;