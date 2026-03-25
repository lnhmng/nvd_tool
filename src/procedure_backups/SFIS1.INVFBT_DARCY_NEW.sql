PROCEDURE       INVFBT_DARCY_NEW (
    machine_code     IN    VARCHAR2 := '',
    model_name       IN    VARCHAR2 := '',
    barcode          IN    VARCHAR2 := '',
    testtime_begin   IN    VARCHAR2 := '',
    testtime_end     IN    VARCHAR2 := '',
    result           IN    VARCHAR2 := '',
    retest           IN    VARCHAR2 := '',
    worksched        IN    VARCHAR2 := '',
    emp              IN    VARCHAR2 := '',
    errorcode        IN    VARCHAR2 := '',
    end_flag         IN    VARCHAR2 := '',
    diag             IN    VARCHAR2 := '',
    ecid             IN    VARCHAR2 := '',
    marketname       IN    VARCHAR2 := '',
    mem_vendor       IN    VARCHAR2 := '',
    mem_part         IN    VARCHAR2 := '',
    mem_datecode     IN    VARCHAR2 := '',
    mac              IN    VARCHAR2 := '',
    teststation      IN    VARCHAR2 := '',
    linename         IN    VARCHAR2 := '',
    res              OUT   VARCHAR2
) AS

    v_station_count   NUMBER(1);
    v_mo_number       VARCHAR(32);
    v_emp_count       number;
    v_model_name      VARCHAR(32);
    v_group_name      VARCHAR2(32);
    v_station_name    VARCHAR2(32);
    v_section_name    VARCHAR2(32);
    v_station_code    VARCHAR2(32);
    v_pcb_count1      NUMBER(1);
    v_pcb_count2      NUMBER(1);
    v_islock          VARCHAR(32);
    v_link_count      NUMBER(1);
    v_mo_count        NUMBER(1);
    v_close_flag      VARCHAR(32);
    v_ecnf            VARCHAR2(2);
    v_ecnp            VARCHAR2(2);
    p_end1            VARCHAR2(32);
    p_start           VARCHAR2(32);
    v_fail_desc       VARCHAR2(200);
    v_fail_desc1      VARCHAR2(50);
    v_fail_desc2      VARCHAR2(50);
    v_fail_desc3      VARCHAR2(50);
    v_ipos            VARCHAR2(32);
    v_fixid           VARCHAR2(32);
    v_fixid_temp      VARCHAR2(32);
    v_is_number       NUMBER(1);
    v_test_count      NUMBER(1);
    p_date                  DATE;
    p_workdate              VARCHAR2 (8);
    p_worksect              NUMBER (2, 0);
    p_worktime              VARCHAR2 (6);

    e_error EXCEPTION;
    e_mo_error EXCEPTION;
    CURSOR kpsn_cursor IS
    SELECT
        kp_sn
    FROM
        sfism4.r_kp_sn_t
    WHERE
        serial_number = barcode
        AND location LIKE 'PCBA%';

BEGIN 

    p_date := SYSDATE;
    p_workdate := TO_CHAR (p_date, 'YYYYMMDD');
    p_worksect := TO_NUMBER (TO_CHAR (p_date, 'HH24'));
    p_worktime := TO_CHAR (p_date, 'HH24MISS');

    IF barcode IS NULL THEN
        res := 'WRONG FILE FORMAT: THE SN IS NULL!';
        RAISE e_error;
    END IF;
    IF NOT ( substr(result,0,1) = 'F' OR substr(result,0,1) = 'P' ) THEN
        res := 'WRONG FILE FORMAT: THE FORMAT OF RESULT IS WRONG!';
        RAISE e_error;
    END IF;

    IF retest IS NULL THEN
        res := 'FixtureID CAN NOT BE EMPTY!';
        RAISE e_error;
    END IF;
--    IF result = 'F' OR result = 'Fail' OR result = 'FAIL' THEN
    IF substr(result,0,1) = 'F' THEN 
        IF errorcode IS NULL THEN
            res := 'errorcode CAN NOT BE EMPTY!';
            RAISE e_error;
        END IF;
    END IF;

    IF teststation IS NULL THEN
        res := 'WRONG FILE FORMAT: THE TESTSTATION IS NULL!';
        RAISE e_error;
    END IF;

    --CHECK SN
    check_sn(barcode, res);
    IF res <> 'OK' THEN
        RAISE e_error;
    END IF;

