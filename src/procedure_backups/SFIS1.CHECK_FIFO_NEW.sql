PROCEDURE             CHECK_FIFO_NEW 
(  
  KEY_PART_NO  IN VARCHAR2,
  PKGID        IN VARCHAR2, 
  RES         OUT VARCHAR2)        

AS

  V_INTO_TIME    VARCHAR2(50);
  V_EXPIRED_TIME VARCHAR2(50);
  V_FLAG         VARCHAR2(50);
  V_FIFOSTATE    VARCHAR2(50);
  V_HHPN         VARCHAR2(100);
  V_RESERVE1     VARCHAR2(100);
  V_PKG          VARCHAR2(50); 
  V_DC           VARCHAR2(50);
  KEY_PART_NEW   VARCHAR2(50);
  FLAG           VARCHAR2(10); --Add by Logan PreLock FLAG  
  v_totalbody1    VARCHAR2(120);
  v_totalbody2    VARCHAR2(120);
  V_OVERDUE      NUMBER;
  V_COUNT0       NUMBER;  
  V_RES          VARCHAR2(500);
  V_COUNT1        NUMBER;
  V_COUNT2        NUMBER;      --Add by Logan ?呾PreLock？講
  P_HHPN           VARCHAR2 (100); 
  P_DATE_CODE      VARCHAR2 (100); 
  P_MFG_PN         VARCHAR2 (100);

--Update Log
--2017.10.31 Added by Jimmy Wang ？FIFO最宒髡夔?傖Procedure

    --FIFO奪諷ㄛ崠?奻?？鏡綎腔PKGID(衄癓蹋)
    CURSOR data_list1
    IS     
    SELECT PKG_ID
      FROM SMTINFO.R_SMT_PKGID_LOG_T
     WHERE PKG_ID IN
              (SELECT pkg_id
                 FROM IQC.R_KPN_INCOMING_T
                WHERE expired_date = TO_DATE (V_EXPIRED_TIME, 'yyyymmdd')
                      AND (fifo_state <> 'C' OR fifo_state IS NULL)
                      AND flag = 0
                      AND hh_pn = V_HHPN
                      AND into_time >= TO_DATE ('20100101', 'yyyymmdd')
              );


    --FIFO奪諷ㄛ崠?奻?？鏡綎腔PKGID(衄癓蹋)ㄛ梑堤D/C 
    CURSOR data_list2
    IS        
    SELECT DISTINCT DATE_CODE 
      FROM IQC.R_KPN_INCOMING_T
     WHERE PKG_ID IN(
                    SELECT PKG_ID
                      FROM SMTINFO.R_SMT_PKGID_LOG_T
                     WHERE PKG_ID IN
                              (SELECT pkg_id
                                 FROM IQC.R_KPN_INCOMING_T
                                WHERE expired_date = TO_DATE (V_EXPIRED_TIME, 'yyyymmdd')
                                      AND (fifo_state <> 'C' OR fifo_state IS NULL)
                                      AND flag = 0
                                      AND hh_pn = V_HHPN
                                      AND into_time >= TO_DATE ('20100101', 'yyyymmdd')
                              )
                    ) 
     ORDER BY DATE_CODE ASC;


    --FIFO奪諷ㄛ帤崠奻?綎ㄛ梑堤D/C   
    CURSOR data_list3
    IS        
    SELECT DISTINCT DATE_CODE 
      FROM IQC.R_KPN_INCOMING_T 
     WHERE expired_date < TO_DATE(V_EXPIRED_TIME,'yyyymmdd') 
       AND (fifo_state <> 'C' OR fifo_state IS NULL ) 
       AND flag = 0 
       AND hh_pn = V_HHPN 
       AND into_time >= TO_DATE('20100101','yyyymmdd')
     ORDER BY DATE_CODE ASC;    

