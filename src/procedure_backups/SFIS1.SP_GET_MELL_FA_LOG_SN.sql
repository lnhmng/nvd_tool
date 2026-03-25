PROCEDURE             SP_GET_MELL_FA_LOG_SN (
   i_START_DATE      IN     VARCHAR2,
   i_END             IN     VARCHAR2,
   i_work_order      IN     VARCHAR2,
   o_res                OUT VARCHAR2)
IS
   p_num               NUMBER;
   p_sn                VARCHAR2 (50);
   p_DESC_LINE         VARCHAR2 (200);
   p_pro_fail_time    VARCHAR2 (50);
   p_model_name        VARCHAR2 (50);   
   p_mo_number         VARCHAR2 (50); 
   P_ERROR_ITEM_CODE   VARCHAR2 (200); 
   p_TARGET_QTY        NUMBER;

   p_reason_code         VARCHAR2 (100); 
   p_reason_desc         VARCHAR2 (200);  

   p_description         VARCHAR2 (200);

   p_station         VARCHAR2 (200);
   p_repair_station   VARCHAR2 (200);
  
   p_FIRST_RESULT      VARCHAR2 (200);
   p_SECORD_RESULT       VARCHAR2 (50);
   p_REPAIR_TIME      VARCHAR2 (50);
   
   p_pass_time      VARCHAR2 (50);
 
   p_ERROR_DESC         VARCHAR2 (200);
   p_SIDE         VARCHAR2 (50);
  
   p_location      VARCHAR2 (2000);

   p_ERROR_PRO         VARCHAR2 (200);  
   P_Failure          VARCHAR2 (200);   
   p_QTY        NUMBER;
   p_SN_TYPE      VARCHAR2 (50);
  
   p_QTY2        NUMBER;

   p_ref_pn            VARCHAR2 (100);
   p_REF_PN_DESC       VARCHAR2 (200);
   
   p_REF_CUST_PN       VARCHAR2 (100);
   P_MO_CREATE_DATE     VARCHAR2 (50);
   p_mnufcture_name   VARCHAR2 (100);
   p_OLD_DATE_CODE   VARCHAR2 (100);
   p_OLD_LOT_NO   VARCHAR2 (100);
   
   P_COMP_TYPE         VARCHAR2 (100);
   P_SYMPTOM           VARCHAR2 (200);
   P_SYMPTOM_DESC        VARCHAR2 (200);
   P_SHAPE               VARCHAR2 (100);
   P_SEQUENCE           NUMBER;
   P_FPY_CALC            NUMBER;  
   
   p_D_CUST_PN         VARCHAR2 (100);
   p_D_PN   VARCHAR2 (50);
      
   p_FG_SFC_PN   VARCHAR2 (50);
   
   p_WEEKLY      VARCHAR2 (30);
   p_D_SN      VARCHAR2 (50);
   p_D_SYMTIOM       VARCHAR2 (200);
   p_D_STATION      VARCHAR2 (200);
   

   CURSOR ssn_cur
     IS    
    
            SELECT 
             DISTINCT BB.serial_number,
               mx.PT_SERIAL,          
               TO_CHAR (BB.test_time, 'YYYY-MM-DD HH24:MI:SS') AS production_fail_time,
               BB.PN AS PN,
               (mx.DESCRIPTION) as desc1,
               MO.mo_number,            
              
               CASE
                  WHEN (BB.ERROR_ITEM_CODE='NTF' OR BB.ERROR_ITEM_CODE='CND') THEN ''
                  ELSE BB.ERROR_ITEM_CODE
                 END
                  AS ERROR_ITEM_CODE,          
             
               MO.TARGET_QTY,                        
               BB.REASON_CODE,
               M1.reason_desc2,
               
              
               BB.TEST_STATION AS STATION,           
               BB.PC,                        
               
               'FAIL' AS RESULT,               
               
                  CASE
                  WHEN TO_CHAR(wip_t.IN_STATION_TIME, 'YYYY-MM-DD HH24:MI:SS') IS NOT NULL 
                  THEN
                     'PASS'
                  ELSE
                     ''
               END  AS TWO_RESULT,           
             
              
               TO_CHAR(BB.repair_time, 'YYYY-MM-DD HH24:MI:SS')  as repair_time,
               
               TO_CHAR(wip_t.IN_STATION_TIME, 'YYYY-MM-DD HH24:MI:SS')  as pass_time,
              
              substr(BB.REF_PN_DESC,1,90) AS ERROR_DESC,
             
               NVL (substr(pkg.MACHINE_CODE,length(pkg.MACHINE_CODE)-3,1),'T') AS SIDE,
              -- substr(pkg.MACHINE_CODE,length(pkg.MACHINE_CODE)-3,1) as SIDE,
              --  pkg.location,
               '' AS LOCATION,
               
               BB.TEST_CODE AS errorcode_prod, 
                           
               substr(BB.REF_PN_DESC,1,90) AS Failure,
               
               to_number('1') as qty,
                CASE
                  WHEN (MO.MO_TYPE='NEW_ITEM' OR MO.MO_TYPE='NORMAL') THEN 'NO'
                  ELSE 'YES'
                 END
                  AS RETURN_SN,
               --BB.SUPPLIER_NAME as REF_PN,
               
               CASE
                  WHEN (M1.reason_desc2='NTF' OR M1.reason_desc2='CND') THEN ''
                  ELSE BB.OLD_HHPN 
                 END
                  AS REF_PN,            
              
             --  BB.OLD_HHPN as REF_PN,
               
             --  BB.OLD_HHPN AS REF_CUSTOMER_PN,               
                 CASE
                  WHEN (M1.reason_desc2='NTF' OR M1.reason_desc2='CND') THEN ''
                  ELSE BB.OLD_HHPN 
                 END
                  AS REF_CUSTOMER_PN,  
                
                  CASE
                   WHEN pkg.location IS NULL
                    THEN ''
                   ELSE to_char(length(pkg.location)-length(replace(pkg.location,','))+1) 

                END AS REF_QTY, 
             
              
               BB.SUPPLIER as mnufcture_name,
              
               CASE
                  WHEN (M1.reason_desc2='NTF' OR M1.reason_desc2='CND') THEN ''
                  ELSE BB.OLD_DATE_CODE 
                 END
                  AS OLD_DATE_CODE,              
              
              -- BB.OLD_DATE_CODE,
              -- BB.OLD_LOT_NO,
               CASE
                  WHEN (M1.reason_desc2='NTF' OR M1.reason_desc2='CND') THEN ''
                  ELSE BB.OLD_LOT_NO 
                 END
                  AS OLD_LOT_NO,  
                   
                
              -- BB.REF_PN_DESC,
               substr(BB.REF_PN_DESC,1,90) AS REF_PN_DESC,
               
               'SMT' AS COMP_TYPE,            
              --  BB.SYMPTOM,
                 substr(BB.SYMPTOM,1,90) AS SYMPTOM,
                
               -- BB.SYMPTOM_DESC,
               substr(BB.SYMPTOM_DESC,1,90) AS SYMPTOM_DESC,
              
               '' AS SHAPE,
               to_number('1') AS SEQUENCE,
               to_number('0') AS FPY_CALC,              
   
              -- link1.MODEL_NAME as DAD_CUSTOMER,
              -- link1.MODEL_NAME AS DAD_PN,
            
                  
                  CASE
                 -- WHEN (BB.PN like 'MCX%') THEN link1.MODEL_NAME
                  WHEN (BB.PN like 'MCX%') THEN BB.PN
                 -- ELSE BB.PN
                      ELSE ''
                 END
                   AS DAD_CUSTOMER,     
               
              -- link1.MODEL_NAME AS DAD_PN,
               
                  
                 CASE
                  WHEN (BB.PN like 'MCX%') THEN link1.MODEL_NAME
                  ELSE BB.PN
                 END
                  AS FG_SFC_PN, 
                 
                  CASE
                 -- WHEN (BB.PN like 'MCX%') THEN link1.MODEL_NAME
                  WHEN (BB.PN like 'MCX%') THEN BB.PN
                  ELSE ''
                 END
                  AS DAD_PN,   
           
             --  link1.init_sn AS DAD_SN,
               
                 CASE
                  WHEN (SUBSTR (BB.serial_number,1,1)='2') or (SUBSTR (BB.serial_number,1,1)='3') or (SUBSTR (BB.serial_number,1,1)='4') THEN  BB.serial_number
                  ELSE link1.init_sn
                  END
                  AS DAD_SN,               
                --BB.SYMPTOM AS DAD_SYMPTIOM,
                substr(BB.SYMPTOM,1,90) AS DAD_SYMPTIOM,
                
               '' DAD_STATION,               
               
               TO_CHAR(mo.MO_CREATE_DATE, 'YYYY-MM-DD') AS MO_CREATE_DATE,
               TO_CHAR(BB.repair_time, 'YYYYIW')  as WEEKLY
       
        FROM (

        select B.SERIAL_NUMBER,B.model_name AS PN,B.ERROR_ITEM_CODE,B.REASON_CODE,B.TEST_STATION,B.MO_NUMBER,B.TEST_CODE,B.TEST_TIME,
                              
        A.STATION_TYPE,A.FAILDESC as REF_PN_DESC,B.repair_time,B.SUPPLIER,B.SUPPLIER_NAME,B.OLD_HHPN,B.OLD_DATE_CODE,B.OLD_LOT_NO,                      
                (A.ERROR_CODE||A.FAILDESC) AS SYMPTOM,
                A.FAILDESC AS SYMPTOM_DESC,A.MACHINE_CODE AS PC             
          -- from sfism4.r_test_temp_t A LEFT JOIN sfism4.r_repair_t B  ON A.serial_number=B.SERIAL_NUMBER AND A.STATION_TYPE=B.TEST_STATION AND A.RESULT='F' AND 
            from sfism4.r_test_temp_t A LEFT JOIN sfism4.r_repair_t B  ON A.serial_number=B.SERIAL_NUMBER AND SUBSTR(A.STATION_TYPE,1,3)=SUBSTR(B.TEST_STATION,1,3) AND A.RESULT='F' AND 
           A.BASIC_TESTTIME_END=(select MAX(A.BASIC_TESTTIME_END) from sfism4.r_test_temp_t A where A.SERIAL_NUMBER=B.SERIAL_NUMBER and A.result='F' )             
           
           WHERE   B.repair_time >=
                   --   TO_DATE ('2021-12-09 08:00:00','YYYY-MM-DD HH24:MI:SS')
                      TO_DATE (i_START_DATE, 'YYYY/MM/DD HH24:MI:SS')
              AND B.repair_time <
                    --  TO_DATE ('2021-12-09 12:00:00','YYYY-MM-DD HH24:MI:SS')
                     TO_DATE (i_END,'YYYY-MM-DD HH24:MI:SS')

               AND (B.MODEL_NAME IN (SELECT DISTINCT MODEL_NAME FROM SFIS1.C_MODEL_DESC_T WHERE CUSTOMER='MELLANOX'))
             
           ) BB LEFT JOIN sfism4.r_sn_link_t link1
                  ON link1.new_sn =BB.serial_number                   
                    
            LEFT JOIN sfis1.c_reason_code_t m1
                  ON m1.reason_code = BB.reason_code
                  
            LEFT JOIN smtinfo.r_sn_pkg_detail_t pkg
                  ON BB.serial_number = pkg.serial_number                
                     AND (   pkg.LOCATION = TRIM (BB.ERROR_ITEM_CODE)
                  OR SUBSTR (pkg.LOCATION, -LENGTH (TRIM (BB.ERROR_ITEM_CODE))) =
                        TRIM (BB.ERROR_ITEM_CODE)
                  OR SUBSTR (pkg.LOCATION,
                             1,
                             LENGTH (TRIM (BB.ERROR_ITEM_CODE || ','))) =
                        TRIM (BB.ERROR_ITEM_CODE) || ','
                  OR INSTR (pkg.LOCATION, ',' || TRIM (BB.ERROR_ITEM_CODE) || ',') >
                        0)                  
            LEFT JOIN iqc.r_kpn_incoming_t kpn
                  ON pkg.pkg_id = kpn.pkg_id 
            INNER JOIN sfism4.r_wip_tracking_t wip_t
                  ON wip_t.serial_number = BB.serial_number AND UPPER (wip_t.customer_no) LIKE 'MELL%'
             LEFT JOIN sfis1.c_model_desc_t mx
                  ON wip_t.model_name = mx.model_name AND wip_t.VERSION_CODE = mx.rev      
             LEFT JOIN sfism4.r_mo_base_t mo
                  ON mo.mo_number = BB.mo_number;   
             
   