--    check_emp_all(emp, teststation, res);
--    IF res <> 'OK' THEN
--        RAISE e_error;
--    END IF;   

SELECT COUNT(*) into v_emp_count  FROM SFIS1.c_emp_desc_t WHERE EMP_NO = emp;
    IF v_emp_count < 0 THEN
        res:='NO EMP';
        RAISE e_error;
    END IF;  

    SELECT
        COUNT(*)
    INTO v_station_count
    FROM
        sfis1.c_ict_station_t
    WHERE
        group_name = teststation
        AND line_name = linename;

    IF v_station_count < 1 THEN
        res := 'NO STATION!';
        RAISE e_error;
    ELSE
        SELECT
            station_code,
            group_name,
            station_name,
            section_name
        INTO
            v_station_code,
            v_group_name,
            v_station_name,
            v_section_name
        FROM
            sfis1.c_ict_station_t
        WHERE
            group_name = teststation
            AND line_name = linename;

    END IF;

    SELECT
        COUNT(*)
    INTO v_pcb_count1
    FROM
        sfism4.r_kp_sn_t
    WHERE
        serial_number = barcode
        AND location LIKE 'PCBA%';


    IF v_pcb_count1 < 1 THEN 
        res := 'KP SN NOT BINDING';
        RAISE e_error;
    ELSE
        FOR sninfo IN kpsn_cursor LOOP
            SELECT
                COUNT(*)
            INTO v_pcb_count2
            FROM
                sfism4.r_wip_tracking_t
            WHERE
                serial_number = sninfo.kp_sn
                AND group_name = 'WAREHOUSE';

            IF v_pcb_count2 = 0 THEN   

                res := 'KP SN ERROR';
                RAISE e_error;
            END IF;
            v_pcb_count2 := NULL;
        END LOOP;
    END IF;

    SELECT
        COUNT(*)
    INTO v_mo_count
    FROM
        sfism4.r_mo_base_t
    WHERE
        mo_number IN (
            SELECT
                mo_number
            FROM
                sfism4.r_wip_tracking_t
            WHERE
                serial_number = barcode
        );

    IF v_mo_count = 1 THEN
        SELECT
            close_flag
        INTO v_close_flag
        FROM
            sfism4.r_mo_base_t
        WHERE
            mo_number IN (
                SELECT
                    mo_number
                FROM
                    sfism4.r_wip_tracking_t
                WHERE
                    serial_number = barcode
            );

    ELSE
        res := 'MO IS NOT FOUND!';
        RAISE e_error;
    END IF;

    IF v_close_flag = 3 THEN
        res := 'MO IS CLOSED';
        RAISE e_error;
    END IF;
    SELECT
        COUNT(*)
    INTO v_islock
    FROM
        web.c_sfc_status_t
    WHERE
        key_word = barcode
        AND status_name = 'LOCK';

    IF v_islock > 0 THEN 
        res := 'SN IS STOP!';
        RAISE e_error;
    END IF;    
    check_route(linename, teststation, barcode, res);
    IF res <> 'OK' THEN
        RAISE e_error;
    END IF;

    v_ipos := instr(';', retest);
    IF v_ipos = 0 THEN
        v_fixid := retest;
        IF length(v_fixid) = 5 OR length(v_fixid) = 6 THEN
            IF length(v_fixid) = 6 THEN
                SELECT
                    COUNT(*)
                INTO v_is_number
                FROM
                    dual
                WHERE
                    REGEXP_LIKE ( substr(v_fixid, 3, 4),'\d{4}' ); 

                IF v_fixid NOT LIKE 'NV%' OR v_is_number <> 1 THEN
                    res := 'FIXID FLAT ERROR!';
                    RAISE e_error;
                END IF;

            END IF;

        ELSE
            res := 'FIXID FLAT ERROR!';
            RAISE e_error;
        END IF;

    ELSE
        v_fixid := substr(retest, v_ipos + 1, length(retest) - v_ipos);

        IF length(v_fixid) = 5 OR length(v_fixid) = 6 THEN
            IF length(v_fixid) = 6 THEN
                SELECT
                    COUNT(*)
                INTO v_is_number
                FROM
                    dual
                WHERE
                    REGEXP_LIKE ( substr(v_fixid, 3, 4),'^[0-9]+$' );

                IF v_fixid NOT LIKE 'NV%' OR v_is_number <> 1 THEN
                    res := 'FIXID FLAT ERROR!';
                    RAISE e_error;
                END IF;

            END IF;

        ELSE
            res := 'FIXID FLAT ERROR!';
            RAISE e_error;
        END IF;

    END IF;

    SELECT
        nvl(ecn_pass_qty, 0),
        nvl(ecn_fail_qty, 0),
        mo_number,
        model_name
    INTO
        v_ecnp,
        v_ecnf,
        v_mo_number,
        v_model_name
    FROM
        sfism4.r_wip_tracking_t
    WHERE
        serial_number = barcode;

    p_end1 := to_char(sysdate - 1 / 24 / 60 / 60, 'yyyy-mm-dd HH24:MI:SS');
    p_start := to_char(sysdate - 1 / 24 / 60, 'yyyy-mm-dd HH24:MI:SS');
    p_start := ( substr(p_start, 1, 4)
                 || substr(p_start, 6, 2)
                 || substr(p_start, 9, 2)
                 || substr(p_start, 12, 2)
                 || substr(p_start, 15, 2)
                 || substr(p_start, 18, 2) );

    p_end1 := ( substr(p_end1, 1, 4)
                || substr(p_end1, 6, 2)
                || substr(p_end1, 9, 2)
                || substr(p_end1, 12, 2)
                || substr(p_end1, 15, 2)
                || substr(p_end1, 18, 2) );
    SELECT
        COUNT(serial_number)
    INTO v_test_count
    FROM
        sfism4.r_test_temp_t
    WHERE
        serial_number = barcode
        AND station_type = teststation;

    IF result = 'F' OR result = 'FAIL' OR result = 'Fail' THEN
        IF v_ecnf = 0 THEN
            IF v_ecnp = 0 THEN
                UPDATE sfism4.r_wip_tracking_t
                SET
                    ecn_fail_qty = 1,
                    ecn_pass_qty = 0
                WHERE
                    serial_number = barcode;

                v_ecnf := 1;
            ELSE
                UPDATE sfism4.r_wip_tracking_t
                SET
                    ecn_fail_qty = 1
                WHERE
                    serial_number = barcode;

                v_ecnf := 1;
            END IF;
        ELSE
            UPDATE sfism4.r_wip_tracking_t
            SET
                ecn_fail_qty = ecn_fail_qty + 1
            WHERE
                serial_number = barcode;

            v_ecnf := v_ecnf + 1;
        END IF;

        IF errorcode LIKE 'E%' OR errorcode LIKE '98%' THEN
            IF errorcode LIKE '98%' THEN
                SELECT
                    symptom_desc1
                INTO v_fail_desc
                FROM
                    sfis1.c_fail_ure_symptom_info
                WHERE
                    symptom_name = errorcode;

            ELSE
                SELECT
                    nvl(symptom_desc1, 'N/A')
                INTO v_fail_desc
                FROM
                    sfis1.c_fail_ure_symptom_info
                WHERE
                    symptom_name = errorcode;

