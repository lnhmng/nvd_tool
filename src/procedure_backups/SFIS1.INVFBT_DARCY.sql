PROCEDURE       invfbt_darcy (
    machine_code     IN    VARCHAR2 := '',--ini模式中系SFC機台號;Web Service模式中不使用
    model_name       IN    VARCHAR2 := '',--MODEL_NAME,料號 Web Service不使用
    barcode          IN    VARCHAR2 := '',--序列號
    testtime_begin   IN    VARCHAR2 := '',--BASIC_TESTTIME_BEGIN
    testtime_end     IN    VARCHAR2 := '',--BASIC_TESTTIME_END
    result           IN    VARCHAR2 := '',--測試結果: P/PASS or F/FAIL
    retest           IN    VARCHAR2 := '', --ini模式中系固定格式: 0;机器編碼(0;NV0084);Web Service模式中系FixtureID: NV0084
    worksched        IN    VARCHAR2 := '',--BIOS
    emp              IN    VARCHAR2 := '',--作業員工賬號
    errorcode        IN    VARCHAR2 := '',--Error_code
    end_flag         IN    VARCHAR2 := '',--ini模式中系固定格式: **END**;Web Service模式中不使用
    diag             IN    VARCHAR2 := '',--DIAG EDITION
    ecid             IN    VARCHAR2 := '',--ECID	
    marketname       IN    VARCHAR2 := '',
    mem_vendor       IN    VARCHAR2 := '',
    mem_part         IN    VARCHAR2 := '',
    mem_datecode     IN    VARCHAR2 := '',--MEMORY_DATACODE
    mac              IN    VARCHAR2 := '',--MAC (FOR 'CAR')
    teststation      IN    VARCHAR2 := '',--測試工站名
    linename         IN    VARCHAR2 := '',--測試線別名
    res              OUT   VARCHAR2
) AS

    v_station_count   INT(1);
    v_mo_number       VARCHAR(32);
    v_model_name      VARCHAR(32);
    v_group_name      VARCHAR2(32);
    v_station_name    VARCHAR2(32);
    v_station_code    VARCHAR2(32);
    v_pcb_count1      INT(1);
    v_pcb_count2      INT(1);
    v_islock          VARCHAR(32);
    v_link_count      INT(1);
    v_mo_count        INT(1);
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
    v_is_number       INT(1);
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
    --判斷參數是否為空或是否符合規範
    IF barcode IS NULL THEN
        res := 'WRONG FILE FORMAT: THE SN IS NULL!';
        RAISE e_error;
    END IF;
    IF NOT ( result = 'P' OR result = 'PASS' OR result = 'F' OR result = 'FAIL' ) THEN
        res := 'WRONG FILE FORMAT: THE FORMAT OF RESULT IS WRONG!';
        RAISE e_error;
    END IF;

    IF retest IS NULL THEN
        res := 'FixtureID CAN NOT BE EMPTY!';
        RAISE e_error;
    END IF;
    IF result = 'F' OR result = 'FAIL' THEN
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

    --check工號權限
    check_emp_v3(emp, teststation, res);
    IF res <> 'OK' THEN
        RAISE e_error;
    END IF;   	 

    --判斷測試工站是否存在
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
            station_name
        INTO
            v_station_code,
            v_group_name,
            v_station_name
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

    IF v_pcb_count1 < 1 THEN    --判斷是否存在KP SN綁定信息是否存在()
        res := 'KP SN NOT BINDING！';
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

            IF v_pcb_count2 = 0 THEN    --判斷KP SN是否完工
                res := 'KP SN不存在或未完工！';
                RAISE e_error;
            END IF;
            v_pcb_count2 := NULL;
        END LOOP;
    END IF;

    --判斷工單狀態
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

  ---判斷SN是否處於鎖定狀態  
    SELECT
        COUNT(*)
    INTO v_islock
    FROM
        web.c_sfc_status_t
    WHERE
        key_word = barcode
        AND status_name = 'LOCK';

    IF v_islock > 0 THEN --判斷SN是否被鎖定
        res := 'SN IS STOP!';
        RAISE e_error;
    END IF;    

    --檢查路由是否正確
    check_route(linename, teststation, barcode, res);
    IF res <> 'OK' THEN
        RAISE e_error;
    END IF;

    --判斷FixtureID
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
                    REGEXP_LIKE ( substr(v_fixid, 3, 4),
                                  '\d{4}' ); --判斷字符串是否為純數字

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
                    REGEXP_LIKE ( substr(v_fixid, 3, 4),
                                  '^[0-9]+$' ); --判斷字符串是否為純數字

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

    IF result = 'F' OR result = 'FAIL' THEN
        --標記fail、pass
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

        ---根據不良代碼，生成failDesc

        IF errorcode LIKE 'E%' OR errorcode LIKE '98%' THEN
            IF errorcode LIKE '98%' THEN
                SELECT
                    symptom_desc1
                INTO v_fail_desc
                FROM
                    sfis1.c_fail_ure_symptom_into
                WHERE
                    symptom_name = errorcode;

            ELSE
                SELECT
                    nvl(symptom_desc1, 'N/A')
                INTO v_fail_desc
                FROM
                    sfis1.c_fail_ure_symptom_into
                WHERE
                    symptom_name = errorcode;

                IF v_fail_desc = 'N/A' THEN
                    v_fail_desc := NULL;
                    IF length(errorcode) = 13 THEN
                        SELECT
                            symptom_desc1
                        INTO v_fail_desc
                        FROM
                            sfis1.c_fail_ure_symptom_into
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

            END IF;

        END IF;

        IF ( v_ecnf = 1 AND v_ecnp = 0 AND teststation IN (
            'MP QUICK SWITCH',
            'OQA UXT'          --MP QUICK SWITCH第一次不良，直接送修
        ) ) THEN
            INSERT INTO sfism4.r_test_temp_t VALUES (
                barcode,
                '1000',
                to_char(sysdate, 'YYYYMMDD'),
                to_char(sysdate, 'HH24MISS'),
                result,
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
                retest
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
                error_flag = '1',
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
                    INSERT INTO sfism4.r_link_t VALUES (
                        barcode,
                        '0',
                        'DIAG',
                        emp,
                        sysdate,
                        emp,
                        sysdate,
                        teststation,
                        diag
                    );

                END IF;

            END IF;

            res := 'OK';
        ELSIF ( v_ecnf = 1 AND v_ecnp = 0 AND teststation NOT IN (
            'MP QUICK SWITCH',
            'OQA UXT'
        ) ) THEN  ---非MP QUICK SWITCH工站，第一次不良提示重測
            INSERT INTO sfism4.h_test_temp_t VALUES (
                barcode,
                '1000',
                to_char(sysdate, 'YYYYMMDD'),
                to_char(sysdate, 'HH24MISS'),
                result,
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
                v_fixid
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
                    INSERT INTO sfism4.h_link_t VALUES (
                        barcode,
                        '0',
                        'DIAG',
                        emp,
                        sysdate,
                        emp,
                        sysdate,
                        teststation,
                        diag
                    );

                END IF;

            END IF;

        ELSIF ( v_ecnf >= 2 OR v_ecnp <> 0 ) THEN --第二次不良，直接送修
            INSERT INTO sfism4.r_test_temp_t VALUES (
                barcode,
                '1000',
                to_char(sysdate, 'YYYYMMDD'),
                to_char(sysdate, 'HH24MISS'),
                result,
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
                retest
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
                error_flag = '1',
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
                    INSERT INTO sfism4.r_link_t VALUES (
                        barcode,
                        '0',
                        'DIAG',
                        emp,
                        sysdate,
                        emp,
                        sysdate,
                        teststation,
                        diag
                    );

                END IF;

            END IF;

        END IF;

    END IF;

    IF result = 'P' OR result = 'PASS' THEN
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

        INSERT INTO sfism4.r_test_temp_t VALUES (
            barcode,
            '1000',
            to_char(sysdate, 'YYYYMMDD'),
            to_char(sysdate, 'HH24MISS'),
            result,
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
            retest
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
            in_station_time = sysdate,
            emp_no = emp
        WHERE
            serial_number = barcode;

        IF diag IS not NULL OR diag <> '' THEN
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
                INSERT INTO sfism4.r_link_t VALUES (
                    barcode,
                    '0',
                    'DIAG',
                    emp,
                    sysdate,
                    emp,
                    sysdate,
                    teststation,
                    diag
                );

            END IF;

        END IF;

    END IF;

    res := 'OK';
EXCEPTION
    WHEN e_error THEN
        NULL;
    WHEN OTHERS THEN
        ROLLBACK;
        res := 'OTHER ERROR! PLEASE CALL IT!';
END;