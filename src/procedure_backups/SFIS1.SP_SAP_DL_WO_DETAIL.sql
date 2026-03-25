PROCEDURE       sp_sap_dl_wo_detail (
   i_op_id          IN       VARCHAR2,
   i_aufnr          IN       VARCHAR2,
   i_matnr          IN       VARCHAR2,
   i_charg          IN       VARCHAR2,
   i_posnr          IN       VARCHAR2,
   i_bismt          IN       VARCHAR2,
   i_bdmng          IN       VARCHAR2,
   i_alpgr          IN       VARCHAR2,
   i_baugr          IN       VARCHAR2,
   i_menge          IN       VARCHAR2,
   i_zunit_qty      IN       VARCHAR2,
   i_b2b_mc_code    IN       VARCHAR2,
   i_dumps          IN       VARCHAR2,
   i_serial         IN       VARCHAR2,
   i_zunit_qty1     IN       VARCHAR2,
   i_cust_po        IN       VARCHAR2,
   i_line           IN       VARCHAR2,
   i_refitem        IN       VARCHAR2,
   i_pocust_pn      IN       VARCHAR2,
   i_werks          IN       VARCHAR2,
   i_rev            IN       VARCHAR2,
   o_error_detail   OUT      VARCHAR2
--   WORK ORDER    VARCHAR2 (25 Byte)    Y    N    1    ????
--PART NO    VARCHAR2 (35 Byte)    Y    N     4    ??
--REV    CHAR(10)    Y    N    34    ??
--SEQ NO    VARCHAR2 (20 Byte)    Y    Y    2    ??
--CUST PN    VARCHAR2 (35 Byte)        N    7    ????
--REQUEST QTY    NUMBER        N    5    ????
--REPLACE GROUP1    VARCHAR2 (50 Byte)        N    10    ????1
--REPLACEGROUP2    VARCHAR2 (50 Byte)        N    16    ????2
--ORIGINALQTY    NUMBER            17
--TLPARTNO        Y    Y    16    ????
--COMID    VARCHAR2 (20 Byte)        Y        A,B,Z,O,M: M?????????A,B,Z,O?????WIP_D_WO_DETAIL_COMID????
--UNITQTY    NUMBER        N    29    ????
--ZUNIT_QTY    QUAN                Required quantity
--SERIAL    CHAR(1)                Serialized Flag
--B2B_MC_CODE    CHAR(10)                B2B_MC_CODE for SFC
--BISMT    CHAR(18)                Old material number
--ZUNIT_QTY1    QUAN                Required quantity
--CUST_PO    CHAR(2)                Customer purchase order number
--LINE    CHAR(6)                Item Number of the Underlying Purchase Order
--REFITEM    CHAR(6)                PO  ITEM  NO
--POCUST_PN    CHAR(18)                Old material number
)
IS
   --v_part_no        VARCHAR2 (50);
   --v_modelname      varchar2(50);
   --v_part_rev       VARCHAR2 (30);
   --v_rev            varchar2(30);
   v_v_rev             VARCHAR2 (30);
   v_count             NUMBER;
   v_inner_err         VARCHAR2 (500);
   v_replace_flag      VARCHAR2 (1);
   v_serialized_flag   VARCHAR2 (1);
   v_flag              VARCHAR2 (1);
   v_sap_wo_type       VARCHAR2 (14);
   v_control_value     VARCHAR2 (1);
   ex                  EXCEPTION;
   i                   NUMBER;
   --v_model_rev_str  varchar2(20);
   v_len               NUMBER;
   v_sfc_wo_type       VARCHAR2 (14);

