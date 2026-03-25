PROCEDURE        NEAT_GET_MAC_SPU (V_INSN    IN     VARCHAR2,
                                           o_flag         OUT      VARCHAR2,
                                           RES       OUT    VARCHAR2)
AS
COUN              INT;
MAC             VARCHAR2(200);
E_NOSN          EXCEPTION;
BEGIN
   o_flag := '-1';
    SELECT COUNT(1) INTO COUN FROM SFISM4.R_MAC_T WHERE SERIAL_NUMBER=V_INSN;

    IF COUN=0 THEN
        RES:=V_INSN||'\nSN NO MAC!';
        RAISE E_NOSN;
    ELSE
        SELECT NVL(TEST_INFO,'') INTO MAC FROM SFISM4.R_MAC_T WHERE SERIAL_NUMBER=V_INSN;

        RES:=V_INSN||'\n'||MAC;
    END IF; 

   o_flag := '0';

    EXCEPTION
        WHEN E_NOSN THEN NULL;
        WHEN OTHERS THEN
            RES:='GET MAC ERROR';
    END;
