PROCEDURE       sp_sap_dl_wo_master_s4 (
   i_op_id          IN       VARCHAR2,      -- C#代碼添加
   i_gstrp          IN       DATE,       -- i_gstrs -> i_gstrp 
   i_aufnr          IN       VARCHAR2,
   i_matnr          IN       VARCHAR2,
   i_revlv          IN       VARCHAR2,
   i_gamng          IN       VARCHAR2,
   --bstkd          IN       VARCHAR2,    --bstkd->i_tdline
   --i_kdauf          IN       VARCHAR2,  -- i_kdauf -> '' so為空null
   i_gltrp          IN       DATE,          --i_gltrp->i_ftrms->i_gltrp  計劃完成時間
   i_ftrms          IN       DATE,          --i_ftrms release時間
   --i_kunnr          IN       VARCHAR2,    -- i_kunnr ->''  客戶為空
   i_werks          IN       VARCHAR2,
   --i_hold_flag      IN       VARCHAR2,    -- no necessary
   --i_del_flag       IN       VARCHAR2,    --no necessary
   --i_cy_seqnr       IN       VARCHAR2,     --i_cy_seqnr ->''  batch為空
   --i_wo_count       IN       VARCHAR2,  --i_wo_count->'' batch_wo_count為空
   --i_kdpos          IN       VARCHAR2,      --i_kdpos->'' so_line為空
   i_erdat          IN       DATE,      -- i_erdat ->i_ftrms 改用sap release date --創建時間
   --i_erfzeit        IN       VARCHAR2,
   --i_erfzeit        IN       DATE,     -- i_erfzeit ->i_ftrms 改用sap release date
   i_sttxt         IN       VARCHAR2,      --i_status->i_sttxt 工單狀態
   --i_kbeasoll       IN       VARCHAR2,     --i_kbeasoll ->'0'  label_time工時 原接一般為0
   i_auart          IN       VARCHAR2,
   --i_verid          IN       VARCHAR2,    --no necessary
   --i_taskgroup      IN       VARCHAR2,    --no necessary
   --i_wempf          IN       VARCHAR2,     --i_wempf ->'' source_wo_no為空
   --i_slink          IN       VARCHAR2,      --i_slink->'X' soft_link 原接口一般為x
   i_aedat          IN       DATE,       --i_aedat ->i_ftrms 改用sap release date     --工單修改時間
   --i_aezeit         IN       DATE,       --i_aezeit ->i_ftrms 改用sap release date
   --i_b2b_mc_code    IN       VARCHAR2,
   --i_rev            IN       VARCHAR2,    -- i_rev ->i_revlv 定義被替換
   --i_bismt          IN       VARCHAR2,      --i_bismt->暫定zmd_no 長料號
   --i_po_type        IN       VARCHAR2,      --i_po_type ->'' PO_TYPE為空  ----add by cody 20110503   remark availability wo type 
   --i_order_type        IN       VARCHAR2,  --i_order_type->'' order_type為空
   --i_special_type        IN       VARCHAR2,   -- i_special_type ->''
   --i_endcponumber  IN       VARCHAR2,           --i_endcponumber->''
   i_ablad          IN       VARCHAR2,      --bstkd  cpo客戶訂單
   i_kdmat          IN       VARCHAR2,    --i_bismt 長料號
   o_error_detail   OUT      VARCHAR2
--  WORK_ORDER VARCHAR2 (25 Byte)   Y  N  1  ???
--PART_NO   VARCHAR2 (26 Byte)      N  4  ??
--PART REV  VARCHAR2 (10 Byte)      N  41 REV
--QTY INTEGER     N  9  ??
--CPO VARCHAR2 (40 Byte)      Y  35 CPO
--CPO_TYPE  VARCHAR2 (20 Byte)      Y     CPO???sap?????
--WO_SCHEDULE  DATE     Y  7  ??????
--SO  VARCHAR2 (20 Byte)      Y  6  ????
--WO_DUE_DATE  DATE     Y  36 ??????
--CUST_NO   VARCHAR2 (25 Byte)      Y  12 ????
--WO_STATUS VARCHAR2 (8 Byte)    Y     ????(00000000)
--EMC_CUST_NO  VARCHAR2 (100 Byte)     Y  10 EMC????
--WO_FLAG   VARCHAR2 (1 Byte)    Y     ????sap?????
--PLANT CODE   VARCHAR2 (20 Byte)      N  2  ??
--SAP_HOLD_FLAG   VARCHAR2 (1 Byte)    N  37 "SAP?????
--Hold:1:YES; 0: NO"
--SAP_DELETE_FLAG NUMBER (1)     N  38 "SAP?????
--?? 1:YES; 0: NO"
--BATCH NO  VARCHAR2 (25 Byte)      Y  28 ???????
--BATCH WO COUNT  NUMBER      Y  39 ???????
--SO LINE   VARCHAR2 (10 Byte)      Y  27 ????
--WO DATE   DATE     Y  20 ??????
--WO TIME   Time     Y  21 ??????
--PART NAME VARCHAR2 (35 Byte)      Y     ???sap?????
--LABOR TIME   NUMBER      Y  25 Standard value
--SAP WO TYPE  VARCHAR2 (14 Byte)      N  3  SAP????
--SAP RELEASE DATE   DATE     Y  20 SAP???????
--PRODUCTION VERSION VARCHAR2 (25 Byte)      N  10
--ROUTING GROUP   VARCHAR2 (25 Byte)      Y  26
--SOURCE WO NO VARCHAR2 (25 Byte)      Y  31 ??????????
--SOFTLINK FLAG   VARCHAR2 (10 Byte)      N  32 ????Softlink
--
)
IS
   --i             NUMBER;
   --v_modelname   VARCHAR2 (25);
   --v_rev         VARCHAR2 (20);
   v_v_rev             VARCHAR2 (20);
   v_count             NUMBER;
   v_sapupdatedate     DATE;
   v_sapcreatedate     DATE;
   v_inner_err         VARCHAR2 (500);
   v_child_wo_status   NUMBER;
   v_sfc_wo_type       VARCHAR2 (25);
   ex                  EXCEPTION;
   v_del_flag          VARCHAR2 (1);
   --v_model_rev_str     varchar2(10);
   v_len               NUMBER;
   t_wo_status         VARCHAR2 (10);
