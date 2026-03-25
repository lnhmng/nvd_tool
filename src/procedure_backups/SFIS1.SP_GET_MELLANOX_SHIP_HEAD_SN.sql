PROCEDURE                   SP_GET_MELLANOX_SHIP_HEAD_SN (
   i_serial_number   IN       VARCHAR2,
   i_dn_no   IN       VARCHAR2,
   i_vehicle_no  IN       VARCHAR2,
   o_res        OUT      VARCHAR2
)
IS
   p_sn    VARCHAR2 (30);  
   p_MO_NUMBER    VARCHAR2 (30); 
   SNCNT         NUMBER (2, 0);

   p_VERSION_CODE      VARCHAR2 (10); 

   p_KEY_PART_NO     VARCHAR2 (30);    

   p_create_date           VARCHAR2 (30); 
   p_SUB_ASSY_DATE           VARCHAR2 (30); 
   p_SHIP_TIME           VARCHAR2 (30);   

   p_po_number         VARCHAR2 (200);
   p_carton_no       VARCHAR2 (30);
   p_GUID       VARCHAR2 (30);
   P_SUBSN       VARCHAR2 (30);
   p_MODEL_NAME     VARCHAR2 (30); 
   p_SUB_VERSION      VARCHAR2 (10);
   p_SUB_MO_NUMBER    VARCHAR2 (30); 
   V_PO_NO      VARCHAR2 (30);
   V_ITEM    VARCHAR2 (30); 
   V_ADD_SN  VARCHAR2 (30); 
   V_ORDER    VARCHAR2 (30); 


   CURSOR ssn_cur
   IS

       select (YY.SERIAL_NUMBER) AS SERIAL_NUMBER,YY.MODEL_NAME AS model_name,YY.VERSION_CODE,YY.MO_NUMBER AS LOT_NO,TO_CHAR (ZZ.CHANGE_DATE,'YYYY-MM-DD HH24:MI:SS') AS CREATE_DATE,    
             TO_CHAR (YY.IN_STATION_TIME,'YYYY-MM-DD HH24:MI:SS') AS SHIP_DATE,
             YY.CARTON_NO,XX.START_GUID AS GUID_MAC,ZZ.INIT_SN,(ZZ.MODEL_NAME) AS SUB_MODEL_NAME,MM.VERSION_CODE AS SUB_VERSION,ZZ.MO_NUMBER,TO_CHAR (YY.IN_LINE_TIME,'YYYY-MM-DD HH24:MI:SS') AS SUB_ASSY_DATE            
             from SFISM4.R_WIP_TRACKING_T YY left join sfism4.r_wip_mo_guid_head XX ON YY.SERIAL_NUMBER=XX.SERIAL_NUMBER 
             left join sfism4.r_sn_link_t ZZ ON YY.SERIAL_NUMBER=ZZ.NEW_SN           
             left join SFISM4.R_MO_BASE_T MO ON MO.MO_NUMBER=ZZ.NEW_MO_NUMBER 
             left join SFISM4.R_MO_BASE_T MM ON MM.MO_NUMBER=ZZ.MO_NUMBER
             WHERE YY.SERIAL_NUMBER=i_serial_number;   

