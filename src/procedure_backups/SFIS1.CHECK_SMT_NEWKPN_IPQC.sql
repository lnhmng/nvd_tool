PROCEDURE CHECK_SMT_NEWKPN_IPQC(STATION_NUM IN VARCHAR2,MACHINE IN VARCHAR2,
                           PPN IN VARCHAR2,VER IN VARCHAR2,QC IN VARCHAR2,
                           LOC IN VARCHAR2,HPN IN VARCHAR2,PID IN VARCHAR2,
                           LINE IN VARCHAR2,RES OUT VARCHAR2) IS
C_KPN VARCHAR2(32);
C_OUTPUT VARCHAR2(64);
V_TEMP_KP VARCHAR2(32);
C_LOC VARCHAR2(16);
C_LOC_1 VARCHAR2(16);
R_HHPN VARCHAR2(32);
C_COUNT_1 NUMBER;
C_COUNT  NUMBER ;
RESULT   INTEGER;
MAXDATE  DATE;
NO_FEEDERNO EXCEPTION;
NEXT_HHPN   EXCEPTION;
BEGIN
  if PID='NEXTHHPN' OR HPN='NEXTHHPN'THEN

     raise NEXT_HHPN;
  end if;
   /* FOR THE kp add 'P'  ,BY ZHANGYUN 2003-10-15 ----- in the old ONLY 1 LINE,*/
/*    V_TEMP_KP:=SUBSTR(TRIM(KPN),2);*/
-- HHPN OR PKG ID
   IF PID IS NOT NULL AND PID <>'N/A' THEN
    SELECT HH_PN INTO R_HHPN FROM IQC.R_KPN_INCOMING_T WHERE PKG_ID=PID;
	 IF R_HHPN is not NULL THEN
		V_TEMP_KP:=R_HHPN;
	 END IF;
   ELSE
	 if SUBSTR(TRIM(HPN),1,1)='P' THEN
      V_TEMP_KP:=SUBSTR(TRIM(HPN),2);
	 ELSE
	  V_TEMP_KP:=TRIM(HPN);
	 end if;
   END IF;


/*---------------zy---------------*/
     /* SELECT KEY_PART_NO INTO C_KPN FROM SFIS1.C_SMT_KP_T
                                                                WHERE KEY_PART_NO = KPN AND KP_DISTINCT = '1' AND ROWNUM = 1;*/

     /*  LF MODIFY ON 20020531 */
  SELECT COUNT(*)  INTO C_COUNT_1  FROM SFIS1.C_SMT_KP_T
  WHERE KEY_PART_NO = V_TEMP_KP AND KP_DISTINCT = '1' ;
  IF  C_COUNT_1=0 THEN

            SELECT HH_PART INTO C_KPN  FROM SFIS1.C_KPN_T WHERE P_PART=V_TEMP_KP;

      SELECT KEY_PART_NO INTO V_TEMP_KP  FROM SFIS1.C_SMT_KP_T
             WHERE KEY_PART_NO =C_KPN AND KP_DISTINCT = '1' AND ROWNUM = 1;

  END IF;

  /* search MIN(LOC)  add by liuyunjiang 2006-03-11*/
  select count(*) into C_COUNT from sfism4.r_sn_group_t where line_name=machine;
  if C_COUNT=0 then
     RAISE NO_FEEDERNO;
  end if;
  select min(MODEL_NAME) into C_LOC from sfism4.r_sn_group_t where line_name=machine;

   /*LF MODIFY ON 20020531*/

     SELECT COUNT(*) INTO C_COUNT   FROM SFIS1.C_SMT_BOM_T BOM,SFISM4.R_SMT_PROD_BOM_T PROD,SFIS1.KPN_SPN_MODEL_V SPARE
                                                       WHERE BOM.FEEDER_NO = C_LOC
                                                              AND (BOM.KEY_PART_NO = V_TEMP_KP OR (SPARE.SPARE_KEY_PART_NO=V_TEMP_KP  AND SPARE.MODEL_NAME=PPN AND SPARE.VALID_DATE>=SYSDATE))
                                                              AND BOM.KEY_PART_NO=SPARE.KEY_PART_NO(+)
                                                              AND BOM.BOM_NO = PROD.BOM_NO  AND PROD.PRODUCT_NO = PPN
                                                              AND PROD.VER = VER AND BOM.MACHINE_CODE = MACHINE;

 /*-----------------------------------------------------------------*/
      IF C_COUNT=0 THEN

             RES := 'KPN NG ';
             C_OUTPUT := RES || ' - ' || V_TEMP_KP ;

       ELSE

		     SELECT ITEM INTO RESULT FROM SFISM4.R_SN_GROUP_T WHERE line_name=machine and ROWNUM = 1;
		      IF RESULT=0 THEN
			    SELECT DISTINCT KEY_PART_NO INTO R_HHPN FROM sfis1.c_smt_bom_t bom, sfism4.r_smt_prod_bom_t prod
		          WHERE  bom.bom_no = prod.bom_no
                    AND prod.product_no = ppn
                    AND prod.ver = ver
                    AND bom.machine_code = machine	
					AND prod.line_name=line				
		            AND FEEDER_NO=C_LOC;
			  END IF;
	         delete from sfism4.r_sn_group_t where model_name in ( select min(MODEL_NAME)  from sfism4.r_sn_group_t where line_name=machine) and line_name=machine;
			 select count(*) into C_COUNT_1 from sfism4.r_sn_group_t where line_name=machine;
             if C_COUNT_1=0 then
			     INSERT  INTO sfism4.R_HHPN_CHECK_LOG_T (PRODUCT_NO,PKG_ID,HHPN,LINE_NAME,MACHINE_CODE,FEEDER_NO,RESULT,IN_STATION_TIME,EMP_NO) VALUES ('N/A','N/A','N/A',LINE,MACHINE,LOC,'PASS',SYSDATE,QC);
			     RES:='OK.CHECK COMPLETE';
		     else
			 	 RES := 'OK';
             end if;

        END IF;

