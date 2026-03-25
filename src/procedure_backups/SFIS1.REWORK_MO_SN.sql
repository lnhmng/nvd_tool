PROCEDURE       rework_mo_sn (
    line      IN    VARCHAR2,
    sn        IN    VARCHAR2,
    mygroup   IN    VARCHAR2,
    mo        IN    VARCHAR2,
    emp       IN    VARCHAR2,
    res       OUT   VARCHAR2
) IS

    d_mo      VARCHAR2(32);
    set_qty   NUMBER;--ADD 20220819 CZ
    d_qty     NUMBER;
    t_qty     NUMBER;
    v_model   VARCHAR2(32);
    v_qty     NUMBER;
    v_route   VARCHAR2(32);
    s_group   VARCHAR2(32);
    n_group   VARCHAR2(32);--GROUP_NAME NOW
    n_model   VARCHAR2(32);--model_NAME NOW
    n_next    VARCHAR2(32);
    v_group   VARCHAR2(32);
    v_part    VARCHAR2(32);
    v_po      VARCHAR2(32);
    set_group VARCHAR2(32);--ADD 20220819 CZ
    e_error EXCEPTION;
BEGIN
    SELECT model_name,target_qty,route_code,key_part_no,po_no,default_group INTO v_model,v_qty,v_route,v_part,v_po,s_group FROM sfism4.r_mo_base_t WHERE mo_number = mo;

    SELECT group_name INTO v_group FROM(SELECT * FROM sfis1.c_route_control_t WHERE route_code = v_route AND group_next = s_group ORDER BY step_sequence) WHERE ROWNUM = 1;

    SELECT COUNT(*) INTO t_qty FROM sfism4.r_wip_tracking_t WHERE mo_number = mo AND station_name <> '0';

    IF t_qty >= v_qty THEN
        res := 'MO QTY FULL';
        RAISE e_error;
    END IF;
    SELECT mo_number, group_name,model_name,next_station INTO d_mo, n_group ,n_model,n_next FROM sfism4.r_wip_tracking_t WHERE serial_number = sn;
    --next_station‘STOP’
    IF n_next = 'STOP' THEN
        res := 'SN LOCK,PLEASE FIND IPQC!';
        RAISE e_error;
    END IF;
--RUANSHIQIAO ADD 20260107
    SELECT COUNT(*) INTO D_QTY FROM sfism4.r_wip_tracking_t WHERE serial_number = sn AND error_flag='1';
    --ERROR_FLAG ‘1’ BULIANG
    IF D_QTY>0 THEN
        res := 'SN FAIL! PLEASE FIND FA CHECK_OUT';
        RAISE e_error;
    END IF;

--RUANSHIQIAO END  ADD 20260107
    IF d_mo = mo THEN
        sfis1.check_route(line, mygroup, sn, res);
    ELSE
  --SELECT COUNT(*) INTO D_QTY FROM SFISM4.r_sn_detail_t WHERE SERIAL_NUMBER = SN AND GROUP_NAME LIKE 'S_VI%';
  --IF D_QTY <1 THEN
  --RES := 'SN NO S_VI GROUP,CANNOT REWORK';
  --RAISE E_ERROR;
  --END IF;  
        SELECT count(*) into set_qty FROM SFISM4.R_REWORK_MO_MODEL_T WHERE REWORK_MO = mo and sn_model = n_model;
        if set_qty <=0 then
            res := 'MO NOT SET'|| n_model || ',TO NNMS SET THE MO';
            RAISE e_error;
        END IF;

        SELECT GROUP_NOW into set_group FROM SFISM4.R_REWORK_MO_MODEL_T WHERE REWORK_MO = mo and sn_model = n_model;
        if set_group <> 'N/A' THEN
            IF SET_GROUP <> n_group then
                res := 'GROUP'|| n_group ||'ERROR:SET GROUP IS' || SET_GROUP;
            RAISE e_error;
            end if;
        END IF;

        IF v_part = ''  THEN
            UPDATE sfism4.r_wip_tracking_t
            SET mo_number = mo,
                model_name = v_model,
                section_name = mygroup,
                group_name = v_group,
                station_name = mygroup,
                special_route = v_route,
                in_station_time = sysdate,  
                error_flag='0',
                --po_no = v_po,
                emp_no = emp,
                line_name = line,
                carton_no = 'N/A',
                pallet_no = 'PN/A',
                container_no = 'N/A'
            WHERE serial_number = sn;
        ELSE
            UPDATE sfism4.r_wip_tracking_t
            SET mo_number = mo,
                model_name = v_model,
                section_name = mygroup,
                group_name = v_group,
                station_name = mygroup,
                special_route = v_route,
                error_flag='0',
                in_station_time = sysdate,
                key_part_no = v_part,
                --po_no = v_po,
                emp_no = emp,
                line_name = line,
                carton_no = 'N/A',
                pallet_no = 'PN/A',
                container_no = 'N/A'
            WHERE serial_number = sn;

        END IF;
        DELETE sfism4.r_wip_tracking_t WHERE mo_number = mo AND group_name = '0' AND ROWNUM = 1;
        res := 'OK';


    END IF;

EXCEPTION
    WHEN e_error THEN
        NULL;
    WHEN OTHERS THEN
        res := 'OTHER ERROR [REWORK_MO_SN]';
END rework_mo_sn;