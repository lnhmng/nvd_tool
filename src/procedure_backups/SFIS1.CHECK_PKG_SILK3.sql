procedure CHECK_PKG_SILK3(STATION_NUM in varchar2,MACHINE in varchar2,
                           PPN in varchar2,VER in varchar2,EMP in varchar2,
                           LOC in varchar2,PKG in varchar2,SN in varchar2,
                           Line in varchar2,RES out varchar2) is
C_KPN varchar2(32);
S_FLAG varchar2(1);
C_COUNT1 varchar2(5);
C_COUNT2 varchar2(5);
C_COUNT3 varchar2(5);
C_COUNT4 varchar2(5);
C_COUNT5 varchar2(5);
C_COUNT6 varchar2(5);
C_COUNT7 varchar2(5);
C_COUNT8 varchar2(5);
C_COUNT9 varchar2(5);
C_COUNT10 varchar2(5);
C_OUTPUT varchar2(64);
begin
 -- SELECT COUNT(*) INTO C_COUNT10 FROM smtinfo.R_PKGID_LOG_T WHERE key_part_no=trim(PKG);
  --IF C_COUNT10>=1 THEN
 -- RES:='DUP PKG,NG';
 -- ELSE
   select count(*) into C_COUNT1 from IQC.R_KPN_INCOMING_T  WHERE  pkg_id=trim(PKG);
   if C_COUNT1=0 THEN      ------A if
     RES:='PKG NG';
   else
     select STATE_FLAG INTO S_FLAG  from iqc.r_kpn_incoming_t where pkg_id=trim(PKG);
         if S_FLAG = 'P' THEN   ------1 if
	              SELECT HH_PN into C_KPN FROM IQC.R_KPN_INCOMING_T  WHERE pkg_id=trim(PKG);
       --     select count(HH_PN) INTO C_COUNT6 FROM IQC.C_KPN_SPEC_T WHERE HH_PN=C_KPN;
		           SELECT COUNT(*) into C_COUNT8 FROM sfis1.c_smt_bom_t
                   where feeder_no=LOC and key_part_no=C_KPN  and machine_code=machine;
                     IF C_COUNT8=0 THEN   ---a if
	                   RES:='KPN NG';
                     end if;              ---a if end
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
                         from sfis1.c_smt_bom_t bom,
                              sfism4.r_smt_prod_bom_t prod,
                              sfis1.c_smt_kp_spare_t spare
                         where bom.feeder_no = LOC
                            and (bom.key_part_no = C_KPN or (spare.spare_key_part_no=C_KPN and spare.valid_date>=sysdate))
                            and bom.key_part_no=spare.key_part_no(+)
                            and bom.bom_no = prod.bom_no
                            and prod.product_no = PPN
                            and BOM.machine_code = MACHINE;
                         IF C_COUNT7>0 THEN
                           RES:='OK';
                         ELSE
                           RES:='KPN NG';
                         END IF;
                      END IF;
	---               IF C_COUNT9=0 THEN
	---                 RES:='KPN NG';
	---               ELSE
        ---             RES:='OK';
        ---           end if;
           end if;          -------1 if end
         IF S_FLAG='F' THEN  -----2 if
              RES:='PKG NG';
         end if;             ------2 if end
         IF S_FLAG='0' THEN     ------3 if
            SELECT HH_PN into C_KPN FROM IQC.R_KPN_INCOMING_T  WHERE pkg_id=trim(PKG);
            select count(HH_PN) INTO C_COUNT5 FROM IQC.C_KPN_SPEC_T WHERE HH_PN=C_KPN;
		    IF C_COUNT5>0 THEN     --- a if
		        SELECT COUNT(HH_PN) INTO C_COUNT4 FROM IQC.C_KPN_SPEC_T WHERE HH_PN=C_KPN AND TEST_FLAG=1;
		      IF C_COUNT4>0 THEN    -----b if
			    RES:='GOTO LCR';
			  ELSE
		          SELECT COUNT(*) into C_COUNT2 FROM sfis1.c_smt_bom_t
                   where feeder_no=LOC and key_part_no=C_KPN  and machine_code=machine;
                  IF C_COUNT2=0 THEN   ----c if
	                RES:='KPN NG';
                  end if;              ----c if end
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
							            if C_COUNT3=0 THEN
                         	         SELECT COUNT(*) INTO C_COUNT6
                                         from sfis1.c_smt_bom_t bom,
                                              sfism4.r_smt_prod_bom_t prod,
                                              sfis1.c_smt_kp_spare_t spare
                                         where bom.feeder_no = LOC
                                            and (bom.key_part_no = C_KPN or (spare.spare_key_part_no=C_KPN and spare.valid_date>=sysdate))
                                            and bom.key_part_no=spare.key_part_no(+)
                                            and bom.bom_no = prod.bom_no
                                            and prod.product_no = PPN
                                            and BOM.machine_code = MACHINE;
                                           IF C_COUNT6>0 THEN
                                            RES:='OK';
                                           END IF;
			            END IF;
                END IF;
		    --      else
			--    RES:='GOTO LCR';
			--  END IF ;               ------- b if end
		    else
		      RES:='NO HH_PN';
		  END IF ;                   ---- a if end
		 end if ;       -------3 if end
end if;
--end if;
exception
   when others then
   RES:='NO PKG';
   C_OUTPUT :=RES;
end;

/* FOR IBM SCAN PKG (FOR SILK)
   CREATE BY ZHANGYUN
   2003-12-19
*/
