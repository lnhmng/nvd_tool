PROCEDURE                   GET_OEE_INFO
(
 DATE_FROM       IN      VARCHAR2,
 DATE_TO         IN      VARCHAR2,
 EMP_NO          IN      VARCHAR2,
 RES             OUT     VARCHAR2,
 O_waittime      OUT     VARCHAR2,
 O_SkipRuning    OUT     VARCHAR2,
 O_alltime       OUT     VARCHAR2,
 O_Runingtime    OUT     VARCHAR2,
 O_Testtime      OUT     VARCHAR2,
 O_NTFTime       OUT     VARCHAR2,
 O_OQATime       OUT     VARCHAR2,
 O_BorrowTime    OUT     VARCHAR2,
 O_RETESTTIME    OUT     VARCHAR2
) AS
p_sn  varchar(30);
p_fixid            varchar(30);
p_fixid_temp       varchar(30);
p_date_temp        date;
p_begindate        date;
p_enddate          date;
p_num              int;
min_all            int;
wait_all           int;
handingtime        int;
p_count            int;
e_NULL        EXCEPTION;

CURSOR test_date
   IS
   SELECT fixid,sn,min(starttestdate) as s_time,max(endtestdate) as e_time fROM SFISM4.R_OEE_DATA group by fixid,sn ORDER BY FIXID,e_time;
      --SELECT  serial_number,in_station_time
          --FROM sfism4.r_wip_tracking_t
         --WHERE in_station_time>=to_date(DATE_FROM,'YYYY-MM-DD HH24:MI:SS')
         --and in_station_time<=to_date(DATE_TO,'YYYY-MM-DD HH24:MI:SS') ORDER BY IN_STATION_TIME;
        
