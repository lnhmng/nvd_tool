PROCEDURE             HAINAHISTORYRECORD_temp
AS 
   TYPE TYP_SMTCODE IS TABLE OF VARCHAR (800);
   VAR_TYP_SMTCODE             TYP_SMTCODE; 
   VAR_SMTCODE                 VARCHAR (50);
   tempcount                   INT; 
   getdata                     varchar2(100);
   
   DATEBEGIN VARCHAR (800); --
   DATEEND VARCHAR (800); --
   YDSJ VARCHAR (800); --
   INPUTQTY VARCHAR (800);      --
   FIRSTPASSQTY VARCHAR (800);  --
   REWORKPASSQTY VARCHAR (800); --
   OUTPUTQTY VARCHAR (800);     --
   DAYTONGJITIME VARCHAR (800); --
   DAYSENDDATATIME VARCHAR (800); --
   HOUR_1_QTY VARCHAR (800); 
   HOUR_1_TIME VARCHAR (800); 
   HOUR_2_QTY VARCHAR (800); 
   HOUR_2_TIME VARCHAR (800); 
   HOUR_3_QTY VARCHAR (800); 
   HOUR_3_TIME VARCHAR (800); 
   HOUR_4_QTY VARCHAR (800); 
   HOUR_4_TIME VARCHAR (800); 
   HOUR_5_QTY VARCHAR (800); 
   HOUR_5_TIME VARCHAR (800); 
   HOUR_6_QTY VARCHAR (800); 
   HOUR_6_TIME VARCHAR (800); 
   HOUR_7_QTY VARCHAR (800); 
   HOUR_7_TIME VARCHAR (800); 
   HOUR_8_QTY VARCHAR (800); 
   HOUR_8_TIME VARCHAR (800); 
   HOUR_9_QTY VARCHAR (800); 
   HOUR_9_TIME VARCHAR (800); 
   HOUR_10_QTY VARCHAR (800); 
   HOUR_10_TIME VARCHAR (800); 
   HOUR_11_QTY VARCHAR (800); 
   HOUR_11_TIME VARCHAR (800); 
   HOUR_12_QTY VARCHAR (800); 
   HOUR_12_TIME VARCHAR (800); 
   HOUR_13_QTY VARCHAR (800); 
   HOUR_13_TIME VARCHAR (800); 
   HOUR_14_QTY VARCHAR (800); 
   HOUR_14_TIME VARCHAR (800); 
   HOUR_15_QTY VARCHAR (800); 
   HOUR_15_TIME VARCHAR (800); 
   HOUR_16_QTY VARCHAR (800); 
   HOUR_16_TIME VARCHAR (800); 
   HOUR_17_QTY VARCHAR (800); 
   HOUR_17_TIME VARCHAR (800); 
   HOUR_18_QTY VARCHAR (800); 
   HOUR_18_TIME VARCHAR (800); 
   HOUR_19_QTY VARCHAR (800); 
   HOUR_19_TIME VARCHAR (800); 
   HOUR_20_QTY VARCHAR (800); 
   HOUR_20_TIME VARCHAR (800); 
   HOUR_21_QTY VARCHAR (800); 
   HOUR_21_TIME VARCHAR (800); 
   HOUR_22_QTY VARCHAR (800); 
   HOUR_22_TIME VARCHAR (800); 
   HOUR_23_QTY VARCHAR (800); 
   HOUR_23_TIME VARCHAR (800); 
   HOUR_24_QTY VARCHAR (800); 
   HOUR_24_TIME VARCHAR (800); 
   
