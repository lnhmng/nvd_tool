PROCEDURE                   sp_inoutstore_handle_NoCWO (
   i_inputdata    IN       VARCHAR2,                               --?????
   i_scan_style   IN       VARCHAR2,                                --????
   i_pro_rev      IN       VARCHAR2,                                --????
   i_pro_id       IN       VARCHAR2,
   --??ID?????? or ???? or ?????
   i_empno        IN       VARCHAR2,                                   --???
   i_group_name   IN       VARCHAR2,                                 --????
   i_whid         IN       VARCHAR2,
   o_binid        OUT      VARCHAR2,                         --?????BINID
   o_res          OUT      VARCHAR2                          --????????
)
IS
   v_count              NUMBER;
   i                    INTEGER;
   sn_qty               INTEGER;
   v_inputdata          VARCHAR (25);
   v_serial_number      sfism4.r_wip_tracking_t.serial_number%TYPE;
   v_mo_number          sfism4.r_wip_tracking_t.mo_number%TYPE;
   v_model_name         sfism4.r_wip_tracking_t.model_name%TYPE;
   v_version_code       sfism4.r_wip_tracking_t.version_code%TYPE;
   v_line_name          sfism4.r_wip_tracking_t.line_name%TYPE;
   --v_in_station_time    sfism4.r_wip_tracking_t.in_station_time%TYPE;
   v_sysdate_time       sfism4.r_wip_tracking_t.in_station_time%TYPE;
   v_cust_no            VARCHAR (25);--sfism4.r_wip_tracking_t.cust_no%TYPE;
   v_carton_no          sfism4.r_wip_tracking_t.carton_no%TYPE;
   v_group_name         sfism4.r_wip_tracking_t.group_name%TYPE;
   v_order_no           sfism4.r_mo_base_t.order_no%TYPE;
   v_plant_code         sfism4.wip_d_wo_master.plant_code%TYPE;
   v_erp_wo             sfism4.wip_d_wo_master.work_order%TYPE;
   v_sfc_wo_type        sfism4.wip_d_wo_master.sfc_wo_type%TYPE;
   v_computer_ip        VARCHAR (25);--sfis1.wip_s_ip_config.ip_address%TYPE;
   v_instore_flag       VARCHAR (25);--sfis1.wip_s_ip_config.instore_flag%TYPE;
   v_whid               VARCHAR (25);--sfis1.wip_s_ip_config.whid%TYPE;
   v_cwo_flag           sfism4.wip_d_cwo_sn.cwo_flag%TYPE;
   v_cwo_type           sfism4.wip_d_cwo_sn.cwo_type%TYPE;
   v_store_flag         VARCHAR (25);--sfism4.wip_d_carton_weight.store_flag%TYPE;
   v_po_no              VARCHAR (25);--sfism4.wip_d_kanban_detail.po_no%TYPE;
   v_kanban_carton_no   VARCHAR (25);--sfism4.wip_d_kanban_detail.carton_no%TYPE;
   v_kanban_pallet_no   VARCHAR (25);--sfism4.wip_d_kanban_detail.pallet_no%TYPE;
   v_work_order         VARCHAR (25);--sfism4.wip_d_kanban_detail.work_order%TYPE;
   v_tla_pn             VARCHAR (25);--sfism4.wip_d_kanban_detail.tla_pn%TYPE;
   v_tla_sn             VARCHAR (25);--sfism4.wip_d_kanban_detail.tla_sn%TYPE;
   v_out_store_time     VARCHAR (25);--sfism4.r_prod_store_t.out_store_time%TYPE;
   v_privilege          VARCHAR (25);
   v_location_id        VARCHAR (10);
   v_binid              VARCHAR (10);
   v_cto_flag           BOOLEAN;                    --?????????CTO?
   v_sap_delete_flag    VARCHAR (5);
   v_sap_hold_flag      VARCHAR (5);
   v_sql                VARCHAR (1000);
   v_scan_style         VARCHAR (25);
   tlasnstart           VARCHAR (25);
   tlasnend             VARCHAR (25);
   temp_str             VARCHAR (25);
   temp_sn              VARCHAR (25);
   v_sample_type        VARCHAR2 (20);
   cur_sysref           sys_refcursor;

   v_locid              VARCHAR (25);
   v_count_totalsn      NUMBER;

    -- add this new PROCEDURE  SFIS1.sp_inoutstore_handle_nocwo base on SFIS1.sp_inoutstore_handle_F    -- cancle CWO by jiang  --20210414


   CURSOR cur_serial_number
   IS
      SELECT serial_number, line_name
        FROM sfism4.r_wip_tracking_t
       WHERE serial_number = v_inputdata
          OR carton_no = v_inputdata
          OR pallet_no = v_inputdata;

   CURSOR cur_instore_wo_qty
   IS
      SELECT          /*+rule+*/
             DISTINCT mo_number, COUNT (serial_number) AS num
                 FROM sfism4.r_wip_tracking_t
                WHERE (    serial_number = v_inputdata
                       AND group_name <> i_group_name
                      )
                   OR (carton_no = v_inputdata AND group_name <> i_group_name
                      )
                   OR (pallet_no = v_inputdata AND group_name <> i_group_name
                      )
             GROUP BY mo_number;

   CURSOR cur_update_sfc
   IS
      SELECT /*+rule+*/
             serial_number, model_name, version_code, line_name, mo_number,
             in_station_time,  carton_no, group_name    --delete 2lie   cust_no
        FROM sfism4.r_wip_tracking_t
       WHERE (serial_number = v_inputdata AND group_name <> i_group_name)
          OR (carton_no = v_inputdata AND group_name <> i_group_name)
          OR (pallet_no = v_inputdata AND group_name <> i_group_name);

   CURSOR cur_cwo_wo
   IS
      SELECT DISTINCT a.mo_number, b.order_no,
                      NVL (c.work_order, 'N/A') AS sap_work_order
                 FROM sfism4.r_wip_tracking_t a,
                      sfism4.r_mo_base_t b,
                      sfism4.wip_d_wo_master c
                WHERE a.mo_number = b.mo_number
                  --AND b.order_no = c.work_order     --r_mo_base_t order_no usreally is null
                  and b.mo_number like c.work_order||'%'
                  AND (   a.carton_no = v_inputdata
                       OR a.pallet_no = v_inputdata
                       OR a.serial_number = v_inputdata
                      );

