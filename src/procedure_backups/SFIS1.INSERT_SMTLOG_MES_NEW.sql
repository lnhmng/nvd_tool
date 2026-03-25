PROCEDURE       INSERT_SMTLOG_MES_NEW (STATION_NUM in varchar2,MACHINE in varchar2,
                           PPN in varchar2,VER in varchar2,EMP in varchar2,
                           LOC in varchar2,KPN in varchar2,SN in varchar2,
                           Line in varchar2,QTY in varchar2,MO in varchar2) is
begin

   INSERT INTO sfism4.r_smt_log_t(
      STATION_NUMBER,
      MACHINE_CODE,
      PRODUCT_NO,
      VER,
      EMP_NO,
      FEEDER_NO,
      KEY_PART_NO,
      WORK_TIME,
      SN  ,
      LINE_NAME,
      LOT_NO,
	  QTY ,
	  MO_NO
    )
    VALUES
    (
      STATION_NUM,
      MACHINE,
      PPN,
      VER,
      EMP,
      LOC,
      KPN,
      SYSDATE,
      'N/A',
      LINE,
      SN,
	  QTY,
	  MO
    );
    COMMIT;
--exception
--  when others then
 --    RES := ' INSERT ERROR ';
end;
