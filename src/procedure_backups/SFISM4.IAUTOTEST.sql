PROCEDURE        iautotest (
--UPDATE 2022/11/07 copy from F20SFCDB
   p_sn                     IN     VARCHAR2,
   p_station_id             IN     VARCHAR2,       ----Now is the MACHINE_CODE
   p_basic_testtime_begin   IN     VARCHAR2,
   p_basic_testtime_end     IN     VARCHAR2,
   p_result                 IN     VARCHAR2,
   p_error_code             IN     VARCHAR2,
   p_model_name             IN     VARCHAR2,  
   p_station_type           IN     VARCHAR2,
   p_work_station           IN     NUMBER,
   p_operatorid             IN     VARCHAR2,
   p_retest                 IN     VARCHAR2,
   p_faildesc               IN     VARCHAR2,
   p_diag                   IN     VARCHAR2,
   p_ecid                   IN     VARCHAR2,
   p_marketname             IN     VARCHAR2,
   p_mem_vendor             IN     VARCHAR2,
   p_mem_part               IN     VARCHAR2,
   p_mem_datecode           IN     VARCHAR2,
   p_collect                IN     VARCHAR2,         --add tzs 2018-07-05 
   test_logname             IN     VARCHAR2,         --add tzs 2019-05-06
   DISPOSITION              IN     VARCHAR2, 
   res                         OUT VARCHAR2)
AS
   p_callres               VARCHAR2 (48);
   c_count                 NUMBER;
   p_line                  VARCHAR2 (16);
   p_section               VARCHAR2 (32);
   p_group                 VARCHAR2 (32);
   p_station               VARCHAR2 (32);
   p_lastgroup             VARCHAR2 (56);
   p_route                 NUMBER (4, 0);
   p_nextgroup             VARCHAR2 (32);
   p_nextstation           VARCHAR2 (16);
   p_state                 VARCHAR2 (1);
   p_stationname           VARCHAR2 (10);                                   --
   p_temp_ec               VARCHAR2 (100);
   p_temp_group            VARCHAR2 (32);
   v_groupres              VARCHAR2 (32);
   p_model                 VARCHAR2 (32);
   p_mo                    VARCHAR2 (32);
   p_passqty               NUMBER (1, 0);
   p_failqty               NUMBER (1, 0);
   p_checksum              VARCHAR2 (20);
   p_routetype             VARCHAR2 (25);
   p_date                  DATE;
   p_workdate              VARCHAR2 (8);
   p_worksect              NUMBER (2, 0);
   p_worktime              VARCHAR2 (6);
   p_laststntype           VARCHAR2 (20);
   p_stntype               VARCHAR2 (20);
   p_maxtesttime           VARCHAR2 (20);
   p_laststnnum            NUMBER (10);
   p_myretest              VARCHAR2 (2);
   v_initsn                VARCHAR2 (25);
   c_tempsn                VARCHAR2 (25);
   v_initsncnt             NUMBER (2, 0);
   v_bios_count            NUMBER (2, 0);
   v_maxdate               DATE;
   Pstation                VARCHAR2 (20);
   v_bios_match            NUMBER (2, 0);
   v_bios_match1           NUMBER (2, 0);
   v_checksum_match        NUMBER (2, 0);
   v_model_name            VARCHAR2 (40);
   p_bios                  VARCHAR2 (16);
   v_seppos                NUMBER (2, 0);
   v_seppos2               NUMBER (2, 0);
   -- added by songFengLiu for S000001GKK 2014-3-15
   v_biosset               NUMBER (2, 0);              -- ADD FOR BIOS CONTROL
   v_bioscnt               NUMBER (2, 0);              -- ADD FOR BIOS CONTROL
   v_sec_bios              VARCHAR2 (20);        --- ADD By Derrick 2012-11-19
   v_sncnt                 NUMBER (3, 0);
   --Modified by Alex Wang for 3UZ9-110519-01
   v_stncnt                NUMBER (2, 0);
   v_duperr                NUMBER (3, 0);
   v_count                 NUMBER;
   count11                 NUMBER;
   v_bios1                 VARCHAR2 (20);
   v_bios2                 VARCHAR2 (20);
   --TTE-070813-01--
   v_fixid                 VARCHAR2 (16);
   ipos                    NUMBER (2, 0);
   v_fixres                VARCHAR2 (50);
   --TTE-070813-01--
   v_dares                 VARCHAR2 (50);
   v_diagres               VARCHAR2 (50);
   v_diagcheckres          VARCHAR2 (50);
   v_ecidres               VARCHAR2 (50);
   v_macres                VARCHAR2 (50);
   v_ckmacres              VARCHAR2 (100);
   v_plx                   VARCHAR2 (30);
   error_code_1            VARCHAR2 (100);
   error_desc_2            VARCHAR2 (100);
   c_error_code            NUMBER;
   c_count1                NUMBER;
   c_count2                NUMBER;
   c_count3                NUMBER;
   v_rownum                NUMBER;
   tempcount               VARCHAR2 (100);
   v_bios_900set           VARCHAR2 (25);
   v_nv_bios               VARCHAR2 (25);
   v_first_bios            VARCHAR2 (25);
   v_second_bios           VARCHAR2 (25);
   v_flag                  VARCHAR2 (20);
   c_flag                  VARCHAR2 (20);
   v_last_model_name       VARCHAR2 (20);
   v_init_model_name       VARCHAR2 (20);
   V_ORDER_NUMBER          VARCHAR2 (20);
   V_collect               VARCHAR2 (100);
   V_collect2              VARCHAR2 (100);
   V_TEMP                  VARCHAR2 (100);
   V_TEMP2                 VARCHAR2 (100);
   V_VALUE                 VARCHAR2 (100);
   V_VALUE2                VARCHAR2 (100);
   ECNP                    NUMBER;
   ECNF                    NUMBER;
   ECNPP                   NUMBER;
   ECNPS                   NUMBER;
   ECNFS                   NUMBER;
   sname                   varchar2 (100);
   ECNFF                   NUMBER;
   p_end                   VARCHAR2 (100);
   p_end1                  VARCHAR2 (100);
   p_ends                  VARCHAR2 (100);
   p_start                 VARCHAR2 (100);
   p_start1                VARCHAR2 (100);

   e_compare900_error      EXCEPTION;
   e_comparenvbios_error   EXCEPTION;
   e_nocomparelist_error   EXCEPTION;
   e_modelname_error       EXCEPTION;
   e_no_flashrom           EXCEPTION;
   e_bios_modelname        EXCEPTION;
   e_access_denied         EXCEPTION;             -- REMOVE THE ACCESS CONTROL
   e_no_ec                 EXCEPTION;          -- REMOVE THE DEFECT CODE CHECK
   e_no_sn                 EXCEPTION;
   e_no_station            EXCEPTION;
   e_route_error           EXCEPTION;
   e_checksum_error        EXCEPTION;
   --TTE-070813-01--
   e_no_fix                EXCEPTION;
   e_fix_error             EXCEPTION;
   --TTE-070813-01--
   e_null                  EXCEPTION;

   --------------e_SCRAP       EXCEPTION;
   CURSOR nextgroup
   IS
      SELECT group_next
        FROM sfism4.r_wip_tracking_t a, sfis1.c_route_control_t b
       WHERE     a.serial_number = p_sn
             AND a.special_route = b.route_code
             AND b.group_name = 'BIOSCHECKFLASH'
             AND b.state_flag = a.error_flag;

   ROW                     nextgroup%ROWTYPE;
