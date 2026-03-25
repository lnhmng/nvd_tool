PROCEDURE                   sp_get_mell_filename
(
    WORKDATE        IN       VARCHAR2,
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

BEGIN

       select to_char(sysdate,'YYYYMMDD'),to_char(sysdate,'HH24MISS') INTO csvfiledate,csvfiletime from dual;


        maxrow:=50000;
        maxrow2:=10000;

       --CMPTRC_FOXCONN_098850_20200617T122933.txt

          select count(DISTINCT PARENT_SN) into v_count from SFISM4.B2B_MELL_ICT_LOG_T 
          where WORK_DATE=WORKDATE and FILE_NAME='N/A' order by PARENT_SN;

         while v_count>0 

          LOOP            
              SELECT COUNT(0) into tempcount FROM SFISM4.B2B_MELL_ICT_LOG_T 
              WHERE FILE_NAME LIKE 'FOXCONN_LH_NBU_ICT_'||csvfiletime||'_'||csvfiledate||'T%';
              if tempcount>0 then            
                 SELECT max(substr(FILE_NAME,36,3))+1 into tempno FROM SFISM4.B2B_MELL_ICT_LOG_T
                 WHERE FILE_NAME LIKE 'FOXCONN_LH_NBU_ICT_'||csvfiletime||'_'||csvfiledate||'T%';
                 if LENGTH(tempno)<2 then

                    tempno:='00'||tempno;
                  ELSIF (LENGTH(tempno)=2) then    
                    tempno:='0'||tempno;
                  ELSIF LENGTH(tempno)=3 then
                    tempno:=tempno; 

                 end if;
                 cabfile:='FOXCONN_LH_NBU_ICT_'||csvfiletime||'_'||csvfiledate||'T'||tempno||'.txt';
              else
                 cabfile:='FOXCONN_LH_NBU_ICT_'||csvfiletime||'_'||csvfiledate||'T001.txt';
              end if;          


                 UPDATE SFISM4.B2B_MELL_ICT_LOG_T SET FILE_NAME=cabfile 
                  WHERE WORK_DATE=WORKDATE AND FILE_NAME='N/A' AND PARENT_SN IN (
                 -- SELECT DISTINCT PARENT_SN FROM (
                      select DISTINCT PARENT_SN from SFISM4.B2B_MELL_ICT_LOG_T  
                      where WORK_DATE=WORKDATE  and FILE_NAME='N/A'
                 -- )
                 --  WHERE ROWNUM<maxrow);
                   AND ROWNUM<maxrow);

              select count(DISTINCT PARENT_SN) into v_count from SFISM4.B2B_MELL_ICT_LOG_T 
              where WORK_DATE=WORKDATE and FILE_NAME='N/A' order by PARENT_SN;

        END LOOP;  

      -- FOXCONN_SFISM4.B2B_MELL_PROCESS_LOG_T文件名BEGIN 
        select count(0) into v_count from SFISM4.B2B_MELL_PROCESS_LOG_T 
          where WORK_DATE=WORKDATE and FILE_NAME='N/A' order by SERIAL_NUMBER;


        while v_count>0
         LOOP            
              SELECT COUNT(0) into tempcount FROM SFISM4.B2B_MELL_PROCESS_LOG_T 
              WHERE FILE_NAME LIKE 'FOXCONN_LH_NBU_PROCESS_'||csvfiletime||'_'||csvfiledate||'T%';
              if tempcount>0 then            
                 SELECT max(substr(FILE_NAME,40,3))+1 into tempno FROM SFISM4.B2B_MELL_PROCESS_LOG_T
                 WHERE FILE_NAME LIKE 'FOXCONN_LH_NBU_PROCESS_'||csvfiletime||'_'||csvfiledate||'T%';
                 if LENGTH(tempno)<2 then

                    tempno:='00'||tempno;
                  ELSIF (LENGTH(tempno)=2) then    
                    tempno:='0'||tempno;
                  ELSIF LENGTH(tempno)=3 then
                    tempno:=tempno;               

                 end if;
                 cabfile:='FOXCONN_LH_NBU_PROCESS_'||csvfiletime||'_'||csvfiledate||'T'||tempno||'.txt';
              else
                 cabfile:='FOXCONN_LH_NBU_PROCESS_'||csvfiletime||'_'||csvfiledate||'T001.txt';
              end if; 

                 UPDATE SFISM4.B2B_MELL_PROCESS_LOG_T SET FILE_NAME=cabfile 
                  WHERE WORK_DATE=WORKDATE AND FILE_NAME='N/A' AND SERIAL_NUMBER IN (

                      select DISTINCT SERIAL_NUMBER from SFISM4.B2B_MELL_PROCESS_LOG_T  
                      where WORK_DATE=WORKDATE  and FILE_NAME='N/A'

                     AND ROWNUM<maxrow);

                 select count(0) into v_count from SFISM4.B2B_MELL_PROCESS_LOG_T 
                 where WORK_DATE=WORKDATE and FILE_NAME='N/A';


        END LOOP;  

      -- FOXCONN_SFISM4.B2B_MELL_PROCESS_LOG_T文件名 END.

      -- FOXCONN_SFISM4.B2B_MELL_FA_LOG_T文件名BEGIN 

        select count(0) into v_count from SFISM4.B2B_MELL_FA_LOG_T 
          where WORK_DATE=WORKDATE and FILE_NAME='N/A' order by SN;


        while v_count>0
         LOOP            
              SELECT COUNT(0) into tempcount FROM SFISM4.B2B_MELL_FA_LOG_T 
              WHERE FILE_NAME LIKE 'FOXCONN_LH_NBU_REPAIR_'||csvfiletime||'_'||csvfiledate||'T%';
              if tempcount>0 then            
                 SELECT max(substr(FILE_NAME,39,3))+1 into tempno FROM SFISM4.B2B_MELL_FA_LOG_T
                 WHERE FILE_NAME LIKE 'FOXCONN_LH_NBU_REPAIR_'||csvfiletime||'_'||csvfiledate||'T%';
                 if LENGTH(tempno)<2 then

                    tempno:='00'||tempno;
                  ELSIF (LENGTH(tempno)=2) then    
                    tempno:='0'||tempno;
                  ELSIF LENGTH(tempno)=3 then
                    tempno:=tempno;               

                 end if;
                 cabfile:='FOXCONN_LH_NBU_REPAIR_'||csvfiletime||'_'||csvfiledate||'T'||tempno||'.txt';
              else
                 cabfile:='FOXCONN_LH_NBU_REPAIR_'||csvfiletime||'_'||csvfiledate||'T001.txt';
              end if; 


                 UPDATE SFISM4.B2B_MELL_FA_LOG_T SET FILE_NAME=cabfile 
                  WHERE WORK_DATE=WORKDATE AND FILE_NAME='N/A' AND SN IN (

                      select DISTINCT SN from SFISM4.B2B_MELL_FA_LOG_T  
                      where WORK_DATE=WORKDATE  and FILE_NAME='N/A'

                     AND ROWNUM<maxrow);              

                 select count(0) into v_count from SFISM4.B2B_MELL_FA_LOG_T 
                 where WORK_DATE=WORKDATE and FILE_NAME='N/A';


        END LOOP;  

      -- FOXCONN_SFISM4.B2B_MELL_FA_LOG_T文件名 END.

       
      -- FOXCONN_SFISM4.B2B_MELL_SA_LOG_T文件名BEGIN 

         select count(DISTINCT PARENT_SN) into v_count from SFISM4.B2B_MELL_SA_LOG_T 
          where WORK_DATE=WORKDATE and FILE_NAME='N/A' order by PARENT_SN;


        while v_count>0 

        LOOP            
              SELECT COUNT(0) into tempcount FROM SFISM4.B2B_MELL_SA_LOG_T 
              WHERE FILE_NAME LIKE 'FOXCONN_LH_NBU_SA_'||csvfiletime||'_'||csvfiledate||'T%';
              if tempcount>0 then            
                 SELECT max(substr(FILE_NAME,35,3))+1 into tempno FROM SFISM4.B2B_MELL_SA_LOG_T
                 WHERE FILE_NAME LIKE 'FOXCONN_LH_NBU_SA_'||csvfiletime||'_'||csvfiledate||'T%';
                 if LENGTH(tempno)<2 then

                    tempno:='00'||tempno;
                  ELSIF (LENGTH(tempno)=2) then    
                    tempno:='0'||tempno;
                  ELSIF LENGTH(tempno)=3 then
                    tempno:=tempno; 

                 end if;
                 cabfile:='FOXCONN_LH_NBU_SA_'||csvfiletime||'_'||csvfiledate||'T'||tempno||'.txt';
              else
                 cabfile:='FOXCONN_LH_NBU_SA_'||csvfiletime||'_'||csvfiledate||'T001.txt';
              end if;          


                 UPDATE SFISM4.B2B_MELL_SA_LOG_T SET FILE_NAME=cabfile 
                  WHERE WORK_DATE=WORKDATE AND FILE_NAME='N/A' AND PARENT_SN IN (
                 -- SELECT DISTINCT PARENT_SN FROM (
                      select DISTINCT PARENT_SN from SFISM4.B2B_MELL_SA_LOG_T  
                      where WORK_DATE=WORKDATE  and FILE_NAME='N/A'
                 -- )
                 --  WHERE ROWNUM<maxrow);
                   AND ROWNUM<maxrow);

              select count(DISTINCT PARENT_SN) into v_count from SFISM4.B2B_MELL_SA_LOG_T 
              where WORK_DATE=WORKDATE and FILE_NAME='N/A' order by PARENT_SN;

        END LOOP;  


    COMMIT;
    res:='Get mellanox FileName OK!';
    EXCEPTION
        WHEN OTHERS
        THEN
           rollback;
           res:='Get mellanox FileName Err;'||substr(sqlerrm,1,80); 


END;