EXCEPTION
   WHEN NO_FEEDERNO THEN
      RES:='OK.CHECK COMPLETE';
   WHEN NEXT_HHPN THEN
   --ITEM
        
		select count(*) into C_COUNT from sfism4.r_sn_group_t where line_name=machine;
            if C_COUNT=0 then
               RES:='NO MACHINE';
            else
			
	    UPDATE SFISM4.R_SN_GROUP_T SET ITEM =1 WHERE LINE_NAME=machine;
		COMMIT;		

      select min(MODEL_NAME) into C_LOC from sfism4.r_sn_group_t where line_name=machine;

	   SELECT DISTINCT KEY_PART_NO INTO R_HHPN FROM sfis1.c_smt_bom_t bom, sfism4.r_smt_prod_bom_t prod
		                             WHERE  bom.bom_no = prod.bom_no
                                       AND prod.product_no = ppn
                                       AND prod.ver = ver
                                       AND bom.machine_code = machine
									   AND prod.line_name=line
		                               AND FEEDER_NO=C_LOC;
	IF PID='NEXTHHPN' THEN
	   	SELECT COUNT(*) INTO C_COUNT FROM SMTINFO.R_SMT_PKGID_LOG_T
		                              WHERE FEEDER_NO=C_LOC
		                                AND MACHINE_CODE=MACHINE
		                                AND BEGIN_TIME=(SELECT MAX(BEGIN_TIME)  FROM SMTINFO.R_SMT_PKGID_LOG_T
		                                                                      WHERE FEEDER_NO=C_LOC
		                                                                        AND MACHINE_CODE=MACHINE);
		IF C_COUNT<>0 THEN
	     SELECT PKG_ID INTO V_TEMP_KP FROM SMTINFO.R_SMT_PKGID_LOG_T
		                             WHERE FEEDER_NO=C_LOC
		                               AND MACHINE_CODE=MACHINE
		                               AND BEGIN_TIME=(SELECT MAX(BEGIN_TIME)  FROM SMTINFO.R_SMT_PKGID_LOG_T
		                                                                      WHERE FEEDER_NO=C_LOC
		                                                                        AND MACHINE_CODE=MACHINE);
		ELSE
		   V_TEMP_KP:=NULL;
		END IF;
	ELSE
	     SELECT COUNT(*) INTO C_COUNT FROM SMTINFO.R_SMT_PKGID_LOG_T
		                             WHERE FEEDER_NO=C_LOC
		                               AND MACHINE_CODE=MACHINE
		                               AND BEGIN_TIME=(SELECT MAX(BEGIN_TIME)  FROM SMTINFO.R_SMT_PKGID_LOG_T
		                                                                      WHERE FEEDER_NO=C_LOC
		                                                                        AND MACHINE_CODE=MACHINE);
		 IF C_COUNT<>0 THEN
		 SELECT KEY_PART_NO INTO V_TEMP_KP FROM sfism4.R_SMT_LOG_T
		                               WHERE FEEDER_NO=C_LOC
		                                 AND MACHINE_CODE=MACHINE
		                                 AND WORK_TIME=(SELECT MAX(WORK_TIME)  FROM sfism4.R_SMT_LOG_T
		                                                                      WHERE FEEDER_NO=C_LOC
		                                                                        AND MACHINE_CODE=MACHINE);
		 ELSE
		    V_TEMP_KP:=NULL;
		 END IF;
	END IF;

      	delete from sfism4.r_sn_group_t where model_name in ( select min(MODEL_NAME)  from sfism4.r_sn_group_t where line_name=machine) and line_name=machine;

		select count(*) into C_COUNT from sfism4.r_sn_group_t where line_name=machine;
         if C_COUNT=0 then
           RES:='OK.CHECK COMPLETE.';
		   INSERT  INTO sfism4.R_HHPN_CHECK_LOG_T (PRODUCT_NO,PKG_ID,HHPN,LINE_NAME,MACHINE_CODE,FEEDER_NO,RESULT,IN_STATION_TIME,EMP_NO) VALUES (PPN,V_TEMP_KP,R_HHPN,LINE,MACHINE,C_LOC,'FAIL',SYSDATE,QC);
		 else
		  select min(MODEL_NAME) into C_LOC_1 from sfism4.r_sn_group_t where line_name=machine;
		  INSERT  INTO sfism4.R_HHPN_CHECK_LOG_T (PRODUCT_NO,PKG_ID,HHPN,LINE_NAME,MACHINE_CODE,FEEDER_NO,RESULT,IN_STATION_TIME,EMP_NO) VALUES (PPN,V_TEMP_KP,R_HHPN,LINE,MACHINE,C_LOC,'FAIL',SYSDATE,QC);
			RES := 'OK.NEXT HH P/N (track:'|| C_LOC_1 ||')?';
         end if;
	end if;

   WHEN OTHERS THEN
      RES := ' NO KPN';
	  RES:=RES||SUBSTR(SQLERRM,1,80);
      C_OUTPUT:= RES || ' - ' || HPN;
END;
/*************************************************************
CREATED BY: LIUYUNJIANG .
CREATE DATE: Mar. 11,2006.
FOR  IPQC SMT MATERIAL CHECK.
*************************************************************/