BEGIN
   IF (   (i_auart = 'EWA0')
       OR (i_auart = 'ERA0')
       OR (i_auart = 'ENA0')
       OR (i_auart = 'EDA0')
       OR (i_auart = 'ERA7')
       OR (i_auart = 'EDA7')
      )
   THEN
      v_sfc_wo_type := 'CTO';
   END IF;

   IF (   (i_auart = 'EWA1')
       OR (i_auart = 'ERA1')
       OR (i_auart = 'ENA1')
       OR (i_auart = 'EDA1')
       --OR (i_auart = 'ERA8')--F project deletet  by jinglong 20170701 
       OR (i_auart = 'EDA8')
      )
   THEN
      v_sfc_wo_type := 'BTO';
   END IF;

   IF (   (i_auart = 'EWA2')
       OR (i_auart = 'ERA2')
       OR (i_auart = 'ENA2')
       OR (i_auart = 'EDA2')
       --OR (i_auart = 'ERA9')--F project deletet  by jinglong 20170701 
       OR (i_auart = 'EDA9')
      )
   THEN
      v_sfc_wo_type := 'SMT';
   END IF;

 --F project modify SAP plant  by jinglong 20170701 begin 
    IF (   (i_auart = 'ERA8')
       OR (i_auart = 'ERA9')
      )
   THEN
      v_sfc_wo_type := 'RMA';
   END IF;


--epd3 moves add new SAP plant  by Liujiang 20181204 zhu shi LH yu ju  begin
/*
 --F project modify SAP plant  by jinglong 20170701 end
   IF i_auart = 'EMF0' AND i_werks = 'PEL1'
   THEN
      v_sfc_wo_type := 'CTO';
   END IF;

   IF i_auart = 'EMF0' AND i_werks = 'PEL2'
   THEN
      v_sfc_wo_type := 'BTO';
   END IF;

   IF i_auart = 'EMF0' AND i_werks = 'PEL3'
   THEN
      v_sfc_wo_type := 'SMT';
   END IF;
  --F project modify SAP plant  by jinglong 20170701 begin 

      IF i_auart = 'EMF0' AND i_werks = 'FGL1'
   THEN
      v_sfc_wo_type := 'CTO';
   END IF;

   IF i_auart = 'EMF0' AND i_werks = 'FGL2'
   THEN
      v_sfc_wo_type := 'BTO';
   END IF;

   IF i_auart = 'EMF0' AND i_werks = 'FGL3'
   THEN
      v_sfc_wo_type := 'SMT';
   END IF;
   --F project modify SAP plant  by jinglong 20170701 end
*/
--epd3 moves add new SAP plant  by Liujiang 20181204 zhu shi LH yu ju end