--   cursor po_detail_cur is SELECT DISTINCT b.work_order, b.cpo, c.part_no, c.cust_pn AS wo_cust_pn,
--                d.cust_pn AS po_cust_pn, c.part_rev,
--                c.serialized_flag AS wo_serialized_flag, d.model_no
--           FROM wip_d_wo_master b, wip_d_wo_detail c, wip_d_erp_po d
--          WHERE b.work_order = c.work_order
--            and b.work_order = i_aufnr
--            AND c.part_no = d.model_no
--            AND c.cust_pn <> d.cust_pn
--            and c.serialized_flag='1'
--            and c.dumps<>'X';
   /*CURSOR po_detail_cur   --delete by zong-long for epd3 DB slow 2012.7.30 
   IS
      SELECT DISTINCT b.work_order, b.cpo, c.part_no,
                      c.cust_pn AS wo_cust_pn, d.cust_pn AS po_cust_pn,
                      c.part_rev, c.serialized_flag AS wo_serialized_flag,
                      d.model_no AS po_model
                 FROM wip_d_wo_master b, wip_d_wo_detail c, wip_d_erp_po d
                WHERE b.work_order = i_aufnr
                  AND b.work_order = c.work_order
                  AND (c.part_no = c.po_cust_pn OR c.part_no = d.model_no)
                  AND c.serialized_flag = '1'
                  AND c.dumps <> 'X';

   ROW                 po_detail_cur%ROWTYPE;*/
BEGIN
   IF ((i_bdmng > 0) AND (i_dumps <> 'X') AND (i_serial = 1))
   THEN
      IF (i_cust_po IS NULL)
      THEN
         o_error_detail :=
               'PO_NO can not be null. WO='
            || i_aufnr
            || ',PN='
            || i_matnr
            || ',Seq='
            || i_posnr;
         RAISE ex;
      END IF;
   END IF;

/* --NVD AUTODOWN     by Liujiang 20200915  end   
--************************Modify by Jesse 20100709  ?down  PO??down WO?****************************************
   IF (i_cust_po||'A' <> 'A')
   THEN
      SELECT COUNT (0)
        INTO v_count
        FROM sfism4.wip_d_erp_po_master
       WHERE po_no = i_cust_po;

      IF (v_count <= 0)
      THEN
         o_error_detail :=
               'No PO information,please download PO first. WO='
            || i_aufnr
            || ',PN='
            || i_matnr
            || ',Seq='
            || i_posnr;
         RAISE ex;
      END IF;
   END IF;

--*************************End modify 20100709************************************************************************************
*/ --NVD AUTODOWN     by Liujiang 20200915  end       not check po info in NVD

   --******* modify by Hugo 2010/7/8 begin *****??Kitting?????????***********
   if (fn_getcontrolvalue ('ALL', 'CHECK_WO_BS_FLAG', 'N') = 'Y')--Modify by Jesse 20100709 ??control_value??
   then

       SELECT COUNT (0)
         INTO v_count
         FROM sfism4.edi870status
        WHERE work_order = i_aufnr;

       IF v_count > 0
       THEN
--************************Modify by Jesse 20100709  ???????????????????????mail????****************************************
          o_error_detail :=
                'WO='
             || i_aufnr
             || ' has started to kitting!You can not download WO again!'
             || ',PN='
             || i_matnr
             || ',Seq='
             || i_posnr;
          RAISE ex;
