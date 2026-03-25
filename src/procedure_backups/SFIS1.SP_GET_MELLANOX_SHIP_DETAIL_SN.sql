PROCEDURE             SP_GET_MELLANOX_SHIP_DETAIL_SN (
   i_serial_number   IN       VARCHAR2,
   i_dn_no   IN       VARCHAR2,
   i_vehicle_no  IN       VARCHAR2,
   o_res        OUT      VARCHAR2
)
IS
   p_parent_pn    VARCHAR2 (30);  
   p_parent_sn    VARCHAR2 (30); 
   p_child_pn     VARCHAR2 (30); 

   p_child_sn      VARCHAR2 (50);    
   p_rev           VARCHAR2 (15);  

   p_date_code           VARCHAR2 (50); 
   p_lot_no           VARCHAR2 (50); 
   p_manufacturer   VARCHAR2 (80); 

   p_GUID_MAC           VARCHAR2 (30); 
   p_in_time           VARCHAR2 (30); 
   p_select_num           number;
   p_COUNT           number; 
   p_qty           number; 
   p_num           number;  
   p_manufacturer_pn      VARCHAR2 (80);
   p_carton_no       VARCHAR2 (30);
   p_type       VARCHAR2 (30);
   p_ref_des         VARCHAR2 (4000);


   CURSOR ssn_cur
   IS

        select rownum,MODEL_NAME AS parent_pn,SERIAL_NUMBER AS parent_sn,HH_PN AS child_pn,PKG_ID as child_sn,VERSION_CODE as rev,DATE_CODE,LOT_NO,

          vendor_name as manufacturer, MFG_PN as manufacturer_pn,carton_no as box_num,LOCATION as ref_des,key_part_qty as qty,GUID_MAC,in_time2  from           
          (                  
            select  (ZZ.NEW_SN) AS SERIAL_NUMBER,YY.KEY_PART_NO AS model_name,TO_CHAR (ZZ.CHANGE_DATE,'YYYY-MM-DD HH24:MI:SS') AS in_time,YY.KEY_PART_NO AS HH_PN,YY.KEY_PART_NO AS MFG_PN,'' AS DATE_CODE,ZZ.NEW_MO_NUMBER AS LOT_NO,'FOXCONN_LH' AS vendor_name,
             'N/A' AS LOCATION,(ZZ.NEW_SN) AS PKG_ID,to_number('1') AS key_part_qty,MO.VERSION_CODE,YY.CARTON_NO,XX.START_GUID AS GUID_MAC,TO_CHAR (ZZ.CHANGE_DATE,'YYYY-MM-DD HH24:MI:SS') AS in_time2             
             from SFISM4.R_WIP_TRACKING_T YY  left join sfism4.r_sn_link_t ZZ ON YY.SERIAL_NUMBER=ZZ.NEW_SN             
             left join sfism4.r_wip_mo_guid_head XX ON ZZ.NEW_SN=XX.SERIAL_NUMBER            
             left join SFISM4.R_MO_BASE_T MO ON MO.MO_NUMBER=ZZ.NEW_MO_NUMBER               
             WHERE YY.SERIAL_NUMBER=i_serial_number

           UNION ALL

           select  (XX.NEW_SN) AS SERIAL_NUMBER,XX.NEW_MODEL_NAME AS model_name,TO_CHAR (XX.CHANGE_DATE,'YYYY-MM-DD HH24:MI:SS') AS in_time,YY.MODEL_NAME AS HH_PN,YY.MODEL_NAME AS MFG_PN,'' AS DATE_CODE,YY.MO_NUMBER AS LOT_NO,'FOXCONN_LH' AS vendor_name,
             'N/A' AS LOCATION,YY.SERIAL_NUMBER AS PKG_ID,to_number('1') AS key_part_qty,YY.VERSION_CODE,YY.CARTON_NO,'' AS GUID_MAC,TO_CHAR (XX.CHANGE_DATE,'YYYY-MM-DD HH24:MI:SS') AS in_time2             
              from SFISM4.R_WIP_TRACKING_T YY left join sfism4.r_sn_link_t XX ON YY.SERIAL_NUMBER=XX.INIT_SN             
              WHERE YY.SERIAL_NUMBER=(SELECT OLD_SN FROM SFISM4.R_SN_LINK_T WHERE NEW_SN=i_serial_number)         

            )             

           UNION ALL

          select rownum,MODEL_NAME AS parent_pn,SERIAL_NUMBER AS parent_sn,HH_PN AS child_pn,PKG_ID as child_sn,VERSION_CODE as rev,DATE_CODE,LOT_NO,

           --  vendor_name as manufacturer, MFG_PN as manufacturer_pn,carton_no as box_num,LOCATION as ref_des,key_part_qty as qty,'' AS GUID_MAC,in_time2  from (                     
             vendor_name as manufacturer, MFG_PN as manufacturer_pn,carton_no as box_num,LOCATION as ref_des,to_number(key_part_qty) as qty,'' AS GUID_MAC,in_time2  from (                     

             SELECT DISTINCT d.serial_number,d.model_name,           

                TO_CHAR (d.in_station_time,
                         'YYYY-MM-DD HH24:MI:SS'
                        ) AS in_time2,
               c.hh_pn,            
                NVL (c.mfg_pn, 'N/A') AS mfg_pn, 

                c.date_code,
                c.lot_no,
                NVL (m.vendor_name, 'N/A') AS vendor_name, 

                 CASE
                   WHEN d.LOCATION IS NULL
                    THEN 'N/A'
                   ELSE REPLACE (d.LOCATION, ',', ' ')
                END AS LOCATION,
                --d.pkg_id,              
                 c.hh_pn AS pkg_id,

                 CASE
                   WHEN d.LOCATION IS NULL
                    THEN '1'
                   ELSE to_char(length(d.LOCATION)-length(replace(d.LOCATION,','))+1) 


                END AS key_part_qty,

               --  CASE
               --    WHEN f.key_part_qty IS NULL
               --     THEN to_number('1')
               --    ELSE key_part_qty
              --  END AS key_part_qty,

                '' AS VERSION_CODE,--d.VERSION_CODE,
                d.carton_no,             
                '' AS KEY_VALUE
           FROM (

             ---3333
               SELECT sn_pkg.serial_number AS serial_number,
                        sn_pkg.feeder_number AS feeder_number,
                        sn_pkg.LOCATION AS LOCATION,
                        sn_pkg.pkg_id AS pkg_id,
                        sn_pkg.machine_code AS machine_code,
                        sn_pkg.in_station_time AS in_station_time,
                        sn_pkg.section_name AS section_name,
                        sn_pkg.barcode1 AS barcode1,
                        wip.model_name AS model_name,
                        WIP.VERSION_CODE,
                        wip.carton_no
                   FROM (

                          --2222
                           SELECT serial_number, feeder_number,LOCATION,TRIM(pkg_id) AS PKG_ID,
                                machine_code, in_station_time, section_name,
                                'N/A' AS barcode1
                           FROM smtinfo.r_sn_pkg_detail_t
                          WHERE 
                            (serial_number=(SELECT OLD_SN FROM SFISM4.R_SN_LINK_T WHERE NEW_SN=i_serial_number) 
                                )
                             UNION ALL      

                          SELECT serial_number, 'N/A' AS feeder_number,'' AS LOCATION,pkg_id,
                                'PCB_OPEN' AS machine_code, in_station_time,
                                'PCB_OPEN' AS section_name, 'N/A' AS barcode1
                           FROM sfism4.r_pcb_datecode_t
                          WHERE (serial_number=(SELECT OLD_SN FROM SFISM4.R_SN_LINK_T WHERE NEW_SN=i_serial_number) 
                                )                            
                             --2222                  
                            ) sn_pkg,
                        sfism4.r_wip_tracking_t wip
                      WHERE sn_pkg.serial_number = wip.serial_number                                                 
                 ---3333
                       ) d                       

                LEFT JOIN
                iqc.r_kpn_incoming_t c ON c.pkg_id(+) = d.pkg_id
                LEFT JOIN iqc.c_vendor_code_t m ON m.vendor_code = c.reserve3  
                LEFT JOIN sfis1.c_station_mapping_t h
                ON h.station_sfc = d.machine_code
                LEFT JOIN smtinfo.r_sn_tracking_log_t j
                ON j.serial_number = d.serial_number
              AND j.machine_code = d.machine_code

              /*
                LEFT JOIN sfism4.r_smt_prod_bom_t bom
                ON bom.product_no = j.product_no
              AND bom.line_name =
                     CASE
                        WHEN j.machine_code LIKE '%PTH_INPUT%'
                           THEN SUBSTR (j.machine_code,
                                        1,
                                        INSTR (j.machine_code, 'PTH_INPUT')
                                        - 1
                                       )
                        WHEN j.machine_code LIKE '%CHECK ICT%'
                           THEN SUBSTR (j.machine_code,
                                        1,
                                        INSTR (j.machine_code, 'CHECK ICT')
                                        - 1
                                       )
                        WHEN j.section_name LIKE 'M%'
                           THEN REPLACE (j.machine_code, j.section_name, '')
                     END
              AND EXISTS (SELECT 1
                            FROM sfis1.c_smt_bom_t smt
                           WHERE smt.bom_no = bom.bom_no)              
                LEFT JOIN sfis1.c_bom_detail_t f
                ON bom.bom_no = f.bom_no   

               AND ( c.hh_pn = f.key_part_no
                   OR EXISTS (
                         SELECT 1
                           FROM sfis1.kpn_spn_model_v spn
                          WHERE c.hh_pn = spn.key_part_no
                            AND c.hh_pn = spn.spare_key_part_no
                            AND model_name = j.product_no)
                  )

              WHERE (f.key_part_no IS NULL  OR HH_PN LIKE 'PCB%')            
              */
             )   

           UNION ALL   ---REPAIR HH_pn

           select rownum,a.MODEL_NAME AS parent_pn,a.SERIAL_NUMBER AS parent_sn,a.SUPPLIER_MODEL AS child_pn,a.SUPPLIER_MODEL as child_sn,'' as rev,a.DATE_CODE,a.MACHINE as lot_no,

             a.SUPPLIER_NAME as manufacturer, a.SUPPLIER as manufacturer_pn,b.carton_no as box_num,a.OLD_LOCATION as ref_des,to_number('1') as qty,'' AS GUID_MAC,TO_CHAR (a.TEST_TIME,'YYYY-MM-DD HH24:MI:SS') AS in_time2

             from sfism4.r_repair_t a,sfism4.r_wip_tracking_t b  where a.serial_number=b.serial_number and (a.SUPPLIER_MODEL IS NOT NULL) AND b.serial_number=(SELECT OLD_SN FROM SFISM4.R_SN_LINK_T WHERE NEW_SN=i_serial_number);                   



BEGIN



   o_res := 'Open Cursor Error.';

   OPEN ssn_cur;

   FETCH ssn_cur INTO p_select_num,p_parent_pn,p_parent_sn,p_child_pn,p_child_sn,p_rev,p_date_code,p_lot_no,p_manufacturer,p_manufacturer_pn,p_carton_no,p_ref_des,p_qty,p_GUID_MAC,p_in_time;


   WHILE ssn_cur%FOUND
     LOOP

        o_res := 'Insert into SFISM4.B2B_MELLANOX_DETAIL_T Error';

        SELECT COUNT(*) INTO p_COUNT FROM SFISM4.R_REPAIR_T WHERE serial_number=(SELECT OLD_SN FROM SFISM4.R_SN_LINK_T WHERE NEW_SN=i_serial_number) AND 
         (SUPPLIER_MODEL=p_child_pn or OLD_HHPN=p_child_pn);

         IF p_COUNT = 0
           THEN 

               p_type := 'NEW_ITEW';

            ELSE                                             

                 SELECT COUNT(*) INTO p_COUNT FROM SFISM4.R_REPAIR_T WHERE serial_number=(SELECT OLD_SN FROM SFISM4.R_SN_LINK_T WHERE NEW_SN=i_serial_number) 
                 AND OLD_HHPN=p_child_pn and TEST_TIME=TO_DATE (p_in_time,'YYYY/MM/DD HH24:MI:SS');  


              IF p_COUNT = 0                   
                   THEN

                      p_type := 'REWORK_DISASSY';

                   else

                      p_type := 'REWORK_ASSY';

                 end if;    

         END IF;


       select NVL(max(rownum),0)+1 INTO p_num from sfism4.b2b_mell_SHIP_DETAIL_t where DN_NO=i_dn_no;

        Insert into SFISM4.B2B_MELL_SHIP_DETAIL_T
        (FILE_NAME,
         FILE_MANUFACTURER_NAME,
         RECORD_ID,
         PARENT_PN,
         PARENT_SN, 
         CHILD_PN,
         CHILD_SN,
         REV,
         QTY,
         MANUFACTURER, 
         MANUFACTURER_PN,
         DATE_CODE,        
         LOT_WO,
         GUID_MAC,
         EXTRA_SN,
         BOX_NUM,
         ULT,
         REF_DES,
         DN_NO,
         PONO,
         JOB_TYPE,
         FG_SN       
         )
        Values
        ('N/A',
        'FOXCONN_LH',
         p_num,
         --rownum,      
         p_parent_pn,   
         p_parent_sn, 
         p_child_pn,     
         p_child_sn,     
         p_rev,             
         p_qty,
         p_manufacturer,       
         p_manufacturer_pn,
         p_date_code,    
         p_lot_no,
         p_GUID_MAC,
         '',   
         p_carton_no,
         '',
         p_ref_des,
         i_dn_no,
         i_vehicle_no,                 
         --'New_Item'
         p_type,
         i_serial_number
         );      


      FETCH ssn_cur
       INTO  p_select_num,p_parent_pn,p_parent_sn,p_child_pn,p_child_sn,p_rev,p_date_code,p_lot_no,p_manufacturer,p_manufacturer_pn,p_carton_no,p_ref_des,p_qty,p_GUID_MAC,p_in_time;


   END LOOP;

   CLOSE ssn_cur;

   o_res := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      o_res := 'NG,ERROR_B2B_MELLANOX_DETAIL_T';
      ROLLBACK;
END;