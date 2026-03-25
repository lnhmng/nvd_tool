PROCEDURE                               Ipqc_Result_Log_AOI_Fail(
       EMP          IN      VARCHAR2,
       LINE         IN      VARCHAR2,
       SECTION      IN      VARCHAR2,
       MYGROUP      IN      VARCHAR2,
       DATETIME     IN      DATE,
       STATION_NUM  IN      VARCHAR2,
       W_STATION    IN      VARCHAR2,
       W_SECTION    IN      NUMBER,
       SN           IN      VARCHAR2,
       EC           IN      VARCHAR2,
       DATA         IN      VARCHAR2,
       QC           IN      VARCHAR2,
       MACHINE      IN      VARCHAR2,
       RES          OUT     VARCHAR2 ) 
       AS
       RESULT               VARCHAR2(36);
       r_RESULT             VARCHAR2(1);
       r_MO                 VARCHAR2(24);
       v_MODEL              VARCHAR2(24);
       R_RETURN             VARCHAR2(36);
       MO_DATE              VARCHAR2(24);
       R_STATION            VARCHAR2(36);
       R_GROUPNAME          VARCHAR2(36);
       R_NEXTGROUPNAME      VARCHAR2(36);
       N_STATION            VARCHAR2(36);
       NECCOUNT             NUMBER;
       SN_ERROR_FLAG        VARCHAR2(2);
       V_GROUP              VARCHAR2(16);
       V_GROUP1             VARCHAR2(16);
       C_ROUTE              VARCHAR2(10);
       C_GROUP              VARCHAR2(16);
       C_GROUP_NEXT         VARCHAR2(16);
       C_NUM                INTEGER;
       OK                   VARCHAR2(15);
       P_TYPE               VARCHAR2(15);
       p_WORKDATE           VARCHAR2(8);
       p_WORKTIME           VARCHAR2(6);
       p_CNTREPAIR          INTEGER;
       p_WORKSECT           NUMBER(2,0);
       C_COUNT              INTEGER;
       C_LINE               VARCHAR2(15);
       CHECKRES             VARCHAR2(50);
       PRODUCTRES           VARCHAR2(50);
       e_EXCUTE             EXCEPTION;
       e_DEBUG              EXCEPTION;
       e_FAILED             EXCEPTION;
       e_SCRAPED            EXCEPTION;
       e_ERROR              EXCEPTION;
       e_route              EXCEPTION;
       e_machine            EXCEPTION;
       e_CHECK_ERROR        EXCEPTION;
BEGIN
     OK := 'OK';

     p_WORKDATE:=TO_CHAR(SYSDATE,'YYYYMMDD');
     p_WORKTIME:=TO_CHAR(SYSDATE,'HH24MISS');
     p_WORKSECT:=SUBSTR(p_WORKTIME,1,2);
       SELECT MO_NUMBER,MODEL_NAME,ERROR_FLAG,GROUP_NAME,SPECIAL_ROUTE INTO r_MO,v_MODEL,SN_ERROR_FLAG,C_GROUP,C_ROUTE FROM SFISM4.R_WIP_TRACKING_T
            WHERE SERIAL_NUMBER=DATA;
       IF SN_ERROR_FLAG='1' THEN
             RAISE e_FAILED;
          END IF;
       IF SN_ERROR_FLAG='2' THEN
          RAISE e_SCRAPED;
       END IF;

       IF MYGROUP='AOI_CHECK' then
          CHECK_ROUTE(LINE,MYGROUP,DATA,OK);
          V_GROUP1:=TRIM(REPLACE(OK,'GO-',''));
          
          IF SUBSTR(V_GROUP1,1,4)='AOI_' THEN
                                    
             select count(1) into C_COUNT from sfis1.c_ict_station_t
                    where station_code = MACHINE 
                    AND LINE_NAME LIKE substr(LINE,1,length(LINE)-1)||'%'
                    and group_name=V_GROUP1;
                    
             if C_COUNT=0 then
                raise e_machine;
             else
                 select line_name into C_LINE from sfis1.c_ict_station_t
                    where station_code = MACHINE 
                    AND LINE_NAME LIKE substr(LINE,1,length(LINE)-1)||'%'
                    and group_name=V_GROUP1 and rownum=1;
                    
             end if;
                
             SMTINFO.CHECK_BIND_ROUTE_V2(TRIM(DATA),SECTION,V_GROUP1,'N/A',C_LINE, PRODUCTRES ,CHECKRES);
             IF CHECKRES <> 'OK' THEN
               raise e_CHECK_ERROR;
             END IF;
             
             IF P_TYPE = 'W' THEN
                INSERT INTO SFISM4.R_REPAIR_T(SERIAL_NUMBER,MO_NUMBER,TEST_TIME,
                   TEST_CODE,TEST_STATION,TEST_LINE,RECORD_TYPE,MODEL_NAME,
                      REPAIRER,REPAIR_TIME,REASON_CODE,REPAIR_STATION, REPAIR_STATUS,
                      DUTY_TYPE,ERROR_ITEM_CODE)
                   VALUES(DATA,r_MO,DATETIME,EC,V_GROUP1,C_LINE,'T',v_MODEL,
                      V_GROUP1,DATETIME,'ERQ002',V_GROUP1,'N',
                      'W','A0000');
                   COMMIT;
             ELSE         
             
                INSERT INTO SFISM4.R_TEST_RESULT_T(SERIAL_NUMBER,STATION_ID,TEST_DATE,TEST_TIME,RESULT,MODEL_NAME,STATION_TYPE,WORK_STATION,OPERATOR,RETEST,FAILDESC,MO_NUMBER,FIXTURE_ID)
                VALUES(DATA,0,p_WORKDATE,p_WORKTIME,'F',v_MODEL,V_GROUP1,0,EMP,0,'N/A',r_MO,MACHINE);
               
                SFIS1.STN_REC_Z(LINE,SECTION,V_GROUP1,V_GROUP1,r_MO,DATA, p_WORKDATE,p_WORKSECT,'1');
                UPDATE_R107(EMP,C_LINE,SECTION,V_GROUP1,V_GROUP1,r_MO,DATA,'1',DATETIME);
                INSERT INTO SFISM4.R_REPAIR_T(SERIAL_NUMBER,MO_NUMBER,TEST_TIME,
                   TEST_CODE,TEST_STATION,TEST_LINE,RECORD_TYPE,MODEL_NAME)
                   VALUES(DATA,r_MO,DATETIME,EC,V_GROUP1,C_LINE,'T',v_MODEL);
               COMMIT;
             END IF;
          ELSE
             RES := OK;
             RAISE e_route;   
          END IF;          
       ELSE            
           RAISE e_ERROR;
       END IF;            
         
       RES:='OK';
EXCEPTION
      WHEN NO_DATA_FOUND THEN
           RES:='NO SN';
      WHEN e_FAILED THEN
           RES:='Need go to REPAIR ';
      WHEN e_SCRAPED THEN
           RES:='SN: Has been scraped.';
      WHEN e_EXCUTE THEN
           RES:=R_RETURN;
      WHEN e_ERROR THEN
           RES:='Error,this SP is only used by AOI_CHECK STATION,Scan Fail!';
      when e_machine then
           RES:='STATION NOT MATCH THE MACHINE_CODE.';
      WHEN e_CHECK_ERROR THEN
           RES := CHECKRES; 
      when e_route then
           NULL;
        WHEN OTHERS THEN
             ROLLBACK;
             RES :='PLEASE RETRY';
END;