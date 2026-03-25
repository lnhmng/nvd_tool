PROCEDURE       check_route_yu_lock (
    mygroup   IN    VARCHAR2,
    data      IN    VARCHAR2,
    res       OUT   VARCHAR2
) AS
    lock_qty   NUMBER;
    lock_emp   VARCHAR2(25);
    e_error EXCEPTION;
BEGIN
    SELECT
        COUNT(*)
    INTO lock_qty
    FROM
        sfism4.r_sn_lock_unlock_t
    WHERE
        serial_number = data
        AND lock_group_name = mygroup
        AND lockflag = 'LOCK';

    IF lock_qty <= 0 THEN
        res := 'OK';
    ELSE
        SELECT
            name
        INTO lock_emp
        FROM
            sfism4.r_sn_lock_unlock_t
        WHERE
            serial_number = data
            AND lock_group_name = mygroup
            AND lockflag = 'LOCK'
            AND ROWNUM = 1;

        res := 'SN IS LOCK AT '
               || mygroup
               || ' FOR '
               || lock_emp;
        RAISE e_error;
    END IF;

EXCEPTION
    WHEN e_error THEN
        NULL;
    WHEN OTHERS THEN
        res := 'OTHER ERROR[CHECK_ROUTE_YU_LOCK]';
END;