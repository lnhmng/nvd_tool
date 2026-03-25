PROCEDURE                         SP_GET_DAILY_WIP_WO_HAINA_NEW
AS
    TYPE TYP_SMTCODE IS TABLE OF VARCHAR (800);
    VAR_TYP_SMTCODE             TYP_SMTCODE;    
    VAR_SMTCODE                 VARCHAR (50);

    V_MO_NUMBER        VARCHAR(20);   
    V_MODEL_NAME       VARCHAR(20);
    V_TARGET_QTY       VARCHAR(20);    
    planptQty     NUMBER;

    V_MO_CREATE_DATE VARCHAR(20);
    V_MO_SCHEDULE_DATE VARCHAR(20);
    V_MO_START_DATE VARCHAR(20);
    V_MO_TARGET_DATE VARCHAR(20);
    V_MO_CLOSE_DATE  VARCHAR(20);

    V_DAILYCOMPLETEDQTY INTEGER;  

    v_count         NUMBER;
    v_SMT_COUNT     NUMBER;
    v_SMT_REPAIRT_COUNT NUMBER; 
    v_SMT_OUT_COUNT NUMBER;

    v_PTH_COUNT     NUMBER;
    v_PTH_REPAIRT_COUNT NUMBER;  
    v_PTH_OUT_COUNT NUMBER;

  --  v_STATIONYIELDRATE NUMBER;  
  --  v_FIRSTPASSYIELDRATE NUMBER;  

    v_ACT_start_date    VARCHAR(20);     --工單實際開始時間

    V_MOTYPE     VARCHAR(20);

    v_start_date    VARCHAR(20);
    v_end_date      VARCHAR(20);
    v_now_date      VARCHAR(20);
    v_start_time    VARCHAR(20); 
    v_end_time      VARCHAR(20);
    ex              EXCEPTION;
    v_res           VARCHAR(500);

