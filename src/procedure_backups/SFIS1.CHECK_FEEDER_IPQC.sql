PROCEDURE       check_feeder_ipqc (
   machine   IN       VARCHAR2,
   ppn       IN       VARCHAR2,
   ver       IN       VARCHAR2,
   emp       IN       VARCHAR2,
   loc       IN       VARCHAR2,
   efn       IN       VARCHAR2,
   line      IN       VARCHAR2,
   res       OUT      VARCHAR2
)
IS
   c_output     VARCHAR2 (64);
   c_feederno   VARCHAR (16);
   c_kpn        VARCHAR2 (32);


   CURSOR c_feeder_no
   IS
      SELECT feeder_no
        FROM sfis1.c_smt_bom_t bom, sfism4.r_smt_prod_bom_t prod
       WHERE  bom.bom_no = prod.bom_no
         AND prod.product_no = ppn
         AND prod.ver = ver
         AND bom.machine_code = machine;
BEGIN
   SELECT bom.key_part_no
     INTO c_kpn
     FROM sfis1.c_smt_bom_t bom, sfism4.r_smt_prod_bom_t prod
    WHERE bom.bom_no = prod.bom_no
      AND prod.product_no = ppn
      AND prod.ver = ver
      AND bom.machine_code = machine
      AND ROWNUM = 1;

   -- Detele all  this machina
   DELETE FROM sfism4.r_sn_group_t
         WHERE line_name = machine;

   -- Save feeder_no from LOC To efn  in sfism4.R_SN_GROUP_T  MODEL_NAME:HFEEDERNO, LINE_NAME:MACHINE ;
   OPEN c_feeder_no;

   LOOP
      FETCH c_feeder_no
       INTO c_feederno;

      EXIT WHEN c_feeder_no%NOTFOUND;

      INSERT INTO sfism4.r_sn_group_t
                  (model_name, line_name,item
                  )
           VALUES (c_feederno, machine,'0'
                  );
   END LOOP;

   CLOSE c_feeder_no;

   res := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      res := ' NO FEEDER';
      c_output := res || ' - ' || loc;
END;
-- Writed by liuyunjiang 2006-03-11 for IPQC Check.
