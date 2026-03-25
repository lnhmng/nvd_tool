PROCEDURE             check_feed_integrity_V5 (
   sn          IN       VARCHAR2,
   section     IN       VARCHAR2,
   mygroup     IN       VARCHAR2,
   w_station   IN       VARCHAR2,
   line        IN       VARCHAR2,
   res         OUT      VARCHAR2
)
AS
   v_model_name    VARCHAR (30);
   v_product_no    VARCHAR (30);
   v_count         NUMBER;
   v_key_part_no   VARCHAR (30);
   v_feeder_no     VARCHAR (30);
   v_exception     EXCEPTION;

   CURSOR cur0
   IS
      SELECT key_part_no, feeder_no
        FROM (SELECT DISTINCT a.key_part_no, a.feeder_no,
                              b.key_part_no AS key_part
                         FROM (SELECT key_part_no, feeder_no, machine_code
                                 FROM sfism4.r_smt_prod_bom_t a,
                                      sfis1.c_smt_bom_t b
                                WHERE a.bom_no = b.bom_no
                                  AND product_no = v_product_no
                                  AND line_name = line
                                  AND machine_code = mygroup) a,
                              (SELECT key_part_no, TRAIL_NO
                                 FROM smtinfo.r_smt_pkgid_log_t
                                WHERE product_no = v_product_no
                                  AND (state_flag = 'C' OR state_flag = 'N')
                                  AND line_name = line
                                  AND machine_code = mygroup) b
                        WHERE a.key_part_no = b.key_part_no(+)
                              AND a.feeder_no = b.TRAIL_NO(+))
       WHERE key_part IS NULL;

   row0            cur0%ROWTYPE;
BEGIN
   SELECT model_name
     INTO v_model_name
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = sn;

   IF section = 'PTH'
   THEN
      v_product_no := v_model_name;
   ELSE
      SELECT product_no
        INTO v_product_no
        FROM smtinfo.c_bind_config_t
       WHERE model_name = v_model_name AND line_name = line AND ROWNUM = 1;
   END IF;

   res := 'OK';

   OPEN cur0;

   LOOP
      FETCH cur0
       INTO row0;

      EXIT WHEN cur0%NOTFOUND;

      SELECT COUNT (pkg_id)
        INTO v_count
        FROM smtinfo.r_smt_pkgid_log_t a, sfis1.kpn_spn_model_v b
       WHERE (   a.key_part_no = b.key_part_no
              OR (    a.key_part_no = b.spare_key_part_no
                  AND b.model_name = v_product_no
                 )
             )
         --AND a.key_part_no = v_product_no
         AND a.product_no = v_product_no
         AND TRAIL_NO= row0.feeder_no
         AND (state_flag = 'C' OR state_flag = 'N');

      IF v_count = 0
      THEN
         res :=
            row0.key_part_no || '(' || row0.feeder_no || ')' || ' NOT FOUND!';
         RAISE v_exception;
      END IF;
   END LOOP;

   CLOSE cur0;
EXCEPTION
   WHEN v_exception
   THEN
      NULL;
   WHEN OTHERS
   THEN
      res := 'OTHER ERROR ' || SUBSTR (SQLERRM, 1, 100);
END;