BEGIN

     o_res := 'Open Cursor Error.';  

     /*
      SELECT COUNT (*) INTO SNCNT   FROM SFIS1.C_PO_SET WHERE MO_NUMBER =(SELECT MO_NUMBER
            FROM SFISM4.R_WIP_TRACKING_T WHERE SERIAL_NUMBER=i_serial_number) AND ROWNUM = 1;

      IF SNCNT = 0
       THEN                                        
             p_po_number := 'CM_COO_LOGISTIC=CHINA|CM_SITE_LOGISTIC=FOXCONN - LONGHUA|MNF_PO';
         ELSE                                             
          SELECT ('CM_COO_LOGISTIC=CHINA|CM_SITE_LOGISTIC=FOXCONN - LONGHUA|MNF_PO='||TRIM(PO_NO)||'.'||+TRIM(ITEM)) AS PO_NUMBER INTO p_po_number FROM SFIS1.C_PO_SET WHERE MO_NUMBER =(SELECT MO_NUMBER
            FROM SFISM4.R_WIP_TRACKING_T WHERE SERIAL_NUMBER=i_serial_number) AND ROWNUM = 1;
      END IF;
     */
      SELECT COUNT (*) INTO SNCNT   FROM SFIS1.C_PO_SET WHERE MO_NUMBER IN (SELECT MO_NUMBER
            FROM SFISM4.R_WIP_TRACKING_T WHERE SERIAL_NUMBER=i_serial_number) AND ROWNUM = 1;
      IF SNCNT < 1
       THEN                                        
            V_PO_NO:='';
            V_ITEM:='';
         ELSE                                             
             SELECT NVL (PO_NO, '') as PO_NO,NVL (ITEM, '') as ITEM into V_PO_NO,V_ITEM FROM SFIS1.C_PO_SET WHERE MO_NUMBER IN (SELECT MO_NUMBER
             FROM SFISM4.R_WIP_TRACKING_T WHERE SERIAL_NUMBER=i_serial_number) AND ROWNUM = 1;
      END IF;
                                                
     SELECT COUNT (*) INTO SNCNT   FROM SFISM4.R_MO_BASE_T WHERE MO_NUMBER IN (SELECT MO_NUMBER
            FROM SFISM4.R_WIP_TRACKING_T WHERE SERIAL_NUMBER=i_serial_number) AND ROWNUM = 1; 
     IF SNCNT < 1 
       THEN                                        
              V_ORDER:='';         
         ELSE                                             
             SELECT NVL (ORDER_NO, '') as ORDER_NO INTO V_ORDER FROM SFISM4.R_MO_BASE_T WHERE MO_NUMBER IN (SELECT MO_NUMBER
              FROM SFISM4.R_WIP_TRACKING_T WHERE SERIAL_NUMBER=i_serial_number) AND ROWNUM = 1;  
      END IF;                                   
           
     IF LENGTH(i_serial_number)>=18 THEN
        -- BEGIN       
           SELECT  NVL (ADD_SN, '') as ADD_SN into V_ADD_SN FROM SFISM4.R_WIP_TRACKING_T WHERE SERIAL_NUMBER=i_serial_number;           
            p_po_number :='CM_COO_LOGISTIC=CHINA|CM_SITE_LOGISTIC=FOXCONN - LONGHUA|MNF_PO='||TRIM(V_PO_NO)||'.'||+TRIM(V_ITEM)||'|'||'SAP_SN='||TRIM(V_ADD_SN)||'|'||'DEVIATION_NUM='||+TRIM(V_ORDER);
                     
       -- END 
     ELSIF SUBSTR(i_serial_number,1,2) = 'MT' THEN
           
            p_po_number := 'CM_COO_LOGISTIC=CHINA|CM_SITE_LOGISTIC=FOXCONN - LONGHUA|MNF_PO='||TRIM(V_PO_NO)||'.'||+TRIM(V_ITEM);
    
     ELSE
           SELECT  NVL (ADD_SN, '') as ADD_SN into V_ADD_SN FROM SFISM4.R_WIP_TRACKING_T WHERE SERIAL_NUMBER=i_serial_number;
            p_po_number := 'CM_COO_LOGISTIC=CHINA|CM_SITE_LOGISTIC=FOXCONN - LONGHUA|MNF_PO='||TRIM(V_PO_NO)||'.'||+TRIM(V_ITEM)||'|'||'TOP_EXTRA_SN='||TRIM(V_ADD_SN);
    
     END IF;       
   
  
   OPEN ssn_cur;

   FETCH ssn_cur INTO p_sn,p_KEY_PART_NO,p_VERSION_CODE,p_MO_NUMBER,p_create_date,p_SHIP_TIME,p_carton_no,p_GUID,P_SUBSN,p_MODEL_NAME,p_SUB_VERSION,p_SUB_MO_NUMBER,p_SUB_ASSY_DATE;

   WHILE ssn_cur%FOUND
   LOOP
        o_res := 'Insert into SFISM4.B2B_MELL_SHIP_HEAD_T Error';        
        Insert into SFISM4.B2B_MELL_SHIP_HEAD_T
        (DN_NO,        
         PARENT_SN,
         PARENT_PN,
         PARENT_REV, 
         MO_NUMBER,
         CREATE_DATE,
         SHIPPING_DATE,
         CARTON_NO,
         GUID,       
         SUB_ASSY_SN,
         SUB_ASSY_PN,
         SUB_ASSY_REV,        
         SUB_WO_SN,
         SUB_ASSY_DATE,
         MNF_PO,   
         FILE_NAME
         )
        Values
        (i_dn_no,         
         p_sn,      
         p_KEY_PART_NO,   
         p_VERSION_CODE, 
         p_MO_NUMBER,
         TO_DATE(p_create_date,'YYYY/MM/DD HH24:MI:SS'),        
         TO_DATE(p_SHIP_TIME,'YYYY/MM/DD HH24:MI:SS'), 
         p_carton_no,             
         p_GUID,
         P_SUBSN,    
         p_MODEL_NAME,    
         p_SUB_VERSION,
         p_SUB_MO_NUMBER, 
         TO_DATE(p_SUB_ASSY_DATE,'YYYY/MM/DD HH24:MI:SS'),           
         p_po_number,        
         'N/A' 
         );    

      FETCH ssn_cur

      INTO p_sn,p_KEY_PART_NO,p_VERSION_CODE,p_MO_NUMBER,p_create_date,p_SHIP_TIME,p_carton_no,p_GUID,P_SUBSN,p_MODEL_NAME,p_SUB_VERSION,p_SUB_MO_NUMBER,p_SUB_ASSY_DATE;

   END LOOP;

   CLOSE ssn_cur;

   o_res := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      o_res := 'NG,ERROR_B2B_MELL_SHIP_HEAD_T';
      ROLLBACK;
END;