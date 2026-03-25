PROCEDURE       CHECK_EC_ICT2286(
DATA IN VARCHAR2,
M_FAILDESC IN VARCHAR2,
RES OUT VARCHAR2) IS

FLAG NUMBER(8,0);
P_RESULT VARCHAR2(1);


BEGIN
IF DATA='F'
   THEN
   SELECT INSTR(m_FAILDESC,'Shorted') into FLAG from dual;
      IF FLAG>0 THEN
      RES:='IC002';
      ELSE
          SELECT INSTR(M_FAILDESC,'CONTACT') INTO FLAG FROM DUAL;
          IF FLAG>0 THEN
             RES:='IC001';
          ELSE
          RES:='IC003';
          END IF;
      END IF;
ELSE
    IF  DATA='P'
        THEN
        RES:='N/A';
	    END IF;
END IF;

EXCEPTION
   WHEN others then
      IF DATA='P'
	  THEN
        RES:='N/A';
        ELSE
		IF DATA='F'
		THEN
        RES:='IC004';
		END IF;
      END IF;
END;
