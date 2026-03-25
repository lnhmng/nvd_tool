PROCEDURE       get_beftest_inf_darcy (
    barcode   IN    VARCHAR2,
    res       OUT   VARCHAR2
) AS

    ressnout         VARCHAR2(32);
    p_sn             VARCHAR2(32);
    p_mo             VARCHAR2(20);
    p_model_name     VARCHAR2(32);
    p_error_flag     VARCHAR2(2);
    p_version_code   VARCHAR2(2);
    p_mo_closed   NUMBER;
    p_group_name     VARCHAR2(32);
    p_route_code     VARCHAR2(32);
    p_next_station   VARCHAR2(40);
    resrouteout      VARCHAR2(250);
    e_null EXCEPTION;
    e_error EXCEPTION;
BEGIN
   ------------ Check sn-------------------
    sfis1.check_sn(trim(barcode), ressnout);
    IF ressnout <> 'OK' THEN
        res := ressnout;
        RAISE e_null;
    END IF;
    SELECT
        mo_number,
        version_code,
        error_flag,
        special_route,
        group_name,
        model_name
    INTO
        p_mo,
        p_version_code,
        p_error_flag,
        p_route_code,
        p_group_name,
        p_model_name
    FROM
        sfism4.r_wip_tracking_t
    WHERE
        serial_number = barcode;

    SELECT
        nvl( close_flag,0)
    INTO p_mo_closed
    FROM
        sfism4.r_mo_base_t
    WHERE
        mo_number = p_mo;

    IF p_mo_closed = 3 THEN
        resrouteout := 'WO' + p_mo + 'is Cancelled';
    ELSIF p_error_flag = '1' THEN
        resrouteout := 'Waiting for Repair';
    ELSE
        SELECT
            nvl(group_next,'N/A')
        INTO p_next_station
        FROM
            sfis1.c_route_control_t
        WHERE
            route_code = p_route_code
            AND group_name = p_group_name
            AND STATE_FLAG =0
            AND rownum = 1;

        resrouteout := 'GO-' || p_next_station;
    END IF;

    res := barcode || '#' || p_model_name || '#' || resrouteout || '#' || p_version_code;
EXCEPTION
    WHEN e_null THEN
        NULL;
--    WHEN OTHERS THEN
--        res := 'OTHER ERROR!';
END get_beftest_inf_darcy;