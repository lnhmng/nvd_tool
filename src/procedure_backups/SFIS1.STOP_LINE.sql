PROCEDURE             STOP_LINE (
SN      IN       VARCHAR2,
MYGROUP IN       VARCHAR2,
RES     OUT      VARCHAR2)
IS
S_MODEL          VARCHAR2 (32);
S_MO             VARCHAR2 (32);
S_FLAG           NUMBER;
S_GROUP          VARCHAR2 (32);
S_STATION        VARCHAR2 (32);
S_CODE           VARCHAR2 (32);
C_QTY            NUMBER;
P_QTY            NUMBER;
H_QTY            NUMBER;
D_QTY            NUMBER;
W_QTY            NUMBER;
MO_QTY           NUMBER;
M_PERCENT        NUMBER;
Q_PERCENT        NUMBER;


BEGIN
  select model_name,mo_number,error_flag,GROUP_NAME,STATION_NAME into S_MODEL,S_MO,S_FLAG,S_GROUP,S_STATION from sfism4.r_wip_tracking_t where serial_number=sn;
  IF S_GROUP=MYGROUP AND S_FLAG=1 THEN
      SELECT TEST_CODE INTO S_CODE FROM (SELECT * FROM SFISM4.r_repair_t WHERE SERIAL_NUMBER=SN AND test_station =S_STATION ORDER BY TEST_TIME DESC) WHERE ROWNUM=1;
      SELECT COUNT(*) INTO P_QTY FROM SFIS1.C_STOP_LINE_T WHERE MODEL_NAME=S_MODEL AND GROUP_NAME=MYGROUP;
        IF P_QTY>0 THEN
          SELECT ONE_H_QTY,ONE_D_QTY,ONE_W_QTY,MO_ERROR_QTY,ONE_M_PERCENT,ONE_Q_PERCENT,cont_qty
          INTO H_QTY,D_QTY,W_QTY,MO_QTY,M_PERCENT,Q_PERCENT,C_QTY
          FROM SFIS1.C_STOP_LINE_T WHERE MODEL_NAME=S_MODEL AND GROUP_NAME=MYGROUP;

            IF H_QTY>0 THEN --1小時相同不良停線規則檢查及操作
                sfis1.STOP_FOR_1H(S_MODEL,S_CODE,MYGROUP,H_QTY,SN);
            END IF;
            IF C_QTY>0 THEN  --連續測試相同不良停線規則檢查及操作
                sfis1.STOP_FOR_CONTINUE(S_MODEL,S_CODE,MYGROUP,C_QTY,SN);
            END IF;
            IF D_QTY>0 THEN  --1天相同不良停線規則檢查及操作
                sfis1.STOP_FOR_1D(S_MODEL,S_CODE,MYGROUP,D_QTY,SN);
            END IF;
            IF W_QTY>0 THEN  --1周相同不良停線規則檢查及操作
                sfis1.STOP_FOR_1W(S_MODEL,S_CODE,MYGROUP,W_QTY,SN);
            END IF;
            IF MO_QTY>0 THEN  --同工令相同不良停線規則檢查及操作
                sfis1.STOP_FOR_MO(S_MODEL,S_CODE,MYGROUP,MO_QTY,SN);
            END IF;
            IF M_PERCENT>0 AND M_PERCENT<1 THEN  --30天相同不良停線規則檢查及操作
                sfis1.STOP_FOR_1M(S_MODEL,S_CODE,MYGROUP,M_PERCENT,SN);
            END IF;
            IF Q_PERCENT>0 AND Q_PERCENT<1 THEN  --90天相同不良停線規則檢查及操作
                sfis1.STOP_FOR_1Q(S_MODEL,S_CODE,MYGROUP,Q_PERCENT,SN);
            END IF;

        END IF;
        RES :='OK';
    else
    RES:='OK';
  END IF;
RES :='OK';
END STOP_LINE;