/*  --begin  ping bi     buxuyao 
   CURSOR cur_kanban
   IS
      SELECT DISTINCT po_no, carton_no, pallet_no, work_order, tla_pn, tla_sn
                 FROM sfism4.wip_d_kanban_detail
                -- WHERE po_no || carton_no = v_inputdata;  --LHIT20110712020 deleted by jean 2011/07/15
      --WHERE           po_no || '+' || carton_no = v_inputdata;
      WHERE           po_no || '-' || carton_no = v_inputdata;--S000002C6R,add by haihui 2014/6/27,POCARTON????po_no || '-' || carton_no
                                   -- LHIT20110712020 added by jean 2011/07/15
*/  --end  

   -- add by jean  11/04/23 for out_store ?? begin
   CURSOR prod_sn
   IS
      SELECT          /*+INDEX(r_prod_store_t,R_PROD_STORE_MO_SN_IDX)*/
             DISTINCT serial_number
                 FROM sfism4.r_prod_store_t
                WHERE (serial_number, mo_number) IN (
                         SELECT serial_number, mo_number
                           FROM sfism4.r_wip_tracking_t
                          WHERE serial_number = v_inputdata
                             OR carton_no = v_inputdata
                             OR pallet_no = v_inputdata);
-- add by jean  11/04/23 for out_store ?? end

/*
 NAME:       sfis1.sp_inoutstore_handle?
 PURPOSE:    ???

  REVISIONS:
  TaskID           Ver        Date        Author           Description
   -------------------------------------------------------------
  LHIT20110712020  ??(1.1)   ??(2011/07/15)  Jean      PO_CARTON?????PO||'+'||CARTON
*/
BEGIN
   o_res := 'OK';
   o_binid := 'N/A';
   v_inputdata := i_inputdata; --11540006710228
   v_scan_style := i_scan_style; --PPID

   v_sysdate_time := sysdate;   -- get current time 當前時間
   v_locid := 'N/A';        --get default locid

   SELECT SYS_CONTEXT ('userenv', 'IP_ADDRESS')
     INTO v_computer_ip --IP
     FROM DUAL;

   SELECT fn_getcontrolvalue ('NVD-LH', 'SFC-PLANT-CODE-F', 'FGLG')     -- define default 'FGLG' ,result is true
     INTO v_plant_code --FG
     FROM DUAL;

 -- modify by JESSE 20100924 for sample and scrap to cwo
