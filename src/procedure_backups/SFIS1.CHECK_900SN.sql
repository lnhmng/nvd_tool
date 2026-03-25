PROCEDURE       CHECK_900SN (DATA   IN     VARCHAR2,
                                           MYGROUP IN VARCHAR2,
                           LINE  IN VARCHAR2,
                                            RES       OUT VARCHAR2)
AS
   C_ID      VARCHAR2 (25);
   C_900ID   VARCHAR2 (25);
   C_901ID   VARCHAR2 (25);
   C_MODEL   VARCHAR (25);
   C_NEXTGROUP VARCHAR(25);
   C_NUM3 VARCHAR(25);
   v_count  NUMBER;
   v_list   VARCHAR2(100);
   e_ERROR   EXCEPTION;
   e_ERROR2   EXCEPTION;
   e_ERROR3   EXCEPTION;
BEGIN

    SELECT SERIAL_NUMBER
       INTO C_ID
       FROM SFISM4.R_WIP_TRACKING_T
      WHERE SERIAL_NUMBER = DATA
   GROUP BY SERIAL_NUMBER;

   SELECT SUBSTR(SERIAL_NUMBER,0,3)
       INTO C_901ID
       FROM SFISM4.R_WIP_TRACKING_T
      WHERE SERIAL_NUMBER = DATA
   GROUP BY SERIAL_NUMBER;

   SELECT NUM2 INTO C_NUM3 
   FROM SFIS1.C_PTH_T 
   WHERE LINE_NAME=LINE 
   AND STATION_NAME=MYGROUP;

   IF (C_NUM3 = '') OR (C_NUM3 <> C_901ID) OR (C_NUM3 IS NULL) THEN
       RAISE   e_ERROR2;  
   ELSIF C_NUM3 = C_901ID THEN
       RES := 'OK';
   END IF;

   SELECT KEY_PART_NO INTO C_MODEL FROM SFISM4.R_WIP_TRACKING_T WHERE SERIAL_NUMBER = DATA;

   IF C_MODEL = '900-2G183-0100-000' AND MYGROUP='900_INPUT'
   THEN
           SELECT SUBSTR (SERIAL_NUMBER, 6, 2)
                  INTO C_900ID
                  FROM SFISM4.R_WIP_TRACKING_T
                 WHERE SERIAL_NUMBER = DATA
              GROUP BY SERIAL_NUMBER;
               IF C_900ID < 19
                THEN
                     RAISE e_ERROR;
    END IF;
   END IF;
 -- RUANSHIQIAO ADD 20251128  S0000YHK6
   v_list := '';

    SELECT COUNT(*)
        INTO v_count
        FROM (
            SELECT GROUP_NAME
            FROM SFISM4.R_SN_DETAIL_T
            WHERE SERIAL_NUMBER = DATA AND UPPER(STATION_NAME) NOT LIKE '%REWORK%'
            AND  NOT (
             UPPER(GROUP_NAME) LIKE 'OQA%'
              OR UPPER(GROUP_NAME) LIKE 'BIOSCHECK%'
              OR UPPER(GROUP_NAME) LIKE 'SECOND_FLASH%'
              OR UPPER(GROUP_NAME) LIKE '900%'
              OR UPPER(GROUP_NAME) LIKE 'SFQC%'
              OR UPPER(GROUP_NAME) LIKE 'SIQA%'
	      OR UPPER(GROUP_NAME) LIKE '%LOCK%'
             )
            GROUP BY GROUP_NAME
            HAVING 
                SUM(CASE WHEN ERROR_FLAG = '1' THEN 1 ELSE 0 END) > 0
                AND
                (
                    MAX(CASE WHEN ERROR_FLAG = '0' THEN IN_STATION_TIME END) IS NULL
                    OR
                    MAX(CASE WHEN ERROR_FLAG = '0' THEN IN_STATION_TIME END)
                        <
                    MAX(CASE WHEN ERROR_FLAG = '1' THEN IN_STATION_TIME END)
                )
        );

        IF v_count > 0 THEN
            v_list := '';

            FOR r IN (
                SELECT GROUP_NAME
                FROM SFISM4.R_SN_DETAIL_T
                WHERE SERIAL_NUMBER = DATA AND UPPER(STATION_NAME) NOT LIKE '%REWORK%'
                AND  NOT (
                UPPER(GROUP_NAME) LIKE 'OQA%'
                 OR UPPER(GROUP_NAME) LIKE 'BIOSCHECK%'
                 OR UPPER(GROUP_NAME) LIKE 'SECOND_FLASH%'
                 OR UPPER(GROUP_NAME) LIKE '900%'
                 OR UPPER(GROUP_NAME) LIKE 'SFQC%'
                 OR UPPER(GROUP_NAME) LIKE 'SIQA%'
		 OR UPPER(GROUP_NAME) LIKE '%LOCK%'
                )
                GROUP BY GROUP_NAME
                HAVING 
                    SUM(CASE WHEN ERROR_FLAG = '1' THEN 1 ELSE 0 END) > 0
                    AND
                    (
                        MAX(CASE WHEN ERROR_FLAG = '0' THEN IN_STATION_TIME END) IS NULL
                        OR
                        MAX(CASE WHEN ERROR_FLAG = '0' THEN IN_STATION_TIME END)
                            <
                        MAX(CASE WHEN ERROR_FLAG = '1' THEN IN_STATION_TIME END)
                    )
            )
            LOOP
                v_list := v_list || r.GROUP_NAME || ', ';
            END LOOP;

    v_list := RTRIM(v_list, ', ');
    RES := DATA || ' NOT PASS ' || v_list || ' PLEASE RETEST';

    RAISE e_ERROR3;
    END IF;

    -- END RUANSHIQIAO ADD 20251128
    RES := 'OK';
    RETURN;


EXCEPTION
    WHEN e_ERROR THEN

        RES := ' NOT 2019 SN ';

    WHEN e_ERROR2 THEN

        RES := 'ERROR SN,PLEASE WEB NURSING';

    WHEN e_ERROR3 THEN
        NULL;

    WHEN OTHERS THEN

        RES := ' NO SN ';
END;