BEGIN
     handingtime:=828;
     p_fixid_temp:='';
     min_all:=0;
     wait_all :=0;
        
        select count(*) into p_count from SFISM4.R_OEE_DATA;
     
        if p_count>0 then
            delete from SFISM4.R_OEE_DATA;
            commit;
        end if;
     
        INSERT INTO SFISM4.R_OEE_DATA
        SELECT serial_number,mo_number,model_name,bios,fixid,station_type,station_nv,
        case when UPPER(result) like 'F%' THEN ERROR_CODE WHEN UPPER(result) like 'P%' THEN 'PASS' END AS RESULT,
        begin_time,end_time,test_time,sfc,
        case when (serial_number like '033%') OR (serial_number like '032%' AND SUBSTR(model_name,5,1)<>2)  then 'BORROW'
        when station_nv='OQA' THEN 'OQA' 
        when station_nv like 'PST' then 'RETEST' 
        when RESULT like 'F%' THEN 'FAILNTF'
        else 'Testing' end as oee_type,EMP_NO,SYSDATE
        FROM 
        (SELECT fixid,a.serial_number,b.mo_number,b.model_name,b.result,b.begin_time,b.end_time,b.test_time,b.station_type,c.station_nv,'1' as sfc,
        case when d.second_bios is not null then d.second_bios else d.first_bios end as bios,B.ERROR_CODE
         fROM 
        (SELECT*fROM  SFISM4.R_SN_FIXTURE_T  WHERE LENGTH(FIXID)=5 and in_station_time>=to_date(DATE_FROM,'YYYY-MM-DD HH24:MI:SS')
        AND IN_STATION_TIME<=to_date(DATE_TO,'YYYY-MM-DD HH24:MI:SS'))A
        LEFT JOIN
        (SELECT serial_number,model_name,result,station_type,mo_number,'1' as sfc,ERROR_CODE,
        to_date(substr(b.BASIC_TESTTIME_END,1,4)||'-'||substr(b.BASIC_TESTTIME_END,5,2)||'-'||substr(b.BASIC_TESTTIME_END,7,2)||' '||substr(b.BASIC_TESTTIME_END,9,2)||':'||substr(b.BASIC_TESTTIME_END,11,2)||':'||
        substr(b.BASIC_TESTTIME_END,13,2),'YYYY-MM-DD HH24:MI:SS') as end_time,
        to_date(substr(b.BASIC_TESTTIME_BEGIN,1,4)||'-'||substr(b.BASIC_TESTTIME_BEGIN,5,2)||'-'||substr(b.BASIC_TESTTIME_BEGIN,7,2)||' '||substr(b.BASIC_TESTTIME_BEGIN,9,2)||':'||
        substr(b.BASIC_TESTTIME_BEGIN,11,2)||':'||substr(b.BASIC_TESTTIME_BEGIN,13,2),'YYYY-MM-DD HH24:MI:SS') as begin_time,
        to_date(substr(test_date||test_time,1,4)||'-'||substr(test_date||test_time,5,2)||'-'||substr(test_date||test_time,7,2)||' '
        ||substr(test_date||test_time,9,2)||':'||substr(test_date||test_time,11,2)||':'||substr(test_date||test_time,13,2),'YYYY-MM-DD HH24:MI:SS') as test_time
        fROM SFISM4.R_TEST_TEMP_T B where LENGTH(BASIC_TESTTIME_END)=14 and LENGTH(BASIC_TESTTIME_begin)=14 and station_type is not null)b 
        on a.serial_number=b.serial_number and a.in_station_time=b.test_time
        and a.group_name=b.station_type 
        left join SFIS1.C_STATION_MAPPING_T c on b.station_type=c.station_sfc AND AREA='F20'
        left join sfism4.R_NVBIOS_MODEL_T d on a.serial_number=d.serial_number
        where C.station_nv is NOT null
        )A 
        UNION ALL
        SELECT serial_number,mo_number,model_name,bios,fixid,station_type,station_nv,
        case when UPPER(result) like 'F%' THEN ERROR_CODE WHEN UPPER(result) like 'P%' THEN 'PASS' END AS RESULT,
        begin_time,end_time,test_time,sfc,
        case when (serial_number like '033%') OR (serial_number like '032%' AND SUBSTR(model_name,5,1)<>2)  then 'BORROW'
        when station_nv='OQA' THEN 'OQA' 
        when station_nv like 'PST' then 'RETEST' 
        when RESULT like 'F%' THEN 'FAILNTF'
        else 'Testing' end as oee_type,EMP_NO,SYSDATE 
        FROM 
        (SELECT a.fixid,B.serial_number,b.model_name,b.mo_number,b.result,b.begin_time,b.end_time,b.test_time,b.station_type,c.station_nv,'0' as sfc,
        case when d.second_bios is not null then d.second_bios else d.first_bios end as bios,B.ERROR_CODE
         fROM 
        (SELECT*fROM SFISM4.H_SN_FIXTURE_T  WHERE LENGTH(FIXID)=5 and in_station_time>=to_date(DATE_FROM,'YYYY-MM-DD HH24:MI:SS')
        AND IN_STATION_TIME<=to_date(DATE_TO,'YYYY-MM-DD HH24:MI:SS'))A
        LEFT JOIN
        (SELECT serial_number,model_name,result,station_type,mo_number,ERROR_CODE,
        to_date(substr(b.BASIC_TESTTIME_END,1,4)||'-'||substr(b.BASIC_TESTTIME_END,5,2)||'-'||substr(b.BASIC_TESTTIME_END,7,2)||' '||substr(b.BASIC_TESTTIME_END,9,2)||':'||substr(b.BASIC_TESTTIME_END,11,2)||':'||
        substr(b.BASIC_TESTTIME_END,13,2),'YYYY-MM-DD HH24:MI:SS') as end_time,
        to_date(substr(b.BASIC_TESTTIME_BEGIN,1,4)||'-'||substr(b.BASIC_TESTTIME_BEGIN,5,2)||'-'||substr(b.BASIC_TESTTIME_BEGIN,7,2)||' '||substr(b.BASIC_TESTTIME_BEGIN,9,2)||':'||
        substr(b.BASIC_TESTTIME_BEGIN,11,2)||':'||substr(b.BASIC_TESTTIME_BEGIN,13,2),'YYYY-MM-DD HH24:MI:SS') as begin_time,
        to_date(substr(test_date||test_time,1,4)||'-'||substr(test_date||test_time,5,2)||'-'||substr(test_date||test_time,7,2)||' '
        ||substr(test_date||test_time,9,2)||':'||substr(test_date||test_time,11,2)||':'||substr(test_date||test_time,13,2),'YYYY-MM-DD HH24:MI:SS') as test_time
        fROM SFISM4.H_TEST_TEMP_T B where LENGTH(BASIC_TESTTIME_END)=14 and LENGTH(BASIC_TESTTIME_begin)=14 and station_type is not null)b 
        on a.serial_number=b.serial_number and a.in_station_time=b.test_time
        and a.group_name=b.station_type 
        left join SFIS1.C_STATION_MAPPING_T c on b.station_type=c.station_sfc AND AREA='F20'
        left join sfism4.R_NVBIOS_MODEL_T d on a.serial_number=d.serial_number
        where station_nv is NOT null
        )A;
     commit;
     
     OPEN test_date;
     LOOP
        FETCH test_date into p_fixid,p_sn,p_begindate,p_enddate;
        exit when test_date%notfound;
        
        if p_fixid_temp<>p_fixid then
            p_fixid_temp:=p_fixid;
            p_date_temp:=p_enddate;
        else
            if (p_begindate-p_date_temp)*24*3600>3600*12 then
                min_all:=min_all+(p_begindate-p_date_temp)*24*3600-handingtime;
            else
                if (p_begindate-p_date_temp)*24*3600>handingtime then
                    wait_all:=wait_all+(p_begindate-p_date_temp)*24*3600-handingtime;
                 end if;
            end if;
            p_date_temp:=p_enddate;
        end if;    
     END LOOP;    
     
     close test_date;
     
     UPDATE SFISM4.R_OEE_DATA SET DISTRIBUTE='RETEST'
        WHERE MO_NUMBER IN
            (select MO_NUMBER from sfism4.r_mo_base_t where mo_type='REWORK');
     
     select round(sum(round((e_time-s_time)*24*3600,2)+828)/3600,2) into O_alltime From
    (SELECT fixid,min(starttestdate) as s_time,max(endtestdate) as e_time fROM SFISM4.R_OEE_DATA 
    group by fixid);

    select RETEST,BORROW,OQA,FAILNTF,TESTING into O_RETESTTIME,O_BorrowTime,O_OQATime,O_NTFTime,O_Testtime From     
    (select 
    a.distribute,
    case when upper(a.distribute)='TESTING' then testtime
    else testtime+qty*0.23 end as total 
    from (select distinct distribute,round(sum(endtestdate-starttestdate)*24,0) as testtime From  SFISM4.R_OEE_DATA 
    group by distribute)a left join 
    (select distribute,count(distribute) as qty from (SELECT distribute,sn,fixid from SFISM4.R_OEE_DATA 
         group by distribute,sn,fixid)group by distribute)b on a.distribute=b.distribute)AA pivot(MAX(TOTAL) 
     for distribute IN('RETEST' AS RETEST,'BORROW' AS BORROW,'OQA' AS OQA,'FAILNTF' AS FAILNTF,'Testing' AS TESTING));  
     
     O_waittime:=ROUND(wait_all/3600,2);
     O_SkipRuning:=ROUND(min_all/3600,2);
EXCEPTION
  WHEN e_NULL THEN NULL;
  WHEN OTHERS THEN
     RES:='OTHER ERROR '||SUBSTR(SQLERRM,1,10);
END;