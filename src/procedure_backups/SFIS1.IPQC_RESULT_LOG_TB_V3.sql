PROCEDURE                                     Ipqc_Result_Log_TB_V3(
       EMP          IN VARCHAR2,
       LINE         IN VARCHAR2,
       SECTION      IN VARCHAR2,
       MYGROUP      IN VARCHAR2,
       DATETIME     IN DATE,
       STATION_NUM  IN  VARCHAR2,
       W_STATION    IN VARCHAR2,
       W_SECTION    IN NUMBER,
       SN           IN VARCHAR2,
       EC           IN VARCHAR2,
       DATA         IN VARCHAR2,
       QC           IN VARCHAR2,
       RES          OUT VARCHAR2 ) AS
       
       RESULT          VARCHAR2(36);
       r_RESULT        VARCHAR2(1);
       r_MO            VARCHAR2(25);
       v_MODEL         VARCHAR2(25);
       R_RETURN        VARCHAR2(36);
       MO_DATE         VARCHAR2(24);
       R_STATION       VARCHAR2(36);
       R_GROUPNAME     VARCHAR2(36);
       R_NEXTGROUPNAME VARCHAR2(36);
       N_STATION       VARCHAR2(36);
       NECCOUNT        NUMBER;
       SN_ERROR_FLAG   VARCHAR2(2);
       V_GROUP         VARCHAR2(20);
       C_ROUTE         VARCHAR2(10);
       C_GROUP         VARCHAR2(20);
       C_GROUP_NEXT    VARCHAR2(20);
       C_NUM           INTEGER;
       e_EXCUTE        EXCEPTION;
       e_DEBUG         EXCEPTION;
       e_FAILED        EXCEPTION;
       e_SCRAPED       EXCEPTION;
       e_INPUT_UPDATE  EXCEPTION;
       e_route         EXCEPTION;
BEGIN
    MO_DATE:=TO_CHAR(SYSDATE,'YYYYMMDD');
    R_STATION:=W_STATION;
    V_GROUP:=MYGROUP;
    SELECT MO_NUMBER,MODEL_NAME,ERROR_FLAG,GROUP_NAME,SPECIAL_ROUTE INTO r_MO,v_MODEL,SN_ERROR_FLAG,C_GROUP,C_ROUTE FROM SFISM4.R_WIP_TRACKING_T
           WHERE SERIAL_NUMBER=SUBSTR(DATA,1,13);
    IF SN_ERROR_FLAG='1' THEN
        RAISE e_FAILED;
    END IF;
    IF SN_ERROR_FLAG='2' THEN
        RAISE e_SCRAPED;
    END IF;
    IF V_GROUP='S_VI' THEN
        SELECT COUNT(*) INTO C_NUM FROM SFIS1.C_ROUTE_CONTROL_T WHERE GROUP_NAME=C_GROUP AND GROUP_NEXT like'%S_VI%' AND ROUTE_CODE=C_ROUTE ;
        IF C_NUM>0 THEN
            SELECT GROUP_NEXT INTO C_GROUP_NEXT FROM SFIS1.C_ROUTE_CONTROL_T WHERE GROUP_NAME=C_GROUP AND GROUP_NEXT like'%S_VI%' AND ROUTE_CODE=C_ROUTE ;
            V_GROUP:=C_GROUP_NEXT;
        ELSE
            RAISE e_route;
        END IF;
    END IF;
    IF QC<>'N/A' AND QC IS NOT NULL THEN
        if EC is null OR EC='N/A' then
            RESULT:='N/A';
        else
            RESULT:=EC;
            --update state .
            INSERT INTO SFISM4.R_REPAIR_T(
                                    SERIAL_NUMBER,
                                 MO_NUMBER,
                                 MODEL_NAME,
                                    TEST_CODE,
                                    TEST_TIME,
                                    TEST_STATION,
                                    TEST_LINE,
                                 TESTER)
                                 VALUES(SUBSTR(DATA,1,13),r_MO,v_MODEL,RESULT,SYSDATE-5/(24*3600),R_STATION,LINE,QC);
            UPDATE SFISM4.R_WIP_TRACKING_T SET
                   ERROR_FLAG='1',SECTION_NAME=SECTION,GROUP_NAME=V_GROUP,STATION_NAME=V_GROUP,IN_STATION_TIME=sysdate,EMP_NO=QC WHERE SERIAL_NUMBER=SUBSTR(DATA,1,13);

        end if;
        INSERT INTO SFISM4.R_IPQC_LOG_T(SERIAL_NUMBER,MODEL_NAME,MO_NUMBER,LINE_NAME,SECTION_NAME,IPQC_EMP,RESULT)
         values(SN,v_MODEL,r_MO,LINE,V_GROUP,QC,RESULT);
        COMMIT;
    ELSE
        if substr(MYGROUP,1,1)='S' then
           SFIS1.Multi_Sn_Update(EMP,LINE,SECTION,V_GROUP,DATETIME,EC,UPPER(SUBSTR(DATA,1,13)),MO_DATE,
                      W_SECTION,V_GROUP,R_RETURN);
        else
           if substr(MYGROUP,1,1)='F' then
               SFIS1.TEST_INPUT_Z_H(EMP,LINE,SECTION,W_STATION,DATETIME,EC,UPPER(SUBSTR(DATA,1,13)),MO_DATE,
                        W_SECTION,MYGROUP,R_RETURN);
           else
               SFIS1.Test_Input_Z(EMP,LINE,SECTION,W_STATION,DATETIME,EC,UPPER(SUBSTR(DATA,1,13)),MO_DATE,
                       W_SECTION,MYGROUP,R_RETURN);
           end if;
        end if;
        IF R_RETURN<>'OK' THEN
              RAISE e_EXCUTE;
        END IF;
    END IF;
RES := 'OK';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
       RES:='NO SN';
    WHEN e_FAILED THEN
       RES:='Need go to REPAIR';
    WHEN e_SCRAPED THEN
       RES:='SN: Has been scraped.';
    WHEN e_EXCUTE THEN
       RES:=R_RETURN;
    when e_route then
       CHECK_ROUTE(LINE,MYGROUP,SUBSTR(DATA,1,13),RES);
    WHEN OTHERS THEN
       ROLLBACK;
       RES :='PLEASE RETRY: '||SUBSTR(SQLERRM,1,50);
END;
-- for issd ipqc write by liuyunjiang 2005-10-10 .
-- update by liuyunjiang 2006-1-12.