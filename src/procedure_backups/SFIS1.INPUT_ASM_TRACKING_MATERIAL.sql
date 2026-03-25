PROCEDURE       input_asm_tracking_material (
   sn           IN     VARCHAR2,
   machine      IN     VARCHAR2,
   line         IN     VARCHAR2,
   ppkg_id      IN     VARCHAR2,
   ffeeder_no   IN     VARCHAR2,
   REFDES       IN     VARCHAR2,
   ttime        IN     DATE,
   res             OUT VARCHAR2)
AS
   sn_count      NUMBER;
   sn_count1     NUMBER;
   sn_count2     NUMBER;
   sn_count3     NUMBER;
   c_count2      NUMBER;
   pkg_count     NUMBER;
   machinesn1    NUMBER;
   machinesn2    NUMBER;
   c_machine     VARCHAR2 (25);
   c_section     VARCHAR2 (25);
   l_pkg_id      VARCHAR2 (32);
   vpkg_id       VARCHAR2 (36);
   vmodel_name   VARCHAR2 (25);
   vproduct_no   VARCHAR2 (25);
   VHH_PN        VARCHAR2 (25);
   vfeeder_no    VARCHAR2 (25);
   insertflag    VARCHAR2 (5);
   l_bomno       VARCHAR2 (100);                        --add by LLF 2017-8-19
   l_location    VARCHAR2 (2000);
   VTIME         DATE;                                  --add by LLF 2017-8-19
   e_error       EXCEPTION;

   --CURSOR C_FEEDER IS  SELECT PKG_ID, FEEDER_NO, TRAIL_NO FROM SMTINFO.R_SMT_PKGID_LOG_T WHERE MACHINE_CODE= C_MACHINE AND LINE_NAME= LINE AND PRODUCT_NO=VPRODUCT_NO AND (STATE_FLAG='N' or STATE_FLAG='C');

   --L_REEL_NO C_FEEDER%ROWTYPE;
   CURSOR cur1
   IS
      SELECT serial_number
        FROM sfism4.r_pcb_datecode_t
       WHERE GROUP_ID IN (SELECT GROUP_ID
                            FROM sfism4.r_pcb_datecode_t
                           WHERE serial_number = sn);

   row1          cur1%ROWTYPE;
