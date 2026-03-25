PROCEDURE                               IPQC_REPAIR(
       EMP IN VARCHAR2,
	   DATA IN VARCHAR2,
	   RES OUT VARCHAR2 ) AS

BEGIN

    UPDATE SFISM4.R_WIP_TRACKING_T
	SET ERROR_FLAG='0',NEXT_STATION='N/A'
	WHERE SERIAL_NUMBER=DATA;

	INSERT INTO sfism4.r_sn_detail_t
    SELECT
        serial_number,
        section_flag,
        mo_number,
        model_name,
        type,
        version_code,
        line_name,
        section_name,
        group_name,
        station_name,
        location,
        station_seq,
        error_flag,
        in_station_time,
        in_line_time,
        out_line_time,
        shipping_sn,
        work_flag,
        finish_flag,
        enc_cnt,
        special_route,
        pallet_no,
        container_no,
        qa_no,
        qa_result,
        scrap_flag,
        next_station,
        customer_no,
        work_date,
        work_section,
        pass_qty,
        fail_qty,
        repass_qty,
        refail_qty,
        ecn_pass_qty,
        ecn_fail_qty,
        key_part_no,
        carton_no,
        warranty_date,
        bom_no,
        po_no,
        rework_no,
        emp_no,
        da_no,
        bugfix,
        eco_no
    FROM
        sfism4.r_wip_tracking_t
		  WHERE SERIAL_NUMBER=DATA;

    COMMIT;

	RES:='OK';

	EXCEPTION
	    WHEN OTHERS THEN
	    RES:='Error Happened,Please Retry.';
END;