PROCEDURE       CHECK_SMT_KPNLOT_NEW  (STATION_NUM IN VARCHAR2,MACHINE IN VARCHAR2,
                           PPN IN VARCHAR2,VER IN VARCHAR2,EMP IN VARCHAR2,
                           LOC IN VARCHAR2,KPN IN VARCHAR2,LOT IN VARCHAR2,
                           Line IN VARCHAR2,QTY IN VARCHAR2,RES OUT VARCHAR2) IS
C_KPN VARCHAR2(32);
C_OUTPUT VARCHAR2(64);
V_TEMP_KP VARCHAR2(32);
V_TEMP_KP2 VARCHAR2(12);
T_COUNT NUMBER(8);
C_COUNT_1 NUMBER(8);
C_COUNT_TEMP NUMBER(8);
C_MO     VARCHAR2(25);
C_MODEL  VARCHAR2(25);
C_LINE   VARCHAR2(10);
C_LINENAME  VARCHAR2(10);

C_CHAR varchar2(1);
C_CHAR_NUM number;
C_QTY    number;
C_LENTH  number;
i number;

E_ERROR EXCEPTION;
BEGIN
   C_LINENAME:=Line;
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

	    select count(*) into C_COUNT_TEMP FROM kitting.p_line where LINE=C_LINENAME and  STATE='1' AND ROWNUM = 1 ;
		if C_COUNT_TEMP=0 THEN
		  RAISE E_ERROR;
		END IF;

		C_LENTH:=LENGTH(QTY);
        for i in 1..C_LENTH  loop
           C_CHAR:=substr(QTY,i,1);
           select ascii(C_CHAR) into C_CHAR_NUM from dual;
           if  C_CHAR_NUM>=48 AND  C_CHAR_NUM<=57 then
               select TO_NUMBER(substr(QTY,i,C_LENTH-i+1)) into C_QTY from dual;
               EXIT ;
           END IF;
        end loop;

		select MO_NO into C_MO FROM kitting.p_line where LINE=C_LINENAME and  STATE='1' AND ROWNUM = 1 ;
                 INSERT_SMTLOG_MES_NEW(STATION_NUM,MACHINE ,
                           PPN ,VER ,EMP ,
                           LOC ,V_TEMP_KP ,LOT ,
                           Line ,C_QTY,C_MO );

        --?????????
		select count(*) into C_COUNT_TEMP from kitting.p_mo_t where  state='S' and  hh_gno=V_TEMP_KP and mo_no=C_MO;
		if C_COUNT_TEMP=0 THEN
		   	update kitting.R_MATERIAL_T set SCAN_NUM=SCAN_NUM+C_QTY WHERE MO_NO=C_MO AND PRODUCT_NO=PPN AND HH_GNO=V_TEMP_KP and LINE= C_LINENAME;
		ELSE
		    select re_gno into V_TEMP_KP from kitting.p_mo_t where  state='S' and  hh_gno=V_TEMP_KP and mo_no=C_MO;
		    update kitting.R_MATERIAL_T set SCAN_NUM=SCAN_NUM+C_QTY WHERE MO_NO=C_MO AND PRODUCT_NO=PPN AND HH_GNO=V_TEMP_KP and LINE= C_LINENAME;
		END IF;

   ELSE
                 INSERT_ERROR_MES(STATION_NUM,MACHINE ,
                           PPN ,VER ,EMP ,
                           LOC ,KPN ,LOT ,
                           Line , C_OUTPUT );

   END IF;
EXCEPTION
   WHEN  E_ERROR THEN
      RES:='NO USING MO NUMBER THIS LINE IN SMT KITTING';
   WHEN OTHERS THEN
      RES :='LOT NG ';
      C_OUTPUT := RES || ' - ' || LOT ;
      INSERT_ERROR_MES(STATION_NUM,MACHINE ,
                           PPN ,VER ,EMP ,
                           LOC ,KPN ,LOT ,
                           Line,C_OUTPUT);

END;