BEGIN

      begin
        select trim(VR_VALUE)
        into v_start_date
        from sfis1.C_PARAMETER_INI
        where PRG_NAME = 'HAINA_REPORT'
          and VR_CLASS = 'NVD'
          and VR_ITEM='HAINA_GET_REPORT_DATA_T';

        if v_start_date || 'A' = 'A' then
            raise ex;
        end if;


        select to_char(to_date(VR_VALUE,'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS')      
        into v_start_date
        from sfis1.C_PARAMETER_INI
        where PRG_NAME = 'HAINA_REPORT'
        and VR_CLASS = 'NVD'
        and VR_ITEM='HAINA_GET_REPORT_DATA_T';

    exception
        WHEN OTHERS
        THEN
            delete from sfis1.C_PARAMETER_INI
              where PRG_NAME = 'HAINA_REPORT'
              and VR_CLASS = 'NVD'
              and VR_ITEM='HAINA_GET_REPORT_DATA_T';


            insert into sfis1.C_PARAMETER_INI
                (PRG_NAME,VR_CLASS,VR_ITEM,VR_VALUE,LAST_MODIFY_DATE)
            values('HAINA_REPORT','NVD','HAINA_GET_REPORT_DATA_T',v_start_date,sysdate);
    end;

    select to_char(sysdate,'YYYY/MM/DD HH24:MI:SS') into v_now_date from dual;

    if to_date(v_start_date,'YYYY/MM/DD HH24:MI:SS')>=to_date(v_now_date,'YYYY/MM/DD HH24:MI:SS') then
        v_res := 'OK';
        return;
    end if;

    v_end_date:=to_char(to_date(v_now_date,'YYYY/MM/DD HH24:MI:SS'),'YYYY/MM/DD HH24:MI:SS');

    v_start_time := v_start_date;
    v_end_time := v_end_date;

    SELECT DISTINCT(A.MO_NUMBER)
        BULK COLLECT INTO VAR_TYP_SMTCODE        
             FROM SFISM4.R_SN_DETAIL_T A,SFISM4.R_MO_BASE_T B WHERE A.MO_NUMBER=B.MO_NUMBER AND A.MODEL_NAME=B.MODEL_NAME AND 
             (B.MODEL_NAME LIKE '6__-_____-____-___' OR B.MODEL_NAME LIKE '9__-_____-____-___')
               and ( a.in_station_time >= to_date(v_start_time,'YYYY/MM/DD HH24:MI:SS')
               and a.in_station_time < to_date(v_end_time,'YYYY/MM/DD HH24:MI:SS')); 

    if (VAR_TYP_SMTCODE is not null) then

       FOR VAR_INDEX IN 1 .. VAR_TYP_SMTCODE.COUNT

      LOOP
         VAR_SMTCODE :=TRIM(VAR_TYP_SMTCODE (VAR_INDEX));

          --實際工單開始時間 
         -- select TO_CHAR((min(IN_STATION_TIME)),'YYYY-MM-DD HH24:MI:SS') AS v_ACT_start_date into v_ACT_start_date from sfism4.r_wip_tracking_t where mo_number=VAR_SMTCODE;          

          select NVL(TO_CHAR((min(IN_STATION_TIME)),'YYYY-MM-DD HH24:MI:SS'),TO_CHAR((SYSDATE),'YYYY-MM-DD HH24:MI:SS')) AS v_ACT_start_date into v_ACT_start_date
                    from sfism4.r_wip_tracking_t where mo_number=VAR_SMTCODE; 


          SELECT  (A.MO_NUMBER),(A.MODEL_NAME),CASE WHEN MO_TYPE='REWORK' THEN '3'
                  ELSE '1' END AS MO_TYPE,(A.TARGET_QTY), 

                 TO_CHAR(A.MO_CREATE_DATE,'YYYY-MM-DD HH24:MI:SS') AS MO_CREATE,         
                 TO_CHAR((A.MO_SCHEDULE_DATE),'YYYY-MM-DD HH24:MI:SS') AS MO_SCHEDULE_DATE,
                 TO_CHAR((A.MO_START_DATE),'YYYY-MM-DD HH24:MI:SS') AS MO_START_DATE,

                 TO_CHAR((A.MO_TARGET_DATE),'YYYY-MM-DD HH24:MI:SS') AS MO_TARGET_DATE,

                 TO_CHAR((A.MO_CLOSE_DATE),'YYYY-MM-DD HH24:MI:SS') AS MO_CLOSE_DATE,(B.DAILYCOMPLETEDQTY) 

                 INTO V_MO_NUMBER,V_MODEL_NAME,V_MOTYPE,V_TARGET_QTY,V_MO_CREATE_DATE,V_MO_SCHEDULE_DATE,V_MO_START_DATE,V_MO_TARGET_DATE,V_MO_CLOSE_DATE,V_DAILYCOMPLETEDQTY 

                 FROM SFISM4.R_MO_BASE_T A,   
                 (SELECT MO_NUMBER,MODEL_NAME,COUNT(DISTINCT(SERIAL_NUMBER)) AS DAILYCOMPLETEDQTY  FROM SFISM4.R_SN_DETAIL_T 
                  WHERE MO_NUMBER=VAR_SMTCODE and  IN_STATION_TIME >= to_date(v_start_time,'YYYY/MM/DD HH24:MI:SS') and IN_STATION_TIME < to_date(v_end_time,'YYYY/MM/DD HH24:MI:SS')            
                    GROUP BY MO_NUMBER,MODEL_NAME  
                  ) B

                 WHERE A.MO_NUMBER=B.MO_NUMBER AND A.MODEL_NAME=B.MODEL_NAME  AND A.MO_NUMBER=VAR_SMTCODE;

                  Insert into SFISM4.R_DAILY_WIP_WO (WONO, WOTYPE, PLANTCODE, PTNO, PTNAME,PLANPTQTY, PLANWOBEGINDATE, PLANWOFINISHDATE,PLANMATERIALBEGINDATE,PLANMATERIALFINISHDATE, DATAUPLOADDATE, WOSTATUSUPDATE, 
                                                    WOCREATEDATE, WOCREATE, WOUPDATEDATE, WOUPDATER, ACTWOBEGINDATE,ACTMATERIALBEGINDATE,ACTMATERIALFINISHDATE,DAILYCOMPLETEDQTY)
                                            Values
                                           (V_MO_NUMBER,V_MOTYPE, 'FGLG', V_MODEL_NAME, SUBSTR(V_MODEL_NAME,5,5),V_TARGET_QTY, V_MO_CREATE_DATE, V_MO_SCHEDULE_DATE,V_MO_CREATE_DATE,V_MO_CREATE_DATE, 
                                           TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'), '1',V_MO_CREATE_DATE, 'DBA', 
                                           TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'), 'DBA', v_ACT_start_date,'','',V_DAILYCOMPLETEDQTY);


                  SELECT NVL(COUNT(SERIAL_NUMBER),0) INTO v_SMT_COUNT FROM SFISM4.R_WIP_TRACKING_T WHERE MO_NUMBER=VAR_SMTCODE AND  GROUP_NAME IN
                   (SELECT DISTINCT(GROUP_NAME) FROM SFIS1.C_GROUP_CONFIG_T WHERE SECTION_NAME='SMT') and 
                  IN_STATION_TIME >= to_date(v_start_time,'YYYY/MM/DD HH24:MI:SS') and IN_STATION_TIME < to_date(v_end_time,'YYYY/MM/DD HH24:MI:SS'); 


                  SELECT NVL(COUNT(SERIAL_NUMBER),0) INTO v_SMT_REPAIRT_COUNT FROM SFISM4.R_REPAIR_T WHERE MO_NUMBER=VAR_SMTCODE AND  TEST_STATION IN 
                  (SELECT DISTINCT(GROUP_NAME) FROM SFIS1.C_GROUP_CONFIG_T WHERE SECTION_NAME='SMT') and 
                  TEST_TIME >= to_date(v_start_time,'YYYY/MM/DD HH24:MI:SS') and TEST_TIME < to_date(v_end_time,'YYYY/MM/DD HH24:MI:SS'); 

                  SELECT NVL(COUNT(SERIAL_NUMBER),0) INTO v_SMT_OUT_COUNT FROM SFISM4.R_WIP_TRACKING_T WHERE MO_NUMBER=VAR_SMTCODE AND GROUP_NAME='WAREHOUSE' and 
                  IN_STATION_TIME >= to_date(v_start_time,'YYYY/MM/DD HH24:MI:SS') and IN_STATION_TIME < to_date(v_end_time,'YYYY/MM/DD HH24:MI:SS'); 

                  if v_SMT_COUNT>0 THEN

                    --   v_STATIONYIELDRATE:=round(((v_SMT_COUNT-v_SMT_REPAIRT_COUNT)/v_SMT_COUNT),5) *100;
                    --   v_FIRSTPASSYIELDRATE:=round(((v_SMT_OUT_COUNT)/v_SMT_COUNT),5) *100;

                          Insert into SFISM4.R_DAILY_WO_GROUP_DETAIL (WONO, PTNO, STATIONCODE, STATIONNAME, STATIONSORT,INSTATIONQTY, 
                                                                INREPAIRQTY, OUTSTATIONQTY, STATIONYIELDRATE, FIRSTPASSYIELDRATE,CREATE_DATE)
                                                                 Values   (V_MO_NUMBER, V_MODEL_NAME, 'CESBG_NVDBU_LH_F20_3F_SMT', 'SMT',
                                                                 1,v_SMT_COUNT, v_SMT_REPAIRT_COUNT, v_SMT_OUT_COUNT,100,
                                                                 100,to_char(sysdate,'YYYY/MM/DD')); 

                   ELSE

                            Insert into SFISM4.R_DAILY_WO_GROUP_DETAIL (WONO, PTNO, STATIONCODE, STATIONNAME, STATIONSORT,INSTATIONQTY, 
                                                                INREPAIRQTY, OUTSTATIONQTY, STATIONYIELDRATE, FIRSTPASSYIELDRATE,CREATE_DATE)
                                                                 Values   (V_MO_NUMBER, V_MODEL_NAME, 'CESBG_NVDBU_LH_F20_3F_SMT', 'SMT',
                                                                 1,v_SMT_COUNT, v_SMT_REPAIRT_COUNT, v_SMT_OUT_COUNT,0.00,
                                                                 0.00,to_char(sysdate,'YYYY/MM/DD')); 

                 end if;                        


                  SELECT NVL(COUNT(SERIAL_NUMBER),0) INTO v_PTH_COUNT FROM SFISM4.R_WIP_TRACKING_T WHERE MO_NUMBER=VAR_SMTCODE AND  GROUP_NAME IN 
                  (SELECT DISTINCT(GROUP_NAME) FROM SFIS1.C_GROUP_CONFIG_T WHERE SECTION_NAME='PTH') and 
                  IN_STATION_TIME >= to_date(v_start_time,'YYYY/MM/DD HH24:MI:SS') and IN_STATION_TIME < to_date(v_end_time,'YYYY/MM/DD HH24:MI:SS'); 


                  SELECT NVL(COUNT(SERIAL_NUMBER),0) INTO v_PTH_REPAIRT_COUNT FROM SFISM4.R_REPAIR_T WHERE MO_NUMBER=VAR_SMTCODE AND  TEST_STATION IN 
                  (SELECT DISTINCT(GROUP_NAME) FROM SFIS1.C_GROUP_CONFIG_T WHERE SECTION_NAME='PTH') and 
                  TEST_TIME >= to_date(v_start_time,'YYYY/MM/DD HH24:MI:SS') and TEST_TIME < to_date(v_end_time,'YYYY/MM/DD HH24:MI:SS'); 

                  SELECT NVL(COUNT(SERIAL_NUMBER),0) INTO v_PTH_OUT_COUNT FROM SFISM4.R_WIP_TRACKING_T WHERE MO_NUMBER=VAR_SMTCODE AND GROUP_NAME IN ('PACKING') and 
                  IN_STATION_TIME >= to_date(v_start_time,'YYYY/MM/DD HH24:MI:SS') and IN_STATION_TIME < to_date(v_end_time,'YYYY/MM/DD HH24:MI:SS'); 

                   if v_PTH_COUNT>0 THEN

                         --  v_STATIONYIELDRATE:=round(((v_PTH_COUNT-v_PTH_REPAIRT_COUNT)/v_PTH_COUNT),5) *100;
                         --  v_FIRSTPASSYIELDRATE:=round(((v_PTH_OUT_COUNT)/v_PTH_COUNT),5) *100;

                           Insert into SFISM4.R_DAILY_WO_GROUP_DETAIL (WONO, PTNO, STATIONCODE, STATIONNAME, STATIONSORT,INSTATIONQTY, 
                                                                INREPAIRQTY, OUTSTATIONQTY, STATIONYIELDRATE, FIRSTPASSYIELDRATE,CREATE_DATE)
                                                                 Values   (V_MO_NUMBER, V_MODEL_NAME, 'CESBG_NVDBU_LH_F20_3F_PTH', 'PTH',
                                                                2,v_PTH_COUNT, v_PTH_REPAIRT_COUNT, v_PTH_OUT_COUNT, 100,                                                             
                                                                100,to_char(sysdate,'YYYY/MM/DD'));                         

                     ELSE


                           Insert into SFISM4.R_DAILY_WO_GROUP_DETAIL (WONO, PTNO, STATIONCODE, STATIONNAME, STATIONSORT,INSTATIONQTY, 
                                                                INREPAIRQTY, OUTSTATIONQTY, STATIONYIELDRATE, FIRSTPASSYIELDRATE,CREATE_DATE)
                                                                 Values   (V_MO_NUMBER, V_MODEL_NAME, 'CESBG_NVDBU_LH_F20_3F_PTH', 'PTH',
                                                                2,v_PTH_COUNT, v_PTH_REPAIRT_COUNT, v_PTH_OUT_COUNT,0.00,                                                             
                                                                0.00,to_char(sysdate,'YYYY/MM/DD'));                         

                    end if;              

                   v_res := 'OK';        

      END LOOP;


       update sfis1.C_PARAMETER_INI
         set VR_VALUE = v_end_date,
             LAST_MODIFY_DATE = sysdate
         where PRG_NAME = 'HAINA_REPORT'
              and VR_CLASS = 'NVD'
              and VR_ITEM='HAINA_GET_REPORT_DATA_T';
   end if;


   COMMIT;

EXCEPTION
   WHEN OTHERS
   THEN
      rollback;

END;