PROCEDURE Check_Vendor_Id_2f_NEW  (STATION_NUM IN VARCHAR2,MACHINE IN VARCHAR2,
                           PPN IN VARCHAR2,VER IN VARCHAR2,EMP IN VARCHAR2,
                           LOC IN VARCHAR2,KPN IN VARCHAR2,VC IN VARCHAR2,
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
C_COUNT_3    VARCHAR2(2);
BEGIN

    --The following statement will sort the machine code and feeder code
	--from the variable MACHINEFEEDER.
   /* SELECT INSTR(MACHINEFEEDER,'&') INTO iStrPosition FROM dual;
    SELECT SUBSTR(MACHINEFEEDER,1,iStrPosition-1) INTO C_MACHINE FROM dual;
	SELECT SUBSTR(MACHINEFEEDER,iStrPosition+1) INTO C_LOC FROM dual;*/
	-------------------------end----------------
   C_MACHINE:=MACHINE;
   C_LOC:=LOC;

   SELECT COUNT(*) INTO T_COUNT FROM SFIS1.C_PRIV_T WHERE TRIM(STATION_GROUP)=SUBSTR(VC,GROUP_ID,STATION_PRIV);

   IF T_COUNT>0 THEN
          SELECT COUNT(*)  INTO C_COUNT_3  FROM KITTING.S_E_GOOD_T  WHERE P_NO=VC AND STATE=3 AND STATE1=0;
		         IF C_COUNT_3>0 THEN
		           RES:='IQC_VC_FAIL';
				   C_OUTPUT := RES || ' - ' || VC ;
				   Insert_Error_Mes(STATION_NUM,C_MACHINE ,
                           PPN ,VER ,EMP ,
                           C_LOC ,KPN ,VC,
                           LINE,C_OUTPUT);
			     ELSE
			     RES:='OK';
		         END IF;
   ELSE
      RES:='VC NG';
     C_OUTPUT := RES || ' - ' || VC ;
	 Insert_Error_Mes(STATION_NUM,C_MACHINE ,
                           PPN ,VER ,EMP ,
                           C_LOC ,KPN ,VC,
                           LINE,C_OUTPUT);
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      RES :='VC NG ';
      C_OUTPUT := RES || ' - ' || VC ;
      Insert_Error_Mes(STATION_NUM,C_MACHINE ,
                           PPN ,VER ,EMP ,
                           C_LOC ,KPN ,VC,
                           LINE,C_OUTPUT);

END;