----------------------------------------------------------------------------
   IF (UPPER (i_pro_id) = '04001')                              --IN OUT STORE
   THEN
      v_cwo_flag := '0';                                           --????
      v_cwo_type := 'N';
      v_instore_flag := 'Y';
      --v_whid := 'N/A';
      v_whid := i_whid;     -- default  get  input  whid value
   END IF;

   IF (UPPER (i_pro_id) = '02003')                                    --SAMPLE
   THEN
      v_cwo_flag := '0';
      v_cwo_type := 'S';
      v_instore_flag := 'S';
      v_whid := 'N/A';
   END IF;

   IF (UPPER (i_pro_id) = '02004')                                     --SCRAP
   THEN
      v_cwo_flag := '0';
      v_cwo_type := 'B';
      v_instore_flag := 'S';
      v_whid := 'N/A';
   END IF;

   IF fn_getcontrolvalue (v_plant_code, 'INSTORE_IP_CONTROL', 'N') = 'Y'    --NO DATA  default N
   THEN

    --begin flag_8989    becauser  IP  zan shi  not control  --20210122     
    --ip ?????control_value ??????IP???? start    

      SELECT COUNT (1)        --temp cancel --20210122
        INTO v_count
        FROM sfis1.wip_s_ip_config
       WHERE ip_address = v_computer_ip AND active_flag = 'Y';

      IF v_count = 0
      THEN
         o_res := 'No config store type in WIP_S_IP_CONFIG';
         RETURN;
      END IF;     

      SELECT instore_flag, whid
        INTO v_instore_flag, v_whid
        FROM sfis1.wip_s_ip_config
       WHERE ip_address = v_computer_ip AND active_flag = 'Y';


      IF v_whid = 'N/A'
      THEN
         o_res :=
                 'WHID have not maintained,Please connect IT to maintain it!';
         RETURN;
      END IF;

      --S000001QWJ,add by haihui 2013/12/26,begin 
      SELECT count(vr_value)
          INTO v_count
          FROM sfis1.C_PARAMETER_INI
         WHERE     PRG_NAME = 'INOUTSTORE'
               AND VR_CLASS = 'WHID'
               AND VR_ITEM = v_whid
               AND VR_NAME =
                      (SELECT plant_code
                         FROM SFISM4.WIP_D_WO_MASTER
                        WHERE work_order =
                                 (SELECT DISTINCT mo_number
                                    FROM sfism4.r_wip_tracking_t
                                   WHERE   ( serial_number = v_inputdata
                                         OR carton_no = v_inputdata
                                         OR pallet_no = v_inputdata) AND ROWNUM = 1));
      IF v_count>0 THEN
         SELECT vr_value
          INTO v_whid
          FROM sfis1.C_PARAMETER_INI
         WHERE     PRG_NAME = 'INOUTSTORE'
               AND VR_CLASS = 'WHID'
               AND VR_ITEM = v_whid
               AND VR_NAME =
                      (SELECT plant_code
                         FROM SFISM4.WIP_D_WO_MASTER
                        WHERE work_order =
                                 (SELECT DISTINCT mo_number
                                    FROM sfism4.r_wip_tracking_t
                                   WHERE   ( serial_number = v_inputdata
                                         OR carton_no = v_inputdata
                                         OR pallet_no = v_inputdata) AND ROWNUM = 1));
      END IF;
      --S000001QWJ,add by haihui 2013/12/26,end 

      IF v_instore_flag = 'Y'
      THEN
         v_cwo_flag := '0';
         v_cwo_type := 'N';
      --v_privilege := 'NORMAL STORE';
      END IF;

      IF v_instore_flag = 'N'
      THEN
         --v_cwo_flag := '2';
         v_cwo_flag := '0';
         -- DUMMY STORE need to do cwo after 20101004 request by liliyi
         v_cwo_type := 'Y';
      --v_privilege := 'DUMMY STORE';
      END IF;

      IF v_instore_flag = 'S' AND UPPER (i_pro_id) = '02003'
      THEN
         v_cwo_flag := '0';
         v_cwo_type := 'S';
      --v_privilege := 'DUMMY STORE';
      END IF;

      IF v_instore_flag = 'S' AND UPPER (i_pro_id) = '02004'
      THEN
         v_cwo_flag := '0';
         v_cwo_type := 'B';
      --v_privilege := 'DUMMY STORE';
      END IF;

      IF v_instore_flag NOT IN ('Y', 'N', 'S')
      THEN
         o_res :=
                 'Instore flag not maintained,please call IT to maintain it!';
         RETURN;
      END IF;
