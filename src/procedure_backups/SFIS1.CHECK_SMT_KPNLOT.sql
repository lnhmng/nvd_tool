PROCEDURE CHECK_SMT_KPNLOT  (STATION_NUM IN VARCHAR2,MACHINE IN VARCHAR2,
                           PPN IN VARCHAR2,VER IN VARCHAR2,EMP IN VARCHAR2,
                           LOC IN VARCHAR2,KPN IN VARCHAR2,LOT IN VARCHAR2,
                           Line IN VARCHAR2,RES OUT VARCHAR2) IS
C_KPN VARCHAR2(32);
C_OUTPUT VARCHAR2(64);
V_TEMP_KP VARCHAR2(32);
V_TEMP_KP2 VARCHAR2(12);
T_COUNT NUMBER(8);
C_COUNT_1 NUMBER(8);
BEGIN
 /*  if substr(KPN,1,3)='3N1' then
             if substr(LOT,1,3)='3N2' then
                  RES:='OK';
             else
                 C_OUTPUT := RES || ' - ' || LOT ;
                  RES :='LOT NG';
             end if;
   else
             RES:='OK';
   end if;*/
   SELECT COUNT(*) INTO T_COUNT FROM SFIS1.C_LOT_STR WHERE TRIM(SUB_STR)=SUBSTR(LOT,S_START,S_LEGTH);

   IF T_COUNT>0 THEN
     RES:='OK';
   ELSE
     C_OUTPUT := RES || ' - ' || LOT ;
     RES:='LOT NG';
   END IF;

   IF RES='OK' THEN
               /* LF ADD 20020611 FOR KPN */
           /* zhangyun update 20031017 for kp add 'P'  */
               if SUBSTR(TRIM(KPN),1,1)='P' THEN
     V_TEMP_KP:=SUBSTR(TRIM(KPN),2);
	 ELSE
	 V_TEMP_KP:=TRIM(KPN);
	 end if;

		/*    V_TEMP_KP:=TRIM(KPN);       by:zhangyun      */

                 SELECT  COUNT(*)  INTO C_COUNT_1  FROM  sfis1.C_SMT_KP_T
                                                                 WHERE key_part_no = V_TEMP_KP AND kp_distinct = '1' ;
	            IF  C_COUNT_1=0 THEN

	                  SELECT HH_PART INTO C_KPN  FROM SFIS1.C_KPN_T WHERE P_PART=V_TEMP_KP;

			          /*SELECT key_part_no INTO V_TEMP_KP  FROM sfis1.C_SMT_KP_T
                                                                   WHERE key_part_no =C_KPN AND kp_distinct = '1' AND ROWNUM = 1;*/
					 V_TEMP_KP:=C_KPN;

	              END IF;

              /*LF */

                 INSERT_SMTLOG_MES(STATION_NUM,MACHINE ,
                           PPN ,VER ,EMP ,
                           LOC ,V_TEMP_KP ,LOT ,
                           Line);
   ELSE
                 INSERT_ERROR_MES(STATION_NUM,MACHINE ,
                           PPN ,VER ,EMP ,
                           LOC ,KPN ,LOT ,
                           Line , C_OUTPUT );

   END IF;
EXCEPTION
   WHEN OTHERS THEN
      RES :='LOT NG ';
      C_OUTPUT := RES || ' - ' || LOT ;
      INSERT_ERROR_MES(STATION_NUM,MACHINE ,
                           PPN ,VER ,EMP ,
                           LOC ,KPN ,LOT ,
                           Line,C_OUTPUT);

END;