BEGIN
   v_sncnt := 0;
   v_stncnt := 0;
   p_nextgroup := '';
   p_date := SYSDATE;
   v_duperr := 0;
   v_seppos := INSTR (p_model_name, ';');
   v_seppos2 := INSTR (p_model_name, ';', v_seppos + 1);

   IF v_seppos2 > 0
   THEN
      p_bios := SUBSTR (p_model_name, v_seppos + 1, v_seppos2 - v_seppos - 1);
      v_plx :=
         TRIM (
            SUBSTR (p_model_name,
                    v_seppos2 + 1,
                    LENGTH (p_model_name) - v_seppos2));
   ELSE
      p_bios :=
         SUBSTR (p_model_name,
                 v_seppos + 1,
                 LENGTH (p_model_name) - v_seppos);
      v_plx := 'N/A';
   END IF;

   v_model_name := SUBSTR (p_model_name, 1, v_seppos - 1);
   p_stntype := p_station_type;
   p_myretest := '0';
   p_workdate := TO_CHAR (p_date, 'YYYYMMDD');
   --p_workdate :='20160902';
   p_worksect := TO_NUMBER (TO_CHAR (p_date, 'HH24'));
   p_worktime := TO_CHAR (p_date, 'HH24MISS');

   --CHECK THE SERIAL NUMBER EXSISTANCE
   SELECT COUNT (serial_number)
     INTO v_sncnt
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = p_sn;

   IF v_sncnt = 0
   THEN
      RAISE e_no_sn;
   END IF;

   --Modified by Steven Hu on 2008-03-19 for TTE-080318-01 Begin
   p_stationname := p_station_id;

   --Modified by Steven Hu on 2008-03-19 for TTE-080318-01 End
   SELECT COUNT (*)
     INTO v_stncnt
     FROM sfis1.c_ict_station_t
    WHERE station_code = p_stationname;

   IF v_stncnt = 0
   THEN
      RAISE e_no_station;
   END IF;

   IF p_result = 'P'
   THEN
      p_temp_ec := 'N/A';
   ELSE
      --add by wangzhiwei begin
      IF    SUBSTR (p_error_code, 1, 1) = 'E'
         OR SUBSTR (p_error_code, 1, 2) = '98'
      THEN
         IF SUBSTR (p_error_code, 1, 2) = '98'
         THEN
              SELECT COUNT (*)
                INTO count11
                FROM sfis1.c_error_code_t
               WHERE ERROR_CODE = p_error_code
            GROUP BY ERROR_CODE;

            IF count11 < 1
            THEN
               res := p_error_code || '' || 'NOT EXIST';
               RAISE e_null;
            END IF;
         ELSIF SUBSTR (p_error_code, 1, 1) = 'E'
         THEN
            IF INSTR (p_error_code, ';') > 0
            THEN
               SELECT SUBSTR (p_error_code, 1, INSTR (p_error_code, ';') - 1)
                 INTO error_code_1
                 FROM DUAL;

               SELECT SUBSTR (
                         p_error_code,
                         INSTR (p_error_code, ';') + 1,
                           LENGTH (p_error_code)
                         - INSTR (p_error_code, ';')
                         + 1)
                 INTO error_desc_2
                 FROM DUAL;

               SELECT COUNT (*)
                 INTO c_error_code
                 FROM sfis1.c_error_code_t
                WHERE ERROR_CODE = error_code_1;

               IF NVL (c_error_code, 0) <= 0
               THEN
                  INSERT INTO sfis1.c_error_code_t (ERROR_CODE,
                                                    error_class,
                                                    error_item,
                                                    error_degree,
                                                    ERROR_TYPE,
                                                    error_desc,
                                                    error_desc2,
                                                    degree_flag)
                       VALUES (error_code_1,
                               'C',
                               '',
                               1,
                               'E',
                               '',
                               error_desc_2,
                               '');

                  COMMIT;
               END IF;

               p_temp_ec := error_code_1;
            END IF;

            res := 'OK';
         END IF;
      ELSE
         res := 'EC error';
         RAISE e_null;
      END IF;

      IF p_temp_ec IS NULL
      THEN
         p_temp_ec := p_error_code;
      END IF;
   --add by wangzhiwei end
   END IF;

   SELECT model_name,
          mo_number,
          NVL (pass_qty, 0),
          NVL (fail_qty, 0),
          group_name,
          special_route,
          error_flag,
          next_station
     INTO p_model,
          p_mo,
          p_passqty,
          p_failqty,
          p_lastgroup,
          p_route,
          p_state,
          p_nextstation
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = p_sn;

   -- GET THE STATION TYPE OF THE LAST TEST STATION
   SELECT COUNT (serial_number)
     INTO v_sncnt
     FROM sfism4.r_test_temp_t
    WHERE serial_number = p_sn;

   IF v_sncnt <> 0
   THEN
      SELECT MAX (test_date || test_time)
        INTO p_maxtesttime
        FROM sfism4.r_test_temp_t
       WHERE serial_number = p_sn;

      SELECT station_type, work_station
        INTO p_laststntype, p_laststnnum
        FROM sfism4.r_test_temp_t
       WHERE     serial_number = p_sn
             AND (test_date || test_time) = p_maxtesttime
             AND ROWNUM = 1;

      SELECT group_name
        INTO p_group
        FROM sfis1.c_ict_station_t
       WHERE station_code = p_stationname;

      IF SUBSTR (p_laststntype, 1, 3) = 'ICT'
      THEN
         IF (p_laststntype = 'ICT_1') OR (p_laststntype = 'ICT_2') OR (p_laststntype = 'ICT_REWORK')  OR (p_laststntype = 'ICT1')  OR (p_laststntype = 'ICT2')  OR (p_laststntype = 'ICT3')
         THEN                                   ------add by lyc 20221130
            p_laststntype := p_laststntype;     
         ELSE
            p_laststntype := SUBSTR (p_laststntype, 1, 3);
         END IF;
      ELSE
         p_laststntype := p_laststntype;
      END IF;

      IF (p_group <> p_lastgroup)
      THEN
         p_laststntype := p_lastgroup;
      END IF;
   ELSE
      p_laststntype := p_lastgroup;
   END IF;

   IF SUBSTR (p_stntype, 1, 3) = 'ICT'
   THEN
      IF (p_stntype = 'ICT_1') OR (p_stntype = 'ICT_2') OR (p_stntype = 'ICT_REWORK') OR (p_stntype = 'ICT1') OR (p_stntype = 'ICT2') OR (p_stntype = 'ICT3')
      THEN                                      ------add by lyc 20221130
         p_stntype := p_stntype;                
      ELSE
         p_stntype := SUBSTR (p_stntype, 1, 3);
      END IF;
   ELSE
      p_stntype := p_stntype;
   END IF;

   SELECT station_name,
          line_name,
          section_name,
          group_name
     INTO p_station,
          p_line,
          p_section,
          p_group
     FROM sfis1.c_ict_station_t
    WHERE station_code = p_stationname;

   ----------------******add by Derrick Chow 2012-05-11 begin ***********----------
   IF (p_nextstation = 'N/A') OR (p_nextstation IS NULL)
   THEN
      res := 'OK';
   ELSE
      IF p_nextstation = p_group
      THEN
         /****** IF P_NEXTSTATION =p_STNTYPE THEN       *****/
         ------------------change by flying  2017/03/09
         res := 'OK';
      ELSE
         res := 'GOTO' || p_nextstation || 'RETEST';
         RAISE e_null;
      END IF;
   END IF;

   ----------------******add by Derrick Chow 2012-05-11 end ***********----------

   --Add by Jason Liu for TTE-090219-01 ON 2009-2-19.
   sfis1.check_line_stop (p_line,
                          p_group,
                          p_section,
                          p_sn,
                          res);

   --GET LAST SN by LINE and GROUP--

   --TTE-070813-01--
   --ICT Menu : TR8001 should not be controled--
   IF INSTR (UPPER (p_group), 'ICT') > 0
   OR INSTR (UPPER (p_group), 'MDA') > 0
   OR INSTR (UPPER (p_group), 'DBA') > 0
   OR INSTR (UPPER (p_group), 'ISP') > 0
   OR INSTR (UPPER (p_group), 'BSIA') > 0
   OR INSTR (UPPER (p_group), 'BSIB') > 0
   THEN
      p_checksum := p_retest;
        INSERT INTO sfism4.r_sn_fixture_t (serial_number,
                                            fixid,
                                            group_name,
                                            station_name,
                                            station_code,
                                            emp,
                                            in_station_time)
              VALUES (p_sn,
                      p_retest,
                      p_group,
                      p_station,
                      p_stationname,
                      p_operatorid,
                      p_date);

         COMMIT;
   ELSE
      ipos := INSTR (p_retest, ';');
      IF ipos = 0
      THEN
         p_checksum := p_retest;
      ELSE
         p_checksum := SUBSTR (p_retest, 1, ipos - 1);
         v_fixid := SUBSTR (p_retest, ipos + 1, LENGTH (p_retest) - ipos);
         sfis1.check_fixture_nv (v_fixid, v_fixres);

         IF v_fixres <> 'OK'
         THEN
            RAISE e_fix_error;
         END IF;


      END IF;

         INSERT INTO sfism4.r_sn_fixture_t (serial_number,
                                            fixid,
                                            group_name,
                                            station_name,
                                            station_code,
                                            emp,
                                            in_station_time)
              VALUES (p_sn,
                      v_fixid,
                      p_group,
                      p_station,
                      p_stationname,
                      p_operatorid,
                      p_date);

         COMMIT;
   END IF;

   --TTE-070813-01--
   p_temp_group := p_group;
   sfism4.sn_station_test (p_stntype,
                           p_laststntype,
                           p_state,
                           p_route,
                           v_groupres);
   p_nextgroup := v_groupres;

   IF (v_plx <> '0') AND (v_plx <> 'N/A')
   THEN
      IF    SUBSTR (p_stntype, 1, 8) = 'FLASHROM'
         OR SUBSTR (p_stntype, 1, 10) = 'REFLASHROM'
         OR p_stntype = 'BIOSCHECK'
      THEN
         IF p_model <> v_model_name
         THEN
            RAISE e_modelname_error;
         END IF;

         sfis1.update_plx (p_stntype,
                           p_line,
                           p_sn,
                           v_plx,
                           p_group,
                           v_model_name,
                           p_checksum,
                           p_callres);

         IF p_callres <> 'OK'
         THEN
            res := p_callres;
            RAISE e_null;
         -- Raise NULL;
         END IF;
      END IF;
   END IF;

   ---*****************  BELOW ADD FOR REFLASHROM  2004 12 7 *******************************
   IF (p_bios <> '0')
   THEN
      --add by lyc 20220607 begin
      IF    SUBSTR (p_stntype, 1, 9) = 'FLASH_BAT' 
        or  SUBSTR (p_stntype, 1, 12) = 'SECOND_FLASH'
        or  SUBSTR (p_stntype, 1, 9) = 'CHILFLASH'
        or  SUBSTR (p_stntype, 1, 9) = 'FLASH_PIC'
        or  SUBSTR (p_stntype, 1, 14) = 'SECOND_REFLASH'
        or SUBSTR (p_stntype, 1, 7) = 'INFOROM'
        or SUBSTR (p_stntype, 1, 12) = 'FLASHROM_FCT'
         or SUBSTR (p_stntype, 1, 11) = 'AURIX_FLASH'
      THEN
        SELECT COUNT (serial_number)
           INTO c_count1
           FROM sfism4.r_nvbios_model_t
          WHERE serial_number = p_sn;

          IF c_count1=0
          THEN
          INSERT INTO sfism4.r_nvbios_model_t (serial_number,
                                                    init_model_name,
                                                    first_bios,
                                                    second_bios,
                                                    last_model_name,
                                                    datetime,
                                                    reserve1,
                                                    reserve2,
                                                    flag,
                                                    group_name)
                    VALUES (p_sn,
                            v_model_name,
                            p_bios,
                            '',
                            '',
                            SYSDATE,
                            '',
                            '',
                            '0',
                            p_group);
              --add by LSC 20221121 
        ELSIF p_group in('FLASH_BAT','SECOND_FLASH','CHILFLASH','SECOND_REFLASH','INFOROM','FLASHROM_FCT','AURIX_FLASH')
        THEN
               IF (LENGTH (p_checksum) > 1 AND TRIM (p_checksum) <> '0')
            THEN
               UPDATE sfism4.r_nvbios_model_t
                  SET second_bios = p_bios,
                      datetime = SYSDATE,
                      flag = '1',
                      group_name = p_group,
                      reserve2 = p_checksum
                WHERE serial_number = p_sn;
            ELSE
               UPDATE sfism4.r_nvbios_model_t
                  SET second_bios = p_bios,
                      datetime = SYSDATE,
                      flag = '1',
                      group_name = p_group,
                      reserve2 = ''
                WHERE serial_number = p_sn;
            END IF;
          END IF;


      --add by tanrongliang 20180114 begin
      ELSIF SUBSTR (p_stntype, 1, 14) = 'BIOSCHECKFLASH'
      THEN
         SELECT COUNT (serial_number)
           INTO c_count1
           FROM sfism4.r_nvbios_model_t
          WHERE serial_number = p_sn;

         IF c_count1 = 0
         THEN
            SELECT COUNT (*)
              INTO c_count2
              FROM sfism4.r_sn_link_t
             WHERE new_sn = p_sn;

            IF c_count2 = 0
            THEN
               res := 0;
               RAISE e_null;
            END IF;

            SELECT init_sn
              INTO v_initsn
              FROM sfism4.r_sn_link_t
             WHERE new_sn = p_sn;

            SELECT COUNT (*)
              INTO c_count3
              FROM sfism4.r_nvbios_model_t a, sfism4.r_sn_link_t b
             WHERE a.serial_number = b.old_sn AND b.init_sn = v_initsn;

            IF c_count3 <= 0
            THEN
               RAISE e_no_flashrom;
            ELSE
               SELECT MAX (a.datetime)
                 INTO v_maxdate
                 FROM sfism4.r_nvbios_model_t a, sfism4.r_sn_link_t b
                WHERE a.serial_number = b.old_sn AND b.init_sn = v_initsn;

               SELECT a.serial_number
                 INTO c_tempsn
                 FROM sfism4.r_nvbios_model_t a, sfism4.r_sn_link_t b
                WHERE     a.serial_number = b.old_sn
                      AND b.init_sn = v_initsn
                      AND a.datetime = v_maxdate;
            END IF;

            SELECT COUNT (*)
              INTO c_count2
              FROM sfism4.r_nvbios_comparelist_t
             WHERE serial_number = p_sn;

            IF c_count2 > 0
            THEN
               SELECT flag, bios_nv, bios_900set
                 INTO v_flag, v_nv_bios, v_bios_900set
                 FROM sfism4.r_nvbios_comparelist_t
                WHERE serial_number = p_sn;

               IF v_flag = 'N'
               THEN
                  IF p_bios = v_bios_900set
                  THEN
                     res := 'OK';

                     IF v_nv_bios <> v_bios_900set
                     THEN
                        SELECT first_bios,
                               second_bios,
                               last_model_name,
                               init_model_name
                          INTO v_bios1,
                               v_bios2,
                               v_last_model_name,
                               v_init_model_name
                          FROM sfism4.r_nvbios_model_t
                         WHERE serial_number = c_tempsn;

                        IF v_bios2 IS NULL
                        THEN
                           INSERT
                             INTO sfism4.r_nvbios_model_t (serial_number,
                                                           init_model_name,
                                                           first_bios,
                                                           second_bios,
                                                           last_model_name,
                                                           datetime,
                                                           reserve1,
                                                           reserve2,
                                                           flag,
                                                           group_name)
                           VALUES (p_sn,
                                   v_init_model_name,
                                   v_bios_900set,
                                   '',
                                   v_last_model_name,
                                   SYSDATE,
                                   '',
                                   '',
                                   '0',
                                   'BIOSCHECKFLASH');

                           COMMIT;
                        ELSE
                           INSERT
                             INTO sfism4.r_nvbios_model_t (serial_number,
                                                           init_model_name,
                                                           first_bios,
                                                           second_bios,
                                                           last_model_name,
                                                           datetime,
                                                           reserve1,
                                                           reserve2,
                                                           flag,
                                                           group_name)
                           VALUES (p_sn,
                                   v_init_model_name,
                                   v_bios1,
                                   v_bios_900set,
                                   v_last_model_name,
                                   SYSDATE,
                                   '',
                                   '',
                                   '0',
                                   'BIOSCHECKFLASH');

                           COMMIT;
                        END IF;
                     END IF;
                  -- UPDATE SFISM4.R_NVBIOS_COMPARELIST_T SET BIOS_NV=V_BIOS_900SET,FLAG='Y',COMPARETIME=p_DATE  WHERE SERIAL_NUMBER=c_tempsn;
                  -- COMMIT;
                  ELSE
                     RAISE e_compare900_error;
                  END IF;
               ELSIF v_flag = 'Y'
               THEN
                  IF p_bios <> v_nv_bios
                  THEN
                     RAISE e_comparenvbios_error;
                  END IF;
               END IF;
            ELSE
               RAISE e_nocomparelist_error;
            END IF;
         ELSIF c_count1 > 0
         THEN
            SELECT COUNT (*)
              INTO c_count2
              FROM sfism4.r_nvbios_comparelist_t
             WHERE serial_number = p_sn;

            IF c_count2 = 1
            THEN
               SELECT flag, bios_nv, bios_900set
                 INTO v_flag, v_nv_bios, v_bios_900set
                 FROM sfism4.r_nvbios_comparelist_t
                WHERE serial_number = p_sn;

               IF v_flag = 'N'
               THEN
                  IF p_bios = v_bios_900set
                  THEN
                     res := 'OK';

                     IF v_nv_bios <> v_bios_900set
                     THEN
                        UPDATE sfism4.r_nvbios_model_t
                           SET second_bios = v_bios_900set,
                               group_name = 'BIOSCHECKFLASH',
                               datetime = SYSDATE
                         WHERE serial_number = p_sn;

                        COMMIT;
                     END IF;
                  -- UPDATE SFISM4.R_NVBIOS_COMPARELIST_T SET BIOS_NV=V_BIOS_900SET,FLAG='Y',COMPARETIME=p_DATE  WHERE SERIAL_NUMBER=c_tempsn;
                  -- COMMIT;
                  ELSE
                     RAISE e_compare900_error;
                  END IF;
               ELSIF v_flag = 'Y'
               THEN
                  IF p_bios <> v_nv_bios
                  THEN
                     RAISE e_comparenvbios_error;
                  END IF;
               END IF;
            ELSE
               RAISE e_nocomparelist_error;
            END IF;
         END IF;
      --add by tanrongliang 20180114 end
      ELSIF    SUBSTR (p_stntype, 1, 8) = 'FLASHROM'
            OR SUBSTR (p_stntype, 1, 10) = 'REFLASHROM'
      THEN
         --Modified by Alex Wang on 2010/07/27 for 26DH-100727-01 Begin--
         sfis1.check_route (p_line,
                            'REFLASHROM',
                            p_sn,
                            p_callres);

         IF SUBSTR (p_stntype, 1, 10) = 'REFLASHROM' AND p_callres = 'OK'
         THEN
            p_group := 'REFLASHROM';
            p_stntype := 'REFLASHROM';
            p_section := 'REFLASHROM';
            p_station := 'REFLASHROM';
            p_nextgroup := 'REFLASHROM';
         END IF;

         IF p_model <> v_model_name
         THEN
            RAISE e_modelname_error;
         END IF;

         SELECT COUNT (*)
           INTO v_bioscnt
           FROM sfism4.r_nvbios_model_t
          WHERE serial_number = p_sn;

         IF v_bioscnt = 0
         THEN
            IF (LENGTH (p_checksum) > 1 AND TRIM (p_checksum) <> '0')
            THEN
               INSERT INTO sfism4.r_nvbios_model_t (serial_number,
                                                    init_model_name,
                                                    first_bios,
                                                    second_bios,
                                                    last_model_name,
                                                    datetime,
                                                    reserve1,
                                                    reserve2,
                                                    flag,
                                                    group_name)
                    VALUES (p_sn,
                            v_model_name,
                            p_bios,
                            '',
                            '',
                            SYSDATE,
                            p_checksum,
                            '',
                            '0',
                            p_group);
            ELSE
               INSERT INTO sfism4.r_nvbios_model_t (serial_number,
                                                    init_model_name,
                                                    first_bios,
                                                    second_bios,
                                                    last_model_name,
                                                    datetime,
                                                    reserve1,
                                                    reserve2,
                                                    flag,
                                                    group_name)
                    VALUES (p_sn,
                            v_model_name,
                            p_bios,
                            '',
                            '',
                            SYSDATE,
                            '',
                            '',
                            '0',
                            p_group);
            END IF;
         END IF;

         IF v_bioscnt > 0
         THEN
            IF (LENGTH (p_checksum) > 1 AND TRIM (p_checksum) <> '0')
            THEN
               UPDATE sfism4.r_nvbios_model_t
                  SET second_bios = p_bios,
                      datetime = SYSDATE,
                      flag = '1',
                      group_name = p_group,
                      reserve2 = p_checksum
                WHERE serial_number = p_sn;
            ELSE
               UPDATE sfism4.r_nvbios_model_t
                  SET second_bios = p_bios,
                      datetime = SYSDATE,
                      flag = '1',
                      group_name = p_group,
                      reserve2 = ''
                WHERE serial_number = p_sn;
            END IF;
         END IF;

         /*SELECT COUNT (*)
           INTO v_biosset
           FROM sfis1.c_nv_modesc_t
          WHERE     (customer_pn = v_model_name OR l600_690_pn = v_model_name)
                AND bios_version = p_bios and L600_690_PN=L900_PN ;             --add by liujiang20250805  L600_690_PN=L900_PN  for 600 690 FC FLASH TEST BIOS check
        */                

         IF SUBSTR (p_stntype, 1, 8) = 'FLASHROM'                               --600段 嚴格BIOS管控   
         THEN
             SELECT COUNT (*)
               INTO v_biosset
               FROM sfis1.c_nv_modesc_t
              WHERE     (customer_pn = v_model_name OR l600_690_pn = v_model_name)
                    AND bios_version = p_bios and L600_690_PN=L900_PN ;          --add by liujiang20250805  L600_690_PN=L900_PN  for 600 690 FC FLASH TEST BIOS check

         ELSIF SUBSTR (p_stntype, 1, 10) = 'REFLASHROM'                           --600段和900段 普通BIOS管控
         THEN
             SELECT COUNT (*)
               INTO v_biosset
               FROM sfis1.c_nv_modesc_t
              WHERE     (customer_pn = v_model_name OR l600_690_pn = v_model_name)
                    AND bios_version = p_bios ;         

         END IF;

         IF v_biosset = 0
         THEN
            RAISE e_bios_modelname;
         END IF;

         IF (LENGTH (p_checksum) > 1 AND TRIM (p_checksum) <> '0')
         THEN
            SELECT COUNT (*)
              INTO v_count
              FROM sfis1.c_nv_modesc_t
             WHERE     (   customer_pn = v_model_name
                        OR l600_690_pn = v_model_name)
                   AND bios_version = p_bios
                   AND INSTR (check_sum, p_checksum) > 0;

            IF (v_count <= 0)
            THEN
               RAISE e_checksum_error;
            END IF;
         END IF;
      --Modified by Alex Wang on 2010/07/27 for 26DH-100727-01 End--
      ELSIF     (p_stntype <> 'ICT')
            AND (p_stntype <> 'ICT_GR')
            AND (p_stntype <> 'ICT_TR')
            AND (p_stntype <> 'SLI')
            AND (p_stntype <> 'MDA')
            AND (p_stntype <> 'DBA')
            AND (p_stntype <> 'ISP')
            AND (p_stntype <> 'BSIA')
            AND (p_stntype <> 'BSIB')
      THEN
         IF p_model <> v_model_name
         THEN
            RAISE e_modelname_error;
         END IF;

         SELECT COUNT (*)
           INTO v_bioscnt
           FROM sfism4.r_nvbios_model_t
          WHERE serial_number = p_sn;

         IF v_bioscnt = 0
         THEN
            -----------------Modified by Alex Wang on 2010/04/28 for 1SXG-100428-01 Begin
            SELECT COUNT (*)
              INTO v_initsncnt
              FROM sfism4.r_sn_link_t
             WHERE new_sn = p_sn;

            IF v_initsncnt = 0
            THEN
               res := 'CURRENT SN HAS NO BIOS;SN NOT LINK';
               RAISE e_null;
            ELSE
               SELECT init_sn
                 INTO v_initsn
                 FROM sfism4.r_sn_link_t
                WHERE new_sn = p_sn;
            END IF;

            SELECT COUNT (*)
              INTO v_bios_count
              FROM sfism4.r_nvbios_model_t a, sfism4.r_sn_link_t b
             WHERE a.serial_number = b.old_sn AND b.init_sn = v_initsn;

            IF v_bios_count = 0
            THEN
               RAISE e_no_flashrom;
            ELSE
               SELECT MAX (a.datetime)
                 INTO v_maxdate
                 FROM sfism4.r_nvbios_model_t a, sfism4.r_sn_link_t b
                WHERE a.serial_number = b.old_sn AND b.init_sn = v_initsn;

               SELECT b.model_name
                 INTO v_model_name                 --Find the right Model_Name
                 FROM sfism4.r_nvbios_model_t a, sfism4.r_sn_link_t b
                WHERE     a.serial_number = b.old_sn
                      AND b.init_sn = v_initsn
                      AND a.datetime = v_maxdate;
            END IF;
         -----------------Modified by Alex Wang on 2010/04/28 for 1SXG-100428-01 End
         END IF;

         IF v_bioscnt <> 0
         THEN
            SELECT COUNT (*)
              INTO v_bios_match
              FROM r_nvbios_model_t
             WHERE     (first_bios = p_bios OR second_bios = p_bios)
                   AND serial_number = p_sn;

            ----------- modefied by Derrick 2012-1119 begin
            IF v_bios_match = 0
            THEN
               RAISE e_bios_modelname;
            ELSE
               SELECT second_bios
                 INTO v_sec_bios
                 FROM r_nvbios_model_t
                WHERE serial_number = p_sn;

               IF (v_sec_bios IS NOT NULL)
               THEN
                  IF v_sec_bios <> p_bios
                  THEN
                     RAISE e_bios_modelname;
                  END IF;
               END IF;
            END IF;

            ----------- modefied by Derrick 2012-1119 end
            IF (LENGTH (p_checksum) > 1 AND TRIM (p_checksum) <> '0')
            THEN
               SELECT COUNT (*)
                 INTO v_checksum_match
                 FROM r_nvbios_model_t
                WHERE     (reserve1 = p_checksum OR reserve2 = p_checksum)
                      AND serial_number = p_sn;

               IF (v_checksum_match = 0)
               THEN
                  RAISE e_checksum_error;
               END IF;
            END IF;
         END IF;

         SELECT COUNT (*)
           INTO v_biosset
           FROM sfis1.c_nv_modesc_t
          WHERE     (customer_pn = v_model_name OR l600_690_pn = v_model_name)
                AND bios_version = p_bios ;             --add by liujiang20250805  L600_690_PN=L900_PN  for 600 690 FC FLASH TEST BIOS check;

         IF v_biosset = 0
         THEN
            RAISE e_bios_modelname;
         END IF;

         IF (LENGTH (p_checksum) > 1 AND TRIM (p_checksum) <> '0')
         THEN
            SELECT COUNT (*)
              INTO v_count
              FROM sfis1.c_nv_modesc_t
             WHERE     (   customer_pn = v_model_name
                        OR l600_690_pn = v_model_name)
                   AND bios_version = p_bios
                   AND INSTR (check_sum, p_checksum) > 0;

            IF (v_count <= 0)
            THEN
               RAISE e_checksum_error;
            END IF;
         END IF;
      END IF;
   END IF;

   IF (p_laststntype = 'FBT')
   THEN
      IF p_stntype = 'FBT'
      THEN
         RAISE e_route_error;
      ELSIF p_stntype <> 'FBT'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----***********************************************************************************************
   ----***********************************************************************************************
   --add by kassi bai on 2008-11-04 for TTE-081104-01 begin
   ELSIF (p_laststntype = 'BIOSCHECK')
   THEN
      IF p_stntype = 'BIOSCHECK'
      THEN
         RAISE e_route_error;           -- NEEDED TO BE REFLASHROOM BIOS CHECK
      ELSIF p_stntype <> 'BIOSCHECK'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   -- add by kassi bai on 2008-11-04 for TTE-081104-01 end
   ----***********************************************************************************************
   ----***********************************************************************************************
   ELSIF (p_laststntype = 'SCREEN')
   THEN
      IF p_stntype = 'SCREEN'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'SCREEN'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----************************************************************************************************
   ----************************************************************************************************
   ELSIF (p_laststntype = 'CRT')
   THEN
      IF p_stntype = 'CRT'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'CRT'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----********************************************************************************
   ----********************************************************************************
   ELSIF (p_laststntype = 'CCRT')
   THEN
      IF p_stntype = 'CCRT'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'CCRT'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----********************************************************************************
   --Added by Alex Wang on 2010/4/8 for 1NY8-100408-01 Begin
   ----********************************************************************************
   ELSIF (p_laststntype = 'BAT_THERMA')
   THEN
      IF p_stntype = 'BAT_THERMA'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'BAT_THERMA'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----********************************************************************************
   ----********************************************************************************
   ELSIF (p_laststntype = 'BOARD_TUNE')
   THEN
      IF p_stntype = 'BOARD_TUNE'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'BOARD_TUNE'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----********************************************************************************
   ----********************************************************************************
   ELSIF (p_laststntype = 'MEMORY_TUNE')
   THEN
      IF p_stntype = 'MEMORY_TUNE'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'MEMORY_TUNE'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----********************************************************************************
   ----********************************************************************************
   ELSIF (p_laststntype = 'CHILFLASH')
   THEN
      IF p_stntype = 'CHILFLASH'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'CHILFLASH'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----********************************************************************************
   ----********************************************************************************
   ELSIF (p_laststntype = 'FUNCTIONAL_TEST')
   THEN
      IF p_stntype = 'FUNCTIONAL_TEST'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'FUNCTIONAL_TEST'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----********************************************************************************
   ----********************************************************************************
   ELSIF (p_laststntype = 'NOISE')
   THEN
      IF p_stntype = 'NOISE'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'NOISE'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----********************************************************************************
   --Added by Alex Wang on 2010/4/8 for 1NY8-100408-01 End
   --Added by Alex Wang on 2010/3/30 for 1MF5-100330-01 Begin
   ----********************************************************************************
   ELSIF (p_laststntype = 'BI')
   THEN
      IF p_stntype = 'BI'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'BI'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----********************************************************************************
   ----********************************************************************************
   ELSIF (p_laststntype = 'EFT')
   THEN
      IF p_stntype = 'EFT'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'EFT'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----********************************************************************************
   ----********************************************************************************
   ELSIF (p_laststntype = 'OTC')
   THEN
      IF p_stntype = 'OTC'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'OTC'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----********************************************************************************
   --Added by Alex Wang on 2010/3/30 for 1MF5-100330-01 Begin
   ----********************************************************************************
   ELSIF (p_laststntype = 'LCD')
   THEN
      IF p_stntype = 'LCD'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'LCD'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----********************************************************************************
   ----********************************************************************************
   ELSIF (p_laststntype = 'SLI')
   THEN
      IF p_stntype = 'SLI'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'SLI'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----********************************************************************************
   ----********************************************************************************
   ELSIF (p_laststntype = 'LCD8030')
   THEN
      IF p_stntype = 'LCD8030'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'LCD8030'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----***************************************************************************************
   ----***************************************************************************************
   ELSIF (p_laststntype = 'LCD7020')
   THEN
      IF p_stntype = 'LCD7020'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'LCD7020'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----******************************************************************************************
   ----******************************************************************************************
   ELSIF (p_laststntype = 'HDTV')
   THEN
      IF p_stntype = 'HDTV'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'HDTV'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----*********************************************************************************************
   ----*********************************************************************************************
   ELSIF (p_laststntype = 'HDCP')
   THEN
      IF p_stntype = 'HDCP'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'HDCP'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----**********************************************************************************************
   ----**********************************************************************************************
   ELSIF (p_laststntype = 'IDT')
   THEN
      IF p_stntype = 'IDT'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'IDT'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----**********************************************************************************************
   ----**********************************************************************************************
   ELSIF (p_laststntype = 'DUAL LINK')
   THEN
      IF p_stntype = 'DUAL LINK'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'DUAL LINK'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----**********************************************************************************************
   ----**********************************************************************************************
   ELSIF (p_laststntype = 'SINGLE LINK')
   THEN
      IF p_stntype = 'SINGLE LINK'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'SINGLE LINK'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----**********************************************************************************************
   ----**********************************************************************************************
   ELSIF (p_laststntype = '40XGL')
   THEN
      IF p_stntype = '40XGL'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> '40XGL'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----*********************************************************************************************
   --Added by Kassi Bai on 2009/06/03 for PM5-090603-01 Begin
   ----**********************************************************************************************
   ELSIF (p_laststntype = 'INFOROM')
   THEN
      IF p_stntype = 'INFOROM'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'INFOROM'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----*********************************************************************************************
   --Added by Kassi Bai on 2009/06/03 for PM5-090603-01 End
   ----*********************************************************************************************
   --Added by Cunku Xing on 2009/09/08 for Y3L-090908-01 Begin
   ELSIF (p_laststntype = 'INFOROM WRITE')
   THEN
      IF p_stntype = 'INFOROM WRITE'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'INFOROM WRITE'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----*********************************************************************************************
   ----*********************************************************************************************
   ELSIF (p_laststntype = 'INFOROM CHECK')
   THEN
      IF p_stntype = 'INFOROM CHECK'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'INFOROM CHECK'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----*********************************************************************************************
   --Added by Cunku Xing on 2009/09/08 for Y3L-090908-01 End
   --Added by Alex Wang on 2011/01/24 for 36G9-110124-01 Begin
   ----********************************************************************************
   ELSIF (p_laststntype = 'FM')
   THEN
      IF p_stntype = 'FM'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'FM'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----********************************************************************************
   ----********************************************************************************
   ELSIF (p_laststntype = 'GN')
   THEN
      IF p_stntype = 'GN'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'GN'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----********************************************************************************
   ----********************************************************************************
   ELSIF (p_laststntype = 'NC')
   THEN
      IF p_stntype = 'NC'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'NC'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----********************************************************************************
   --Added by Alex Wang on 2011/01/24 for 36G9-110124-01 End
   --Added by Alex Wang on 2011/06/10 for 34NA8-110610-01 Begin
   ----********************************************************************************
   ELSIF (p_laststntype = 'POWER_CAPPING')
   THEN
      IF p_stntype = 'POWER_CAPPING'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'POWER_CAPPING'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ----********************************************************************************
   --Added by Alex Wang on 2011/06/10 for 34NA8-110610-01 End
   ----*********************************************************************************************

   ELSIF (SUBSTR (p_laststntype, 1, 2) = '5X')
   THEN
      IF p_stntype = p_laststntype
      THEN
         IF (p_failqty = 1) OR (p_passqty = 5 AND p_failqty = 0)
         THEN                                                    -- FAIED ONCE
            RAISE e_route_error;
         END IF;

         IF (p_passqty < 5 AND p_failqty = 0)
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = pass_qty + 1
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET fail_qty = fail_qty + 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         END IF;
      ELSIF p_stntype <> p_laststntype
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   -------------****************---------------------------
   --- modefied by Derrick for 5X station  2012/04/05 end
   -------------****************---------------------------

   ---------------------add by RoyTan 20170922 begin-------------------------------
   ELSIF (p_laststntype = 'OQA')
   THEN
      IF p_stntype = 'OQA'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'OQA'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ELSIF (p_laststntype = 'COQA')
   THEN
      IF p_stntype = 'COQA'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'COQA'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ELSIF (p_laststntype = 'OBA')
   THEN
      IF p_stntype = 'OBA'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'OBA'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ELSIF (p_laststntype = 'OBAT')
   THEN
      IF p_stntype = 'OBAT'
      THEN
         RAISE e_route_error;                         -- NEEDED TO BE REPAIRED
      ELSIF p_stntype <> 'OBAT'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
         ELSIF (p_laststntype = 'IOT')
   THEN
      IF p_stntype = 'IOT'
      THEN
         RAISE e_route_error;
      ELSIF p_stntype <> 'IOT'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1,
                         fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0,
                         fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   ---------------------add by RoyTan 20170922 end-------------------------------

   ----***********************************************************************************************
   --Modified by Alex Wang on 2010/05/13 for 1V4A-100513-01 Begin
   ELSIF (p_laststntype = 'OSOI')
   THEN
      IF p_stntype = 'OSOI'
      THEN
         RAISE e_route_error;
      ELSIF p_stntype <> 'OSOI'
      THEN
         IF p_group = p_nextgroup
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 1, fail_qty = 0
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = 0, fail_qty = 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      END IF;
   --Modified by Alex Wang on 2010/05/13 for 1V4A-100513-01 End
   ----***********************************************************************************************
   ELSIF (p_laststntype IN ('ICT','MDA','DBA','ISP','BSIA','BSIB'))
   THEN                      -- PROCESS THE ICT GROUP, IT'S DIFFERENT FROM FBT
      IF p_stntype =p_laststntype --IN ('ICT','MDA','DBA','ISP','BSIA','BSIB') BY yangjun20241107

      THEN
         IF (p_passqty = 0 AND p_failqty = 1)
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = p_passqty + 1
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET fail_qty = p_failqty + 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
               p_myretest := '1';
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      ELSE
         IF (p_passqty = 0 AND p_failqty = 1)
         THEN
            BEGIN
               p_nextgroup := 'ICT RETEST';
               RAISE e_route_error;
            END;
         ELSE
            IF (p_group = p_nextgroup)
            THEN
               BEGIN
                  res := 'OK';

                  IF p_result = 'P'
                  THEN
                     UPDATE sfism4.r_wip_tracking_t
                        SET pass_qty = 1, fail_qty = 0
                      WHERE serial_number = p_sn;
                  ELSIF p_result = 'F'
                  THEN
                     UPDATE sfism4.r_wip_tracking_t
                        SET pass_qty = 0, fail_qty = 1
                      WHERE serial_number = p_sn;
                  END IF;

                  COMMIT;
               END;
            ELSE
               RAISE e_route_error;
            END IF;
         END IF;
      END IF;
   ---------add by lyc 20221130 begin-----------
   ELSIF (p_laststntype = 'ICT_1')
   THEN
      IF p_stntype = 'ICT_1'
      THEN
         IF (p_passqty = 0 AND p_failqty = 1)
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = p_passqty + 1
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET fail_qty = p_failqty + 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
               p_myretest := '1';
            END;
         ELSE
            RAISE e_route_error;
         END IF;


      ELSE
         IF (p_passqty = 0 AND p_failqty = 1)
         THEN
            BEGIN
               p_nextgroup := 'ICT RETEST';
               RAISE e_route_error;
            END;
         ELSE
            IF (p_group = p_nextgroup)
            THEN
               BEGIN
                  res := 'OK';

                  IF p_result = 'P'
                  THEN
                     UPDATE sfism4.r_wip_tracking_t
                        SET pass_qty = 1, fail_qty = 0
                      WHERE serial_number = p_sn;
                  ELSIF p_result = 'F'
                  THEN
                     UPDATE sfism4.r_wip_tracking_t
                        SET pass_qty = 0, fail_qty = 1
                      WHERE serial_number = p_sn;
                  END IF;

                  COMMIT;
               END;
            ELSE
               RAISE e_route_error;
            END IF;
         END IF;
      END IF;
   ELSIF (p_laststntype = 'ICT_2')
   THEN
      IF p_stntype = 'ICT_2'
      THEN
         IF (p_passqty = 0 AND p_failqty = 1)
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = p_passqty + 1
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET fail_qty = p_failqty + 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
               p_myretest := '1';
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      ELSE
         IF (p_passqty = 0 AND p_failqty = 1)
         THEN
            BEGIN
               p_nextgroup := 'ICT RETEST';
               RAISE e_route_error;
            END;
         ELSE
            IF (p_group = p_nextgroup)
            THEN
               BEGIN
                  res := 'OK';

                  IF p_result = 'P'
                  THEN
                     UPDATE sfism4.r_wip_tracking_t
                        SET pass_qty = 1, fail_qty = 0
                      WHERE serial_number = p_sn;
                  ELSIF p_result = 'F'
                  THEN
                     UPDATE sfism4.r_wip_tracking_t
                        SET pass_qty = 0, fail_qty = 1
                      WHERE serial_number = p_sn;
                  END IF;

                  COMMIT;
               END;
            ELSE
               RAISE e_route_error;
            END IF;
         END IF;
      END IF;

     ------add by 220829 -lyc begin-------------
     ELSIF (p_laststntype = 'ICT_REWORK')
   THEN
      IF p_stntype = 'ICT_REWORK'
      THEN
         IF (p_passqty = 0 AND p_failqty = 1)
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = p_passqty + 1
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET fail_qty = p_failqty + 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
               p_myretest := '1';
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      ELSE
         IF (p_passqty = 0 AND p_failqty = 1)
         THEN
            BEGIN
               p_nextgroup := 'ICT RETEST';
               RAISE e_route_error;
            END;
         ELSE
            IF (p_group = p_nextgroup)
            THEN
               BEGIN
                  res := 'OK';

                  IF p_result = 'P'
                  THEN
                     UPDATE sfism4.r_wip_tracking_t
                        SET pass_qty = 1, fail_qty = 0
                      WHERE serial_number = p_sn;
                  ELSIF p_result = 'F'
                  THEN
                     UPDATE sfism4.r_wip_tracking_t
                        SET pass_qty = 0, fail_qty = 1
                      WHERE serial_number = p_sn;
                  END IF;

                  COMMIT;
               END;
            ELSE
               RAISE e_route_error;
            END IF;
         END IF;
      END IF;
     ------add by 220829 -lyc end-------------
     ------add by 221130-lyc begin-------------
     ELSIF (p_laststntype = 'ICT1')
   THEN
      IF p_stntype = 'ICT1'
      THEN
         IF (p_passqty = 0 AND p_failqty = 1)
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = p_passqty + 1
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET fail_qty = p_failqty + 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
               p_myretest := '1';
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      ELSE
         IF (p_passqty = 0 AND p_failqty = 1)
         THEN
            BEGIN
               p_nextgroup := 'ICT RETEST';
               RAISE e_route_error;
            END;
         ELSE
            IF (p_group = p_nextgroup)
            THEN
               BEGIN
                  res := 'OK';

                  IF p_result = 'P'
                  THEN
                     UPDATE sfism4.r_wip_tracking_t
                        SET pass_qty = 1, fail_qty = 0
                      WHERE serial_number = p_sn;
                  ELSIF p_result = 'F'
                  THEN
                     UPDATE sfism4.r_wip_tracking_t
                        SET pass_qty = 0, fail_qty = 1
                      WHERE serial_number = p_sn;
                  END IF;

                  COMMIT;
               END;
            ELSE
               RAISE e_route_error;
            END IF;
         END IF;
      END IF;

     ELSIF (p_laststntype = 'ICT2')
   THEN
      IF p_stntype = 'ICT2'
      THEN
         IF (p_passqty = 0 AND p_failqty = 1)
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = p_passqty + 1
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET fail_qty = p_failqty + 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
               p_myretest := '1';
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      ELSE
         IF (p_passqty = 0 AND p_failqty = 1)
         THEN
            BEGIN
               p_nextgroup := 'ICT RETEST';
               RAISE e_route_error;
            END;
         ELSE
            IF (p_group = p_nextgroup)
            THEN
               BEGIN
                  res := 'OK';

                  IF p_result = 'P'
                  THEN
                     UPDATE sfism4.r_wip_tracking_t
                        SET pass_qty = 1, fail_qty = 0
                      WHERE serial_number = p_sn;
                  ELSIF p_result = 'F'
                  THEN
                     UPDATE sfism4.r_wip_tracking_t
                        SET pass_qty = 0, fail_qty = 1
                      WHERE serial_number = p_sn;
                  END IF;

                  COMMIT;
               END;
            ELSE
               RAISE e_route_error;
            END IF;
         END IF;
      END IF;

     ELSIF (p_laststntype = 'ICT3')
   THEN
      IF p_stntype = 'ICT3'
      THEN
         IF (p_passqty = 0 AND p_failqty = 1)
         THEN
            BEGIN
               res := 'OK';

               IF p_result = 'P'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET pass_qty = p_passqty + 1
                   WHERE serial_number = p_sn;
               ELSIF p_result = 'F'
               THEN
                  UPDATE sfism4.r_wip_tracking_t
                     SET fail_qty = p_failqty + 1
                   WHERE serial_number = p_sn;
               END IF;

               COMMIT;
               p_myretest := '1';
            END;
         ELSE
            RAISE e_route_error;
         END IF;
      ELSE
         IF (p_passqty = 0 AND p_failqty = 1)
         THEN
            BEGIN
               p_nextgroup := 'ICT RETEST';
               RAISE e_route_error;
            END;
         ELSE
            IF (p_group = p_nextgroup)
            THEN
               BEGIN
                  res := 'OK';

                  IF p_result = 'P'
                  THEN
                     UPDATE sfism4.r_wip_tracking_t
                        SET pass_qty = 1, fail_qty = 0
                      WHERE serial_number = p_sn;
                  ELSIF p_result = 'F'
                  THEN
                     UPDATE sfism4.r_wip_tracking_t
                        SET pass_qty = 0, fail_qty = 1
                      WHERE serial_number = p_sn;
                  END IF;

                  COMMIT;
               END;
            ELSE
               RAISE e_route_error;
            END IF;
         END IF;
      END IF;
     ------add by 221130-lyc end-------------

   -------add by flying on 2017/03/16 end
   ELSE
      IF p_nextgroup <> p_group
      THEN
         RAISE e_route_error;
      ELSE
         BEGIN
            res := 'OK';

            IF p_result = 'P'
            THEN
               UPDATE sfism4.r_wip_tracking_t
                  SET pass_qty = 1, fail_qty = 0
                WHERE serial_number = p_sn;
            ELSIF p_result = 'F'
            THEN
               UPDATE sfism4.r_wip_tracking_t
                  SET pass_qty = 0, fail_qty = 1
                WHERE serial_number = p_sn;
            END IF;

            COMMIT;
         END;
      END IF;
   END IF;


   --Modified by Alex Wang on 2010/7/5 for 22H1-100705-01 Begin




            --??????  20200720
   if p_result='F'  --add by  LY 20200513  ??? F
  THEN
        select NEXT_STATION into tempcount from sfism4.r_wip_tracking_t where serial_number=p_sn;
        if (tempcount='N/A') and ( (substr(p_nextgroup,0,3)= 'ICT') or (substr(p_nextgroup,0,3)= 'MDA') or (substr(p_nextgroup,0,3)= 'DBA')  or (substr(p_nextgroup,0,3)= 'ISP')  or (substr(p_nextgroup,0,4)= 'BSIA')  or (substr(p_nextgroup,0,4)= 'BSIB') or    (substr(p_nextgroup,0,3)= 'AOI') or (substr(p_nextgroup,0,3)= 'API') ) 
   then

   p_end :=sysdate;
   p_end1 :=to_char(sysdate-1/24/60/60,'yyyy-mm-dd HH24:MI:SS');
   p_start:=to_char(sysdate-1/24/60,'yyyy-mm-dd HH24:MI:SS');
    ipos := INSTR (p_retest, ';');
    v_fixid := SUBSTR (p_retest, ipos + 1, LENGTH (p_retest) - ipos);
   p_start:=(   SUBSTR (p_start, 1, 4)
                || SUBSTR (p_start, 6, 2)
                || SUBSTR (p_start, 9, 2)
                || SUBSTR (p_start, 12, 2)
                || SUBSTR (p_start, 15, 2)
                || SUBSTR (p_start, 18, 2)
               ) ;
   p_ends := (   SUBSTR (p_end1, 1, 4)
                || SUBSTR (p_end1, 6, 2)
                || SUBSTR (p_end1, 9, 2)
                || SUBSTR (p_end1, 12, 2)
                || SUBSTR (p_end1, 15, 2)
                || SUBSTR (p_end1, 18, 2)
               );

                 INSERT INTO sfism4.h_test_temp_t (serial_number,
                                     station_id,
                                     test_date,
                                     test_time,
                                     RESULT,
                                     ERROR_CODE,
                                     model_name,
                                     station_type,
                                     work_station,
                                     OPERATOR,
                                     retest,
                                     faildesc,
                                     mo_number,
                                     market_name,
                                     mem_vendor_id,
                                     mem_part_id,
                                     mem_dc,
                                     basic_testtime_begin,
                                     basic_testtime_end,
                                     MACHINE_CODE)
        VALUES (p_sn,
                1000,
                p_workdate,
                p_worktime,
                p_result,
                p_temp_ec,
                p_model,
                p_stntype,
                p_work_station,
                p_operatorid,
                p_myretest,
                p_faildesc,
                p_mo,
                p_marketname,
                p_mem_vendor,
                p_mem_part,
                p_mem_datecode,
                p_start,
                p_ends,
                V_FIXID);

        COMMIT;

          INSERT INTO sfism4.h_sn_fixture_t (serial_number,
                                            fixid,
                                            group_name,
                                            station_name,
                                            station_code,
                                            emp,
                                            in_station_time)
              VALUES (p_sn,
                      v_fixid,
                      p_group,
                      p_station,
                      p_stationname,
                      p_operatorid,
                      p_date);

         COMMIT;





            select ECN_FAIL_QTY,ECN_PASS_QTY into ECNFS,ECNPS  from sfism4.r_wip_tracking_t where serial_number=p_sn;
           if (ECNF=1) or(ECNF>1)
        then 

        update sfism4.r_wip_tracking_t set  ECN_FAIL_QTY='0',ECN_PASS_QTY='0' where serial_number=p_sn;


             end if;

        end if;
     end if;


   --add  by  20200616       LY  ???`????????``????

       if (p_basic_testtime_begin='' or p_basic_testtime_begin is null) or(p_basic_testtime_end='' or p_basic_testtime_end is null)
       then 
     p_end :=sysdate;
     p_end1 :=to_char(sysdate-1/24/60/60,'yyyy-mm-dd HH24:MI:SS');
     p_start:=to_char(sysdate-1/24/60,'yyyy-mm-dd HH24:MI:SS');
     p_start:=(   SUBSTR (p_start, 1, 4)
                || SUBSTR (p_start, 6, 2)
                || SUBSTR (p_start, 9, 2)
                || SUBSTR (p_start, 12, 2)
                || SUBSTR (p_start, 15, 2)
                || SUBSTR (p_start, 18, 2)
               ) ;
     p_ends := (   SUBSTR (p_end1, 1, 4)
                || SUBSTR (p_end1, 6, 2)
                || SUBSTR (p_end1, 9, 2)
                || SUBSTR (p_end1, 12, 2)
                || SUBSTR (p_end1, 15, 2)
                || SUBSTR (p_end1, 18, 2)
               ) ;
    INSERT INTO sfism4.r_test_temp_t (serial_number,
                                     station_id,
                                     test_date,
                                     test_time,
                                     RESULT,
                                     ERROR_CODE,
                                     model_name,
                                     station_type,
                                     work_station,
                                     OPERATOR,
                                     retest,
                                     faildesc,
                                     mo_number,
                                     market_name,
                                     mem_vendor_id,
                                     mem_part_id,
                                     mem_dc,
                                     basic_testtime_begin,
                                     basic_testtime_end,
                                     MACHINE_CODE)
        VALUES (p_sn,
                1000,
                p_workdate,
                p_worktime,
                p_result,
                p_temp_ec,
                p_model,
                p_stntype,
                p_work_station,
                p_operatorid,
                p_myretest,
                p_faildesc,
                p_mo,
                p_marketname,
                p_mem_vendor,
                p_mem_part,
                p_mem_datecode,
                p_start,
                p_ends,
                V_FIXID);

                else 

                 INSERT INTO sfism4.r_test_temp_t (serial_number,
                                     station_id,
                                     test_date,
                                     test_time,
                                     RESULT,
                                     ERROR_CODE,
                                     model_name,
                                     station_type,
                                     work_station,
                                     OPERATOR,
                                     retest,
                                     faildesc,
                                     mo_number,
                                     market_name,
                                     mem_vendor_id,
                                     mem_part_id,
                                     mem_dc,
                                     basic_testtime_begin,
                                     basic_testtime_end,
                                     MACHINE_CODE)
        VALUES (p_sn,
                1000,
                p_workdate,
                p_worktime,
                p_result,
                p_temp_ec,
                p_model,
                p_stntype,
                p_work_station,
                p_operatorid,
                p_myretest,
                p_faildesc,
                p_mo,
                p_marketname,
                p_mem_vendor,
                p_mem_part,
                p_mem_datecode,
                p_basic_testtime_begin,
                p_basic_testtime_end,
                V_FIXID);

   COMMIT;
      end if; 
   --Modified by Alex Wang on 2010/7/5 for 22H1-100705-01 End
   --Added by Alex Wang on 2010/05/24 for 1TFE-100524-01 Begin
   sfism4.da_link (p_operatorid,
                   p_sn,
                   p_stntype,
                   v_dares);

   IF v_dares <> 'OK'
   THEN
      res := 'DA_LINK ERROR:' || v_dares;
      RAISE e_null;
   END IF;

   --Added by Alex Wang on 2010/05/24 for 1TFE-100524-01 End
   --Added by Alex Wang on 2010/5/28 for 1U13-100528-01 Begin

   ---------*************modefy by Derrick Chow*********------------

   sfis1.check_diagsbygroup (p_sn,
                             p_diag,
                             p_bios,
                             p_group,
                             p_operatorid,
                             v_diagcheckres);

   IF v_diagcheckres <> 'OK'
   THEN
      res := 'diags error:' || v_diagcheckres;
      RAISE e_null;
   END IF;



   ---------*************modefy by Derrick Chow*********------------

   --Added by Alex Wang on 2010/5/28 for 1U13-100528-01 End
   --Added by Alex Wang on 2011/2/15 for 38CP-110215-01 Begin
   IF p_ecid <> 'N/A'
   THEN
      --Modified by Felix 2017-03-27 14:30: update parameter 'group_name' from 'N/A' to p_GROUP
      sfism4.datalink (p_operatorid,
                       p_sn,
                       p_ecid,
                       p_group,
                       'ECID',
                       v_ecidres);

      IF v_ecidres <> 'OK'
      THEN
         res := 'ECID DATA_LINK ERROR:' || v_ecidres;
         RAISE e_null;
      END IF;
   END IF;



   /*
   --Added by tanzisong on 2019/5/06 for TEST_LOGNAME BEGING

     IF TEST_LOGNAME <> 'N/A'
   THEN

      sfism4.datalink (p_operatorid,
                       p_sn,
                       TEST_LOGNAME,
                       p_group,
                       'LOGNAME',
                       v_ecidres);

      IF v_ecidres <> 'OK'
      THEN
         res := 'TEST_LOGNAME DATA_LINK ERROR:' || v_ecidres;
         RAISE e_null;
      END IF;
   END IF;
   */


  --Added by tanzisong on 2019/5/06 for TEST_LOGNAME END.


 --Added by tanzisong on 2019/5/06 for TEST_LOGNAME BEGING

     IF TEST_LOGNAME <> 'N/A'
      THEN
       BEGIN
       sfism4.datalink (p_operatorid,
                       p_sn,
                       TEST_LOGNAME,
                       p_group,
                       'LOGNAME',
                       v_ecidres);

      IF v_ecidres <> 'OK'
      THEN
         res := 'TEST_LOGNAME DATA_LINK ERROR:' || v_ecidres;
         RAISE e_null;
      END IF;
     END;
    else            -- ELSE ADD 20240801 客戶提出當LOGNAME為'N/A'時，插入一條NOtestlogname record
      BEGIN  

        -- SELECT COUNT(*) INTO v_count FROM SFISM4.R_LINK_T WHERE SERIAL_NUMBER=P_SN AND GROUP_NAME=P_GROUP AND FLAG='LOGNAME';
        --  IF v_count<=0 THEN

               INSERT INTO sfism4.r_link_t
                  (serial_number, key_value, available, flag, create_by,
                   create_dt, last_edit_by, last_edit_dt, group_name
                  )
              VALUES (P_SN, 'NO TEST LOGNAME', '0', 'LOGNAME', p_operatorid,
                sysdate, '', '', P_GROUP
               );                

        --   END IF;

      END;
    END IF;

  --Added by tanzisong on 2019/5/06 for TEST_LOGNAME END.






if DISPOSITION<>'N/A'
then 
 sfism4.datalink (p_operatorid,
                       p_sn,
                       DISPOSITION,
                       p_group,
                       'DISPOSITION',
                       v_ecidres);

      IF v_ecidres <> 'OK'
      THEN
         res := 'DISPOSITION DATA_LINK ERROR:' || v_ecidres;
         RAISE e_null;
      END IF;
END IF;



--Added by luoyang  on 2019/10/30 for luoyang END.

-- **********by  2018-07-04 tzs add -***************************8--
-- **********by  2018-07-04 tzs add -***************************8--

  IF LENGTH(p_collect)>0 AND p_collect<>'N/A' THEN 

        IF INSTR(p_collect,'|')>0 THEN
           begin
              V_collect:=substr(p_collect,1,instr(p_collect,'|')-1);
              V_collect2:=substr(p_collect,instr(p_collect,'|')+1,length(P_collect)-instr(P_collect,'|'));

              if length(V_collect)>0 and INSTR(V_collect,':')>0 then              

               BEGIN
                  V_TEMP:=substr(V_collect,1,instr(V_collect,':')-1);
                  V_VALUE:=substr(V_collect,instr(V_collect,':')+1,length(V_collect)-instr(V_collect,':')); 

                 SFISM4.DATALINK(p_OPERATORID,p_SN,V_VALUE,p_group,V_TEMP,v_MACRES);                  

                   IF (v_MACRES<>'OK') THEN
                         RES := v_MACRES||'(RUN SFISM4.DATALINK ERROR)';
                         RAISE e_NULL;
                    END IF;                     


               END;
               END IF; 


              if length(V_collect2)>0 and INSTR(V_collect2,':')>0 then
               BEGIN
                    V_TEMP2:=substr(V_collect2,1,instr(V_collect2,':')-1);
                    V_VALUE2:=substr(V_collect2,instr(V_collect2,':')+1,length(V_collect2)-instr(V_collect2,':')); 

                   SFISM4.DATALINK(p_OPERATORID,p_SN,V_VALUE2,p_group,V_TEMP2,v_MACRES);                  

                     IF (v_MACRES<>'OK') THEN  
                         RES := v_MACRES||'(RUN SFISM4.DATALINK ERROR)';
                          RAISE e_NULL;
                     END IF; 

               END;
               END IF; 

           end;           

         else

           begin

              if length(p_collect)>0 and INSTR(p_collect,':')>0 then              

               BEGIN
                  V_TEMP:=substr(p_collect,1,instr(p_collect,':')-1);
                  V_VALUE:=substr(p_collect,instr(p_collect,':')+1,length(p_collect)-instr(p_collect,':')); 
                  -- SFISM4.DATALINK(p_OPERATORID,p_SN,p_collect,'N/A','MAC',v_MACRES);

                   SFISM4.DATALINK(p_OPERATORID,p_SN,V_VALUE,p_group,V_TEMP,v_MACRES);                  

                   IF (v_MACRES<>'OK') THEN
                          RES := v_MACRES||'(RUN SFISM4.DATALINK ERROR)';
                          RAISE e_NULL;
                     END IF;                     


               END;
               END IF; 
           end;     

           end IF;  


      END IF;     


   --Added by Alex Wang on 2011/2/15 for 38CP-110215-01 End
   SELECT pass_qty, fail_qty
     INTO p_passqty, p_failqty
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = p_sn;

   IF p_result = 'P'
   THEN
      --IF (p_STNTYPE<>'5XOQA') THEN
      IF (SUBSTR (p_stntype, 1, 2) <> '5X')
      THEN                          -------MODEFIED BY Derrick chow 2012/04/05
         IF    (p_passqty = 1 AND p_failqty = 0)
            OR (p_passqty = 2 AND p_failqty = 1)
         THEN
            BEGIN
               sfis1.stn_rec_z (p_line,
                                p_section,
                                p_group,
                                p_station,
                                p_mo,
                                p_sn,
                                p_workdate,
                                p_worksect,
                                '0');
               sfis1.update_r107 (p_operatorid,
                                  p_line,
                                  p_section,
                                  p_group,
                                  p_station,
                                  p_mo,
                                  p_sn,
                                  '0',
                                  p_date);
               sfis1.update_rlsa_h (p_sn,
                                    p_line,
                                    p_temp_group,
                                    p_mo,
                                    p_temp_ec,
                                    res);
               res := 'OK';
            END;
         ELSIF (p_passqty = 1 AND p_failqty = 1)
         THEN
            IF    (p_stntype = 'ICT')
               OR (p_stntype = 'ICT_1')
               OR (p_stntype = 'ICT_2')
               OR (p_stntype = 'ICT_REWORK')
               OR (p_stntype = 'ICT1')
               OR (p_stntype = 'ICT2')
               OR (p_stntype = 'ICT3')
               OR (p_stntype = 'MDA')
               OR (p_stntype = 'DBA')
               OR (p_stntype = 'ISP')
               OR (p_stntype = 'BSIA')
               OR (p_stntype = 'BSIB')
            THEN                               --add by from lyc 20221130
               BEGIN
                  sfis1.stn_rec_z (p_line,
                                   p_section,
                                   p_group,
                                   p_station,
                                   p_mo,
                                   p_sn,
                                   p_workdate,
                                   p_worksect,
                                   '0');
                  sfis1.update_r107 (p_operatorid,
                                     p_line,
                                     p_section,
                                     p_group,
                                     p_station,
                                     p_mo,
                                     p_sn,
                                     '0',
                                     p_date);
                  sfis1.update_rlsa_h (p_sn,
                                       p_line,
                                       p_temp_group,
                                       p_mo,
                                       p_temp_ec,
                                       res);
                  res := 'OK';
               END;
            END IF;
         END IF;
      ELSE
         IF (p_passqty = 5 AND p_failqty = 0)
         THEN
            sfis1.stn_rec_z (p_line,
                             p_section,
                             p_group,
                             p_station,
                             p_mo,
                             p_sn,
                             p_workdate,
                             p_worksect,
                             '0');
            sfis1.update_r107 (p_operatorid,
                               p_line,
                               p_section,
                               p_group,
                               p_station,
                               p_mo,
                               p_sn,
                               '0',
                               p_date);
            sfis1.update_rlsa_h (p_sn,
                                 p_line,
                                 p_temp_group,
                                 p_mo,
                                 p_temp_ec,
                                 res);
            res := 'OK';
         ELSIF (p_passqty < 5 AND p_failqty = 0)
         THEN
            UPDATE sfism4.r_wip_tracking_t
               SET line_name = p_line,
                   section_name = p_section,
                   group_name = p_group,
                   station_name = p_station,
                   in_station_time = p_date,
                   next_station = 'N/A',
                   error_flag = '0',
                   emp_no = p_operatorid
             WHERE serial_number = p_sn;

            DELETE FROM sfism4.r_sn_detail_t
                  WHERE in_station_time = p_date AND serial_number = p_sn;

            COMMIT;
            res := 'OK';
         END IF;
      END IF;
   ELSIF p_result = 'F'
   THEN
      BEGIN
         --IF (p_STNTYPE<>'5XOQA') THEN
         IF (SUBSTR (p_stntype, 1, 2) <> '5X')
         THEN                       -------MODEFIED BY Derrick chow 2012/04/05
            IF    (p_failqty = 2 AND p_passqty = 1)
               OR (p_failqty = 2 AND p_passqty = 0)
            THEN
               sfis1.stn_rec_z (p_line,
                                p_section,
                                p_group,
                                p_station,
                                p_mo,
                                p_sn,
                                p_workdate,
                                p_worksect,
                                '1');
               sfis1.update_r107 (p_operatorid,
                                  p_line,
                                  p_section,
                                  p_group,
                                  p_station,
                                  p_mo,
                                  p_sn,
                                  '1',
                                  p_date);

               INSERT INTO sfism4.r_repair_t (serial_number,
                                              mo_number,
                                              test_time,
                                              test_code,
                                              test_station,
                                              test_line,
                                              record_type,
                                              model_name)
                    VALUES (p_sn,
                            p_mo,
                            p_date,
                            p_temp_ec,
                            p_station,
                            p_line,
                            'T',
                            p_model);

               COMMIT;
               sfis1.update_rlsa_h (p_sn,
                                    p_line,
                                    p_temp_group,
                                    p_mo,
                                    p_temp_ec,
                                    res);
            ELSIF (p_failqty = 1 AND p_passqty = 0)
            THEN
               --Modified by Alex Wang on 2010/03/22 for 1MG4-100324-01 Begin
               IF (   p_stntype = 'ICT' --OR p_STNTYPE='OQA' OR p_STNTYPE='COQA' OR p_STNTYPE='OBA' OR p_STNTYPE='OBAT')
                   OR p_stntype = 'ICT_1'
                   OR p_stntype = 'ICT_2'
                   OR p_stntype = 'ICT_REWORK'
                   OR p_stntype = 'ICT1'
                   OR p_stntype = 'ICT2'
                   OR p_stntype = 'ICT3'
                   OR p_stntype = 'MDA'
                   OR p_stntype = 'DBA'
                   OR p_stntype = 'ISP'
                   OR p_stntype = 'BSIA'
                   OR p_stntype = 'BSIB')
               THEN                            --add by from Lyc 20221130
                  --Modified by Alex Wang on 2010/03/22 for 1MG4-100324-01 End
                  ---     ************ -Modified by  Derrick Chow 2012/05/10 begin for 0000005PFSFS******************* ------------
                  UPDATE sfism4.r_wip_tracking_t
                     SET line_name = p_line,
                         section_name = p_section,
                         group_name = p_group,
                         station_name = p_station,
                         in_station_time = p_date,
                         -- NEXT_STATION='N/A',
                         next_station = p_stntype,
                         emp_no = p_operatorid
                   WHERE mo_number = p_mo AND serial_number = p_sn;

                  COMMIT;

                  DELETE FROM sfism4.r_sn_detail_t
                        WHERE     in_station_time = p_date
                              AND serial_number = p_sn;

                  --       COMMIT;
                  ---     ************ -Modified by  Derrick Chow 2012/05/10 end for 0000005PFSFS******************* ------------

                  -- ADD BY derrick for0 000005QBK 2012/01/06---------
                  INSERT INTO sfism4.h_repair_t (serial_number,
                                                 mo_number,
                                                 test_time,
                                                 test_code,
                                                 test_station,
                                                 test_line,
                                                 record_type,
                                                 model_name)
                       VALUES (p_sn,
                               p_mo,
                               p_date,
                               p_temp_ec,
                               p_station,
                               p_line,
                               'T',
                               p_model);

                  sfis1.update_rlsa_h (p_sn,
                                       p_line,
                                       p_temp_group,
                                       p_mo,
                                       p_temp_ec,
                                       res);
                  COMMIT;
               -- ADD BY derrick for0 000005QBK 2012/01/06---------
               ELSE
                  sfis1.stn_rec_z (p_line,
                                   p_section,
                                   p_group,
                                   p_station,
                                   p_mo,
                                   p_sn,
                                   p_workdate,
                                   p_worksect,
                                   '1');
                  sfis1.update_r107 (p_operatorid,
                                     p_line,
                                     p_section,
                                     p_group,
                                     p_station,
                                     p_mo,
                                     p_sn,
                                     '1',
                                     p_date);

                  INSERT INTO sfism4.r_repair_t (serial_number,
                                                 mo_number,
                                                 test_time,
                                                 test_code,
                                                 test_station,
                                                 test_line,
                                                 record_type,
                                                 model_name)
                       VALUES (p_sn,
                               p_mo,
                               p_date,
                               p_temp_ec,
                               p_station,
                               p_line,
                               'T',
                               p_model);

                  sfis1.update_rlsa_h (p_sn,
                                       p_line,
                                       p_temp_group,
                                       p_mo,
                                       p_temp_ec,
                                       res);
               END IF;

               COMMIT;
            END IF;

            res := 'OK';
         ELSE
            IF (p_failqty = 1)
            THEN
               sfis1.stn_rec_z (p_line,
                                p_section,
                                p_group,
                                p_station,
                                p_mo,
                                p_sn,
                                p_workdate,
                                p_worksect,
                                '1');
               sfis1.update_r107 (p_operatorid,
                                  p_line,
                                  p_section,
                                  p_group,
                                  p_station,
                                  p_mo,
                                  p_sn,
                                  '1',
                                  p_date);

               INSERT INTO sfism4.r_repair_t (serial_number,
                                              mo_number,
                                              test_time,
                                              test_code,
                                              test_station,
                                              test_line,
                                              record_type,
                                              model_name)
                    VALUES (p_sn,
                            p_mo,
                            p_date,
                            p_temp_ec,
                            p_station,
                            p_line,
                            'T',
                            p_model);

               sfis1.update_rlsa_h (p_sn,
                                    p_line,
                                    p_temp_group,
                                    p_mo,
                                    p_temp_ec,
                                    res);
               COMMIT;
            END IF;

            res := 'OK';
         END IF;
      END;
   END IF;

   IF res = 'OK'
   THEN
      -- IF (p_STNTYPE<>'5XOQA') THEN
      IF (SUBSTR (p_stntype, 1, 2) <> '5X')
      THEN                          -------MODEFIED BY Derrick chow 2012/04/05
         IF (p_passqty = 1 AND p_failqty = 0)
         THEN
            res := '0';
         ELSIF p_passqty = 1 AND p_failqty = 1
         THEN
            IF    (p_stntype = 'ICT')
               OR (p_stntype = 'ICT_1')
               OR (p_stntype = 'ICT_2')
               OR (p_stntype = 'ICT_REWORK')
               OR (p_stntype = 'ICT1')
               OR (p_stntype = 'ICT2')
               OR (p_stntype = 'ICT3')
               OR (p_stntype = 'MDA')
               OR (p_stntype = 'DBA')
               OR (p_stntype = 'ISP')
               OR (p_stntype = 'BSIA')
               OR (p_stntype = 'BSIB')
            THEN                               --add by from lyc 20221130
               res := '0';
            ELSE
               res := '0';
            END IF;
         ELSIF p_passqty = 1 AND p_failqty = 2
         THEN
            res := '1';
         -- IT SHOULD BE FBT FAIL,NOT ICT, ICT NEEDS 2 TIMES TEST  AT MOST
         ELSIF p_passqty = 2 AND p_failqty = 1
         THEN
            res := '0';                  -- SHOULD PASS WHEN PASS 2 TIMES TEST
         ELSIF p_passqty = 0 AND p_failqty = 1
         THEN
            --Modified by Alex Wang on 2010/03/22 for 1MG4-100324-01 Begin
            IF (   p_stntype = 'ICT'
                OR p_stntype = 'ICT_1'
                OR p_stntype = 'ICT_2'
                OR p_stntype = 'ICT_REWORK'
                OR p_stntype = 'ICT1'
                OR p_stntype = 'ICT2'
                OR p_stntype = 'ICT3'
                OR p_stntype = 'MDA'
                OR p_stntype = 'DBA'
                OR p_stntype = 'ISP'
                OR p_stntype = 'BSIA'
                OR p_stntype = 'BSIB')
            THEN                               --add by from lyc 20221130
               --Modified by Alex Wang on 2010/03/22 for 1MG4-100324-01 End
               res := '2';
            ELSE
               res := '1';
            END IF;
         ELSIF p_passqty = 0 AND p_failqty = 2
         THEN
            res := '1';
         END IF;
      ELSE
         IF (p_passqty = 5 AND p_failqty = 0)
         THEN
            res := '0';
         END IF;

         IF (p_passqty < 5 AND p_failqty = 0)
         THEN
            res := '2';
         END IF;

         IF (p_failqty = 1)
         THEN
            res := '1';
         END IF;
      END IF;
   END IF;
EXCEPTION
   WHEN e_null
   THEN
      NULL;
   WHEN e_modelname_error
   THEN
      BEGIN
         res := 'WRONG MODEL_NAME  PM:' || p_model || '  OM:' || v_model_name;
      END;
   WHEN e_no_flashrom
   THEN
      BEGIN
         res := 'BIOS NOT FLASH';
      END;
   WHEN e_bios_modelname
   THEN
      BEGIN
         res := 'BIOS NOT MATCH MODEL_NAME';
      END;
   WHEN e_checksum_error
   THEN
      BEGIN
         res := 'CHECKSUM ERROR';
      END;
   WHEN e_no_sn
   THEN
      BEGIN
         res := 'NO SN';
      END;
   --TTE-070813-01--

   WHEN e_no_fix
   THEN
      BEGIN
         res := 'NO FIXTURE';
      END;
   WHEN e_fix_error
   THEN
      BEGIN
         res := v_fixres;
      END;
   --TTE-070813-01--

   WHEN e_access_denied
   THEN
      res := p_callres;
   WHEN e_no_station
   THEN
      BEGIN
         res := 'NO STATION';
      END;
   WHEN e_route_error
   THEN
      BEGIN
         IF p_nextgroup = 'RETEST'
         THEN
            res := '2';
         ELSIF SUBSTR (p_nextgroup, 1, 2) = 'R_'
         THEN
            res := 'GOTO-' || p_nextgroup;
         ELSE
            BEGIN
               IF SUBSTR (p_nextgroup, 1, 4) <> 'GOTO'
               THEN
                  p_nextgroup := 'GOTO-' || p_nextgroup;
               END IF;

               res := p_nextgroup;
            END;
         END IF;
      END;
   WHEN e_no_ec
   THEN
      res := p_callres;
   --add by tanrongliang 20180111 begin
   WHEN e_compare900_error
   THEN
      BEGIN
         res := 'Current BIOS not the same with 900INPUTS';
      END;
   WHEN e_comparenvbios_error
   THEN
      BEGIN
         res := 'Current BIOS not the same with NVBIOS';
      END;

   WHEN NO_DATA_FOUND
   THEN
      IF p_nextgroup IS NULL
      THEN
         res := 'ROUTE ERROR';
      ELSIF p_routetype IS NULL
      THEN
         res := 'NO ROUTE';
      ELSE
         res := 'INPUT ERROR';
      END IF;
   WHEN OTHERS
   THEN
      res := SUBSTR (SQLERRM, 1, 100);
END;

/* ******************************************************
FOR: TEST MACHINE DATA AUTO TRANSFER

RES:
0- OK
1- REPAIR
2- RETEST
3- BIOS DOES NOT MATCH THE MODEL_NAME
******************************************************** */
