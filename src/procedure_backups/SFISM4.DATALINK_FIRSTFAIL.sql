PROCEDURE               DATALINK_firstfail            ----Added by Alex Wang on 2010/05/24 for 1TFE-100524-01 Begin
(
  EMP      IN      VARCHAR2,
  DATA     IN      VARCHAR2,
  VALUE    IN      VARCHAR2,
  MYGROUP  IN      VARCHAR2,
  FLAG     IN      VARCHAR2,
  TESTDATE IN      DATE,
  RES      OUT     VARCHAR2
) AS
C_COUNT0   NUMBER;
C_COUNT1   NUMBER;
V_FLAG     VARCHAR2(15);
C_INIT_SN  VARCHAR2(25);
BEGIN
    V_FLAG:=FLAG;
    SELECT COUNT(*)
    INTO   C_COUNT1
    FROM   SFISM4.R_SN_LINK_T
    WHERE  OLD_SN = DATA OR NEW_SN = DATA;

    IF C_COUNT1 = 0 THEN
        SELECT COUNT(*)
        INTO   C_COUNT0
        FROM   SFISM4.H_LINK_T
        WHERE  SERIAL_NUMBER = DATA
               AND FLAG = V_FLAG
               AND AVAILABLE = '0'
               AND GROUP_NAME = MYGROUP;
        IF C_COUNT0 > 0 THEN
            UPDATE SFISM4.H_LINK_T
            SET    AVAILABLE = '1',LAST_EDIT_BY = EMP,LAST_EDIT_DT= SYSDATE
            WHERE  SERIAL_NUMBER = DATA
                AND FLAG = V_FLAG
                AND AVAILABLE = '0'
                AND GROUP_NAME = MYGROUP;
        END IF;
    ELSE
        SELECT INIT_SN
        INTO   C_INIT_SN
        FROM   SFISM4.R_SN_LINK_T
        WHERE  (OLD_SN = DATA OR NEW_SN = DATA)
               AND ROWNUM = 1;
        --Modified by Alex Wang on 2010/11/2 for SQL optimize--Begin--       
--         SELECT COUNT(*)
--        INTO   C_COUNT0
--        FROM   SFISM4.H_LINK_T A
--        WHERE  EXISTS (SELECT *
--                          FROM   SFISM4.R_SN_LINK_T B
--                       WHERE  (A.SERIAL_NUMBER = B.NEW_SN OR A.SERIAL_NUMBER = B.OLD_SN)
--                                 AND B.INIT_SN = C_INIT_SN)
--               AND FLAG = V_FLAG
--               AND AVAILABLE = '0'
--               AND GROUP_NAME = MYGROUP;

--         IF C_COUNT0 > 0 THEN
--            UPDATE SFISM4.H_LINK_T A
--            SET    AVAILABLE = '1',LAST_EDIT_BY = EMP,LAST_EDIT_DT= SYSDATE
--            WHERE  EXISTS (SELECT *
--                              FROM   SFISM4.R_SN_LINK_T B
--                           WHERE  (A.SERIAL_NUMBER = B.NEW_SN OR A.SERIAL_NUMBER = B.OLD_SN)
--                                     AND B.INIT_SN = C_INIT_SN)
--                   AND FLAG = V_FLAG
--                   AND AVAILABLE = '0'
--                   AND GROUP_NAME = MYGROUP;
--        END IF;

        SELECT /*+use_nlindex(C SN_R_LINK_T_INDEX2) */ COUNT(*)      --update  on 20150518
        INTO   C_COUNT0
        FROM   SFISM4.H_LINK_T
        WHERE SERIAL_NUMBER IN  
                                   (SELECT B.NEW_SN
                                    FROM  SFISM4.H_LINK_T A,SFISM4.R_SN_LINK_T B
                                    WHERE  (A.SERIAL_NUMBER = B.NEW_SN OR A.SERIAL_NUMBER = B.OLD_SN)
                                    AND B.INIT_SN = C_INIT_SN
                                    UNION
                                   SELECT B.OLD_SN
                                    FROM  SFISM4.H_LINK_T A,SFISM4.R_SN_LINK_T B
                                    WHERE  (A.SERIAL_NUMBER = B.NEW_SN OR A.SERIAL_NUMBER = B.OLD_SN)
                                    AND B.INIT_SN = C_INIT_SN )
               AND FLAG = V_FLAG
               AND AVAILABLE = '0'
               AND GROUP_NAME = MYGROUP;

        IF C_COUNT0 > 0 THEN
            UPDATE SFISM4.H_LINK_T
            SET    AVAILABLE = '1',LAST_EDIT_BY = EMP,LAST_EDIT_DT= SYSDATE
            WHERE SERIAL_NUMBER IN 
                                       (SELECT B.NEW_SN
                                        FROM  SFISM4.H_LINK_T A,SFISM4.R_SN_LINK_T B
                                        WHERE  (A.SERIAL_NUMBER = B.NEW_SN OR A.SERIAL_NUMBER = B.OLD_SN)
                                        AND B.INIT_SN = C_INIT_SN
                                        UNION
                                       SELECT B.OLD_SN
                                        FROM  SFISM4.H_LINK_T A,SFISM4.R_SN_LINK_T B
                                        WHERE  (A.SERIAL_NUMBER = B.NEW_SN OR A.SERIAL_NUMBER = B.OLD_SN)
                                        AND B.INIT_SN = C_INIT_SN) 
                   AND FLAG = V_FLAG
                   AND AVAILABLE = '0'
                   AND GROUP_NAME = MYGROUP;
        END IF;
        --Modified by Alex Wang on 2010/11/2 for SQL optimize--End--         
    END IF;
    INSERT INTO SFISM4.H_LINK_T
    (
        SERIAL_NUMBER,
        KEY_VALUE,
        AVAILABLE,
        FLAG,
        CREATE_BY,
        CREATE_DT,
        LAST_EDIT_BY,
        LAST_EDIT_DT,
        GROUP_NAME
    )
    VALUES
    (
        DATA,
        VALUE,
        '0',
        V_FLAG,
        EMP,
--        SYSDATE,
    TESTDATE,
        '',
        '',
        MYGROUP
    );
    COMMIT;
    RES:='OK';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RES:='OTHER ERROR '||SUBSTR(SQLERRM,1,10)||'\n'||'**END**';
END;