BEGIN


   o_res := 'Open Cursor Error.';

   OPEN ssn_cur;

    FETCH ssn_cur INTO p_sn,p_DESC_LINE,p_pro_fail_time,p_model_name,p_description,p_mo_number,P_ERROR_ITEM_CODE,p_TARGET_QTY,p_reason_code,p_reason_desc,
        p_station,p_repair_station,p_FIRST_RESULT,
        p_SECORD_RESULT,p_REPAIR_TIME,p_pass_time,p_ERROR_DESC,p_SIDE,p_location,p_ERROR_PRO,P_Failure,P_QTY,P_SN_TYPE,p_ref_pn,p_REF_CUST_PN,P_QTY2,p_mnufcture_name,p_OLD_DATE_CODE,p_OLD_LOT_NO,        
        p_REF_PN_DESC,P_COMP_TYPE,P_SYMPTOM,P_Failure,P_SHAPE,P_SEQUENCE,P_FPY_CALC,p_D_CUST_PN,
        p_FG_SFC_PN,p_D_PN,p_D_SN,p_D_SYMTIOM,p_D_STATION,
        P_MO_CREATE_DATE,P_WEEKLY;

   WHILE ssn_cur%FOUND
   LOOP
    
     o_res := 'Insert into SFISM4.B2B_MELL_PROCESS_LOG_T Error';

      SELECT NVL (MAX (ROWNUM), 0) + 1
        INTO p_num
        FROM SFISM4.B2B_MELL_FA_LOG_T
       WHERE WORK_DATE = i_work_order;
       
        IF  (P_LOCATION  IS NOT NULL) THEN
         
           P_QTY2:=GET_LOCATION_QTY(P_LOCATION,o_res);


          END IF;
      
      INSERT INTO SFISM4.B2B_MELL_FA_LOG_T (WORK_DATE,
                                                 FILE_NAME,
                                                 RECORD_ID,
                                                 SN,
                                                 PN,
                                                 CUSTOMER_PN,
                                                 PL,
                                                 EVENT_TIME,
                                                 BOARD_DESCRIPTION,                                              
                                                 WO,                                                 
                                                 WO_QTY,                                              
                                                 PC,
                                                 STATION,
                                                 
                                                 RESULT,
                                                 SECOND_RESULT,
                                                
                                                  REPAIR_TIME,
                                                  
                                                 PASS_TIME,
                                                 
                                                 RESULT_DESC,
                                                 SIDE,                                              
                                                 REF_DES,
                                                
                                                 FAILURE,
                                                 QTY,
                                                 RETURN_SN,
                                                 REF_PN,
                                                 REF_CUSTOMER_PN,
                                                 REF_QTY,
                                                 
                                                 MNUFCTURER_NAME,
                                                 LOT_CODE,
                                                 DATE_CODE,
                                                 
                                                 REF_PN_DESC,

                                                 COMP_TYPE,
                                                 SYMPTOM,
                                                 SYMPTOM_DESC,
                                                 SHAPE,
                                                 SEQUENCE,
                                                 FPY_CALC,
                                                
                                                 DAD_CUSTOMER_PN,
                                                 DAD_PN,
                                                 DAD_SN,
                                                 DAD_SYMPTOM,
                                                 DAD_STATION,
                                                
                                                 MO_CREATE_DATE,
                                                 WEEKLY                                                                         

                                                 )
           VALUES (i_work_order,
                   'N/A',
                   p_num,
                   p_sn, 
                   p_FG_SFC_PN,  --sfG 料號               
                  
                   p_model_name,
                   p_DESC_LINE, 
                   TO_DATE(p_pro_fail_time,'YYYY/MM/DD HH24:MI:SS'),            
                   p_description,      -- p_pro_fail_time,                 
                   p_mo_number,    
                   p_TARGET_QTY,
                   p_repair_station,                   
                   p_station,               
                 
                   p_FIRST_RESULT,
                   p_SECORD_RESULT,
                  
                   TO_DATE(p_REPAIR_TIME,'YYYY/MM/DD HH24:MI:SS'), 
                                  
                   TO_DATE(p_pass_time,'YYYY/MM/DD HH24:MI:SS'),
                   
                   p_reason_desc,--p_ERROR_DESC,
                   p_SIDE,                 
                   P_ERROR_ITEM_CODE,  -- 'U10',
                  
                   P_Failure,
                   P_QTY,
                   p_SN_TYPE,
                   p_ref_pn,                 
                   p_REF_CUST_PN,
                 
                   P_QTY2,
                   
                   p_mnufcture_name,
                   p_OLD_LOT_NO,
                   p_OLD_DATE_CODE,
                                     
                   p_REF_PN_DESC,

                   P_COMP_TYPE,                 
                  (trim(p_ERROR_PRO)||','||trim(P_Failure)),   -- P_SYMPTOM,
                                    
                   P_SYMPTOM_DESC,
                   P_SHAPE,
                   P_SEQUENCE,
                   P_FPY_CALC,
                   
                   p_D_CUST_PN,
                   p_D_PN,     -- 如果是成品料號顯示半成品料號，如是半成品料號為空
                  -- p_model_name,
                   p_D_SN,
                   p_D_SYMTIOM,              
                   p_D_STATION,                               
                  
                  TO_DATE(P_MO_CREATE_DATE,'YYYY/MM/DD'),
                  P_WEEKLY
                   );
  
          FETCH ssn_cur INTO p_sn,p_DESC_LINE,p_pro_fail_time,p_model_name,p_description,p_mo_number,P_ERROR_ITEM_CODE,p_TARGET_QTY,p_reason_code,p_reason_desc,
                    p_station,p_repair_station,p_FIRST_RESULT,
                    p_SECORD_RESULT,p_REPAIR_TIME,p_pass_time,p_ERROR_DESC,p_SIDE,p_location,p_ERROR_PRO,P_Failure,P_QTY,P_SN_TYPE,p_ref_pn,p_REF_CUST_PN,P_QTY2,p_mnufcture_name,p_OLD_DATE_CODE,p_OLD_LOT_NO,
                   p_REF_PN_DESC,P_COMP_TYPE,P_SYMPTOM,P_Failure,P_SHAPE,P_SEQUENCE,P_FPY_CALC,p_D_CUST_PN,
                   p_FG_SFC_PN,p_D_PN,p_D_SN,p_D_SYMTIOM,p_D_STATION,
                   P_MO_CREATE_DATE,P_WEEKLY;      
        

   END LOOP;

   CLOSE ssn_cur;

   o_res := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      o_res := o_res;
      ROLLBACK;
END;