--         SELECT COUNT (1)
--           INTO v_count
--           FROM sfis1.c_privilege
--          WHERE emp = i_empno AND fun = v_privilege;

   --         IF v_count = 0
--         THEN
--            o_res := 'Sorry, you have no ' || v_privilege || ' privilege!';
--            RETURN;
--         END IF;
   END IF;   
--ip ?????control_value ??????IP???? end

  --end flag_8989    becauser  IP  zan shi  not control  --20210122

-----------------------------------------------------------------------------
--end by JESSE 20100924 for sample and scrap to cwo

   /* --???????pallet?carton?ppid?pocarton
IF    (v_scan_style IS NULL)
   OR (v_scan_style = '') THEN
  SELECT COUNT (1)
  INTO   v_count
  FROM   sfism4.r_wip_tracking_t
  WHERE  pallet_no = v_inputdata;

  IF v_count > 0 THEN
    v_scan_style := 'PALLET';
  END IF;

  SELECT COUNT (1)
  INTO   v_count
  FROM   sfism4.r_wip_tracking_t
  WHERE  carton_no = v_inputdata;

  IF v_count > 0 THEN
    v_scan_style := 'CARTON';
  END IF;

  SELECT COUNT (1)
  INTO   v_count
  FROM   sfism4.r_wip_tracking_t
  WHERE  serial_number = v_inputdata
  OR     tla_sn = v_inputdata;

  IF v_count > 0 THEN
    v_scan_style := 'PPID';

    SELECT serial_number
    INTO   v_inputdata
    FROM   sfism4.r_wip_tracking_t
    WHERE  serial_number = v_inputdata
    OR     tla_sn = v_inputdata;
  END IF;

  SELECT COUNT (1)
  INTO   v_count
  FROM   sfism4.wip_d_carton_weight
  WHERE  po_no || carton_no = v_inputdata;

  IF v_count > 0 THEN
    v_scan_style := 'POCARTON';
  END IF;

  IF v_scan_style IS NULL THEN
    o_res := 'data not exists,please check!';
    RETURN;
  END IF;
END IF;
*/
-----------------------------------------------------------------------------
/*---??franklin HDD ????
IF fn_getcontrolvalue (v_plant_code, 'HDD-INSTORE-CHECK-INPUT-CARTON', 'N') = 'Y' THEN
  IF v_scan_style <> 'CARTON' THEN
    o_res := 'Please input Packing ID!';
    RETURN;
  END IF;
END IF;*/
/*
IF v_scan_style = 'POCARTON' THEN
  v_cto_flag := TRUE;
--ELSE
  --v_cto_flag := checkcto (inputdata);                                      ----???
END IF;
*/
-----------------------------------------------------------------------------
   IF (UPPER (i_pro_id) = '04001')
   THEN
      IF v_scan_style <> 'POCARTON'
      THEN
         /*----?????????

-- begin  flag_123123 --20210122         
     -- PLSQL delete   can kao  epd3 yuan  sql  has pingbi  no use  
-- end  flag_123123 --20210122
         -----------------------------------------------------------------------------
--????????*/


         SELECT /*+rule+*/ 
                COUNT (1)
           INTO v_count
           FROM sfism4.r_wip_tracking_t
          WHERE (carton_no = v_inputdata AND group_name <> i_group_name)
             OR (pallet_no = v_inputdata AND group_name <> i_group_name)
             OR (serial_number = v_inputdata AND group_name <> i_group_name);

         IF (i_group_name = 'IN STORE' OR i_group_name = 'WAREHOUSE IN' OR i_group_name = '690_WH_IN' OR i_group_name = 'KANBAN IN' ) AND v_count = 0   --add new group_name by jiang on 20210325
         THEN
            o_res := 'Has been InStore (KANBAN IN) all, please confirm. ';
            RETURN;
         END IF;

         IF (i_group_name = 'OUT STORE' OR i_group_name = 'WAREHOUSE OUT' OR i_group_name = 'KANBAN OUT') AND v_count = 0
         THEN
            o_res := 'Has been OutStore (KANBAN OUT) all, please confirm. ';
            RETURN;
         END IF;


        v_count_totalsn := v_count;     -- get total sn QTY ,for update locid QTY
