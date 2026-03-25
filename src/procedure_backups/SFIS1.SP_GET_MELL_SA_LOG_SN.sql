PROCEDURE       SP_GET_MELL_SA_LOG_SN (
   i_serial_number   IN       VARCHAR2,
   
   i_v_start_date   IN       VARCHAR2,
   
   i_v_end_date   IN       VARCHAR2,   
   
   i_work_order   IN       VARCHAR2,
   
   o_res        OUT      VARCHAR2
)
IS
   p_parent_pn    VARCHAR2 (30);  
   p_parent_sn    VARCHAR2 (30); 
   p_child_pn     VARCHAR2 (30); 
   p_rownum           number;
   p_child_sn      VARCHAR2 (30);    
   p_rev           VARCHAR2 (15);  

   p_date_code           VARCHAR2 (100); 
   p_lot_no           VARCHAR2 (100); 
   p_manufacturer   VARCHAR2 (80); 

   p_GUID_MAC           VARCHAR2 (30); 

   p_qty           number; 
   p_num           number;  
   p_manufacturer_pn      VARCHAR2 (80);
   p_carton_no       VARCHAR2 (30);
   p_type       VARCHAR2 (30);
   P_in_time    VARCHAR2 (30);
   p_ref_des         VARCHAR2 (4000);




   CURSOR ssn_cur
   IS
          select rownum, MODEL_NAME AS parent_pn,SERIAL_NUMBER AS parent_sn,HH_PN AS child_pn,pkg_id as child_sn,VERSION_CODE as rev,DATE_CODE,LOT_NO,

          vendor_name as manufacturer, MFG_PN as manufacturer_pn,'' as box_num,LOCATION as ref_des,key_part_qty as qty,GUID_MAC,in_time  from (                     

          select  YY.SERIAL_NUMBER,YY.MODEL_NAME AS model_name,TO_CHAR (YY.IN_STATION_TIME,'YYYY-MM-DD HH24:MI:SS') AS in_time,YY.MODEL_NAME AS HH_PN,YY.MODEL_NAME AS MFG_PN,'' AS DATE_CODE,YY.MO_NUMBER AS LOT_NO,'FOXCONN_LH' AS vendor_name,
             'N/A' AS LOCATION,YY.SERIAL_NUMBER AS PKG_ID,'1' AS key_part_qty,YY.VERSION_CODE,'' AS CARTON_NO,'N/A' AS GUID_MAC             
              from SFISM4.R_WIP_TRACKING_T YY left join sfism4.r_wip_mo_guid_detail XX ON YY.SERIAL_NUMBER=XX.SERIAL_NUMBER WHERE YY.SERIAL_NUMBER=i_serial_number   
            UNION ALL 
             select  YY.SERIAL_NUMBER,YY.MODEL_NAME AS model_name,TO_CHAR (YY.IN_STATION_TIME,'YYYY-MM-DD HH24:MI:SS') AS in_time,YY.MODEL_NAME AS HH_PN,YY.MODEL_NAME AS MFG_PN,'' AS DATE_CODE,YY.MO_NUMBER AS LOT_NO,'FOXCONN_LH' AS vendor_name,
             'N/A' AS LOCATION,YY.SERIAL_NUMBER AS PKG_ID,'1' AS key_part_qty,YY.VERSION_CODE,YY.CARTON_NO,'' AS GUID_MAC             
            
              from SFISM4.R_WIP_TRACKING_T YY left join sfism4.r_wip_mo_guid_detail XX ON YY.SERIAL_NUMBER=XX.SERIAL_NUMBER WHERE YY.SERIAL_NUMBER=i_serial_number   

           UNION   

             SELECT DISTINCT d.serial_number,d.model_name,           

                TO_CHAR (d.in_station_time,
                         'YYYY-MM-DD HH24:MI:SS'
                        ) AS in_time,
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
                c.hh_pn AS pkg_id,--d.pkg_id,              
               -- f.key_part_qty,
             
               CASE
                   WHEN d.LOCATION IS NULL
                    THEN '1'
                   ELSE to_char(length(d.LOCATION)-length(replace(d.LOCATION,','))+1)

                END AS key_part_qty,
             
             
             --     CASE
             --      WHEN f.key_part_qty IS NULL
             --       THEN to_number('1')
             --      ELSE key_part_qty
             --   END AS key_part_qty, 
             
               '' as version_code, --d.VERSION_CODE,
                d.carton_no,             
                '' AS GUID_MAC
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
                           SELECT serial_number, feeder_number,LOCATION,pkg_id,
                                machine_code, in_station_time, section_name,
                                'N/A' AS barcode1
                           FROM smtinfo.r_sn_pkg_detail_t
                          WHERE 
                            (serial_number=i_serial_number
                                )
                             --2222                   
                           UNION ALL      
                                
                          SELECT serial_number, 'N/A' AS feeder_number,'' AS LOCATION,pkg_id,
                                'PCB_OPEN' AS machine_code, in_station_time,
                                'PCB_OPEN' AS section_name, 'N/A' AS barcode1
                           FROM sfism4.r_pcb_datecode_t
                          WHERE  (serial_number=i_serial_number
                                )

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

       WHERE  serial_number=i_serial_number  ORDER BY parent_pn,parent_sn,rownum desc;         


BEGIN


   select mo_type INTO p_type from sfism4.r_mo_base_t where mo_number in
     (select mo_number from sfism4.r_wip_tracking_t where serial_number=i_serial_number);  

   o_res := 'Open Cursor Error.';

   OPEN ssn_cur;

   FETCH ssn_cur INTO  p_rownum,p_parent_pn,p_parent_sn,p_child_pn,p_child_sn,p_rev,p_date_code,p_lot_no,p_manufacturer,p_manufacturer_pn,p_carton_no,p_ref_des,p_qty,p_GUID_MAC,P_in_time;


   WHILE ssn_cur%FOUND
   LOOP

        o_res := 'Insert into SFISM4.B2B_MELLANOX_DETAIL_T Error';


       select NVL(max(rownum),0)+1 INTO p_num from SFISM4.B2B_MELL_SA_LOG_T where WORK_DATE=i_work_order;

        Insert into SFISM4.B2B_MELL_SA_LOG_T
        (
         WORK_DATE,
         FILE_NAME,
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
         IN_STATION_TIME,
         PONO,
         JOB_TYPE        
         )
        Values
        (
         i_work_order,
        'N/A',
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
        -- '',
         TO_DATE(P_in_time,'YYYY/MM/DD HH24:MI:SS'),        
         '',                 
         p_type
         );      


      FETCH ssn_cur
       INTO  p_rownum,p_parent_pn,p_parent_sn,p_child_pn,p_child_sn,p_rev,p_date_code,p_lot_no,p_manufacturer,p_manufacturer_pn,p_carton_no,p_ref_des,p_qty,p_GUID_MAC,P_in_time;


   END LOOP;

   CLOSE ssn_cur;

   o_res := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      o_res := o_res;
      ROLLBACK;
END;