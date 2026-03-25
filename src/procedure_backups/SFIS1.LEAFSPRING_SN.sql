PROCEDURE       LEAFSPRING_SN (
   DATA      IN        VARCHAR2,
   LINE    IN VARCHAR2,
   MYGROUP IN VARCHAR2,
   PSN     IN VARCHAR2,
   RES       OUT       VARCHAR2)
IS
   UPC_SN       VARCHAR2 (25);
   C_ID         VARCHAR2 (25);
   e_ERROR      EXCEPTION;         --S0000WDY0,SN 比對 19/11/27

BEGIN
   --base on SFIS1.BIDUI_SN for leafspring_assy  --liujiang20250419
    /*
   SELECT SERIAL_NUMBER INTO UPC_SN  FROM SFISM4.R_WIP_TRACKING_T WHERE SERIAL_NUMBER=SUBSTR(DATA,1,13);
   IF UPC_SN <=0 THEN
       RES:='NO SN/';
   ELSE
   RES :='OK';
   END IF; */
    
   IF DATA = PSN THEN    
     RES:='ID not allow same SN/';
   ELSE
   RES :='OK';
   END IF; 
   
   IF SUBSTR(DATA,1,7) <>'VNNVFXA' THEN     --光州臨時提供的 治具編碼前綴 原則 後續可能調整20250419
     RES:='TOOL ID ERROR/';
   ELSE
     RES :='OK';
   END IF; 
   
   SELECT LINE_NAME INTO C_ID FROM SFISM4.R_BIDUI_SN_T WHERE SERIAL_NUMBER = PSN AND GROUP_NAME = MYGROUP ;
   
    IF C_ID <> LINE THEN
        RES :='LINE changed pls UNDO/';      --防止多個工站同時掃描 第三部發生等待 突然再掃描 導致路由從後面退到當前
    ELSE        
        UPDATE SFISM4.R_BIDUI_SN_T SET BIDUI_SN = DATA,BIDUI_DATE = SYSDATE WHERE SERIAL_NUMBER = PSN AND GROUP_NAME =MYGROUP and LINE_NAME =LINE ;
    insert into SFISM4.R_BIDUI_SN_T1 VALUES(PSN,DATA,sysdate);
    END IF;
   ---------20230601 add by lyc end-------

exception
   when others then
      RES:='ERROR PLS UNDO/';
END;