-----------------------------------------------------------------------------
--IN STORE ???BIN ID ?START
---------------------------------------------------------
--???????SN????CTO
/*  --begin   flag_2233
       -- PLSQL delete  can kao  epd3  sql  
*/      --end  flag_2233   temp cancel      because no  CTO        --20210122

         -----------------------------------------------------------------------------
--update mo_base QTY updateqty
         /* --begin flag_123        -- temp  pingbi  decause  no in_store_qty and out_store_qty  column  in r_mo_base_t     --20210122
         OPEN cur_instore_wo_qty;

         LOOP
            FETCH cur_instore_wo_qty
             INTO v_mo_number, v_count;

            EXIT WHEN cur_instore_wo_qty%NOTFOUND;

            IF i_group_name = 'IN STORE'
            THEN
               UPDATE sfism4.r_mo_base_t
                  SET in_store_qty =
                         DECODE (in_store_qty, NULL, 0, in_store_qty)
                         + v_count
                WHERE mo_number = v_mo_number;

               IF fn_getcontrolvalue (v_plant_code, 'CLOSE_WO_SWITCH','Y') = 'Y' then  
                  UPDATE sfism4.r_mo_base_t  --add by zong-long for auto close WO 2012.11.1 
                    SET close_flag = '3',MO_CLOSE_DATE =SYSDATE
                  WHERE mo_number = v_mo_number and target_qty <= in_store_qty; 
               end if;               

            END IF;

            IF i_group_name = 'OUT STORE'
            THEN
               UPDATE sfism4.r_mo_base_t
                  SET out_store_qty =
                           DECODE (out_store_qty, NULL, 0, out_store_qty)
                         + v_count
                WHERE mo_number = v_mo_number;
            END IF;
         END LOOP;

         CLOSE cur_instore_wo_qty;
        */   --end  flag_123        
