PROCEDURE       sp_sap_dl_wo_master (
   i_op_id          IN       VARCHAR2,
   i_gstrs          IN       DATE,
   i_aufnr          IN       VARCHAR2,
   i_matnr          IN       VARCHAR2,
   i_revlv          IN       VARCHAR2,
   i_gamng          IN       VARCHAR2,
   i_bstkd          IN       VARCHAR2,
   i_kdauf          IN       VARCHAR2,
   i_gltrp          IN       DATE,
   i_kunnr          IN       VARCHAR2,
   i_werks          IN       VARCHAR2,
   i_hold_flag      IN       VARCHAR2,
   i_del_flag       IN       VARCHAR2,
   i_cy_seqnr       IN       VARCHAR2,
   i_wo_count       IN       VARCHAR2,
   i_kdpos          IN       VARCHAR2,
   i_erdat          IN       DATE,
   --i_erfzeit        IN       VARCHAR2,
   i_erfzeit        IN       DATE,
   i_status         IN       VARCHAR2,
   i_kbeasoll       IN       VARCHAR2,
   i_auart          IN       VARCHAR2,
   i_verid          IN       VARCHAR2,
   i_taskgroup      IN       VARCHAR2,
   i_wempf          IN       VARCHAR2,
   i_slink          IN       VARCHAR2,
   i_aedat          IN       DATE,
   i_aezeit         IN       DATE,
   --i_b2b_mc_code    IN       VARCHAR2,
   i_rev            IN       VARCHAR2,
   i_bismt          IN       VARCHAR2,
   i_po_type        IN       VARCHAR2,----add by cody 20110503   remark availability wo type 
   i_order_type        IN       VARCHAR2,
   i_special_type        IN       VARCHAR2,
   i_endcponumber  IN       VARCHAR2,
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
   IF i_del_flag = 'N'
   THEN
      v_del_flag := '0';
   END IF;

   IF i_del_flag = 'Y'
   THEN
      v_del_flag := '1';
   END IF;

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
   v_sapupdatedate := sfis1.fn_combine_sap_date_and_time (i_aedat, i_aezeit);
   v_sapcreatedate := sfis1.fn_combine_sap_date_and_time (i_erdat, i_erfzeit);

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
   IF ((i_rev = '') OR (i_rev IS NULL))
   THEN
      --v_v_rev := 'A00';
      v_v_rev := '';    --SAP wei kong,ze sfc wei kong
   ELSE
      v_v_rev := i_rev;
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
           VALUES (i_aufnr, i_bismt, i_gamng, i_bstkd, 'N/A', i_gstrs,
                   i_kdauf, i_gltrp, i_kunnr, t_wo_status, 'N/A',
                   '0', i_werks, '0', '0',
                   i_cy_seqnr, i_wo_count, i_kdpos, i_erdat, 'N/A',
                   i_kbeasoll, i_auart, i_erdat, i_wempf,
                   i_slink, v_v_rev, i_op_id, SYSDATE,                      --part_version: 'N/A' --> v_v_rev   20201218
                   'N/A', v_child_wo_status, v_sfc_wo_type, i_matnr,
                   v_sapupdatedate, v_sapcreatedate,i_po_type,i_order_type,i_special_type,i_endcponumber,i_status            --i_b2b_mc_code
                  );
   ELSE
      o_error_detail := 'Update error,WO=' || i_aufnr;

      DELETE FROM sfism4.wip_d_wo_detail
            WHERE work_order = i_aufnr;

      UPDATE sfism4.wip_d_wo_master
         SET part_no = i_bismt,
             qty = i_gamng,
             cpo = i_bstkd,
             cpo_type = 'N/A',
             wo_schedule = i_gstrs,
             so_no = i_kdauf,
             wo_due_date = i_gltrp,
             cust_no = i_kunnr,
             -- wo_status = 'N/A',
             emc_cust_no = 'N/A',
             --print_flag = '0',     20100902 ????20100831???????X??????
             plant_code = i_werks,
             sap_hold_flag = '0',
             sap_delete_flag = '0',
             batch_no = i_cy_seqnr,
             batch_wo_count = i_wo_count,
             so_line = i_kdpos,
             wo_date = i_erdat,
             part_name = 'N/A',
             labor_time = i_kbeasoll,
             sap_wo_type = i_auart,
             sap_release_date = i_erdat,
             source_wo_no = i_wempf,
             soft_link_flag = i_slink,
             part_version = v_v_rev,            --part_version: 'N/A' --> v_v_rev   20201218
             updater = 'N/A',
             update_date = SYSDATE,
             wo_type = 'N/A',
             --CHILD_WO_STATUS = V_CHILD_WO_STATUS,
             sfc_wo_type = v_sfc_wo_type,
             ref_pn = i_matnr,
             po_type=i_po_type,
             ORDER_TYPE=i_order_type,
             SPECIAL_TYPE=i_special_type,
             sap_update_date = v_sapupdatedate,
             ENDCPONUMBER = i_endcponumber,
             SAP_WO_STATUS = i_status
             --SAP_CREATE_DATE = v_SapCREATEDate
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
