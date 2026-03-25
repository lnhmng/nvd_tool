PROCEDURE       input_asm_pkg_material (
   machine       IN       VARCHAR2,
   ppn           IN       VARCHAR2,
   ver           IN       VARCHAR2,
   hhpn          IN       VARCHAR2,
   ttime         IN       DATE,
   line          IN       VARCHAR2,
   loc           IN       VARCHAR2,
   feeder        IN       VARCHAR2,
   pkg           IN       VARCHAR2,
   emp           IN       VARCHAR2,   
   Quantity      IN       NUMBER,   
   action_type   IN       NUMBER,
   res           OUT      VARCHAR2
)
IS
   c_kpn           VARCHAR2 (32);
   c_loc           VARCHAR2 (32);
   c_feeder        VARCHAR2 (32);
   c_machine       VARCHAR2 (32);
   c_machinecode   VARCHAR2 (32);
   c_trailno       VARCHAR2 (16);
   p_type          NUMBER;
   c_count0        NUMBER;
   c_count1        NUMBER;
   c_count2        NUMBER;
   c_count3        NUMBER;
   c_count4        NUMBER;
   c_count         NUMBER;
   station_num     VARCHAR2 (32);
   e_error         EXCEPTION;
BEGIN
   p_type := action_type;
   c_loc := loc;
   c_feeder := feeder;
   c_kpn := hhpn;
   res := 'OK';

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

   IF p_type = '1'
   THEN
      BEGIN
         IF res = 'OK'
         THEN
            INSERT INTO sfism4.r_smt_log_t
                        (station_number, machine_code, product_no, ver,
                         emp_no, feeder_no, key_part_no, work_time, sn,
                         line_name, lot_no
                        )
                 VALUES ('111', c_machine, ppn, ver,
                         emp, c_loc, pkg, ttime, 'N/A',
                         line, loc
                        );
                        
           

            SELECT COUNT (*)
              INTO c_count
              FROM smtinfo.r_smt_pkgid_log_t
             WHERE machine_code = c_machine
               AND product_no = ppn
               AND trail_no = c_loc
               AND state_flag = 'N';

            IF c_count > 0
            THEN
               UPDATE smtinfo.r_smt_pkgid_log_t
                  SET state_flag = 'C',
                      end_time = ttime
                WHERE machine_code = c_machine
                  AND product_no = ppn
                  AND trail_no = c_loc
                  AND state_flag = 'N'
                  AND pkg_id <> pkg;
            END IF;

            SELECT COUNT (*)
              INTO c_count3
              FROM smtinfo.r_smt_pkgid_log_t
             WHERE pkg_id = pkg
               AND machine_code = c_machine
               AND product_no = ppn
               AND trail_no = c_loc
               AND (state_flag = 'N' OR state_flag = 'C');

            IF c_count3 = 0
            THEN
               INSERT INTO smtinfo.r_smt_pkgid_log_t
                           (station_number, machine_code, product_no,
                            emp_no, feeder_no, trail_no, key_part_no,
                            begin_time, end_time, line_name, pkg_id,
                            state_flag, feeder_state
                           )
                    VALUES (station_num, c_machine, ppn,
                            emp, c_feeder, c_loc, c_kpn,
                            ttime, '', line, pkg,
                            'N', ''
                           );
            END IF;
         END IF;
      END;
   ELSIF (p_type = '2' OR p_type = '3')
   THEN
      BEGIN
                      
           -- ****ADD TZS 2018-08-04 *********              
           
            IF p_type = '2'
            THEN
                UPDATE IQC.R_KPN_INCOMING_T
                  SET QTY = Quantity                     
                WHERE PKG_ID = pkg;
            END IF;
            
             -- ****ADD TZS 2018-08-04 *********              
           
            IF p_type = '3'
            THEN
               UPDATE IQC.R_KPN_INCOMING_T
                  SET QTY = Quantity                     
                WHERE PKG_ID = pkg;
            END IF;
              
           
          -- ****ADD TZS 2018-08-04 *********     
      
         
          SELECT COUNT (*)
           INTO c_count4
           FROM smtinfo.r_smt_pkgid_log_t
          WHERE pkg_id = TRIM (pkg);
      if c_count4 > 0 then
      
         SELECT COUNT (*)
           INTO c_count0
           FROM smtinfo.r_smt_pkgid_log_t
          WHERE pkg_id = TRIM (pkg)
                AND (state_flag = 'N' OR state_flag = 'C');

         IF c_count0 > 0
         THEN
            UPDATE smtinfo.r_smt_pkgid_log_t
               SET state_flag = 'Y',
                   end_time = ttime
             WHERE pkg_id = TRIM (pkg)
               AND (state_flag = 'N' OR state_flag = 'C');

            res := 'OK';
         end if;
      ELSE
           res := 'PKG IS NOT LOADING';
            RAISE e_error;
         END IF;

         res := 'OK';

         SELECT COUNT (*)
           INTO c_count1
           FROM smtinfo.r_smt_pkgid_log_t
          WHERE pkg_id = TRIM (pkg)
                AND (state_flag = 'N' OR state_flag = 'C');

         IF c_count1 > 0
         THEN
            SELECT machine_code, trail_no
              INTO c_machinecode, c_trailno
              FROM smtinfo.r_smt_pkgid_log_t
             WHERE (state_flag = 'N' OR state_flag = 'C') AND ROWNUM = 1;

            --RES:='THE PKG ID HAS NOT BE CLOSED,PLEASE CLOSED FIRSTLY';
            res :=
                  'PLEASE GOTO MACHINE:'
               || c_machinecode
               || ';TRAIL:'
               || c_trailno
               || ' TO CLOSE FIRST';
            RAISE e_error;
         END IF;
      END;
   ELSE
      res := 'ASM ACTION_TYPE ERROR';
      RAISE e_error;
   END IF;
EXCEPTION
   WHEN e_error
   THEN
      NULL;
   --INSERT_ERROR_MES(STATION_NUM,C_MACHINE,PPN,VER,EMP,C_LOC,PKG,LOC,LINE,RES);
   WHEN OTHERS
   THEN
      ROLLBACK;
      res := 'OTHER ERROR ' || SUBSTR (SQLERRM, 1, 50);
--INSERT_ERROR_MES(STATION_NUM,C_MACHINE,PPN,VER,EMP,C_LOC,PKG,LOC,LINE,RES);
END;