-----------------------------------------------------------------------------
--????sn?????

         SELECT /*+ index (r_wip_tracking_t WIP_TRACKING_PALLET_NO,r_wip_tracking_t WIP_TRACKING_SERIAL_NUMBER) */
                COUNT (1)
           INTO v_count
           FROM sfism4.r_wip_tracking_t
          WHERE carton_no = 'N/A'
            AND (pallet_no = v_inputdata OR serial_number = v_inputdata);

         IF v_count > 0
         THEN
            o_res := 'Carton Number abnormal,is N/A!';
            RETURN;
         END IF;


            --begin  flag_5555  new add --20210122       --get  locid 空餘儲位 chuwei 
            SELECT count(wh_locid) 
            into v_count
              FROM (  SELECT whid, wh_locid, remain_qty
                        FROM (SELECT whid,
                                     wh_locid,
                                     std_qty,
                                     qty,
                                     (std_qty - qty) remain_qty
                                FROM sfis1.c_warehouse_config_t
                               WHERE whid = i_whid)
                       WHERE remain_qty > 0
                    ORDER BY remain_qty DESC)
             WHERE ROWNUM = 1 ;

            if v_count > 0
            then
                SELECT wh_locid 
                into v_locid
                  FROM (  SELECT whid, wh_locid, remain_qty
                            FROM (SELECT whid,
                                         wh_locid,
                                         std_qty,
                                         qty,
                                         (std_qty - qty) remain_qty
                                    FROM sfis1.c_warehouse_config_t
                                   WHERE whid = i_whid)
                           WHERE remain_qty > 0
                        ORDER BY remain_qty DESC)
                 WHERE ROWNUM = 1 ; 

            end if;
         --end   flag_5555  new add --20210122       --get  locid 空餘儲位 chuwei 


         SELECT /*+ index (r_prod_store_t R_PROD_STORE_MO_SN_IDX) */
                COUNT (1)
           INTO v_count
           FROM sfism4.r_prod_store_t
          WHERE (serial_number, mo_number) IN (
                   SELECT serial_number, mo_number
                     FROM sfism4.r_wip_tracking_t
                    WHERE serial_number = v_inputdata
                       OR carton_no = v_inputdata
                       OR pallet_no = v_inputdata);

         IF v_count > 0     -- 重复入庫 sfism4.r_prod_store_t 采用更新 ，第一次入庫 sfism4.r_prod_store_t 插入 --20210325 note
         THEN
            --ReUpdateSFC

            --delete by jean  11/04/23 for out_store sql?? begin
            /*UPDATE sfism4.r_wip_tracking_t
                SET section_name = i_group_name,
                    group_name = i_group_name,
                    station_name = i_group_name,
                    error_flag = '0',
                    in_station_time = SYSDATE,
                    next_station = 'N/A',
                    emp_no = i_empno
              WHERE serial_number IN (
                       SELECT serial_number
                         FROM sfism4.r_prod_store_t
                        WHERE (serial_number, mo_number) IN (
                                 SELECT serial_number, mo_number
                                   FROM sfism4.r_wip_tracking_t
                                  WHERE serial_number = v_inputdata
                                     OR carton_no = v_inputdata
                                     OR pallet_no = v_inputdata));

             INSERT INTO sfism4.r_wip_log_t
                         (serial_number, group_name, in_station_time,
                          mo_number)
                SELECT serial_number, group_name, in_station_time, mo_number
                  FROM sfism4.r_wip_tracking_t
                 WHERE serial_number IN (
                          SELECT serial_number
                            FROM sfism4.r_prod_store_t
                           WHERE (serial_number, mo_number) IN (
                                    SELECT serial_number, mo_number
                                      FROM sfism4.r_wip_tracking_t
                                     WHERE serial_number = v_inputdata
                                        OR carton_no = v_inputdata
                                        OR pallet_no = v_inputdata));*/

            --delete by jean  11/04/23 for out_store sql?? end

            --add by jean 11/04/23  for out_store ?? begin
            OPEN prod_sn;

            LOOP
               FETCH prod_sn
                INTO temp_sn;

               EXIT WHEN prod_sn%NOTFOUND;

               UPDATE sfism4.r_wip_tracking_t
                  SET section_name = i_group_name,
                      group_name = i_group_name,
                      station_name = i_group_name,
                      error_flag = '0',
                      in_station_time = v_sysdate_time,
                      next_station = 'N/A',
                      emp_no = i_empno
                WHERE serial_number = temp_sn;

               INSERT INTO sfism4.r_wip_log_t
                           (serial_number, group_name, in_station_time,
                            mo_number)
                  SELECT serial_number, group_name, in_station_time,
                         mo_number
                    FROM sfism4.r_wip_tracking_t
                   WHERE serial_number = temp_sn;
            END LOOP;

            CLOSE prod_sn;

            --add by jean 11/04/23 for out_store ?? end
            IF (i_group_name = 'IN STORE' OR i_group_name = 'WAREHOUSE IN' OR i_group_name = '690_WH_IN' )
            THEN
               o_res := 'Update sfism4.r_prod_store_t error in store';

               UPDATE /*+ index (r_prod_store_t R_PROD_STORE_MO_SN_IDX) */sfism4.r_prod_store_t
                  SET in_store_time = v_sysdate_time,                  
                      in_store_emp = i_empno,
                      in_type = i_scan_style,
                      whid = v_whid,
                      wh_locid = v_locid,
                      in_store_flag = 'Y',
                      out_store_time = '',
                      out_store_emp = '',
                      out_type = ''
                WHERE (serial_number, mo_number) IN (
                         SELECT serial_number, mo_number
                           FROM sfism4.r_wip_tracking_t
                          WHERE serial_number = v_inputdata
                             OR carton_no = v_inputdata
                             OR pallet_no = v_inputdata);

                update sfis1.c_warehouse_config_t set qty = qty + v_count_totalsn where whid = v_whid and wh_locid = v_locid ;    -- update locid qty             

            ELSIF (i_group_name = 'OUT STORE' OR i_group_name = 'WAREHOUSE OUT' OR i_group_name = 'KANBAN OUT' )
            THEN
               o_res := 'Update sfism4.r_prod_store_t error out store';

               UPDATE /*+ index (r_prod_store_t R_PROD_STORE_MO_SN_IDX) */sfism4.r_prod_store_t
                  SET in_store_flag = 'N',
                      out_store_time = v_sysdate_time,
                      out_store_emp = i_empno,
                      out_type = i_scan_style
                WHERE (serial_number, mo_number) IN (
                         SELECT serial_number, mo_number
                           FROM sfism4.r_wip_tracking_t
                          WHERE serial_number = v_inputdata
                             OR carton_no = v_inputdata
                             OR pallet_no = v_inputdata);

				--add by liujiang20230320 auto check exist whid and wh_locid when out ,avoid N/A				
				SELECT /*+ index (r_prod_store_t R_PROD_STORE_MO_SN_IDX) */
					whid ,wh_locid		
				INTO v_whid, v_locid
				FROM sfism4.r_prod_store_t
				WHERE (serial_number, mo_number) IN (
					   SELECT serial_number, mo_number
						 FROM sfism4.r_wip_tracking_t
						WHERE (serial_number = v_inputdata
						   OR carton_no = v_inputdata
						   OR pallet_no = v_inputdata)
						   and rownum=1 );				   
				update sfis1.c_warehouse_config_t set qty = qty - v_count_totalsn where whid = v_whid and wh_locid = v_locid ;

            END IF;


         ELSE               --no  prod_instroe  info
            --UpdateSFC
            o_res := 'Update sfism4.r_wip_tracking_t error ';

            UPDATE sfism4.r_wip_tracking_t
               SET section_name = i_group_name,
                   group_name = i_group_name,
                   station_name = i_group_name,
                   error_flag = '0',
                   in_station_time = v_sysdate_time,
                   next_station = 'N/A',
                   emp_no = i_empno
             WHERE serial_number = v_inputdata
                OR carton_no = v_inputdata
                OR pallet_no = v_inputdata;

            o_res := 'Insert sfism4.r_wip_log_t error ';

            INSERT INTO sfism4.r_wip_log_t
                        (serial_number, group_name, in_station_time,
                         mo_number)
               SELECT serial_number, group_name, in_station_time, mo_number
                 FROM sfism4.r_wip_tracking_t
                WHERE serial_number = v_inputdata
                   OR carton_no = v_inputdata
                   OR pallet_no = v_inputdata;

            IF (i_group_name = 'IN STORE' OR i_group_name = 'WAREHOUSE IN' OR i_group_name = '690_WH_IN' )
            THEN
               o_res := 'Update sfism4.r_prod_store_t error in store';

               INSERT INTO sfism4.r_prod_store_t
                           (serial_number, model_name, mo_number, line_name,
                            in_store_time, first_in_store_time, in_store_emp, in_type, whid, wh_locid ,in_store_flag )
                  SELECT serial_number, model_name, mo_number, line_name,
                         v_sysdate_time, v_sysdate_time, i_empno,i_scan_style, v_whid, v_locid ,'Y'           -- ADD in_store_flag             
                    FROM sfism4.r_wip_tracking_t
                   WHERE serial_number = v_inputdata
                      OR carton_no = v_inputdata
                      OR pallet_no = v_inputdata;

                update sfis1.c_warehouse_config_t set qty = qty + v_count_totalsn where whid = v_whid and wh_locid = v_locid ;          

            ELSIF (i_group_name = 'OUT STORE' OR i_group_name = 'WAREHOUSE OUT' OR i_group_name = 'KANBAN OUT' )
            THEN
               o_res := 'Update sfism4.r_prod_store_t error out store';

               UPDATE /*+ index (r_prod_store_t R_PROD_STORE_MO_SN_IDX) */sfism4.r_prod_store_t
                  SET in_store_flag = 'N',
                      out_store_time = v_sysdate_time,
                      out_store_emp = i_empno,
                      out_type = i_scan_style
                WHERE (serial_number, mo_number) IN (
                         SELECT serial_number, mo_number
                           FROM sfism4.r_wip_tracking_t
                          WHERE serial_number = v_inputdata
                             OR carton_no = v_inputdata
                             OR pallet_no = v_inputdata);
            --IN_STORE_TIME>=SYSDATE-30

				--add by liujiang20230320 auto check exist whid and wh_locid when out ,avoid N/A				
				SELECT /*+ index (r_prod_store_t R_PROD_STORE_MO_SN_IDX) */
					whid ,wh_locid		
				INTO v_whid, v_locid
				FROM sfism4.r_prod_store_t
				WHERE (serial_number, mo_number) IN (
					   SELECT serial_number, mo_number
						 FROM sfism4.r_wip_tracking_t
						WHERE (serial_number = v_inputdata
						   OR carton_no = v_inputdata
						   OR pallet_no = v_inputdata)
						   and rownum=1 );			
                update sfis1.c_warehouse_config_t set qty = qty - v_count_totalsn where whid = v_whid and wh_locid = v_locid ;

            END IF;
         END IF;

