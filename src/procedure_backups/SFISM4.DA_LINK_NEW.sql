PROCEDURE                                           DA_LINK_NEW(   ----Added by Alex Wang on 2010/05/24 for 1TFE-100524-01 Begin
EMP     IN  VARCHAR2,
DATA    IN  VARCHAR2,
MYGROUP IN  VARCHAR2,
RES     OUT VARCHAR2)AS

v_MODEL     VARCHAR2(25);
v_DA        VARCHAR2(15);
v_RES       VARCHAR2(25);

v_MODELCNT  NUMBER(2,0);

e_NULL      EXCEPTION;


v_MO    VARCHAR2(25);
--v_DA    VARCHAR2(15);
v_count NUMBER(2,0);
v_count2 NUMBER(2,0);
v_confirm    VARCHAR2(1);
v_unlock    VARCHAR2(1);

BEGIN
    -- modify on 20210512 update message identity
    -- begin, add by jiang on 20210323 for Mellanox DA contril,  base on procedure: SFISM4.DA_LINK
    SELECT MO_NUMBER
    INTO v_MO
    FROM SFISM4.R_WIP_TRACKING_T
    WHERE SERIAL_NUMBER=DATA
          AND ROWNUM=1;

     --add by lsc in order to control sampling test station rate 202309114
    select count(*) INTO v_count2 from sfis1.c_sapling_lock_t where flag='Y' and mo_number=v_MO;
    IF v_count2>0 THEN
           RES:='MO HAS BEEN LOCK BY SAMPLING SYSTEM';
           RAISE e_NULL;
    END IF;

    SELECT count(order_no)
    INTO v_count
    FROM SFISM4.R_MO_BASE_T
    WHERE MO_NUMBER = v_MO and UPPER(CUST_CODE) ='MELLANOX'     --氝樓諦癹秶璃ㄛ硐NLX 家奪諷DA  --liujiang20221214
          AND ROWNUM=1;

    IF v_count>0 THEN
        SELECT order_no
        INTO v_DA
        FROM SFISM4.R_MO_BASE_T
        WHERE MO_NUMBER = v_MO
              AND ROWNUM=1;

        SELECT COUNT (MO_NUMBER)
        INTO v_count
          FROM SFIS1.C_DA_MO_T
         WHERE MO_NUMBER = v_MO AND DA_NO = v_DA AND GROUP_NAME = MYGROUP;

        IF v_count = 0 THEN
            --RES:='MO not DA control data!';
            RES:='MO not '|| v_DA ||' control data!';
            RETURN;                  
        ELSE       
            SELECT CONFIRM, UNLOCK
              INTO v_confirm, v_unlock
              FROM SFIS1.C_DA_MO_T
             WHERE MO_NUMBER = v_MO AND DA_NO = v_DA AND GROUP_NAME = MYGROUP AND ROWNUM =1; 

            if v_confirm <>'Y' THEN
              RES:='MO not '|| v_DA ||' confirm!';
              RETURN; 
            END IF;

            if v_unlock <>'Y' THEN
              RES:='MO not '|| v_DA ||' unlock!';
              RETURN; 
            END IF;            

        end if;

        RES:='OK';
    end if;
    -- end, add by jiang on 20210323 for Mellanox DA contril,  base on procedure: SFISM4.DA_LINK

    SELECT MODEL_NAME
    INTO v_MODEL
    FROM SFISM4.R_WIP_TRACKING_T
    WHERE SERIAL_NUMBER=DATA
          AND ROWNUM=1;

    SELECT COUNT(MODEL_NAME)
    INTO v_MODELCNT
    FROM SFIS1.C_DA_T
    WHERE MODEL_NAME =v_MODEL
          AND (SYSDATE > S_DATE AND SYSDATE < E_DATE)
          AND GROUP_NAME=MYGROUP;

    IF v_MODELCNT>0 THEN
        SELECT DA_ECO
        INTO v_DA
        FROM SFIS1.C_DA_T
        WHERE MODEL_NAME = v_MODEL
              AND (SYSDATE > S_DATE AND SYSDATE < E_DATE)
              AND GROUP_NAME = MYGROUP
              AND ROWNUM=1;

        SFISM4.DATALINK(EMP,DATA,v_DA,MYGROUP,'DA',v_RES);
        IF v_RES <> 'OK' THEN
           RES:='LINK DA ERROR!'||'\n'||'**END**';
           RAISE e_NULL;
        END IF;
    END IF;
    RES:='OK';
EXCEPTION
    WHEN e_NULL THEN NULL;
    WHEN OTHERS THEN
        RES:='OTHER ERROR '||SUBSTR(SQLERRM,1,10)||'\n'||'**END**';
END;