--*************************End modify 20100709************************************************************************************
       END IF;

   end if;

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
--********* modify by Hugo 2010/7/8 end ****************************
   SELECT sap_wo_type
     INTO v_sap_wo_type
     FROM sfism4.wip_d_wo_master
    WHERE work_order = i_aufnr;

   IF (   (v_sap_wo_type = 'EDA0')
       OR (v_sap_wo_type = 'EDA1')
       OR (v_sap_wo_type = 'EDA2')
       OR (v_sap_wo_type = 'EDA7')
       OR (v_sap_wo_type = 'EDA8')
       OR (v_sap_wo_type = 'EDA9')
       OR (v_sap_wo_type = 'ERA0')
       OR (v_sap_wo_type = 'ERA1')
       OR (v_sap_wo_type = 'ERA2')
       OR (v_sap_wo_type = 'ERA7')
       OR (v_sap_wo_type = 'ERA8')
       OR (v_sap_wo_type = 'ERA9')
      )
   THEN
      o_error_detail := '';
      RETURN;
   END IF;

   v_count := 0;
   o_error_detail := '';
   v_serialized_flag := NVL (i_serial, '0');

   IF ((i_bdmng > 0) AND (i_dumps <> 'X') AND (i_serial = 1))
   THEN
      IF (i_line||'A' = 'A')
      THEN
         o_error_detail :=
               'PO_line can not be null. WO='
            || i_aufnr
            || ',PN='
            || i_matnr
            || ',Seq='
            || i_posnr;
         RAISE ex;
      END IF;
   END IF;

   IF ((i_bdmng > 0) AND (i_dumps <> 'X') AND (i_serial = 1))
   THEN
      IF (i_refitem IS NULL)
      THEN
         o_error_detail :=
               'Item_no can not be null. WO='
            || i_aufnr
            || ',PN='
            || i_matnr
            || ',Seq='
            || i_posnr;
         RAISE ex;
      END IF;
   END IF;

   IF ((i_bdmng > 0) AND (i_dumps <> 'X') AND (i_serial = 1))
   THEN
      IF (i_pocust_pn||'A'='A')
      THEN
         o_error_detail :=
               'PO_CUST_PN can not be null. WO='
            || i_aufnr
            || ',PN='
            || i_matnr
            || ',Seq='
            || i_posnr;
         RAISE ex;
      END IF;
   END IF;

   IF (i_posnr||'A'='A')
   THEN
      o_error_detail :=
            'Seq_NO can not be null. WO='
         || i_aufnr
         || ',PN='
         || i_matnr
         || ',Seq='
         || i_posnr;
      RAISE ex;
   END IF;

   IF (i_aufnr||'A' = 'A')
   THEN
      o_error_detail :=
            'WO can not be null. WO='
         || i_aufnr
         || ',PN='
         || i_matnr
         || ',Seq='
         || i_posnr;
      RAISE ex;
   END IF;

--   v_count := NVL (INSTR (i_matnr, '+'), 0);
--   IF v_count <= 0
--   THEN
--      v_part_no := i_matnr;
--      v_part_rev := 'A00';
--   ELSE
--      v_part_no := SUBSTR (i_matnr, 1, v_count - 1);
--      v_part_rev := SUBSTR (i_matnr, v_count + 1);
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
      v_v_rev := 'A00';
   ELSE
      v_v_rev := i_rev;
   END IF;

   IF (i_matnr||'A' = 'A')
   THEN
      o_error_detail :=
            'Part NO can not be null. WO='
         || i_aufnr
         || ',PN='
         || i_matnr
         || ',Seq='
         || i_posnr;
      RAISE ex;
   END IF;

   IF (i_baugr||'A' = 'A')
   THEN
      o_error_detail :=
            'Upper PN can not be null. WO='
         || i_aufnr
         || ',PN='
         || i_matnr
         || ',Seq='
         || i_posnr;
      RAISE ex;
   END IF;

--   if (dumps = 'X') and
--   IF (i_bismt IS NULL)
--   THEN
--      o_error_detail :=
--            'CUST_PN can not be null. WO='
--         || i_aufnr
--         || ',PN='
--         || v_part_no
--         || ',Seq='
--         || i_posnr;
--      RAISE ex;
--   END IF;

/* --NVD AUTODOWN     by Liujiang 20200915  end       not check po info in NVD
   --wheather it is a replaced model
   SELECT COUNT (0)
     INTO v_count
     FROM sfism4.wip_d_erp_po
    WHERE work_order = i_aufnr AND cust_pn = i_bismt;

   IF (v_count <= 0)
   THEN
      v_replace_flag := 1;
   ELSE
      v_replace_flag := 0;

      IF i_bdmng = 0
      THEN
         v_replace_flag := 1;
      END IF;
   END IF;
*/ --NVD AUTODOWN     by Liujiang 20200915  end       not check po info in NVD
    v_replace_flag := 1;--NVD AUTODOWN     by Liujiang 20200915  end    zhi jie fu zhi 1


--   SELECT COUNT (0)
--     INTO v_count
--     FROM sfism4.wip_d_wo_detail
--    WHERE work_order = i_aufnr AND part_no = v_modelname and part_rev = v_v_rev
--    AND seq_no = i_posnr and upper_pn = i_BAUGR and  ((PO_NO = i_CUST_PO)or(PO_NO is null))
--    and ((PO_LINE = i_LINE) or(PO_LINE is null)) and ((ITEM_NO = i_REFITEM) or (ITEM_NO is null));

   --   IF v_count = 0