--epd3 moves add new SAP plant  by Liujiang 20181204 begin
   IF i_auart = 'EMF0' AND i_werks = 'HB3B'
   THEN
      v_sfc_wo_type := 'BTO-SMT';
   END IF;
--epd3 moves add new SAP plant  by Liujiang 20181204  end


   IF (   (i_auart = 'AWO0')
       OR (i_auart = 'NWO0')
      ) AND i_werks = 'CNV1'
   THEN
      v_sfc_wo_type := 'NORMAL';
   END IF;

   IF (   (i_auart = 'NDW0')
       OR (i_auart = 'RMWO')
       OR (i_auart = 'RRWO')
       OR (i_auart = 'RWO0')
      ) AND i_werks = 'CNV1'
   THEN
      v_sfc_wo_type := 'REWORK';
   END IF;



/* --NVD AUTODOWN   no CTO PO  by Liujiang 20200915  begin
--************************Modify by Jesse 20100709  CTO??ENA0?,??PO???WO***************************************
   IF ((v_sfc_wo_type = 'CTO') AND (i_auart = 'EWA0')
      )                                              --AND (i_auart <> 'ENA0')
   THEN
      IF (i_bstkd || 'A' = 'A')
      THEN
         o_error_detail := 'PO NO can not be null,' || 'WO=' || i_aufnr;
         RAISE ex;
      END IF;
   END IF;

----*************************End modify 20100709************************************************************************************


   --************************Modify by Jesse 20100709  ?down PO,?down WO****************************************
   IF (i_bstkd || 'A' <> 'A')
   THEN
      SELECT COUNT (0)
        INTO v_count
        FROM sfism4.wip_d_erp_po_master
       WHERE po_no = i_bstkd;

      IF (v_count <= 0)
      THEN
         o_error_detail :=
                 'No PO information,please download PO first. WO=' || i_aufnr;
         RAISE ex;
      END IF;
   END IF;

----*************************End modify 20100709************************************************************************************
*/ --NVD AUTODOWN   no CTO PO  by Liujiang 20200915  end


/* --NVD AUTODOWN     by Liujiang 20200915  end
   --**** modify by Hugo 2010/7/8 begin *****??Kitting?????????****************
   IF (fn_getcontrolvalue ('ALL', 'CHECK_WO_BS_FLAG', 'N') = 'Y'
      )                           --Modify by Jesse 20100709 ??control_value??
   THEN
      SELECT COUNT (0)
        INTO v_count
        FROM sfism4.edi870status
       WHERE work_order = i_aufnr;

      IF v_count > 0
      THEN
--************************Modify by Jesse 20100709  ????,????????,???mail?????****************************************
         o_error_detail :=
               'WO='
            || i_aufnr
            || ' has been kitting!You can not download WO again!';
         RAISE ex;
--*************************End modify by Jesse 20100709************************************************************************************
      END IF;
   END IF;
*/ --NVD AUTODOWN     by Liujiang 20200915  end   


--    if FN_GETCONTROLVALUE('ALL','CHECK_PO_CONFIRM','N')='Y' then
--        select count(0) into v_count
--        from SFISM4.WIP_D_ERP_PO_CONFIRM
--        where po_number = i_bstkd;
--
--        if v_count > 0 then
--          o_error_detail := '';
--          return;
--        end if;
--    end if;
--********* modify by Hugo 2010/7/8 end **************************
   /*  no necessary for S4
   IF i_del_flag = 'N'
   THEN
      v_del_flag := '0';
   END IF;

   IF i_del_flag = 'Y'
   THEN
      v_del_flag := '1';
   END IF;
  */ 

