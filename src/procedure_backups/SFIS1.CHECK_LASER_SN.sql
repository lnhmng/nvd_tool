PROCEDURE             CHECK_LASER_SN (DATA    IN  VARCHAR2,
                                                      EMP     IN  VARCHAR2,
                                                      LINE    IN  VARCHAR2, 
                                                      MYGROUP IN  VARCHAR2,
                                                      RES     OUT VARCHAR2)
    IS

       LASER_NO    VARCHAR2 (25);
       LASER_SN    VARCHAR2 (50); 
       COUNT1      NUMBER;
       C_ID        VARCHAR2 (25);        
       E_ERROR   EXCEPTION; 
       e_null    EXCEPTION;   

    BEGIN   -- lyc 2023/07/25 S0000XS24

       LASER_SN :=DATA;

       LASER_NO :=SUBSTR(LASER_SN,1,13);

       SELECT LENGTH (LASER_SN) INTO COUNT1  FROM DUAL;

       IF 
        COUNT1 >13 then
        res :='ok';
       ELSE 
        RAISE e_null;
       END IF;


       SELECT SERIAL_NUMBER
       INTO C_ID
       FROM SFISM4.R_WIP_TRACKING_T
       WHERE SERIAL_NUMBER = SUBSTR(DATA,1,13)
       GROUP BY SERIAL_NUMBER;

       IF C_ID >=0  THEN
       RES :='OK';
        INSERT INTO SFISM4.R_LASER_SN_T(SERIAL_NUMBER,LASER_SN,EMP_NO,LINE_NAME,GROUP_NAME,CREATE_DATE) 
         VALUES(LASER_NO,DATA,EMP,LINE,MYGROUP,SYSDATE);
       END IF;


    EXCEPTION
       WHEN e_null THEN 
            res := 'ERROR1:PLS INPUT 2D SN /';
        NULL;
       WHEN OTHERS THEN
          RES := 'NO SN OR  SN HAS BIDUIED /';
    END;