/*                IF v_fail_desc = 'N/A' THEN
                    v_fail_desc := NULL;
                    IF length(errorcode) = 13 THEN
                        SELECT
                            symptom_desc1
                        INTO v_fail_desc
                        FROM
                            sfis1.c_fail_ure_symptom_info
                        WHERE
                            symptom_name LIKE 'E_________' + substr(errorcode, - 3, 3);

                    ELSIF length(errorcode) = 10 THEN
                        SELECT
                            value1
                        INTO v_fail_desc1
                        FROM
                            sfis1.c_fail_ure_symptom1
                        WHERE
                            error_type = 'Nuts'
                            AND code1 = substr(errorcode, 2, 3);

                        SELECT
                            value2
                        INTO v_fail_desc2
                        FROM
                            sfis1.c_fail_ure_symptom2
                        WHERE
                            error_type = 'Nuts'
                            AND code1 = substr(errorcode, 2, 3)
                            AND code2 = substr(errorcode, 5, 3);

                        SELECT
                            value3
                        INTO v_fail_desc3
                        FROM
                            sfis1.c_fail_ure_symptom3
                        WHERE
                            error_type = 'Nuts'
                            AND code3 = substr(errorcode, 8, 3);

                        v_fail_desc := v_fail_desc1 + ';' + v_fail_desc2 + ';' + v_fail_desc3;
                    ELSIF length(errorcode) = 20 THEN
                        SELECT
                            value1
                        INTO v_fail_desc1
                        FROM
                            sfis1.c_fail_ure_symptom1
                        WHERE
                            error_type = 'Nuts'
                            AND code1 = substr(errorcode, 2, 3);

                        SELECT
                            value2
                        INTO v_fail_desc2
                        FROM
                            sfis1.c_fail_ure_symptom2
                        WHERE
                            error_type = 'Nuts'
                            AND code1 = substr(errorcode, 2, 3)
                            AND code2 = substr(errorcode, 5, 3);

                        SELECT
                            value3
                        INTO v_fail_desc3
                        FROM
                            sfis1.c_fail_ure_symptom3
                        WHERE
                            error_type = 'Nuts'
                            AND code3 = substr(errorcode, 8, 3);

                        v_fail_desc := v_fail_desc1 + ';' + v_fail_desc2 + ';' + v_fail_desc3;
                        SELECT
                            value1
                        INTO v_fail_desc1
                        FROM
                            sfis1.c_fail_ure_symptom1
                        WHERE
                            error_type = 'SW'
                            AND code1 = substr(errorcode, 12, 3);

                        SELECT
                            value2
                        INTO v_fail_desc2
                        FROM
                            sfis1.c_fail_ure_symptom2
                        WHERE
                            error_type = 'SW'
                            AND code1 = substr(errorcode, 15, 3)
                            AND code2 = substr(errorcode, 15, 3);

                        SELECT
                            value3
                        INTO v_fail_desc3
                        FROM
                            sfis1.c_fail_ure_symptom3
                        WHERE
                            error_type = 'SW'
                            AND code3 = substr(errorcode, 18, 3);

                        v_fail_desc := v_fail_desc + ';' + v_fail_desc1 + ';' + v_fail_desc2 + ';' + v_fail_desc3;
                    END IF;

                END IF;
*/
            END IF;
        END IF;
