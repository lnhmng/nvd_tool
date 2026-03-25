PROCEDURE CHECK_PKG_FEEDER3(STATION_NUM IN VARCHAR2,MACHINE IN VARCHAR2,
                           PPN IN VARCHAR2,VER IN VARCHAR2,EMP IN VARCHAR2,
                           LOC IN VARCHAR2,PKG IN VARCHAR2,SN IN VARCHAR2,
                           LINE IN VARCHAR2,RES OUT VARCHAR2) IS
C_KPN VARCHAR2(32);
S_FLAG VARCHAR2(1);
C_COUNT0 NUMBER;
C_COUNT1 NUMBER;
C_COUNT2 NUMBER;
C_COUNT3 NUMBER;
C_COUNT4 NUMBER;
C_COUNT5 NUMBER;
C_COUNT6 NUMBER;
C_COUNT7 NUMBER;
C_COUNT8 NUMBER;
C_COUNT9 NUMBER;
C_OUTPUT VARCHAR(64);
BEGIN
   SELECT COUNT(*) INTO C_COUNT0 FROM SMTINFO.R_SMT_PKGID_LOG_T  WHERE  PKG_ID=TRIM(PKG);
   IF C_COUNT0>0 THEN
      RES:='THE PKG ID HAS USED';
   ELSE
   SELECT COUNT(*) INTO C_COUNT1 FROM IQC.R_KPN_INCOMING_T  WHERE  PKG_ID=TRIM(PKG);
   IF C_COUNT1<1 THEN      ------A IF
     RES:='PKG NG';
   ELSE
   --  SELECT COUNT(*) INTO C_COUNT10 FROM SMTINFO.R_PKGID_LOG_T WHERE PKG_ID=TRIM(PKG);
	--  IF C_COUNT10 =0 THEN   -------Z IF
     SELECT STATE_FLAG INTO S_FLAG  FROM IQC.R_KPN_INCOMING_T WHERE PKG_ID=TRIM(PKG);
         IF S_FLAG = 'P' THEN   ------1 IF
	              SELECT HH_PN INTO C_KPN FROM IQC.R_KPN_INCOMING_T  WHERE PKG_ID=TRIM(PKG);
       --     SELECT COUNT(HH_PN) INTO C_COUNT6 FROM IQC.C_KPN_SPEC_T WHERE HH_PN=C_KPN;
		           SELECT COUNT(*) INTO C_COUNT8 FROM SFIS1.C_SMT_BOM_T
                   WHERE FEEDER_NO=LOC AND KEY_PART_NO=C_KPN  AND MACHINE_CODE=MACHINE;
                     IF C_COUNT8<1 THEN   ---A IF
	                   RES:='KPN NG';
                     END IF;              ---A IF END
	              SELECT COUNT(*) INTO C_COUNT9
	              FROM SFIS1.C_SMT_BOM_T BOM,
                       SFISM4.R_SMT_PROD_BOM_T PROD
	               WHERE BOM.BOM_NO=PROD.BOM_NO AND
	                     BOM.FEEDER_NO=LOC AND
						 BOM.MACHINE_CODE=MACHINE AND
		                 BOM.KEY_PART_NO=C_KPN;
		       IF C_COUNT9 >0 THEN
		         RES:='OK';
		       ELSE
		         SELECT COUNT(*) INTO C_COUNT7
                         FROM SFIS1.C_SMT_BOM_T BOM,
                              SFISM4.R_SMT_PROD_BOM_T PROD,
                              SFIS1.C_SMT_KP_SPARE_T SPARE
                         WHERE BOM.FEEDER_NO = LOC
                            AND (BOM.KEY_PART_NO = C_KPN OR (SPARE.SPARE_KEY_PART_NO=C_KPN AND SPARE.VALID_DATE>=SYSDATE))
                            AND BOM.KEY_PART_NO=SPARE.KEY_PART_NO(+)
                            AND BOM.BOM_NO = PROD.BOM_NO
                            AND PROD.PRODUCT_NO = PPN
                            AND BOM.MACHINE_CODE = MACHINE;
                         IF C_COUNT7>0 THEN
                           RES:='OK';
                         ELSE
                           RES:='KPN NG';
                         END IF;
                      END IF;
	       ---        IF C_COUNT9=0 THEN
	       ---          RES:='KPN NG';
	       ----        ELSE
               ----         RES:='OK';
               ----        END IF;
           END IF;          -------1 IF END
         IF S_FLAG='F' THEN  -----2 IF
              RES:='PKG NG';
         END IF;             ------2 IF END
         IF S_FLAG='0' THEN     ------3 IF
            SELECT HH_PN INTO C_KPN FROM IQC.R_KPN_INCOMING_T  WHERE PKG_ID=TRIM(PKG);
            SELECT COUNT(HH_PN) INTO C_COUNT5 FROM IQC.C_KPN_SPEC_T WHERE HH_PN=C_KPN;
		    IF C_COUNT5>0 THEN     --- A IF
		        SELECT COUNT(HH_PN) INTO C_COUNT4 FROM IQC.C_KPN_SPEC_T WHERE HH_PN=C_KPN AND TEST_FLAG=1;
		      IF C_COUNT4>0 THEN    -----B IF
			    RES:='GOTO LCR';
			  ELSE
		          SELECT COUNT(*) INTO C_COUNT2 FROM SFIS1.C_SMT_BOM_T
                   WHERE FEEDER_NO=LOC AND KEY_PART_NO=C_KPN  AND MACHINE_CODE=MACHINE;
                  IF C_COUNT2<1 THEN   ----C IF
	                RES:='KPN NG';
                  ELSE
	                  SELECT COUNT(*) INTO C_COUNT3
	                   FROM SFIS1.C_SMT_BOM_T BOM,
                            SFISM4.R_SMT_PROD_BOM_T PROD
	                   WHERE BOM.BOM_NO=PROD.BOM_NO AND
	                         BOM.FEEDER_NO=LOC AND
							 BOM.MACHINE_CODE=MACHINE AND
		                 	 BOM.KEY_PART_NO=C_KPN;
					IF C_COUNT3>0 THEN
					RES:='OK';
					END IF;
					 IF C_COUNT3<1 THEN
                         	         SELECT COUNT(*) INTO C_COUNT6
                                         FROM SFIS1.C_SMT_BOM_T BOM,
                                              SFISM4.R_SMT_PROD_BOM_T PROD,
                                              SFIS1.C_SMT_KP_SPARE_T SPARE
                                         WHERE BOM.FEEDER_NO = LOC
                                            AND (BOM.KEY_PART_NO = C_KPN OR (SPARE.SPARE_KEY_PART_NO=C_KPN AND SPARE.VALID_DATE>=SYSDATE))
                                            AND BOM.KEY_PART_NO=SPARE.KEY_PART_NO(+)
                                            AND BOM.BOM_NO = PROD.BOM_NO
                                            AND PROD.PRODUCT_NO = PPN
                                            AND BOM.MACHINE_CODE = MACHINE;
                                           IF C_COUNT6>0 THEN
                                            RES:='OK';
                                           END IF;
			            END IF;
				  END IF;   ---C IF END
                END IF;      ----B IF END
		    --      ELSE
			--    RES:='GOTO LCR';
			--  END IF ;               ------- B IF END
		    ELSE
		      RES:='NO HH_PN';
		  END IF ;                   ---- A IF END
		 END IF ;    -------3 IF END
	END IF;
	--ELSE
	-- RES:='DUP PKG,NG';
	--END IF;   ----Z IF END
END IF;             ----- A IF END
   IF RES='OK' THEN
    INSERT INTO SFISM4.R_SMT_LOG_T(
      STATION_NUMBER,MACHINE_CODE, PRODUCT_NO, VER, EMP_NO, FEEDER_NO,
      KEY_PART_NO, WORK_TIME, SN  , LINE_NAME, LOT_NO    )
    VALUES    (
      STATION_NUM, MACHINE, PPN, VER, EMP, LOC, PKG, SYSDATE, 'N/A', LINE, SN );
    COMMIT;
   END IF;

EXCEPTION
   WHEN OTHERS THEN
   RES:='NO PKG';
   C_OUTPUT :=RES;
END;