BEGIN
   /*CHECK_BIND_ROUTE_V1(SN,SECTION,MYGROUP,W_STATION,LINE,VPRODUCT_NO,RES);
   IF RES<>'OK' THEN
      RAISE E_ERROR;
   END IF ;*/
   insertflag := 'FALSE';
   vfeeder_no := ffeeder_no;
   vpkg_id := ppkg_id;
   l_location:= REFDES;

   VTIME := ttime; 
   
 --  SELECT SYSDATE INTO VTIME FROM DUAL;
 
   SELECT COUNT (*)
     INTO sn_count2
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = sn;

   IF sn_count2 <= 0
   THEN
      res := 'NO SN';
      RAISE e_error;
   END IF;

   SELECT model_name
     INTO vmodel_name
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = sn;

   SELECT COUNT (*)
     INTO c_count2
     FROM sfis1.c_asm_sfc_machinecode
    WHERE asm_code = machine;

   IF c_count2 > 0
   THEN
      SELECT sfc_code
        INTO c_machine
        FROM sfis1.c_asm_sfc_machinecode
       WHERE asm_code = machine;
   ELSE
      res := 'sfis1.c_asm_sfc_machinecode no sfc machine code';
      RAISE e_error;
   END IF;

   c_section := SUBSTR (TRIM (c_machine), LENGTH (TRIM (c_machine)) - 2, 3);

   SELECT COUNT (*)
     INTO sn_count1
     FROM smtinfo.c_bind_config_t
    WHERE line_name = line AND model_name = vmodel_name;

   IF sn_count1 <= 0
   THEN
      res := 'DOES NOT CONFIG BIND ROUTE';
      RAISE e_error;
   END IF;

   SELECT product_no
     INTO vproduct_no
     FROM smtinfo.c_bind_config_t
    WHERE line_name = line AND model_name = vmodel_name AND ROWNUM = 1;

   SELECT COUNT (*)
     INTO sn_count
     FROM smtinfo.r_sn_pkg_detail_t
    WHERE     serial_number = sn
          AND pkg_id = vpkg_id
          AND machine_code = c_machine
          AND feeder_number = vfeeder_no;

   IF sn_count = 0
   THEN
      -----------------------------------------------TAS-071009-01  Begin Steven Hu----------------------------------
      OPEN cur1;

      FETCH cur1 INTO row1;

      IF cur1%FOUND
      THEN
         insertflag := 'TRUE';
      END IF;

      CLOSE cur1;

      -----------------------------------------------TAS-071009-01  End  Steven Hu-----------------------------------
      SELECT COUNT (pkg_id)
        INTO pkg_count
        FROM smtinfo.r_smt_pkgid_log_t
       WHERE     machine_code = c_machine
             AND line_name = line
             AND product_no = vproduct_no
             AND (state_flag = 'N' OR state_flag = 'C');

      IF pkg_count > 0
      THEN
         BEGIN
            SELECT COUNT (serial_number)
              INTO machinesn1
              FROM smtinfo.r_sn_tracking_log_t
             WHERE     serial_number = sn
                   AND machine_code = c_machine
                   AND product_no = vproduct_no;

            IF machinesn1 = 0
            THEN
               INSERT INTO smtinfo.r_sn_tracking_log_t (serial_number,
                                                        in_station_time,
                                                        machine_code,
                                                        section_name,
                                                        product_no)
                    VALUES (sn,
                            VTIME,
                            c_machine,
                            c_section,
                            vproduct_no);

               res := 'OK';
            END IF;
         END;
        
      
       --TZS  ******************2018-0809  REVOCATION *******************************************
       --  l_location := '';

       --  SELECT HH_PN
       --    INTO VHH_PN
       --    FROM IQC.R_KPN_INCOMING_T
       --   WHERE PKG_ID = VPKG_ID AND ROWNUM = 1;
        
         ---ADD BY LLF 2017-08-19
        -- SELECT COUNT (DISTINCT a.bom_no)
        --   INTO sn_count2
        --   FROM sfism4.r_smt_prod_bom_t a, sfis1.c_smt_bom_t b
        --  WHERE     a.product_no = vproduct_no
        --        AND b.machine_code = c_machine
        --        AND line_name = line
        --        AND a.bom_no = b.bom_no;

        -- IF sn_count2 > 0
        -- THEN
        --    SELECT a.bom_no
        --      INTO l_bomno
        --      FROM sfism4.r_smt_prod_bom_t a, sfis1.c_smt_bom_t b
        --     WHERE     a.product_no = vproduct_no
        --           AND b.machine_code = c_machine
        --           AND line_name = line
        --           AND a.bom_no = b.bom_no
        --           AND ROWNUM = 1;
        -- END IF;

        --SELECT COUNT (LOCATION)
        --   INTO sn_count2
        --   FROM sfis1.c_bom_detail_t
        --  WHERE bom_no = l_bomno AND KEY_PART_NO = VHH_PN;

        -- IF sn_count2 > 0
        -- THEN
        --    SELECT LOCATION
        --     INTO l_location
        --      FROM sfis1.c_bom_detail_t
        --     WHERE     bom_no = l_bomno
        --           AND SUBSTR (feeder_no, 1, INSTR (feeder_no, '-', -1)) =
        --                  SUBSTR (vfeeder_no, 1, INSTR (vfeeder_no, '-', -1))
        --           AND KEY_PART_NO = VHH_PN
        --           AND ROWNUM = 1;
        -- ELSE
        --    SELECT COUNT (*)
        --      INTO sn_count3
        --      FROM sfis1.c_bom_detail_t A, sfis1.kpn_spn_model_v B
        --     WHERE     A.bom_no = l_bomno
        --           AND B.SPARE_KEY_PART_NO = VHH_PN
        --           AND A.KEY_PART_NO = B.KEY_PART_NO
        --           AND B.MODEL_NAME = vproduct_no;

        --    IF sn_count3 > 0
        --   THEN
        --       SELECT LOCATION
        --         INTO l_location
        --         FROM sfis1.c_bom_detail_t A, sfis1.kpn_spn_model_v B
        --        WHERE     A.bom_no = l_bomno
        --              AND SUBSTR (feeder_no, 1, INSTR (feeder_no, '-', -1)) =
        --                     SUBSTR (vfeeder_no,
        --                             1,
        --                             INSTR (vfeeder_no, '-', -1))
        --              AND B.SPARE_KEY_PART_NO = VHH_PN
        --              AND A.KEY_PART_NO = B.KEY_PART_NO
        --              AND B.MODEL_NAME = vproduct_no
        --              AND ROWNUM = 1;
         --   END IF;
        -- END IF;

         ---ADD BY LLF 2017-08-19
        
        --TZS  ******************2018-0809  REVOCATION ************************************************************************* 
         
         INSERT INTO smtinfo.r_sn_pkg_detail_t (serial_number,
                                                feeder_number,
                                                pkg_id,
                                                machine_code,
                                                in_station_time,
                                                section_name,
                                                LOCATION)
              VALUES (sn,
                      vfeeder_no,
                      vpkg_id,
                      c_machine,
                      VTIME,
                      c_section,
                      l_location);

         ------------------------------------------TAS-071009-01  Begin Steven Hu-----------------------------------
         IF insertflag = 'TRUE'
         THEN
            INSERT INTO smtinfo.r_sn_pkg_temp_t (serial_number,
                                                 feeder_number,
                                                 pkg_id,
                                                 machine_code,
                                                 in_station_time,
                                                 section_name,
                                                 LOCATION)
                 VALUES (sn,
                         vfeeder_no,
                         vpkg_id,
                         c_machine,
                         VTIME,
                         c_section,
                         l_location);
         END IF;

         ------------------------------------------TAS-071009-01  End  Steven Hu------------------------------------
         UPDATE smtinfo.r_smt_pkgid_log_t
            SET state_flag = 'Y'
          WHERE machine_code = c_machine AND state_flag = 'C';

         res := 'OK';
      ELSE
         res := 'NO DATA TO BIND';
         RAISE e_error;
      END IF;
   ELSE
      res := 'OK';
      --res := 'DUPLICATE';
      RAISE e_error;
   END IF;

   OPEN cur1;

   FETCH cur1 INTO row1;

   IF cur1%FOUND
   THEN
      LOOP
         EXIT WHEN cur1%NOTFOUND;

         IF row1.serial_number <> sn
         THEN
         
           
           --TZS  ******************2018-0809  REVOCATION ********************* 
         
            -- l_location := '';

            ---ADD BY LLF 2017-08-19
           -- SELECT COUNT (DISTINCT a.bom_no)
           --   INTO sn_count2
           --   FROM sfism4.r_smt_prod_bom_t a, sfis1.c_smt_bom_t b
           --  WHERE     a.product_no = vproduct_no
           --        AND b.machine_code = c_machine
           --        AND line_name = line
            --       AND a.bom_no = b.bom_no;

           -- IF sn_count2 > 0
           -- THEN
           --    SELECT a.bom_no
           --      INTO l_bomno
           --      FROM sfism4.r_smt_prod_bom_t a, sfis1.c_smt_bom_t b
           --     WHERE     a.product_no = vproduct_no
           --           AND b.machine_code = c_machine
           --           AND line_name = line
           --          AND a.bom_no = b.bom_no
           --           AND ROWNUM = 1;
           -- END IF;

           -- SELECT COUNT (DISTINCT LOCATION)
           --   INTO sn_count2
           --   FROM sfis1.c_bom_detail_t
           --  WHERE bom_no = l_bomno AND feeder_no = vfeeder_no;

           -- IF sn_count2 > 0
           -- THEN
           --    SELECT LOCATION
           --      INTO l_location
           --    FROM sfis1.c_bom_detail_t
           --     WHERE     bom_no = l_bomno
           --           AND feeder_no = vfeeder_no
            --          AND ROWNUM = 1;
           -- END IF;
            ---ADD BY LLF 2017-08-19
            
            
           --TZS  ******************2018-0809  REVOCATION ********************* 
            
            INSERT INTO smtinfo.r_sn_pkg_detail_t (serial_number,
                                                   feeder_number,
                                                   pkg_id,
                                                   machine_code,
                                                   in_station_time,
                                                   section_name,
                                                   LOCATION)
               SELECT row1.serial_number,
                      feeder_number,
                      vpkg_id,
                      machine_code,
                      in_station_time,
                      section_name,
                      LOCATION
                 FROM smtinfo.r_sn_pkg_temp_t
                WHERE serial_number = sn AND machine_code = c_machine;

            --TAS-071009-01  Steven HU

            SELECT COUNT (serial_number)
              INTO machinesn2
              FROM smtinfo.r_sn_tracking_log_t
             WHERE     serial_number = row1.serial_number
                   AND machine_code = c_machine
                   AND product_no = vproduct_no;

            IF machinesn2 = 0
            THEN
               INSERT INTO smtinfo.r_sn_tracking_log_t (serial_number,
                                                        in_station_time,
                                                        machine_code,
                                                        section_name,
                                                        product_no)
                  SELECT row1.serial_number,
                         in_station_time,
                         machine_code,
                         section_name,
                         product_no
                    FROM smtinfo.r_sn_tracking_log_t
                   WHERE     serial_number = sn
                         AND machine_code = c_machine
                         AND product_no = vproduct_no;
            END IF;
         END IF;

         FETCH cur1 INTO row1;
      END LOOP;

      DELETE smtinfo.r_sn_pkg_temp_t
       WHERE serial_number = sn AND machine_code = c_machine;
   --TAS-071009-01 Steven Hu
   END IF;

   CLOSE cur1;

   COMMIT;
EXCEPTION
   WHEN e_error
   THEN
      NULL;
   WHEN OTHERS
   THEN
      ROLLBACK;
      res := 'OTHER ERROR ' || SUBSTR (SQLERRM, 1, 100);
--RES:='ERROR';
END; 