BEGIN

    RES := 'OK';

    IF SUBSTR(KEY_PART_NO,1,1) = 'P' THEN
       KEY_PART_NEW := SUBSTR(KEY_PART_NO,2,LENGTH(KEY_PART_NO)-1);
    ELSE
       KEY_PART_NEW := KEY_PART_NO;
    END IF;    

    SELECT COUNT(0) INTO V_COUNT0 FROM IQC.R_KPN_INCOMING_T WHERE pkg_id = PKGID;

    IF V_COUNT0 > 0 THEN

      --BEGIN ADD BY GINA CHECK GRN DATA 20211002

      SELECT COUNT(0) INTO V_COUNT0 FROM IQC.r_lot_result_t WHERE (GRN_NO,LOT_NO) IN (SELECT GRN_NO,LOT_NO FROM IQC.r_kpn_incoming_t WHERE pkg_id=PKGID);

      IF V_COUNT0=0 THEN

        INSERT INTO IQC.r_lot_result_t
        SELECT GRN_NO,LOT_NO,HH_PN,'SYS','N',NULL,MFG_PN,'N',NULL,'A',NULL,NULL,SYSDATE FROM IQC.r_kpn_incoming_t WHERE PKG_ID=PKGID;
        COMMIT;

      END IF;
      --END ADD BY GINA CHECK GRN DATA 20211002 

       --Add by Logan begin
       /*SELECT COUNT(PKG_ID) INTO V_COUNT2 FROM SFISM4.R_HHPN_LOCK_UNLOCK_T WHERE PKG_ID =PKGID AND UNLOCK_DATE is null;   
       IF V_COUNT2>0 THEN     
          SELECT LOCKFLAG INTO  FLAG FROM SFISM4.R_HHPN_LOCK_UNLOCK_T WHERE PKG_ID =PKGID AND UNLOCK_DATE is null;
          IF  FLAG='LOCK' THEN
             RES := PKGID||' BEING PRE LOCKED';
          RETURN;
          END IF;
       END IF;*/

       --Modify by Logan Begin 2021.12.16
       SELECT HH_PN, DATE_CODE, MFG_PN INTO P_HHPN, P_DATE_CODE, P_MFG_PN
       FROM IQC.R_KPN_INCOMING_T 
       WHERE PKG_ID=PKGID;

       SELECT COUNT(*) INTO V_COUNT2 
       FROM SFISM4.R_HHPN_LOCK_UNLOCK_T WHERE HH_PN=P_HHPN AND DATE_CODE=P_DATE_CODE AND MFG_PN=P_MFG_PN AND UNLOCK_DATE is null;   
       IF V_COUNT2>0 THEN     
         SELECT LOCKFLAG INTO FLAG FROM SFISM4.R_HHPN_LOCK_UNLOCK_T WHERE HH_PN=P_HHPN AND DATE_CODE=P_DATE_CODE AND MFG_PN=P_MFG_PN AND UNLOCK_DATE is null;
         IF FLAG='LOCK' THEN 
            RES := 'HH_PN:' || P_HHPN || ' DATE_CODE:' || P_DATE_CODE ||' BEING PRE LOCKED, CALL QA CHECK!';
            RETURN;
         END IF;
       END IF;
      --Modify by Logan end 2021.12.16
       --Add by Logan end

       SELECT TO_CHAR(into_time,'yyyymmddhh24'),TO_CHAR(expired_date,'yyyymmdd'),flag,NVL(fifo_state,'N'),hh_pn,nvl(RESERVE1,'N/A'),SYSDATE-TO_DATE(TO_CHAR(expired_date,'yyyymmdd'),'yyyymmdd')       
         INTO V_INTO_TIME,V_EXPIRED_TIME,V_FLAG,V_FIFOSTATE,V_HHPN,V_RESERVE1,V_OVERDUE 
         FROM IQC.R_KPN_INCOMING_T 
        WHERE pkg_id = PKGID;

       IF KEY_PART_NEW <> V_HHPN THEN
          --RES := '？鏡蹋?鷂PKGID蹋?祥珨祡,?笭陔？鏡ㄐ'
          RES := 'HH P/N and PKGID is not match, please Check!';
          RETURN;       
       END IF;

       IF V_FLAG <> '0' THEN
          --RES := '森PKG ID？祥謎昜蹋,輦砦追蹋ㄐ'
          RES := 'The Material is bad, prohibited sends the material!';
          RETURN;
       END IF;       

       IF V_FIFOSTATE = 'C' THEN
          --RES := '森PKG ID眒追蹋ㄐ'
          RES := 'The PKG ID is sending!';
          RETURN;    
       END IF;

       IF V_RESERVE1 <> 'Y' THEN
          --RES := '森PKG ID帤?？?磁跡,輦砦追蹋'
          RES := 'This PKGID without inspection, prohibited sends the material!';
          RETURN;    
       END IF;       

       IF V_OVERDUE > 0 THEN
          --RES := '森PKG ID眒綎？ㄐ'
          RES := 'This PKG ID has expired!';
          RETURN;    
       END IF;

       --FIFO奪諷
       V_COUNT1 := 0;
       --data_list1
       OPEN data_list1;
       LOOP
           FETCH data_list1     
           INTO V_PKG;
           EXIT WHEN data_list1%NOTFOUND;

           IF V_PKG = PKGID 
           THEN
              V_COUNT1 := V_COUNT1 + 1 ;
           END IF;      

       END LOOP;  
       CLOSE data_list1;

       --data_list2
       IF V_COUNT1 = 0 
       THEN
          OPEN data_list2;
          LOOP
              FETCH data_list2     
              INTO V_DC;
              EXIT WHEN data_list2%NOTFOUND;

              IF v_totalbody1 IS NULL
              THEN                
                   --?復庲善？？珂筳珂堤
                  --v_totalbody1:= 'Please Check Expired Date FIFO: '||V_PKG; 
                  --2017.12.06 蜊？枑尨D/C
                  v_totalbody1:= 'Please Check D/C FIFO: '||V_DC;
              ELSE
                  IF LENGTH(v_totalbody1) > 100
                  THEN 
                      v_totalbody1:= v_totalbody1||'...'; 

                      RES := v_totalbody1;                
                      RETURN;  
                  ELSE
                      --v_totalbody1:= v_totalbody1||', '||V_PKG;   
                      v_totalbody1:= v_totalbody1||', '||V_DC;               
                  END IF;                         
              END IF;  

          END LOOP;

          IF v_totalbody1 IS NOT NULL
          THEN
             RES := v_totalbody1;
             RETURN;
          END IF;      

          CLOSE data_list2; 

       END IF;   



       --data_list3
       OPEN data_list3;
       LOOP
           FETCH data_list3     
           INTO V_DC;
           EXIT WHEN data_list3%NOTFOUND;

           IF v_totalbody2 IS NULL
           THEN                
                --?復庲善？？珂筳珂堤
               --v_totalbody2:= 'Please Check Expired Date FIFO: '||V_PKG; 
               --2017.12.06 蜊？枑尨D/C
                  v_totalbody2:= 'Please Check D/C FIFO: '||V_DC;
           ELSE
               IF LENGTH(v_totalbody2) > 100
               THEN 
                   v_totalbody2:= v_totalbody2||'...'; 

                   RES := v_totalbody2;                
                   RETURN;  
               ELSE
                   --v_totalbody2:= v_totalbody2||', '||V_PKG;
                   v_totalbody2:= v_totalbody2||', '||V_DC;                 
               END IF;                         
           END IF;  

       END LOOP;    

       IF v_totalbody2 IS NOT NULL
       THEN   
          RES := v_totalbody2;
          RETURN;         
       END IF;

       CLOSE data_list3;    


       --追蹋
       --UPDATE IQC.R_KPN_INCOMING_T SET fifo_state = 'C' WHERE pkg_id = PKGID ; 
       --COMMIT;        

    ELSE

       RES := 'NO PKGID';
       RETURN;
    END IF;


EXCEPTION
    WHEN OTHERS THEN
       RES:='ERROR :SP[CHECK_FIFO_NEW]';
END;