PROCEDURE                   check900input 
                                                --Create by Steven Hu at 2008-03-01 for TAS-080301-01
(
   line      IN       VARCHAR2,
   mygroup   IN       VARCHAR2,
   DATA      IN       VARCHAR2,
   res       OUT      VARCHAR2
)
AS
   c_carton                 VARCHAR2 (25);
   c_model                  VARCHAR2 (25);
   c_bios                   VARCHAR2 (40);
   c_count0                 NUMBER;
   c_count1                 NUMBER;
   c_count2                 NUMBER;
   c_count3                 NUMBER;
   c_count4                 NUMBER;
   c_count5                 NUMBER;
   c_initsn                 VARCHAR2 (25);
   v_bios                   VARCHAR2 (40);
   v_bios1                  VARCHAR2 (40);
   v_bios2                  VARCHAR2 (40);
   v_carton                 VARCHAR2 (30);
   v_lp_900model            VARCHAR2 (25);
   c_plx                    VARCHAR2 (40);
   bpmodel                  VARCHAR2 (20);
   bprepair                 VARCHAR2 (20);
   --- Add By Derrick Cho for tickets:S000001GKK 2013-11-22 9:54:53
   count11                  NUMBER;
   ps_plx                   VARCHAR (40);
   pf_plx                   VARCHAR (40);
   c_maxdate                DATE;
   e_null                   EXCEPTION;
   v_cnt_900model           NUMBER (2, 0);
   v_cnt_900model_matched   NUMBER (2, 0);
   e_900model               EXCEPTION;
   v_900model               VARCHAR2 (25);
   lock_station             VARCHAR2 (25);
   flag                     VARCHAR (20);
BEGIN
   -------------------------------------Add by Steven Hu on 2008/7/25 for TAS-080725-01 Begin-----------------------
   IF mygroup = 'P_VI'
   THEN
      SELECT carton_no
        INTO c_carton
        FROM sfism4.r_wip_tracking_t
       WHERE serial_number = DATA;

      IF (c_carton IS NOT NULL AND c_carton <> 'N/A')
      THEN
         UPDATE sfism4.r_wip_tracking_t
            -- SET carton_no = 'N/A'
         SET carton_no = 'N/A',
             pallet_no = 'N/A'                          --TANZISONG 2019-06-01
          WHERE serial_number = DATA;

         res := 'OK';
         COMMIT;
         RAISE e_null;
      ELSE
         res := 'OK';
         RAISE e_null;
      END IF;
   ELSIF mygroup <> '900_INPUT'
   THEN
      res := 'OK';
      RAISE e_null;
   END IF;

   -------------------------------------Add by Steven Hu on 2008/7/25 for TAS-080725-01 End-----------------------
   --add by tanrongliang20180130 begin
   SELECT COUNT (serial_number)
     INTO c_count5
     FROM sfism4.r_sn_lock_unlock_t
    WHERE serial_number = DATA;

   IF c_count5 > 0
   THEN
      SELECT lock_group_name, lockflag
        INTO lock_station, flag
        FROM sfism4.r_sn_lock_unlock_t
       WHERE serial_number = DATA;

      IF lock_station = mygroup AND flag = 'LOCK'
      THEN
         res := DATA || ' BEING PRE LOCKED';
         RAISE e_null;
      END IF;
   END IF;

   --add by tanrongliang20180130 end
   SELECT model_name
     INTO c_model
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = DATA;

   SELECT COUNT (*)
     INTO c_count0
     FROM sfis1.c_pth_t
    WHERE line_name = line AND model_name = c_model AND station_name = mygroup;

   IF c_count0 = 0
   THEN
      res := 'ERROR1:NO FOUND CONFIG INFO';
      RAISE e_null;
   ELSE
      SELECT bios_version, lp_900model
        INTO c_bios, v_lp_900model
        FROM sfis1.c_pth_t
       WHERE line_name = line
         AND model_name = c_model
         AND station_name = mygroup
         AND ROWNUM = 1;

      /*IF C_BIOS = 'N/A' THEN
         RES:='ERROR2:NO CONFIG BIOS';
         RAISE e_NULL;
      END IF; */
      -- ADD By Derrick.chow begin 2012-07-24 begin--
      IF (v_lp_900model IS NULL OR v_lp_900model = 'N/A')
      THEN
         res := 'ERROR9:NO FOUND 900MODEL CONFIG INFO';
         RAISE e_null;
      END IF;

      -- ADD By Derrick.chow  2012-07-24 end--