/*
        IF v_test_count > 0 THEN 
            sfis1.stn_rec_z (linename,
                                v_section_name,
                                teststation,
                                v_station_name,
                                v_mo_number,
                                barcode,
                                p_workdate,
                                p_worksect,
                                '1');
            INSERT INTO sfism4.r_test_temp_t VALUES (
                barcode,
                '1000',
                to_char(sysdate, 'YYYYMMDD'),
                to_char(sysdate, 'HH24MISS'),
                substr(result,0,1),
                errorcode,
                v_model_name,
                teststation,
                '0',
                emp,
                '',
                v_fail_desc,
                v_mo_number,
                '',
                '',
                '',
                '',
                p_start,
                p_end1,
                v_station_code
            );

            INSERT INTO sfism4.r_repair_t (
                serial_number,
                model_name,
                mo_number,
                test_time,
                test_code,
                test_station,
                test_line,
                tester,
                record_type
            ) VALUES (
                barcode,
                v_model_name,
                v_mo_number,
                sysdate,
                errorcode,
                v_group_name,
                linename,
                emp,
                'T'
            );

            INSERT INTO sfism4.r_sn_fixture_t VALUES (
                barcode,
                v_fixid,
                v_group_name,
                v_station_name,
                v_station_code,
                emp,
                sysdate,
                v_model_name,
                result
            );

            UPDATE sfism4.r_wip_tracking_t
            SET
                line_name = linename,
                section_name = teststation,
                group_name = teststation,
                station_name = teststation,
                error_flag = '1',
                pass_qty = 0,
                fail_qty = 1,
                in_station_time = sysdate,
                emp_no = emp
            WHERE
                serial_number = barcode;

            IF diag IS NOT NULL OR diag <> '' THEN
                SELECT
                    COUNT(*)
                INTO v_link_count
                FROM
                    sfism4.r_link_t
                WHERE
                    serial_number = barcode
                    AND available = '0'
                    AND group_name = teststation;

                IF v_link_count > 0 THEN
                    UPDATE sfism4.r_link_t
                    SET
                        available = '1',
                        last_edit_by = emp,
                        last_edit_dt = sysdate,
                        group_name = teststation,
                        key_value = diag
                    WHERE
                        serial_number = barcode;

                ELSE
                    INSERT INTO sfism4.r_link_t (SERIAL_NUMBER,KEY_VALUE,AVAILABLE,FLAG,CREATE_BY,CREATE_DT,LAST_EDIT_BY,LAST_EDIT_DT,GROUP_NAME) VALUES (
                        barcode,
                        diag,
                         '0',
                         'DIAG',
                        emp,
                        sysdate,
                        emp,
                        sysdate,
                        teststation  
                    );

                END IF;
            END IF;  
            res := 'OK';
*/            
        IF ( v_ecnf = 1 AND v_ecnp = 0 AND teststation IN (
            'MP QUICK SWITCH',
            'FUSING'
        ) ) THEN
            sfis1.stn_rec_z (linename,
                                v_section_name,
                                teststation,
                                v_station_name,
                                v_mo_number,
                                barcode,
                                p_workdate,
                                p_worksect,
                                '1');
            INSERT INTO sfism4.r_test_temp_t VALUES (
                barcode,
                '1000',
                to_char(sysdate, 'YYYYMMDD'),
                to_char(sysdate, 'HH24MISS'),
                substr(result,0,1),
                errorcode,
                v_model_name,
                teststation,
                '0',
                emp,
                '',
                v_fail_desc,
                v_mo_number,
                '',
                '',
                '',
                '',
                p_start,
                p_end1,
                v_station_code
            );

            INSERT INTO sfism4.r_repair_t (
                serial_number,
                model_name,
                mo_number,
                test_time,
                test_code,
                test_station,
                test_line,
                tester,
                record_type
            ) VALUES (
                barcode,
                v_model_name,
                v_mo_number,
                sysdate,
                errorcode,
                v_group_name,
                linename,
                emp,
                'T'
            );

            INSERT INTO sfism4.r_sn_fixture_t VALUES (
                barcode,
                v_fixid,
                v_group_name,
                v_station_name,
                v_station_code,
                emp,
                sysdate,
                v_model_name,
                result
            );

            UPDATE sfism4.r_wip_tracking_t
            SET
                line_name = linename,
                section_name = teststation,
                group_name = teststation,
                station_name = teststation,
                error_flag = '1',
                pass_qty = 0,
                fail_qty = 1,
                in_station_time = sysdate,
                emp_no = emp
            WHERE
                serial_number = barcode;

            IF diag IS NOT NULL OR diag <> '' THEN
                SELECT
                    COUNT(*)
                INTO v_link_count
                FROM
                    sfism4.r_link_t
                WHERE
                    serial_number = barcode
                    AND available = '0'
                    AND group_name = teststation;

                IF v_link_count > 0 THEN
                    UPDATE sfism4.r_link_t
                    SET
                        available = '1',
                        last_edit_by = emp,
                        last_edit_dt = sysdate,
                        group_name = teststation,
                        key_value = diag
                    WHERE
                        serial_number = barcode;

                ELSE
                    INSERT INTO sfism4.r_link_t (SERIAL_NUMBER,KEY_VALUE,AVAILABLE,FLAG,CREATE_BY,CREATE_DT,LAST_EDIT_BY,LAST_EDIT_DT,GROUP_NAME) VALUES (
                        barcode,
                        diag,
                         '0',
                         'DIAG',
                        emp,
                        sysdate,
                        emp,
                        sysdate,
                        teststation  
                    );
                END IF;       
            END IF;
           res := 'OK';
        ELSIF ( v_ecnf = 1 AND v_ecnp = 0 AND teststation NOT IN (
            'MP QUICK SWITCH',
            'FUSING'
        ) ) THEN  
            INSERT INTO sfism4.h_test_temp_t VALUES (
                barcode,
                '1000',
                to_char(sysdate, 'YYYYMMDD'),
                to_char(sysdate, 'HH24MISS'),
                substr(result,0,1),
                errorcode,
                v_model_name,
                teststation,
                '0',
                emp,
                '',
                v_fail_desc,
                v_mo_number,
                '',
                '',
                '',
                '',
                p_start,
                p_end1,
                v_station_code
            );

            INSERT INTO sfism4.h_repair_t (
                serial_number,
                model_name,
                mo_number,
                test_time,
                test_code,
                test_station,
                test_line,
                tester,
                record_type
            ) VALUES (
                barcode,
                v_model_name,
                v_mo_number,
                sysdate,
                errorcode,
                v_group_name,
                linename,
                emp,
                'T'
            );

            INSERT INTO sfism4.h_sn_fixture_t VALUES (
                barcode,
                v_fixid,
                v_group_name,
                v_station_name,
                v_station_code,
                emp,
                sysdate
            );

            IF diag IS NOT NULL OR diag <> '' THEN
                SELECT
                    COUNT(*)
                INTO v_link_count
                FROM
                    sfism4.h_link_t
                WHERE
                    serial_number = barcode
                    AND available = '0'
                    AND group_name = teststation;

                IF v_link_count > 0 THEN
                    UPDATE sfism4.h_link_t
                    SET
                        available = '1',
                        last_edit_by = emp,
                        last_edit_dt = sysdate,
                        group_name = teststation,
                        key_value = diag
                    WHERE
                        serial_number = barcode;

                ELSE
                    INSERT INTO sfism4.h_link_t(SERIAL_NUMBER,KEY_VALUE,AVAILABLE,FLAG,CREATE_BY,CREATE_DT,LAST_EDIT_BY,LAST_EDIT_DT,GROUP_NAME) VALUES (
                        barcode,
                        diag,
                         '0',
                         'DIAG',
                        emp,
                        sysdate,
                        emp,
                        sysdate,
                        teststation  
                    );

                END IF;      
            END IF;      
        ELSIF ( v_ecnf >= 2 OR v_ecnp <> 0 ) THEN 
         sfis1.stn_rec_z (linename,
                                v_section_name,
                                teststation,
                                v_station_name,
                                v_mo_number,
                                barcode,
                                p_workdate,
                                p_worksect,
                                '1');
            INSERT INTO sfism4.r_test_temp_t VALUES (
                barcode,
                '1000',
                to_char(sysdate, 'YYYYMMDD'),
                to_char(sysdate, 'HH24MISS'),
                substr(result,0,1),
                errorcode,
                v_model_name,
                teststation,
                '0',
                emp,
                '',
                v_fail_desc,
                v_mo_number,
                '',
                '',
                '',
                '',
                p_start,
                p_end1,
                v_station_code
            );

            INSERT INTO sfism4.r_repair_t (
                serial_number,
                model_name,
                mo_number,
                test_time,
                test_code,
                test_station,
                test_line,
                tester,
                record_type
            ) VALUES (
                barcode,
                v_model_name,
                v_mo_number,
                sysdate,
                errorcode,
                v_group_name,
                linename,
                emp,
                'T'
            );

            INSERT INTO sfism4.r_sn_fixture_t VALUES (
                barcode,
                v_fixid,
                v_group_name,
                v_station_name,
                v_station_code,
                emp,
                sysdate,
                v_model_name,
                result
            );

            UPDATE sfism4.r_wip_tracking_t
            SET
                line_name = linename,
                section_name = teststation,
                group_name = teststation,
                station_name = teststation,
                error_flag = '1',
                pass_qty = 0,
                fail_qty = 1,
                in_station_time = sysdate,
                emp_no = emp
            WHERE
                serial_number = barcode;

            IF diag IS NOT NULL OR diag <> '' THEN
                SELECT
                    COUNT(*)
                INTO v_link_count
                FROM
                    sfism4.r_link_t
                WHERE
                    serial_number = barcode
                    AND available = '0'
                    AND group_name = teststation;

                IF v_link_count > 0 THEN
                    UPDATE sfism4.r_link_t
                    SET
                        available = '1',
                        last_edit_by = emp,
                        last_edit_dt = sysdate,
                        group_name = teststation,
                        key_value = diag
                    WHERE
                        serial_number = barcode;

                ELSE
                    INSERT INTO sfism4.r_link_t (SERIAL_NUMBER,KEY_VALUE,AVAILABLE,FLAG,CREATE_BY,CREATE_DT,LAST_EDIT_BY,LAST_EDIT_DT,GROUP_NAME) VALUES (
                        barcode,
                        diag,
                         '0',
                         'DIAG',
                        emp,
                        sysdate,
                        emp,
                        sysdate,
                        teststation  
                    );

                END IF;

            END IF;    
        END IF;
    END IF;
    IF result = 'P' OR result = 'PASS' OR result = 'Pass' THEN
        IF v_ecnp = 0 THEN
            IF v_ecnf = 0 THEN
                UPDATE sfism4.r_wip_tracking_t
                SET
                    ecn_fail_qty = 0,
                    ecn_pass_qty = 1
                WHERE
                    serial_number = barcode;

                v_ecnp := 1;
            ELSE
                UPDATE sfism4.r_wip_tracking_t
                SET
                    ecn_pass_qty = 1
                WHERE
                    serial_number = barcode;

                v_ecnp := 1;
            END IF;
        ELSE
            UPDATE sfism4.r_wip_tracking_t
            SET
                ecn_pass_qty = ecn_pass_qty + 1
            WHERE
                serial_number = barcode;

            v_ecnp := v_ecnp + 1;
        END IF;
        sfis1.stn_rec_z (linename,
                                v_section_name,
                                teststation,
                                v_station_name,
                                v_mo_number,
                                barcode,
                                p_workdate,
                                p_worksect,
                                '0');

        INSERT INTO sfism4.r_test_temp_t VALUES (
            barcode,
            '1000',
            to_char(sysdate, 'YYYYMMDD'),
            to_char(sysdate, 'HH24MISS'),
            substr(result,0,1),
            '0',
            v_model_name,
            teststation,
            '0',
            emp,
            '',
            '',
            v_mo_number,
            '',
            '',
            '',
            '',
            p_start,
            p_end1,
            ''
        );

        INSERT INTO sfism4.r_sn_fixture_t VALUES (
            barcode,
            retest,
            v_group_name,
            v_station_name,
            v_station_code,
            emp,
            sysdate,
            v_model_name,
            result
        );

        UPDATE sfism4.r_wip_tracking_t
        SET
            line_name = linename,
            section_name = teststation,
            group_name = teststation,
            station_name = teststation,
            error_flag = '0',
            pass_qty = 1,
            fail_qty = 0,
            ecn_fail_qty = 0,
            ecn_pass_qty = 0,
            in_station_time = sysdate,
            emp_no = emp
        WHERE
            serial_number = barcode;

        IF diag IS NOT NULL OR diag <> '' THEN
            SELECT
                COUNT(*)
            INTO v_link_count
            FROM
                sfism4.r_link_t
            WHERE
                serial_number = barcode
                AND available = '0'
                AND group_name = teststation;

            IF v_link_count > 0 THEN
                UPDATE sfism4.r_link_t
                SET
                    available = '1',
                    last_edit_by = emp,
                    last_edit_dt = sysdate,
                    group_name = teststation,
                    key_value = diag
                WHERE
                    serial_number = barcode;

            ELSE
                INSERT INTO sfism4.r_link_t (SERIAL_NUMBER,KEY_VALUE,AVAILABLE,FLAG,CREATE_BY,CREATE_DT,LAST_EDIT_BY,LAST_EDIT_DT,GROUP_NAME) VALUES (
                        barcode,
                        diag,
                         '0',
                         'DIAG',
                        emp,
                        sysdate,
                        emp,
                        sysdate,
                        teststation  
                    );
            END IF;      
        END IF;
    END IF;
EXCEPTION
    WHEN e_error THEN
        NULL;
    WHEN OTHERS THEN
        ROLLBACK;

--        res := sqlerrm ; --3??Æù?H?¡Ò?AIT????¨Ó?
        res := 'OTHER ERROR! PLEASE CALL IT!';
END INVFBT_DARCY_NEW; 