-------------------------------------------------------------------------------
      -- cancle CWO by jiang  --20210414
      /*
--?CWO  START
         IF     fn_getcontrolvalue (v_plant_code, 'DO_CWO_STATION',
                                    'IN STORE') = 'IN STORE'    -- default value has been 'IN STORE', whither data exist or not,result must true 
            AND (i_group_name = 'IN STORE' OR i_group_name = 'WAREHOUSE IN' OR i_group_name = '690_WH_IN' )
         THEN
            OPEN cur_cwo_wo;

            LOOP
               FETCH cur_cwo_wo
                INTO v_mo_number, v_order_no, v_erp_wo;

               EXIT WHEN cur_cwo_wo%NOTFOUND;

               --?SAP???<>'N/A?CWO
               IF v_erp_wo <> 'N/A'
               THEN
                  INSERT INTO sfism4.wip_d_cwo_sn
                              (sysserialno, part_no, carton_no, pallet_no,
                               sfc_wo, wo_type, erp_wo, cpo_no, so_no,
                               cwo_flag, plant_code, creator, create_date,
                               instore_scan_type, ip_address, cwo_type, whid,
                               pro_rev)
                     SELECT DISTINCT a.serial_number, a.model_name,
                                     a.carton_no, a.pallet_no, a.mo_number,
                                     NVL (b.wo_type, 'N/A'),
                                     NVL (b.work_order, 'N/A'), b.cpo, b.so_no,
                                     v_cwo_flag, b.plant_code, i_empno,
                                     SYSDATE, v_scan_style, v_computer_ip,
                                     v_cwo_type, v_whid, i_pro_rev
                                FROM sfism4.r_wip_tracking_t a,
                                     sfism4.wip_d_wo_master b,
                                     sfism4.r_mo_base_t c
                               WHERE a.mo_number = c.mo_number
                                 --AND b.work_order = c.order_no        --r_mo_base_t order_no usreally is null
                                 and c.mo_number like b.work_order||'%'
                                 AND a.serial_number NOT IN (
                                                      SELECT sysserialno
                                                        FROM sfism4.wip_d_cwo_sn
                                                       WHERE erp_wo = v_erp_wo)
                                 AND (   a.carton_no = v_inputdata
                                      OR a.pallet_no = v_inputdata
                                      OR a.serial_number = v_inputdata
                                     )
                                 AND a.mo_number = v_mo_number;
               END IF;
            END LOOP;

            CLOSE cur_cwo_wo;
         END IF;
      --?CWO end
      */
      -- cancle CWO by jiang  --20210414

      -----------------------------------------------------------------------------
      END IF;

---
         /*  --begin       flag_5566     --temp pingbi  because  no po+carton type  --20210122
          --  PLSQL  DELETE   can kao  EPD3 yu  ju 

      */ --end   flag_5566     --temp pingbi  because  no po+carton type  --20210122
-----------------------------------------------------------------------------
   END IF;


/*  --begin flag_5959    --temp  ping bi because  zan shi bu xu yao  ,--20210122 for  sample  and  scrap
   --add by JESSE  20100924 for sample and scrap to cwo

    -- PLSQL delete   can kao  epd3 yuan  sql  ,if necessary  


   --end by JESSE  20100924 for sample and scrap to cwo
*/   --end  flag_5959    --temp  ping bi because  zan shi bu xu yao  ,--20210122    

   COMMIT;
   o_res := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      o_res := o_res;
-- o_res := o_res || SQLCODE;
-- o_res := o_res || SQLERRM;
END;