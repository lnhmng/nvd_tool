PROCEDURE                                                       CHECK_SYNCHRONIZATION_STATUS
AS
   v_sn        VARCHAR2 (50);
   v_count     INTEGER ;
   v_count_bk  INTEGER ;
   v_mo_number  VARCHAR2 (50);
   modetail    VARCHAR2 (50);
   last_date   DATE;
   curr_date   DATE;
   RES         VARCHAR2 (100);
   
   CURSOR MO IS SELECT DISTINCT MO_NUMBER FROM SFISM4.R_SN_DETAIL_T WHERE IN_STATION_TIME BETWEEN last_date and curr_date ;
   
BEGIN
  
    last_date := sysdate - 30/1440  ;
    curr_date  := sysdate - 2;

    SELECT count(1) into v_count
    FROM SFIS1.C_SYNCHRONIZATION_LOG
    WHERE  VR_STATUS ='CHECK_DATA';
    
    IF v_count >0
    THEN
        select max(VR_DATE) INTO last_date
        FROM SFIS1.C_SYNCHRONIZATION_LOG;
    ELSE 
        INSERT INTO SFIS1.C_SYNCHRONIZATION_LOG(VR_STATUS,VR_DATE)
        VALUES ('CHECK_DATA',curr_date);
    END IF ;
    
    
    
    FOR molist in MO
    LOOP  modetail := molist.mo_number ;
         
         SELECT MO_NUMBER ,COUNT(*) 
         INTO v_mo_number ,v_count
         FROM SFISM4.R_SN_DETAIL_T 
         WHERE IN_STATION_TIME BETWEEN last_date and curr_date 
         AND MO_NUMBER = modetail
         GROUP BY MO_NUMBER ;
         
         SELECT MO_NUMBER ,COUNT(*) 
         INTO v_mo_number ,v_count_bk
         FROM SFISM4.R_SN_DETAIL_T@NVDBK
         WHERE IN_STATION_TIME BETWEEN last_date and curr_date 
         AND MO_NUMBER = modetail
         GROUP BY MO_NUMBER ;
    
         insert into SFIS1.C_SYNCHRONIZATION_LOG(VR_STATUS,VR_DATE,VR_MO,VR_NUM,VR_NUM_BK)
         values ( 'SUCCESS',curr_date,v_mo_number,v_count,v_count_bk);
    END LOOP;
    
    
END;