----------*****add By Derrick Chow for tickets:S000001GKK 2013-11-22 10:20:11******---------
      SELECT COUNT (*)
        INTO count11
        FROM sfism4.r_nvplx_model_t
       WHERE serial_number = DATA;

      SELECT plx_version
        INTO c_plx
        FROM sfis1.c_pth_t
       WHERE line_name = line
         AND model_name = c_model
         AND station_name = mygroup
         AND ROWNUM = 1;

      IF (count11 > 0) AND (c_plx IS NOT NULL) AND (c_plx <> 'N/A')
      THEN
         SELECT second_plx
           INTO ps_plx
           FROM sfism4.r_nvplx_model_t
          WHERE serial_number = DATA;

         IF ps_plx IS NULL
         THEN
            SELECT first_plx
              INTO pf_plx
              FROM sfism4.r_nvplx_model_t
             WHERE serial_number = DATA;

            IF c_plx <> pf_plx
            THEN
               res := 'ERROR11:PLX ERROR1';
               RAISE e_null;
            END IF;
         ELSE
            IF c_plx <> ps_plx
            THEN
               res := 'ERROR10:PLX ERROR2';
               RAISE e_null;
            END IF;
         END IF;
      END IF;
   ----------*****add By Derrick Chow for tickets:S000001GKK 2013-11-22 10:20:11******---------
   END IF;

   --Added by songFengLiu 2013-8-8  for S000001C2H-130808-01 begin
   -- check 900 model name
   SELECT COUNT (0)
     INTO v_cnt_900model
     FROM sfism4.r_link_t rlt
    WHERE rlt.serial_number = DATA
      AND rlt.flag = '900_MODEL_NAME'
      AND rlt.available = '1';

   IF v_cnt_900model > 0
   THEN
      SELECT COUNT (0)
        INTO v_cnt_900model_matched
        FROM sfism4.r_link_t rlt
       WHERE rlt.serial_number = DATA
         AND rlt.key_value = v_lp_900model
         AND rlt.flag = '900_MODEL_NAME'
         AND rlt.available = '1';

      IF v_cnt_900model_matched = 0
      THEN
         RAISE e_900model;
      END IF;
   END IF;

   --Added by songFengLiu 2013-8-8  for S000001C2H-130808-01 end
   SELECT COUNT (*)
     INTO c_count1
     FROM sfism4.r_nvbios_model_t
    WHERE serial_number = DATA;

   IF c_count1 = 0
   THEN
      IF c_bios = 'N/A'
      THEN
         UPDATE sfism4.r_wip_tracking_t
            -- SET carton_no = 'N/A'
         SET carton_no = 'N/A',
             pallet_no = 'N/A'                          --TANZISONG 2019-06-01
          WHERE serial_number = DATA;

         SELECT COUNT (*)                                      ------ADD BY ZC
           INTO c_count4
           FROM sfism4.r_nvbios_model_spare_t
          WHERE serial_number = DATA;

         IF c_count4 > 0
         THEN
            UPDATE sfism4.r_nvbios_model_spare_t
               SET last_model_name = v_lp_900model,
                   group_name = mygroup,
                   datetime = SYSDATE
             WHERE serial_number = DATA;

            res := 'OK';
            COMMIT;
            RAISE e_null;
         ELSE
            INSERT INTO sfism4.r_nvbios_model_spare_t
                        (serial_number, init_model_name, first_bios,
                         second_bios, last_model_name, datetime, reserve1,
                         reserve2, flag, group_name
                        )
                 VALUES (DATA, c_model, c_bios,
                         c_bios, v_lp_900model, SYSDATE, '',
                         '', 1, mygroup
                        );                            -----------ADD END BY ZC

            res := 'OK';
            COMMIT;
            RAISE e_null;
         END IF;
      ELSE
         SELECT COUNT (*)
           INTO c_count2
           FROM sfism4.r_sn_link_t
          WHERE new_sn = DATA;

         IF c_count2 = 0
         THEN
            res := 'ERROR3:NO FLASH BIOS';
            RAISE e_null;
         ELSE
            ------------------------------------Add by Steven Hu on 2008/11/20 for TAS-081120-01 Begin-------------------------------
            SELECT init_sn
              INTO c_initsn
              FROM sfism4.r_sn_link_t
             WHERE new_sn = DATA;

            SELECT COUNT (*)
              INTO c_count3
              FROM sfism4.r_nvbios_model_t a, sfism4.r_sn_link_t b
             WHERE a.serial_number = b.old_sn AND b.init_sn = c_initsn;

            IF c_count3 = 0
            THEN
               res := 'ERROR7:NO FLASH BIOS';
               RAISE e_null;
            ELSE
               SELECT MAX (a.datetime)
                 INTO c_maxdate
                 FROM sfism4.r_nvbios_model_t a, sfism4.r_sn_link_t b
                WHERE a.serial_number = b.old_sn AND b.init_sn = c_initsn;

               SELECT NVL (a.second_bios, a.first_bios)
                 INTO v_bios
                 FROM sfism4.r_nvbios_model_t a, sfism4.r_sn_link_t b
                WHERE a.serial_number = b.old_sn
                  AND b.init_sn = c_initsn
                  AND a.datetime = c_maxdate;

               IF v_bios <> c_bios
               THEN
                  res := 'ERROR8:BIOS IS ERROR';
                  RAISE e_null;
               ELSE
                  res := 'OK';
               END IF;
            END IF;
         ------------------------------------Add by Steven Hu on 2008/11/20 for TAS-081120-01 End-------------------------------
         END IF;
      END IF;
   ELSE
      SELECT second_bios
        INTO v_bios2
        FROM sfism4.r_nvbios_model_t
       WHERE serial_number = DATA;

      IF v_bios2 IS NULL
      THEN
         SELECT first_bios
           INTO v_bios1
           FROM sfism4.r_nvbios_model_t
          WHERE serial_number = DATA;

         IF v_bios1 IS NULL
         THEN
            res := 'ERROR4:BIOS IS NULL';
            RAISE e_null;
         ELSE
            IF v_bios1 <> c_bios
            THEN
               res := 'ERROR5:BIOS IS ERROR';
               RAISE e_null;
            ELSE
               res := 'OK';
            END IF;
         END IF;
      ELSE
         IF v_bios2 <> c_bios
         THEN
            res := 'ERROR6:BIOS IS ERROR';
            RAISE e_null;
         ELSE
            res := 'OK';
         END IF;
      END IF;

      --- add BY Derrik .Chow 2012-07-24 begin---
      UPDATE sfism4.r_nvbios_model_t
         SET last_model_name = v_lp_900model,
             group_name = mygroup
       WHERE serial_number = DATA;

      COMMIT;
   --- add BY Derrik .Chow 2012-07-24 end---
   END IF;

   --Modified by Alex Wang on 2010/12/10 for 2XKF-101210-01 Begin
   SELECT carton_no
     INTO v_carton
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = DATA;

   IF NOT (   (SUBSTR (v_carton, 1, 3) = 'CLH')
           OR (SUBSTR (v_carton, 1, 3) = '032')
           OR (SUBSTR (v_carton, 1, 3) = '132')
           OR (SUBSTR (v_carton, 1, 2) = 'CF')
           OR (SUBSTR (v_carton, 1, 3) = '056')         --TANZISONG 2019-06-01
           OR (SUBSTR (v_carton, 1, 3) = '156')         --TANZISONG 2019-06-01
          )
   THEN
      UPDATE sfism4.r_wip_tracking_t
         --SET carton_no = 'N/A'
      SET carton_no = 'N/A',
          pallet_no = 'N/A'                             --TANZISONG 2019-06-01
       WHERE serial_number = DATA;
   END IF;


    --  add by   LY 2019-11-14  E2992 測試備品管控

   --SELECT model_name
    -- INTO bpmodel
    -- FROM sfism4.r_wip_tracking_t
   -- WHERE serial_number = DATA;

   --IF SUBSTR (bpmodel, 5, 5) IN ('2G503', '2G504', '2G506')
   --THEN
    --  SELECT COUNT (serial_number)
     --   INTO bprepair
      --  FROM sfism4.r_repair_t
      -- WHERE serial_number = DATA AND reason_code LIKE '%RC04%';

      --IF bprepair > 0
      --THEN
       --  UPDATE sfis1.c_bp_product_t
         --   SET lock_unlock = 'lock',
           --     reason = 'PG503/PG504/PG506歪PIN'
         --- WHERE serial_number = DATA;

         --INSERT INTO sfism4.r_sn_lock_unlock_t
           -- SELECT serial_number, mo_number, group_name, '900_VI', 'LOCK',
             --      emp_no, SYSDATE, '', 'PG503/PG504/PG506歪PIN', ''
            ---  FROM (SELECT serial_number, mo_number, group_name, model_name,
             --              emp_no
             --         FROM sfism4.r_wip_tracking_t
            --         WHERE serial_number = DATA);

       --  UPDATE sfism4.r_wip_tracking_t
         --   SET next_station = 'STOP'
       --   WHERE serial_number = DATA;
     -- END IF;
  -- END IF;


  --  add by  2019-11-14  E2992 測試備品管控
   --Modified by Alex Wang on 2010/12/10 for 2XKF-101210-01 End
   COMMIT;
EXCEPTION
   WHEN e_null
   THEN
      NULL;
   WHEN e_900model
   THEN
      res := 'ERR:900 MODEL MISMATCH';
   WHEN OTHERS
   THEN
      ROLLBACK;
      res := 'OTHER ERROR' || SUBSTR (SQLERRM, 1, 100);
END;