PROCEDURE       sp_get_mellanox_filename
(
    v_dn        IN       VARCHAR2,
    res         OUT      VARCHAR2
)
AS
v_count       INTEGER;
maxrow        INTEGER;
maxrow2        INTEGER;
tempcount     INTEGER;
tempno        VARCHAR2 (100);
pdfile        VARCHAR2 (100);
sdfile        VARCHAR2 (100);
cabfile       VARCHAR2 (100);
csvfiledate   VARCHAR2 (100);
csvfiletime   VARCHAR2 (100);
filedate      VARCHAR2 (30);

BEGIN

       select to_char(sysdate,'YYYYMMDD'),to_char(sysdate,'HH24MISS') INTO csvfiledate,csvfiletime from dual;

       filedate:=substr(csvfiledate,3,6); 

        maxrow:=49880;
        maxrow2:=10000;

       --CMPTRC_FOXCONN_098850_20200617T122933.txt
        /*
          select count(DISTINCT PARENT_SN) into v_count from sfism4.b2b_mell_ship_detail_t 
          where dn_no=v_dn and FILE_NAME='N/A' order by PARENT_SN;


        while v_count>0 LOOP            
              SELECT COUNT(0) into tempcount FROM sfism4.b2b_mell_ship_detail_t 
              WHERE FILE_NAME LIKE 'CMPTRC_FOXCONN_LH_'||csvfiletime||'_'||csvfiledate||'T%';
              if tempcount>0 then            
                 SELECT max(substr(FILE_NAME,35,3))+1 into tempno FROM sfism4.b2b_mell_ship_detail_t
                 WHERE FILE_NAME LIKE 'CMPTRC_FOXCONN_LH_'||csvfiletime||'_'||csvfiledate||'T%';
                 if LENGTH(tempno)<2 then

                    tempno:='00'||tempno;
                  ELSIF (LENGTH(tempno)=2) then    
                    tempno:='0'||tempno;
                  ELSIF LENGTH(tempno)=3 then
                    tempno:=tempno; 

                 end if;
                 cabfile:='CMPTRC_FOXCONN_LH_'||csvfiletime||'_'||csvfiledate||'T'||tempno||'.txt';
              else
                 cabfile:='CMPTRC_FOXCONN_LH_'||csvfiletime||'_'||csvfiledate||'T001.txt';
              end if;          

          
                 UPDATE sfism4.b2b_mell_ship_detail_t SET FILE_NAME=cabfile 
                  WHERE dn_no=v_dn AND FILE_NAME='N/A' AND PARENT_SN IN (
              
                      select DISTINCT PARENT_SN from sfism4.b2b_mell_ship_detail_t  
                      where dn_no=v_dn  and FILE_NAME='N/A' 
                 
                  AND ROWNUM<=maxrow);

              select count(DISTINCT PARENT_SN) into v_count from sfism4.b2b_mell_ship_detail_t 
              where dn_no=v_dn and FILE_NAME='N/A' order by PARENT_SN;
 
       END LOOP;  

        */
         
           select count(0) into v_count from sfism4.b2b_mell_ship_detail_t 
          where dn_no=v_dn and FILE_NAME='N/A' order by DN_NO,RECORD_ID;
   
   
        while v_count>0 LOOP            
              SELECT COUNT(0) into tempcount FROM sfism4.b2b_mell_ship_detail_t 
              WHERE FILE_NAME LIKE 'CMPTRC_FOXCONN_LH_'||csvfiletime||'_'||csvfiledate||'T%';
              if tempcount>0 then            
                 SELECT max(substr(FILE_NAME,35,3))+1 into tempno FROM sfism4.b2b_mell_ship_detail_t
                 WHERE FILE_NAME LIKE 'CMPTRC_FOXCONN_LH_'||csvfiletime||'_'||csvfiledate||'T%';
                 if LENGTH(tempno)<2 then

                    tempno:='00'||tempno;
                  ELSIF (LENGTH(tempno)=2) then    
                    tempno:='0'||tempno;
                  ELSIF LENGTH(tempno)=3 then
                    tempno:=tempno; 

                 end if;
                 cabfile:='CMPTRC_FOXCONN_LH_'||csvfiletime||'_'||csvfiledate||'T'||tempno||'.txt';
              else
                 cabfile:='CMPTRC_FOXCONN_LH_'||csvfiletime||'_'||csvfiledate||'T001.txt';
                 tempno:=1;
              end if;          

            
              --   UPDATE sfism4.b2b_mell_ship_detail_t SET FILE_NAME=cabfile 
              --    WHERE dn_no=v_dn AND FILE_NAME='N/A' AND PARENT_SN IN (
              
              --        select DISTINCT PARENT_SN from sfism4.b2b_mell_ship_detail_t  
              --        where dn_no=v_dn  and FILE_NAME='N/A' 
              --     AND RECORD_ID<=TO_NUMBER(tempno)*maxrow);
              
                 UPDATE sfism4.b2b_mell_ship_detail_t SET FILE_NAME=cabfile 
                  WHERE dn_no=v_dn AND FILE_NAME='N/A' AND FG_SN IN (              
                      select DISTINCT FG_SN from sfism4.b2b_mell_ship_detail_t  
                      where dn_no=v_dn  and FILE_NAME='N/A' 
                   AND RECORD_ID<=TO_NUMBER(tempno)*maxrow);
        
        
        
              select count(0) into v_count from sfism4.b2b_mell_ship_detail_t 
              where dn_no=v_dn and FILE_NAME='N/A' order by DN_NO,RECORD_ID;




       END LOOP;  


       
       


       --FOXCONN_20200617T01.txt  按dn在生成文件名 


        select count(0) into v_count from sfism4.b2b_mell_ship_head_t 
          where dn_no=v_dn and FILE_NAME='N/A' order by DN_NO,PARENT_SN;


        while v_count>0 LOOP            
              SELECT COUNT(0) into tempcount FROM sfism4.b2b_mell_ship_head_t 
              WHERE FILE_NAME LIKE '000%'||'_'||filedate||'.txt';

              if tempcount>0 then            
                 SELECT max(substr(FILE_NAME,4,3))+1 into tempno FROM sfism4.b2b_mell_ship_head_t                

                 WHERE FILE_NAME LIKE '000%'||'_'||filedate||'.txt';

                if LENGTH(tempno)<2 then

                    tempno:='00'||tempno;
                  ELSIF (LENGTH(tempno)=2) then    
                    tempno:='0'||tempno;
                  ELSIF LENGTH(tempno)=3 then
                    tempno:=tempno;               

                 end if;
               --  cabfile:='000'||tempno||filedate||'_'||'.txt';

                 cabfile:='000'||tempno||'_'||filedate||'.txt';
              else
                 cabfile:='000001'||'_'||filedate||'.txt';
              end if;          

           UPDATE sfism4.b2b_mell_ship_head_t SET FILE_NAME=cabfile 
              WHERE dn_no=v_dn AND FILE_NAME='N/A' AND PARENT_SN IN (
                  SELECT DISTINCT PARENT_SN FROM (
                      select PARENT_SN from sfism4.b2b_mell_ship_head_t  
                      where dn_no=v_dn  and FILE_NAME='N/A'
                  ) WHERE ROWNUM<maxrow2);

              select count(0) into v_count from sfism4.b2b_mell_ship_head_t 
              where dn_no=v_dn and FILE_NAME='N/A';



        END LOOP;  


    COMMIT;
    res:='Get mellanox FileName OK!';
    EXCEPTION
        WHEN OTHERS
        THEN
           rollback;
           res:='Get mellanox FileName Err;'||substr(sqlerrm,1,80); 


END;