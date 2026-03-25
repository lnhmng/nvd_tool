PROCEDURE       CHECK_EC_ICT2286_V1(--Added by Alex Wang on 2010/4/10 for 1PTB-100412-01 Begin
DATA IN VARCHAR2,
M_FAILDESC IN VARCHAR2,
RES OUT VARCHAR2) IS

FLAG NUMBER(8,0);
P_RESULT VARCHAR2(1);


BEGIN
    IF DATA='F' THEN
        SELECT INSTR(m_FAILDESC,'Shorted') INTO FLAG FROM dual;
        IF FLAG>0 THEN
            RES:='IT002';
        ELSE
            SELECT INSTR(M_FAILDESC,'CONTACT') INTO FLAG FROM DUAL;
            IF FLAG>0 THEN
                RES:='IT001';
            ELSE
                RES:='IT003';
            END IF;
        END IF;
    ELSE
        IF DATA='P' THEN
            RES:='N/A';
	    END IF;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        IF DATA='P' THEN
            RES:='N/A';
        ELSIF DATA='F' THEN
            RES:='IT004';
        END IF;
END;