/* --NVD AUTODOWN     by Liujiang 20200915  end   
   SELECT COUNT (0)
     INTO v_count
     FROM sfis1.c_model_desc_t a, sfism4.wip_d_wo_master b
    WHERE a.child_wo_flag = 1
      AND a.model_name = b.part_no
      AND a.rev = b.part_version;

   IF v_count > 0
   THEN
      v_child_wo_status := 0;
   ELSE
      v_child_wo_status := 1;
   END IF;
*/ --NVD AUTODOWN     by Liujiang 20200915  end   
  v_child_wo_status := 1;    --NVD AUTODOWN     by Liujiang 20200915  end   


   v_count := 0;
   o_error_detail := 'Get Update Time Fail!';
   --v_sapupdatedate := sfis1.fn_combine_sap_date_and_time (i_aedat, i_aezeit);     --工單更新時間 RFC004不再返回
   --v_sapcreatedate := sfis1.fn_combine_sap_date_and_time (i_erdat, i_erfzeit);    --工單創建時間 RFC004不再返回
   --v_sapupdatedate := sfis1.fn_combine_sap_date_and_time (i_ftrms, i_ftrms);
   --v_sapcreatedate := sfis1.fn_combine_sap_date_and_time (i_ftrms, i_ftrms);
   v_sapupdatedate := sfis1.fn_combine_sap_date_and_time (i_aedat, i_aedat);     --工單更新時間 RFC004不再返回
   v_sapcreatedate := sfis1.fn_combine_sap_date_and_time (i_erdat, i_erdat);    --工單創建時間 RFC004不再返回

--   i := INSTR (i_matnr, '+');

   --   IF (i > 0)
--   THEN
--      v_modelname := SUBSTR (i_matnr, 1, i - 1);
--      v_rev := SUBSTR (i_matnr, i + 1, LENGTH (i_matnr));
--   ELSE
--      v_modelname := i_matnr;
--      v_rev := NVL (i_revlv, 'A00');
--   END IF;

   --   i := INSTR (i_matnr, v_model_rev_str);

   --   IF (i > 0)
--   THEN
--      v_modelname := SUBSTR (i_matnr, 1, i - 1);
--      v_rev := SUBSTR (i_matnr, i + 1, 3);
--      v_len := LENGTH (i_matnr);
--      IF (v_len-i-3) > 0
--      THEN
--         v_modelname := v_modelname || SUBSTR (i_matnr, i + 4, v_len-i-3);
--      else
--        null;
--      END IF;
--   ELSE
--      i := INSTR (i_matnr, '+');

   --      IF (i > 0)
--      THEN
--         v_modelname := SUBSTR (i_matnr, 1, i - 1);
--         v_rev := SUBSTR (i_matnr, i + 1, LENGTH (i_matnr));
--      ELSE
--         v_modelname := i_matnr;
--         v_rev := '';
--      END IF;
--   END IF;
   IF ((i_revlv = '') OR (i_revlv IS NULL))
   THEN
      --v_v_rev := 'A00';
      v_v_rev := '';    --SAP wei kong,ze sfc wei kong
   ELSE
      v_v_rev := i_revlv;   --i_rev改為i_revlv
   END IF;  



