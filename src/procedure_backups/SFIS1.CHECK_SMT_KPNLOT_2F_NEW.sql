PROCEDURE CHECK_SMT_KPNLOT_2F_NEW    (STATION_NUM IN VARCHAR2,MACHINE IN VARCHAR2,
                           PPN IN VARCHAR2,VER IN VARCHAR2,EMP IN VARCHAR2,
                           LOC IN VARCHAR2,KPN IN VARCHAR2,LOT IN VARCHAR2,VC IN VARCHAR2,
                           LINE IN VARCHAR2,RES OUT VARCHAR2) IS
iStrPosition INTEGER;
C_MACHINE VARCHAR2(32);
C_LOC VARCHAR2(32);

C_KPN VARCHAR2(32);
C_OUTPUT VARCHAR2(64);
V_TEMP_KP VARCHAR2(32);
V_TEMP_KP2 VARCHAR2(12);
T_COUNT NUMBER(8);
C_COUNT_1 NUMBER(8);
C_COUNT_3  NUMBER(8);

BEGIN

    --The following statement will sort the machine code and feeder code
	--from the variable MACHINEFEEDER.
    /*SELECT INSTR(MACHINEFEEDER,'&') INTO iStrPosition FROM dual;
    SELECT SUBSTR(MACHINEFEEDER,1,iStrPosition-1) INTO C_MACHINE FROM dual;
	SELECT SUBSTR(MACHINEFEEDER,iStrPosition+1) INTO C_LOC FROM dual;*/
	C_MACHINE:=MACHINE;
	C_LOC:=LOC;
	-------------------------end----------------

   SELECT COUNT(*) INTO T_COUNT FROM SFIS1.C_LOT_STR WHERE TRIM(SUB_STR)=SUBSTR(LOT,S_START,S_LEGTH);
   IF T_COUNT>0 THEN
        SELECT COUNT(*) INTO C_COUNT_3   FROM KITTING.S_E_GOOD_T  WHERE LOT_NO=LOT AND P_NO=VC AND STATE=4 AND STATE1=0 ;
		 IF C_COUNT_3>0    THEN
            RES:='IQC_LOT_FAIL';
			C_OUTPUT := RES|| ' - ' || LOT ;
	   ELSE
	     RES:='OK';
	    END IF;

   ELSE
      RES:='LOT NG';
     C_OUTPUT := RES || ' - ' || LOT ;
   END IF;
   IF RES='OK' THEN
    IF SUBSTR(TRIM(KPN),1,1)='P' THEN
     V_TEMP_KP:=TRIM(SUBSTR(TRIM(KPN),2));
	 ELSE
	 V_TEMP_KP:=TRIM(KPN);
	 END IF;
               SELECT  COUNT(*)  INTO C_COUNT_1  FROM  SFIS1.C_SMT_KP_T
                         WHERE KEY_PART_NO = V_TEMP_KP AND KP_DISTINCT = '1' ;
	            IF  C_COUNT_1=0 THEN
                     SELECT HH_PART INTO C_KPN  FROM SFIS1.C_KPN_T WHERE P_PART=V_TEMP_KP;
			         V_TEMP_KP:=C_KPN;
                END IF;
                Insert_Smtlog2_Mes(STATION_NUM,C_MACHINE ,
                           PPN ,VER ,EMP ,
                           C_LOC ,V_TEMP_KP ,LOT ,VC,
                           LINE);
   ELSE
                Insert_Error_Mes(STATION_NUM,C_MACHINE ,
                           PPN ,VER ,EMP ,
                           C_LOC ,KPN ,VC ,
                           LINE , C_OUTPUT );
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      RES :='LOT NG ';
      C_OUTPUT := RES || ' - ' || LOT ;
      Insert_Error_Mes(STATION_NUM,C_MACHINE ,
                           PPN ,VER ,EMP ,
                           C_LOC ,KPN ,VC ,
                           LINE,C_OUTPUT);

END;