--   THEN
   o_error_detail :=
         'Insert error. WO='
      || i_aufnr
      || ',PNANDREV='
      || i_matnr
      || ',Seq='
      || i_posnr;

   INSERT INTO sfism4.wip_d_wo_detail
               (work_order, part_no, part_rev, seq_no, cust_pn,
                request_qty, replace_group1, replace_group2,
                original_qty, com_id, unit_qty, upper_pn,
                creator, create_date, b2b_mc_code, replace_flag,
                dumps, serialized_flag, parent_unit_qty,
                po_no, po_line, item_no, po_cust_pn
               )
        VALUES (i_aufnr, i_matnr, v_v_rev, i_posnr, i_bismt,
                NVL (i_bdmng, 0), NVL (i_alpgr, 'N/A'), NVL (i_baugr, 'N/A'),
                NVL (i_menge, 0), 'O', NVL (i_zunit_qty, 0), i_baugr,
                i_op_id, SYSDATE, i_b2b_mc_code, v_replace_flag,
                NVL (i_dumps, 'N/A'), v_serialized_flag, i_zunit_qty1,
                i_cust_po, i_line, i_refitem, i_pocust_pn
               );

--   ELSE
--      o_error_detail :=
--            'Update record. WO='
--         || i_aufnr
--         || ',PNANDREV='
--         || i_matnr
--         || ',Seq='
--         || i_posnr;

   --      UPDATE sfism4.wip_d_wo_detail
--         SET part_no = v_modelname,
--             part_rev = v_v_rev,
--             seq_no = i_posnr,
--             cust_pn = i_bismt,
--             request_qty = NVL (i_bdmng, 0),
--             replace_group1 = NVL (i_alpgr, 'N/A'),
--             replace_group2 = NVL (i_baugr, 'N/A'),
--             original_qty = NVL (i_menge, 0),
--             com_id = 'O',
--             unit_qty = NVL (i_zunit_qty, 0),
--             upper_pn = i_baugr,
--             updater = i_op_id,
--             update_date = SYSDATE,
--             b2b_mc_code = i_b2b_mc_code,
--             replace_flag = v_replace_flag,
--            DUMPS = NVL (I_DUMPS , 'N/A'),
--             serialized_flag = v_serialized_flag,
--             parent_unit_qty = i_zunit_qty1,
--             PO_NO = i_CUST_PO,
--             PO_LINE = i_LINE,
--             ITEM_NO = i_REFITEM,
--             PO_CUST_PN = i_POCUST_PN
--       WHERE work_order = i_aufnr AND part_no = v_modelname and part_rev = v_v_rev
--    AND seq_no = i_posnr and upper_pn = i_BAUGR and  ((PO_NO = i_CUST_PO)or(PO_NO is null))
--    and ((PO_LINE = i_LINE) or(PO_LINE is null)) and ((ITEM_NO = i_REFITEM) or (ITEM_NO is null));
--   END IF;
   o_error_detail :=
         'Check PO_CUST_PN ERROR. WO='
      || i_aufnr
      || ',PNANDREV='
      || i_matnr
      || ',Seq='
      || i_posnr;

  /* IF fn_getcontrolvalue ('EPD3', 'CheckWOPOCust_PN', 'N') = 'Y'
   THEN
      IF (i_werks = 'PEL1')
      THEN
         OPEN po_detail_cur;

         v_count := 0;

         LOOP
            FETCH po_detail_cur
             INTO ROW;

            EXIT WHEN po_detail_cur%NOTFOUND;
            v_count := v_count + 1;
         END LOOP;

         CLOSE po_detail_cur;

         IF v_count > 0
         THEN
            o_error_detail :=
                  'WO,CUST_PN not exist in PO Detail. WO='
               || i_aufnr
               || ',PN='
               || i_matnr
               || ',Seq='
               || i_posnr;
            RAISE ex;
         END IF;
      END IF;
   END IF;*/   --delete by zong-long for epd3 DB slow 2012.7.30 

   commit;
   o_error_detail := '';
EXCEPTION
   WHEN OTHERS 
   THEN 
      rollback;
      o_error_detail :=
         'SP_SAP_DL_WO_DETAIL: ' || o_error_detail || '. [' || SQLERRM || ']';
END;