BEGIN

    select count(0) into tempcount
    FROM SFISM4.HAINAHISTORYRECORD_DAY;
    if tempcount=0
    then
        getdata:='2018/01/01';
    else
        select to_char(max(DAY+1),'YYYY/MM/DD') INTO getdata
        FROM SFISM4.HAINAHISTORYRECORD_DAY;
    end if;

    if getdata='2018/11/05'
    then
        return;
    end if;
    
     SELECT DISTINCT HNLILE 
     BULK COLLECT INTO VAR_TYP_SMTCODE
     FROM SFIS1.HNLILE 
     WHERE GCLINE IN (
            select distinct A.LINE_NAME 
            from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b
            where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
             AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
             AND IN_STATION_TIME >= TO_DATE(getdata||' 00:00:01','YYYY/MM/DD HH24:MI:SS')
             AND IN_STATION_TIME <= TO_DATE(getdata||' 23:59:59','YYYY/MM/DD HH24:MI:SS')
            UNION ALL 
            select distinct A.LINE_NAME  
            from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b
            where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NEXT IN ('PF','PF_B','PTH_INPUT','P_VI','P_VI_B','TVI','S_VI_B','S_VI_T','P_AOI','P_3DX','P_5DX','S_5DX','S_3DX','S_LINK','MDA','FCT','ICT','FLASHROM','FBT')
             AND B.GROUP_NAME LIKE 'AOI%' AND A.GROUP_NAME=B.GROUP_NAME
             AND IN_STATION_TIME >= TO_DATE(getdata||' 00:00:01','YYYY/MM/DD HH24:MI:SS')
             AND IN_STATION_TIME <= TO_DATE(getdata||' 23:59:59','YYYY/MM/DD HH24:MI:SS')
      ) ORDER BY HNLILE ASC; 
    
    FOR VAR_INDEX IN 1 .. VAR_TYP_SMTCODE.COUNT
    LOOP
         VAR_SMTCODE := VAR_TYP_SMTCODE (VAR_INDEX);
         
         
         SELECT COUNT (*)
          INTO INPUTQTY
          FROM (
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 00:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 23:59:59','YYYY/MM/DD HH24:MI:SS'));   
         
         SELECT COUNT (*)
           INTO OUTPUTQTY
           FROM (   
                 select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                 from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                 where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NEXT IN ('PF','PF_B','PTH_INPUT','P_VI','P_VI_B','TVI','S_VI_B','S_VI_T','P_AOI','P_3DX','P_5DX','S_5DX','S_3DX','S_LINK','MDA','FCT','ICT','FLASHROM','FBT')
                 AND B.GROUP_NAME LIKE 'AOI%' AND A.GROUP_NAME=B.GROUP_NAME
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 00:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 23:59:59','YYYY/MM/DD HH24:MI:SS')
                 AND A.ERROR_FLAG='0');                 
            
         SELECT COUNT (*)
          into FIRSTPASSQTY
          FROM (   
             select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
             from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
             where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NEXT IN ('PF','PF_B','PTH_INPUT','P_VI','P_VI_B','TVI','S_VI_B','S_VI_T','P_AOI','P_3DX','P_5DX','S_5DX','S_3DX','S_LINK','MDA','FCT','ICT','FLASHROM','FBT')
             AND B.GROUP_NAME LIKE 'AOI%' AND A.GROUP_NAME=B.GROUP_NAME
             AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
             AND IN_STATION_TIME >= TO_DATE(getdata||' 00:00:01','YYYY/MM/DD HH24:MI:SS')
             AND IN_STATION_TIME <= TO_DATE(getdata||' 23:59:59','YYYY/MM/DD HH24:MI:SS')
             AND A.ERROR_FLAG='0' 
             AND A.SERIAL_NUMBER NOT IN (
                 select A.SERIAL_NUMBER
                 from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b
                 where a.SPECIAL_ROUTE=B.ROUTE_CODE 
                 and B.GROUP_NEXT IN ('PF','PF_B','PTH_INPUT','P_VI','P_VI_B','TVI','S_VI_B','S_VI_T','P_AOI','P_3DX','P_5DX','S_5DX','S_3DX','S_LINK','MDA','FCT','ICT','FLASHROM','FBT')
                 AND B.GROUP_NAME LIKE 'AOI%' AND A.GROUP_NAME=B.GROUP_NAME AND A.ERROR_FLAG='1' AND A.IN_STATION_TIME>SYSDATE-365)
          );  
         
         SELECT COUNT (*)
         INTO REWORKPASSQTY
         FROM (   
             select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
             from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
             where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NEXT IN ('PF','PF_B','PTH_INPUT','P_VI','P_VI_B','TVI','S_VI_B','S_VI_T','P_AOI','P_3DX','P_5DX','S_5DX','S_3DX','S_LINK','MDA','FCT','ICT','FLASHROM','FBT')
             AND B.GROUP_NAME LIKE 'AOI%' AND A.GROUP_NAME=B.GROUP_NAME
             AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
             AND IN_STATION_TIME >= TO_DATE(getdata||' 00:00:01','YYYY/MM/DD HH24:MI:SS')
             AND IN_STATION_TIME <= TO_DATE(getdata||' 23:59:59','YYYY/MM/DD HH24:MI:SS')
             AND A.ERROR_FLAG='0' 
             AND A.SERIAL_NUMBER IN (
                 select A.SERIAL_NUMBER
                 from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b
                 where a.SPECIAL_ROUTE=B.ROUTE_CODE 
                 and B.GROUP_NEXT IN ('PF','PF_B','PTH_INPUT','P_VI','P_VI_B','TVI','S_VI_B','S_VI_T','P_AOI','P_3DX','P_5DX','S_5DX','S_3DX','S_LINK','MDA','FCT','ICT','FLASHROM','FBT')
                 AND B.GROUP_NAME LIKE 'AOI%' AND A.GROUP_NAME=B.GROUP_NAME AND A.ERROR_FLAG='1' AND A.IN_STATION_TIME>SYSDATE-365
             ));
         
         SELECT TO_CHAR(IN_STATION_TIME,'YYYY/MM/DD HH24:MI:SS') 
            INTO DATEBEGIN
            FROM ( 
                SELECT IN_STATION_TIME FROM (
                select DISTINCT A.SERIAL_NUMBER,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 00:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 23:59:59','YYYY/MM/DD HH24:MI:SS')
                UNION ALL 
                select DISTINCT A.SERIAL_NUMBER,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NEXT IN ('PF','PF_B','PTH_INPUT','P_VI','P_VI_B','TVI','S_VI_B','S_VI_T','P_AOI','P_3DX','P_5DX','S_5DX','S_3DX','S_LINK','MDA','FCT','ICT','FLASHROM','FBT')
                 AND B.GROUP_NAME LIKE 'AOI%' AND A.GROUP_NAME=B.GROUP_NAME
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 00:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 23:59:59','YYYY/MM/DD HH24:MI:SS')     
                 ) ORDER BY IN_STATION_TIME ASC) WHERE ROWNUM = 1;
         
         
         SELECT TO_CHAR(IN_STATION_TIME,'YYYY/MM/DD HH24:MI:SS')  
            INTO DATEEND
            FROM ( 
                SELECT IN_STATION_TIME FROM (
                select DISTINCT A.SERIAL_NUMBER,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 00:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 23:59:59','YYYY/MM/DD HH24:MI:SS')
                UNION ALL 
                select DISTINCT A.SERIAL_NUMBER,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NEXT IN ('PF','PF_B','PTH_INPUT','P_VI','P_VI_B','TVI','S_VI_B','S_VI_T','P_AOI','P_3DX','P_5DX','S_5DX','S_3DX','S_LINK','MDA','FCT','ICT','FLASHROM','FBT')
                 AND B.GROUP_NAME LIKE 'AOI%' AND A.GROUP_NAME=B.GROUP_NAME
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 00:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 23:59:59','YYYY/MM/DD HH24:MI:SS')     
                 ) ORDER BY IN_STATION_TIME DESC) WHERE ROWNUM = 1;
         
         select ROUND((TO_DATE(DATEEND,'YYYY/MM/DD HH24:MI:SS') - TO_DATE(DATEBEGIN,'YYYY/MM/DD HH24:MI:SS'))*24,1)  INTO YDSJ FROM DUAL;
         SELECT TO_CHAR(TO_DATE(getdata,'YYYY/MM/DD')+1,'YYYY/MM/DD')||' 00:02:04' INTO DAYTONGJITIME FROM DUAL;
         SELECT TO_CHAR(TO_DATE(getdata,'YYYY/MM/DD')+1,'YYYY/MM/DD')||' 00:10:04' INTO DAYSENDDATATIME FROM DUAL;
          
         
         
         SELECT COUNT (*)
          INTO HOUR_1_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 00:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 00:59:59','YYYY/MM/DD HH24:MI:SS'));
         
         SELECT COUNT (*)
          INTO HOUR_2_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 01:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 01:59:59','YYYY/MM/DD HH24:MI:SS'));         
         
         SELECT COUNT (*)
          INTO HOUR_3_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 02:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 02:59:59','YYYY/MM/DD HH24:MI:SS'));          
         
         SELECT COUNT (*)
          INTO HOUR_4_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 03:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 03:59:59','YYYY/MM/DD HH24:MI:SS'));          
         
         SELECT COUNT (*)
          INTO HOUR_5_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 04:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 04:59:59','YYYY/MM/DD HH24:MI:SS')); 
                 
         SELECT COUNT (*)
          INTO HOUR_6_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 05:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 05:59:59','YYYY/MM/DD HH24:MI:SS'));                  
                 
         SELECT COUNT (*)
          INTO HOUR_7_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 06:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 06:59:59','YYYY/MM/DD HH24:MI:SS'));                  
                 
         SELECT COUNT (*)
          INTO HOUR_8_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 07:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 07:59:59','YYYY/MM/DD HH24:MI:SS'));                  
                 
         SELECT COUNT (*)
          INTO HOUR_9_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 08:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 08:59:59','YYYY/MM/DD HH24:MI:SS'));                  
                 
         SELECT COUNT (*)
          INTO HOUR_10_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 09:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 09:59:59','YYYY/MM/DD HH24:MI:SS'));                  
                 
         SELECT COUNT (*)
          INTO HOUR_11_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 10:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 10:59:59','YYYY/MM/DD HH24:MI:SS')); 
                 
                 
         SELECT COUNT (*)
          INTO HOUR_12_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 11:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 11:59:59','YYYY/MM/DD HH24:MI:SS'));                  
                 
         SELECT COUNT (*)
          INTO HOUR_13_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 12:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 12:59:59','YYYY/MM/DD HH24:MI:SS'));                  
                 
         SELECT COUNT (*)
          INTO HOUR_14_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 13:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 13:59:59','YYYY/MM/DD HH24:MI:SS'));                  
                 
         SELECT COUNT (*)
          INTO HOUR_15_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 14:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 14:59:59','YYYY/MM/DD HH24:MI:SS'));                  
                 
         SELECT COUNT (*)
          INTO HOUR_16_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 15:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 15:59:59','YYYY/MM/DD HH24:MI:SS'));                  
                 
         SELECT COUNT (*)
          INTO HOUR_17_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 16:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 16:59:59','YYYY/MM/DD HH24:MI:SS'));                  
                 
         SELECT COUNT (*)
          INTO HOUR_18_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 17:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 17:59:59','YYYY/MM/DD HH24:MI:SS'));                  
                 
                 
         SELECT COUNT (*)
          INTO HOUR_19_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 18:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 18:59:59','YYYY/MM/DD HH24:MI:SS'));                  
                 
         SELECT COUNT (*)
          INTO HOUR_20_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 19:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 19:59:59','YYYY/MM/DD HH24:MI:SS'));                  
                 
                 
                 
         SELECT COUNT (*)
          INTO HOUR_21_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 20:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 20:59:59','YYYY/MM/DD HH24:MI:SS'));                  
                 
                 
                 
         SELECT COUNT (*)
          INTO HOUR_22_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 21:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 21:59:59','YYYY/MM/DD HH24:MI:SS'));                                   
                 
         SELECT COUNT (*)
          INTO HOUR_23_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 22:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 22:59:59','YYYY/MM/DD HH24:MI:SS'));                 
                 
         SELECT COUNT (*)
          INTO HOUR_24_QTY
          FROM (     
                select DISTINCT A.SERIAL_NUMBER--,A.LINE_NAME,A.GROUP_NAME,A.ERROR_FLAG,A.IN_STATION_TIME,A.SPECIAL_ROUTE
                from sfism4.r_sn_detail_t a,SFIS1.C_ROUTE_CONTROL_T b, SFIS1.HNLILE C
                where a.SPECIAL_ROUTE=B.ROUTE_CODE and B.GROUP_NAME IN ('PCB_OPEN','SN_BINDING')
                 AND B.GROUP_NEXT LIKE 'S_INPUT%' AND A.GROUP_NAME=B.GROUP_NEXT 
                 AND A.LINE_NAME=C.GCLINE AND C.HNLILE=VAR_SMTCODE
                 AND IN_STATION_TIME >= TO_DATE(getdata||' 23:00:01','YYYY/MM/DD HH24:MI:SS')
                 AND IN_STATION_TIME <= TO_DATE(getdata||' 23:59:59','YYYY/MM/DD HH24:MI:SS'));       
         
         SELECT getdata||' 01:02:01' INTO HOUR_1_TIME FROM DUAL;   
         SELECT getdata||' 02:02:01' INTO HOUR_2_TIME FROM DUAL;   
         SELECT getdata||' 03:02:01' INTO HOUR_3_TIME FROM DUAL;
         SELECT getdata||' 04:02:01' INTO HOUR_4_TIME FROM DUAL;
         SELECT getdata||' 05:02:01' INTO HOUR_5_TIME FROM DUAL;
         SELECT getdata||' 06:02:01' INTO HOUR_6_TIME FROM DUAL;
         SELECT getdata||' 07:02:01' INTO HOUR_7_TIME FROM DUAL;
         SELECT getdata||' 08:02:01' INTO HOUR_8_TIME FROM DUAL;
         SELECT getdata||' 09:02:01' INTO HOUR_9_TIME FROM DUAL;
         SELECT getdata||' 10:02:01' INTO HOUR_10_TIME FROM DUAL;
         SELECT getdata||' 11:02:01' INTO HOUR_11_TIME FROM DUAL;
         SELECT getdata||' 12:02:01' INTO HOUR_12_TIME FROM DUAL;
         SELECT getdata||' 13:02:01' INTO HOUR_13_TIME FROM DUAL;
         SELECT getdata||' 14:02:01' INTO HOUR_14_TIME FROM DUAL;
         SELECT getdata||' 15:02:01' INTO HOUR_15_TIME FROM DUAL;
         SELECT getdata||' 16:02:01' INTO HOUR_16_TIME FROM DUAL;
         SELECT getdata||' 17:02:01' INTO HOUR_17_TIME FROM DUAL;
         SELECT getdata||' 18:02:01' INTO HOUR_18_TIME FROM DUAL;
         SELECT getdata||' 19:02:01' INTO HOUR_19_TIME FROM DUAL;
         SELECT getdata||' 20:02:01' INTO HOUR_20_TIME FROM DUAL;
         SELECT getdata||' 21:02:01' INTO HOUR_21_TIME FROM DUAL;
         SELECT getdata||' 22:02:01' INTO HOUR_22_TIME FROM DUAL;
         SELECT getdata||' 23:02:01' INTO HOUR_23_TIME FROM DUAL;
         SELECT to_char(TO_DATE(getdata,'yyyy/mm/dd')+1,'yyyy/mm/dd')||' 00:02:01' INTO HOUR_24_TIME FROM DUAL;      
         
         INSERT INTO SFISM4.HAINAHISTORYRECORD
         (
           LINE, DATEBEGIN, DATEEND, 
           YDSJ, INPUTQTY, FIRSTPASSQTY, 
           REWORKPASSQTY, OUTPUTQTY, DAYTONGJITIME, 
           DAYSENDDATATIME, HOUR_1_QTY, HOUR_1_TIME, 
           HOUR_2_QTY, HOUR_2_TIME, HOUR_3_QTY, 
           HOUR_3_TIME, HOUR_4_QTY, HOUR_4_TIME, 
           HOUR_5_QTY, HOUR_5_TIME, HOUR_6_QTY, 
           HOUR_6_TIME, HOUR_7_QTY, HOUR_7_TIME, 
           HOUR_8_QTY, HOUR_8_TIME, HOUR_9_QTY, 
           HOUR_9_TIME, HOUR_10_QTY, HOUR_10_TIME, 
           HOUR_11_QTY, HOUR_11_TIME, HOUR_12_QTY, 
           HOUR_12_TIME, HOUR_13_QTY, HOUR_13_TIME, 
           HOUR_14_QTY, HOUR_14_TIME, HOUR_15_QTY, 
           HOUR_15_TIME, HOUR_16_QTY, HOUR_16_TIME, 
           HOUR_17_QTY, HOUR_17_TIME, HOUR_18_QTY, 
           HOUR_18_TIME, HOUR_19_QTY, HOUR_19_TIME, 
           HOUR_20_QTY, HOUR_20_TIME, HOUR_21_QTY, 
           HOUR_21_TIME, HOUR_22_QTY, HOUR_22_TIME, 
           HOUR_23_QTY, HOUR_23_TIME, HOUR_24_QTY, 
           HOUR_24_TIME, DAY
         )       
         VALUES
         (
           VAR_SMTCODE, DATEBEGIN, DATEEND, 
           YDSJ, INPUTQTY, FIRSTPASSQTY, 
           REWORKPASSQTY, OUTPUTQTY, DAYTONGJITIME, 
           DAYSENDDATATIME, HOUR_1_QTY, HOUR_1_TIME, 
           HOUR_2_QTY, HOUR_2_TIME, HOUR_3_QTY, 
           HOUR_3_TIME, HOUR_4_QTY, HOUR_4_TIME, 
           HOUR_5_QTY, HOUR_5_TIME, HOUR_6_QTY, 
           HOUR_6_TIME, HOUR_7_QTY, HOUR_7_TIME, 
           HOUR_8_QTY, HOUR_8_TIME, HOUR_9_QTY, 
           HOUR_9_TIME, HOUR_10_QTY, HOUR_10_TIME, 
           HOUR_11_QTY, HOUR_11_TIME, HOUR_12_QTY, 
           HOUR_12_TIME, HOUR_13_QTY, HOUR_13_TIME, 
           HOUR_14_QTY, HOUR_14_TIME, HOUR_15_QTY, 
           HOUR_15_TIME, HOUR_16_QTY, HOUR_16_TIME, 
           HOUR_17_QTY, HOUR_17_TIME, HOUR_18_QTY, 
           HOUR_18_TIME, HOUR_19_QTY, HOUR_19_TIME, 
           HOUR_20_QTY, HOUR_20_TIME, HOUR_21_QTY, 
           HOUR_21_TIME, HOUR_22_QTY, HOUR_22_TIME, 
           HOUR_23_QTY, HOUR_23_TIME, HOUR_24_QTY, 
           HOUR_24_TIME, getdata
         );                
    END LOOP;
    
    INSERT INTO SFISM4.HAINAHISTORYRECORD_DAY (DAY) VALUES (TO_DATE(getdata,'YYYY/MM/DD'));
    
    COMMIT;
    
end;