/* --NVD AUTODOWN     by Liujiang 20200915  end   
   IF (v_sfc_wo_type = 'CTO') AND (i_auart = 'EWA0')
   THEN
      SELECT COUNT (*)
        INTO v_count
        FROM sfis1.wip_s_model_confirm_cto
       WHERE model_name = i_bismt AND active_flag = '1';

      IF v_count >= 1
      THEN
         SELECT a.confirm_flag || b.confirm_flag || c.confirm_flag
           INTO t_wo_status
           FROM (SELECT confirm_flag
                   FROM sfis1.wip_s_model_confirm_cto
                  WHERE confirm_type = 'PN'
                    AND active_flag = '1'
                    AND model_name = i_bismt
                    AND ROWNUM = 1) a,
                (SELECT confirm_flag
                   FROM sfis1.wip_s_model_confirm_cto
                  WHERE confirm_type = 'ROUTE'
                    AND active_flag = '1'
                    AND model_name = i_bismt
                    AND ROWNUM = 1) b,
                (SELECT confirm_flag
                   FROM sfis1.wip_s_model_confirm_cto
                  WHERE confirm_type = 'ASSY'
                    AND active_flag = '1'
                    AND model_name = i_bismt
                    AND ROWNUM = 1) c;

         IF LENGTH (t_wo_status) <> 3
         THEN
            t_wo_status := '00000000';
         ELSE
            t_wo_status := '00000' || t_wo_status;
         END IF;
      ELSE
         t_wo_status := '00000000';
      END IF;
   ELSE
      t_wo_status := '00000111';
   END IF;
*/ --NVD AUTODOWN     by Liujiang 20200915  end   
  t_wo_status := '00000111';    --NVD AUTODOWN     by Liujiang 20200915  end   

   SELECT COUNT (0)
     INTO v_count
     FROM sfism4.wip_d_wo_master
    WHERE work_order = i_aufnr;

   IF v_count <= 0
   THEN
      o_error_detail := 'Insert error,WO=' || i_aufnr;

      INSERT INTO sfism4.wip_d_wo_master
                  (work_order, part_no, qty, cpo, cpo_type, wo_schedule,
                   so_no, wo_due_date, cust_no, wo_status, emc_cust_no,
                   print_flag, plant_code, sap_hold_flag, sap_delete_flag,
                   batch_no, batch_wo_count, so_line, wo_date, part_name,
                   labor_time, sap_wo_type, sap_release_date, source_wo_no,
                   soft_link_flag, part_version, creator, create_date,
                   wo_type, child_wo_status, sfc_wo_type, ref_pn,
                   sap_update_date, sap_create_date,po_type,ORDER_TYPE,SPECIAL_TYPE,ENDCPONUMBER,SAP_WO_STATUS              --b2b_mc_code
                  )
           VALUES (i_aufnr, i_kdmat, i_gamng, i_ablad, 'N/A', i_gstrp,  
                   '', i_gltrp, '', t_wo_status, 'N/A',
                   '0', i_werks, '0', '0',
                   '', '', '', i_ftrms, 'N/A',
                   '0', i_auart, i_ftrms, '',
                   'X', v_v_rev, i_op_id, SYSDATE,                      --part_version: 'N/A' --> v_v_rev   20201218
                   'N/A', v_child_wo_status, v_sfc_wo_type, i_matnr,
                   v_sapupdatedate, v_sapcreatedate,'','','','',i_sttxt            --i_b2b_mc_code
                  );
   ELSE
      o_error_detail := 'Update error,WO=' || i_aufnr;

      DELETE FROM sfism4.wip_d_wo_detail
            WHERE work_order = i_aufnr;

      UPDATE sfism4.wip_d_wo_master
         SET part_no = i_kdmat,
             qty = i_gamng,
             cpo = i_ablad,
             cpo_type = 'N/A',
             wo_schedule = i_gstrp,
             so_no = '',
             wo_due_date = i_gltrp,
             cust_no = '',
             -- wo_status = 'N/A',
             emc_cust_no = 'N/A',
             --print_flag = '0',     20100902 ????20100831???????X??????
             plant_code = i_werks,
             sap_hold_flag = '0',
             sap_delete_flag = '0',
             batch_no = '',
             batch_wo_count = '',
             so_line = '',
             wo_date = i_ftrms,
             part_name = 'N/A',
             labor_time = '0',
             sap_wo_type = i_auart,
             sap_release_date = i_ftrms,
             source_wo_no = '',
             soft_link_flag = 'X',
             part_version = v_v_rev,            --part_version: 'N/A' --> v_v_rev   20201218
             updater = 'N/A',
             update_date = SYSDATE,
             wo_type = 'N/A',
             --CHILD_WO_STATUS = V_CHILD_WO_STATUS,
             sfc_wo_type = v_sfc_wo_type,
             ref_pn = i_matnr,
             po_type='',
             ORDER_TYPE='',
             SPECIAL_TYPE='',
             sap_update_date = v_sapupdatedate,
             ENDCPONUMBER = '',
             SAP_WO_STATUS = i_sttxt,
             SAP_CREATE_DATE = v_SapCREATEDate
       --b2b_mc_code = i_b2b_mc_code
      WHERE  work_order = i_aufnr;
   END IF;


   SELECT COUNT (0)
     INTO v_count
     FROM sfism4.WIP_D_JOB_LIST
    WHERE data1 = i_aufnr and flag='N'; 

   IF v_count = 0  then
    insert into sfism4.WIP_D_JOB_LIST(DATA1,GROUP_NAME) VALUES(i_aufnr,'DOWNLOAD_WO');
   end if;

   o_error_detail := '';
EXCEPTION
   WHEN OTHERS
   THEN
      o_error_detail :=
         'SP_SAP_DL_WO_MASTER: ' || o_error_detail || '. [' || SQLERRM || ']';
END;