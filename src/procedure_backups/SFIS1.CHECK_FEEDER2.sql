procedure CHECK_FEEDER2(STATION_NUM in varchar2,MACHINE in varchar2,
                           PPN in varchar2,VER in varchar2,EMP in varchar2,
                           LOC in varchar2,PKG in varchar2,FEED in varchar2,
                           Line in varchar2,RES out varchar2) is

C_COUNT    varchar2(50);
C_OUTPUT  varchar2(50);

begin

IF LENGTH(FEED)=4 THEN
RES:='OK';
ELSE
RES:='NO FEEDER1';
END IF;

  if res='OK' THEN
      select COUNT(*) INTO C_COUNT from SMTINFO.R_SMT_PKGID_LOG_T WHERE MACHINE_CODE=MACHINE AND TRAIL_NO=LOC and state_flag='N';
      IF C_COUNT>0 THEN
       UPDATE SMTINFO.R_SMT_PKGID_LOG_T SET STATE_FLAG='Y',END_TIME=SYSDATE WHERE MACHINE_CODE=MACHINE AND TRAIL_NO=LOC and state_flag='N';
      END IF;

    INSERT INTO smtinfo.r_smt_pkgid_log_t(
	  STATION_NUMBER,MACHINE_CODE,PRODUCT_NO,EMP_NO,FEEDER_NO,TRAIL_NO,KEY_PART_NO,BEGIN_TIME,END_TIME,
	  LINE_NAME,PKG_ID,STATE_FLAG,FEEDER_STATE)
	VALUES   (
	STATION_NUM,MACHINE,PPN,EMP,FEED,LOC,'N/A',SYSDATE,'',LINE,PKG,'N','');

    COMMIT;
  end if;

exception
   when others then
   RES:='NO FEEDER OTHER ERROR';
   C_OUTPUT :=RES;
end;