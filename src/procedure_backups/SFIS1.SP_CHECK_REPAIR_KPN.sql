PROCEDURE       sp_check_repair_kpn (
   station_num   IN     VARCHAR2,
   machine       IN     VARCHAR2,
   kpn           IN     VARCHAR2,
   ver           IN     VARCHAR2,
   emp           IN     VARCHAR2,
   loc           IN     VARCHAR2,
   sn            IN     VARCHAR2,
   line          IN     VARCHAR2,
   res              OUT VARCHAR2)
IS
   c_model              VARCHAR2 (25);
   c_spare_model_name   VARCHAR2 (50);
   c_product_no         VARCHAR2 (50);
   C_COUNT              NUMBER;
   V_ITEM_CODE          sfis1.c_item_desc_t.item_code%TYPE;

   CURSOR CUR1
   IS
          SELECT old_sn
            FROM sfism4.r_sn_link_t
      START WITH new_sn = sn
      CONNECT BY PRIOR old_sn = new_sn;

   ROW1                 CUR1%ROWTYPE;
BEGIN
   SELECT COUNT (*)
     INTO C_COUNT
     FROM sfis1.C_ITEM_DESC_T a, SFIS1.C_PARAMETER_INI b
    WHERE     (a.item_serial = kpn OR a.item_serial = kpn || 'HF')
          AND a.item_code = b.vr_name
          AND b.PRG_NAME = 'SMO'
          AND b.VR_CLASS = 'itemcode'
          AND b.VR_ITEM = 'itemcode';

   IF C_COUNT >= 1
   THEN
      SELECT DISTINCT ITEM_CODE
        INTO V_ITEM_CODE
        FROM sfis1.C_ITEM_DESC_T a, SFIS1.C_PARAMETER_INI b
       WHERE     (a.item_serial = kpn OR a.item_serial = kpn || 'HF')
             AND a.item_code = b.vr_name
             AND b.PRG_NAME = 'SMO'
             AND b.VR_CLASS = 'itemcode'
             AND b.VR_ITEM = 'itemcode'
             AND ROWNUM = 1;
   ELSE
      res := kpn || ' - ' || 'have over an itemcode';
      RETURN;
   END IF;



   SELECT model_name, SPARE_MODEL_NAME
     INTO c_model, c_spare_model_name
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = sn;

   IF c_spare_model_name IS NULL
   THEN
      c_product_no := c_model;
   ELSE
      c_product_no := c_spare_model_name;
   END IF;


   SELECT COUNT (*)
     INTO C_COUNT
     FROM SFIS1.C_ITEM_DESC_T
    WHERE     model_name = c_product_no
          AND ITEM_CODE = V_ITEM_CODE
          AND (ITEM_SERIAL = kpn OR ITEM_SERIAL = kpn || 'HF');

   IF C_COUNT = 0
   THEN
      OPEN CUR1;

      FETCH CUR1 INTO ROW1;

      IF CUR1%FOUND
      THEN
         LOOP
            EXIT WHEN CUR1%NOTFOUND;

            SELECT model_name, SPARE_MODEL_NAME
              INTO c_model, c_spare_model_name
              FROM sfism4.r_wip_tracking_t
             WHERE serial_number = ROW1.old_sn;

            IF c_spare_model_name IS NULL
            THEN
               c_product_no := c_model;
            ELSE
               c_product_no := c_spare_model_name;
            END IF;


            SELECT COUNT (*)
              INTO C_COUNT
              FROM SFIS1.C_ITEM_DESC_T
             WHERE     model_name = c_product_no
                   AND ITEM_CODE = V_ITEM_CODE
                   AND (ITEM_SERIAL = kpn OR ITEM_SERIAL = kpn || 'HF');

            IF C_COUNT = 0
            THEN
               FETCH CUR1 INTO ROW1;
            ELSE
               res := 'OK';
               RETURN;
            END IF;
         END LOOP;
      END IF;

      CLOSE CUR1;

      res := kpn || ' - ' || 'have not an itemcode';
      RETURN;
   --ELSE
     -- res := kpn || ' - ' || 'have not an itemcode';
      --RETURN;
   END IF;

   res := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      res := 'OTHER ERROR';
END;