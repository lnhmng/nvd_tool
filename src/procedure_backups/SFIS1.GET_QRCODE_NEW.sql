PROCEDURE       GET_QRCODE_NEW (
   DATA      IN        VARCHAR2,
   SN        IN        VARCHAR2,
   PKG       IN        VARCHAR2,
   EMP       IN VARCHAR2,             
   RES       OUT       VARCHAR2)
IS
    V_COUNT      NUMBER;
    --V_COUNT1     NUMBER;
    PCB          VARCHAR2(100);
    PCB_2D       VARCHAR2(24);
    D_1          VARCHAR2(3);
    D_2          VARCHAR2(6);
    D_3          VARCHAR2(4);
    D_4          VARCHAR2(3);
    PCB_HH       VARCHAR2(20);
    S_QTY        NUMBER(4);
    L_QTY        NUMBER(4);
    e_CLOSE      EXCEPTION;
    e_PCB        EXCEPTION;
    e_null       EXCEPTION;        
/* Created by Lyc  Date: 2023-01-06 */
BEGIN
/* Created by Lyc  Date: 2023-02-14 */  
  IF DATA = 'CLOSE' THEN
    UPDATE SFISM4.R_WIP_TRACKING_T SET GROUP_NAME ='0' WHERE SERIAL_NUMBER =SN;
    DELETE FROM SFISM4.R_PCB_DATECODE_T WHERE SERIAL_NUMBER =SN;
    RAISE e_CLOSE;
  END IF;

  PCB :=DATA;

  PCB_2D :=SUBSTR(PCB,8,18);
  D_1 :=SUBSTR(PCB_2D,1,3);
  D_2 :=SUBSTR(PCB_2D,5,6);
  D_3 :=SUBSTR(PCB_2D,-8,4);
  D_4 :=SUBSTR(PCB_2D,-3,3);

  PCB_HH :=D_1||D_2 ||D_3 ||D_4 ||'HF';

  SELECT COUNT(KEY_PART_NO) 
    INTO S_QTY  
    FROM  SFIS1.C_SMT_KP_SPARE_T 
  WHERE SPARE_KEY_PART_NO = PCB_HH;

  SELECT COUNT(*) 
   INTO L_QTY 
   FROM SFIS1.C_ITEM_DESC_T
  WHERE ITEM_SERIAL = PCB_HH; 

   IF (S_QTY =0 and L_QTY =0) THEN
       RAISE e_PCB;
      END IF;
/* Created by Lyc  Date: 2023-02-14 */   
   IF SUBSTR (DATA, 8, 3) = '180'
   THEN
        SELECT COUNT(*)
         INTO V_COUNT
         FROM SFISM4.R_SN_LINK_PKG_QRCODE_T 
        WHERE QR_CODE = DATA;

        /*
        SELECT COUNT(*)
        INTO V_COUNT1
        FROM SFISM4.R_SN_LINK_PKG_QRCODE_T
        WHERE SERIAL_NUMBER = SN;
        */

        IF V_COUNT > 0 --(V_COUNT > 0 OR V_COUNT1 >0)
        THEN
            RES:='QRCODE IS USED';
        ELSE
            RES:='OK';
        END IF;        
   ELSE
    res := 'WRONG QRCODE';

   END IF;

EXCEPTION
   WHEN e_CLOSE
   THEN
      res :='PLS SCAN UNDO';
   WHEN e_PCB
   THEN
      res :='NO INPUT MAKEFEEDER!';
   WHEN e_null
   THEN
      NULL;
   WHEN OTHERS
   THEN
      res := 'OTHER ERROR ';
END;