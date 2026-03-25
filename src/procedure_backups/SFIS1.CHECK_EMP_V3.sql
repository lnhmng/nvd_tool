PROCEDURE       check_emp_v3 (
    emp       IN    VARCHAR2,
    mygroup   IN    VARCHAR2,
    res       OUT   VARCHAR2
) AS
    l_empno           VARCHAR2(12);
    l_station_name    NUMBER;
    l_station_group   VARCHAR2(18);
BEGIN
    SELECT
        emp_no,
        group_id
    INTO
        l_empno,
        l_station_name
    FROM
        sfis1.c_emp_desc_t
    WHERE
        emp_no = emp
        AND ROWNUM = 1;

    SELECT
        station_group
    INTO l_station_group
    FROM
        sfis1.c_priv_t
    WHERE
        group_id = l_station_name
        AND station_group = mygroup;   	--AND STATION_PRIV=FUNC;

    res := 'OK';
EXCEPTION
    WHEN OTHERS THEN
        BEGIN
            IF l_empno IS NULL THEN
                res := 'NO EMP';
            ELSIF l_station_group IS NULL THEN
                res := 'ACCESS DENIED';
            ELSE
                res := 'EXCEPTION!|UNDO';
            END IF;

        END;
END;

/* ************************************************************

   CREATRD BY: SUN FANRONG
   CREATE DATE: SEPT 13,2002
   UPDATE DATA: SEPT 13,2002
   FUNCTION: FOR ICT, FBT, ICT518,SMT PRIVILEGE CONTROL.

***************************************************************/