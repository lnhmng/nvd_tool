PROCEDURE                      Insert_Route( LINE IN VARCHAR2,
MYGROUP  IN VARCHAR2,
T_CODE IN  NUMBER,
T_STEP  IN NUMBER,
RES OUT VARCHAR2) AS
T_STATE NUMBER(1);
CURSOR  OTHER_GROUP IS SELECT DISTINCT  GROUP_NEXT FROM
                                                                         SFIS1.C_ROUTE_CONTROL_T
                   WHERE  STEP_SEQUENCE<=T_STEP
                            AND     ROUTE_CODE=T_CODE;
BEGIN
SELECT STATE INTO T_STATE FROM SFISM4.R_LSA_STOP_H;
      FOR V_ROW IN  OTHER_GROUP LOOP
           IF  V_ROW.group_next<>MYGROUP AND V_ROW.GROUP_NEXT<>'BEGIN' THEN
                INSERT INTO SFISM4.R_LSA_STOP_H (LINE_NAME,GROUP_NAME,C_RATIO,S_RATIO,P_RATIO,
                                                                                FAIL_NUM,TOTAL_NUM,STATE,SN,CDATE)
                                                                         VALUES(LINE,V_ROW.GROUP_NEXT,0,0, 0,0,0,T_STATE,MYGROUP,SYSDATE);
           END IF;
		   commit;
      END LOOP;
  RES:='OK';
EXCEPTION
   WHEN OTHERS THEN
   RES := 'OK';
END;