PROCEDURE       sp_check_assy_pn (
   station_num   IN       VARCHAR2,
   machine       IN       VARCHAR2,
   pn            IN       VARCHAR2,
   ver           IN       VARCHAR2,
   emp           IN       VARCHAR2,
   loc           IN       VARCHAR2,
   sn            IN       VARCHAR2,
   line          IN       VARCHAR2,
   res           OUT      VARCHAR2
)
IS
   c_model              VARCHAR2 (25);
   c_kpn                VARCHAR2 (25);
   c_output             VARCHAR2 (64);
   v_count              NUMBER (2, 0);
   c_spare_model_name   VARCHAR2 (50);
   c_product_no         VARCHAR2 (50);
   c_sncnt              VARCHAR2 (50);
   v_barcode            VARCHAR2 (50);
   v_oldsn              VARCHAR2 (50);
   e_hhpn_error         EXCEPTION;
/*
 NAME:       SFIS1.SP_CHECK_ASSY_PN
 PURPOSE:   PTH_INPUT PN

  REVISIONS:
  TaskID           Ver        Date        Author           Description
   -------------------------------------------------------------
  S0000027RW       1.0       2014/05/22   Maggie           PTH_INPUT PN
*/
BEGIN
    /*SELECT key_part_no
    INTO C_KPN
    FROM sfis1.c_smt_kp_t
   WHERE (key_part_no = data||'HF' OR  key_part_no = data||'G' )
              AND kp_distinct = '1' AND ROWNUM = 1;*/
   SELECT model_name, spare_model_name                           ----Add by zc
     INTO c_model, c_spare_model_name
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = sn AND ROWNUM = 1;

   IF c_spare_model_name IS NULL
   THEN
      SELECT COUNT (*)
        INTO c_sncnt
        FROM sfism4.r_sn_link_t
       WHERE new_sn = sn;

      IF c_sncnt > 0
      THEN
         SELECT init_sn, old_sn
           INTO v_barcode, v_oldsn
           FROM sfism4.r_sn_link_t
          WHERE new_sn = sn AND ROWNUM = 1;

         SELECT spare_model_name
           INTO c_spare_model_name
           FROM sfism4.r_wip_tracking_t
          WHERE serial_number = v_oldsn AND ROWNUM = 1;

         IF NVL (c_spare_model_name, 0) <> '0'
         THEN
            c_product_no := c_spare_model_name;
         ELSE
            c_product_no := c_model;
         END IF;
      ELSE
         c_product_no := c_model;
      END IF;
   ELSE
      c_product_no := c_spare_model_name;                   ----Add end by zc
   END IF;

   /*SELECT KEY_PART_NO
     INTO C_KPN
     FROM SFIS1.C_SMT_BOM_T
    WHERE     (key_part_no = DATA || 'HF' OR key_part_no = DATA || 'G')
          AND bom_no =
                 (SELECT bom_no
                    FROM SFISM4.R_SMT_PROD_BOM_T
                   WHERE     PRODUCT_NO = C_MODEL
                         AND LINE_NAME = Line
                         AND BOM_NO LIKE '%PTH_INPUT%');*/
   SELECT COUNT (key_part_no)
     INTO v_count
     FROM sfis1.c_smt_bom_t
    WHERE (key_part_no = pn || 'HF' OR key_part_no = pn || 'G' OR key_part_no = pn)
      AND bom_no =
             (SELECT bom_no
                FROM sfism4.r_smt_prod_bom_t
               WHERE product_no = c_product_no
                 AND line_name = line
                 AND (bom_no LIKE '%PTH_INPUT%'OR bom_no LIKE '%ASSY_INPUT%'));

   IF v_count = 0
   THEN
      RAISE e_hhpn_error;
   END IF;

   res := 'OK';
EXCEPTION
   WHEN e_hhpn_error
   THEN
      res := 'HHPN NG';
   WHEN OTHERS
   THEN
      res := 'OTHER ERROR';
      c_output := res || ' - ' || pn;
      insert_error_mes (station_num,
                        machine,
                        c_model,
                        ver,
                        emp,
                        loc,
                        pn || 'HF/G',
                        sn,
                        line,
                        c_output
                       );
END;