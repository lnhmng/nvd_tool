PROCEDURE       BP_TESTTIME
is
count1 int;
BEGIN

      delete from SFIS1.BP_BARCODETESTTIME;
      delete from SFIS1.BP_PLANTTESTTIME;
      commit;   

       INSERT INTO SFIS1.BP_BARCODETESTTIME   select sum((etime-stime)*24*3600) test_time, barcode from (
        select to_date(a.basic_testtime_end,'yyyymmddhh24miss') etime,to_date(a.basic_testtime_begin,'yyyymmddhh24miss') stime ,b.model_barcode AS barcode
        from SFISM4.r_test_temp_t a,SFIS1.fixture_bind b where  LENGTH(a.basic_testtime_end)=14 and LENGTH(a.basic_testtime_begin)=14 and a.machine_code=b.fixture_id and b.flag='1'
         AND TO_DATE (a.basic_testtime_begin, 'yyyymmddhh24miss') >lasteditdt AND LASTEDITDT IS NOT NULL
        union all
        select to_date(basic_testtime_end,'yyyymmddhh24miss') etime,to_date(basic_testtime_begin,'yyyymmddhh24miss') stime,b.model_barcode AS barcode
        from SFISM4.h_test_temp_t a,SFIS1.fixture_bind b where  LENGTH(a.basic_testtime_end)=14 and LENGTH(a.basic_testtime_begin)=14 and a.machine_code=b.fixture_id and b.flag='1'
         AND TO_DATE (a.basic_testtime_begin, 'yyyymmddhh24miss') >lasteditdt AND LASTEDITDT IS NOT NULL
        ) GROUP BY BARCODE;

   commit;
       INSERT INTO SFIS1.BP_PLANTTESTTIME   select (case when mt=5 then sum((etime-stime)*24*3600) when mt=6 then sum((etime-stime)*24*3600) end)  test_time,
        (case when mt=5 then 'Tesla' when mt=6 then 'GPU' end) mt,to_char(sysdate,'YYYYWW') from
        (        
        select to_date(a.basic_testtime_end,'yyyymmddhh24miss') etime,to_date(a.basic_testtime_begin,'yyyymmddhh24miss') stime,
        length(machine_code)  as mt from SFISM4.r_test_temp_t a where
         LENGTH(a.basic_testtime_end)=14 and LENGTH(a.basic_testtime_begin)=14 
                  and a.test_date>(to_char(sysdate+(2-to_char(sysdate,'d'))-7,'yyyymmdd')) and a.test_date<to_char(sysdate+(2-to_char(sysdate,'d'))-1,'yyyymmdd') AND a.machine_code IN( SELECT DISTINCT(FIXTURE_ID) FROM fixture_bind WHERE FLAG='1')

        union all   
         select to_date(a.basic_testtime_end,'yyyymmddhh24miss') etime,to_date(a.basic_testtime_begin,'yyyymmddhh24miss') stime,
        length(machine_code)  as mt from SFISM4.h_test_temp_t a where
         LENGTH(a.basic_testtime_end)=14 and LENGTH(a.basic_testtime_begin)=14 
                  and a.test_date>to_char(sysdate+(2-to_char(sysdate,'d'))-7,'yyyymmdd') and a.test_date<to_char(sysdate+(2-to_char(sysdate,'d'))-1,'yyyymmdd')  AND a.machine_code IN( SELECT DISTINCT(FIXTURE_ID) FROM fixture_bind WHERE FLAG='1')   ) group 
by mt;
 commit;                 
                  select count(*) into count1 from SFIS1.BP_PLANTTESTTIME where apcModel='GPU';
                  if count1<1
                  then
                        insert into SFIS1.BP_PLANTTESTTIME values(0,'GPU',0);
                  end if;

  commit;      
END;