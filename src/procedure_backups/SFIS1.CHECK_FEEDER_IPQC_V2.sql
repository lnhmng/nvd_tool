PROCEDURE       check_feeder_ipqc_v2 (
   machine   IN       VARCHAR2,
   ppn       IN       VARCHAR2,
   ver       IN       VARCHAR2,
   emp       IN       VARCHAR2,
   loc       IN       VARCHAR2,
   efn       IN       VARCHAR2,
   line      IN       VARCHAR2,
   tab       IN       VARCHAR2,
   res       OUT      VARCHAR2
)
IS
   c_output     VARCHAR2 (64);
   c_feederno   VARCHAR (16);
   c_loc        VARCHAR (16);
   c_kpn        VARCHAR2 (32);
   c_count      NUMBER;
   no_tab_no    EXCEPTION;
   e_null       EXCEPTION;

   CURSOR c_feeder_no
   IS
      SELECT feeder_no
        FROM sfis1.c_smt_bom_t bom, sfism4.r_smt_prod_bom_t prod
       WHERE bom.bom_no = prod.bom_no
         AND prod.product_no = ppn
         AND prod.ver = ver
         AND bom.machine_code = machine;

   CURSOR c_tabel_no
   IS
      SELECT feeder_no
        FROM sfis1.c_smt_bom_t bom, sfism4.r_smt_prod_bom_t prod
       WHERE bom.bom_no = prod.bom_no
         AND prod.product_no = ppn
         AND prod.ver = ver
         AND bom.machine_code = machine
         AND bom.feeder_no LIKE tab || '%';
BEGIN
   -- Detele all  this machina
   DELETE FROM sfism4.r_sn_group_t
         WHERE line_name = machine;

-----------------------------------------TAS-070329-02-------------------------------------
   -- Save feeder_no from LOC To efn  in sfism4.R_SN_GROUP_T  MODEL_NAME:HFEEDERNO, LINE_NAME:MACHINE ;//
   /*SELECT count(*) into c_count
       FROM sfis1.c_smt_bom_t bom, sfism4.r_smt_prod_bom_t prod
      WHERE  bom.bom_no = prod.bom_no
        AND prod.product_no = ppn
        AND prod.ver = ver
        AND bom.machine_code = machine
        AND bom.FEEDER_NO like TAB||'%';
   IF c_count=0 then
      RAISE NO_TAB_NO ;
   END IF;
   IF c_count>0 then   */
   IF TRIM (tab) IS NULL
   THEN
      RAISE no_tab_no;
   END IF;

   IF SUBSTR (TRIM (tab), 1, 3) = 'TBL'
   THEN
      SELECT COUNT (*)
        INTO c_count
        FROM sfis1.c_smt_bom_t bom, sfism4.r_smt_prod_bom_t prod
       WHERE bom.bom_no = prod.bom_no
         AND prod.product_no = ppn
         AND prod.ver = ver
         AND bom.machine_code = machine
         AND bom.feeder_no LIKE tab || '%';

      IF c_count = 0
      THEN
         RAISE no_tab_no;
      END IF;

      OPEN c_tabel_no;

      LOOP
         FETCH c_tabel_no
          INTO c_feederno;

         EXIT WHEN c_tabel_no%NOTFOUND;

         INSERT INTO sfism4.r_sn_group_t
                     (model_name, line_name, item
                     )
              VALUES (c_feederno, machine, '0'
                     );
      END LOOP;

      CLOSE c_tabel_no;

      res := 'OK';
      RAISE e_null;
   END IF;

   IF TRIM (tab) = 'NOTAB'
   THEN
      OPEN c_feeder_no;

      LOOP
         FETCH c_feeder_no
          INTO c_feederno;

         EXIT WHEN c_feeder_no%NOTFOUND;

         INSERT INTO sfism4.r_sn_group_t
                     (model_name, line_name, item
                     )
              VALUES (c_feederno, machine, '0'
                     );
      END LOOP;

      CLOSE c_feeder_no;

      res := 'OK';
      RAISE e_null;
   ELSE
      res := 'INPUT ERROR!';
      RAISE e_null;
   END IF;
-----------------------------------------TAS-070329-02-------------------------------------
EXCEPTION
   WHEN e_null
   THEN
      NULL;
   WHEN no_tab_no
   THEN
      res := ' NO TAB ';
      c_output := res || ' - ' || loc;
   WHEN OTHERS
   THEN
      res := ' NO FEEDER';
      c_output := res || ' - ' || loc;
END;
-- Writed by liuyunjiang 2006-03-11 for IPQC Check. 