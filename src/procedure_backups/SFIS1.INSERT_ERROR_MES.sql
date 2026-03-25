PROCEDURE         INSERT_ERROR_MES (STATION_NUM in varchar2,MACHINE in varchar2,
                           PPN in varchar2,VER in varchar2,EMP in varchar2,
                           LOC in varchar2,KPN in varchar2,SN in varchar2,
                           Line in varchar2, MESS in varchar2) is
C_LINE varchar2(32);
begin

   INSERT INTO SFISM4.R_SMT_LOG_ERROR_T (
      STATION_NUMBER,
      MACHINE_CODE,
      PRODUCT_NO,
      VER,
      EMP_NO,
      FEEDER_NO,
      KEY_PART_NO,
      SN  ,
      LINE_NAME,
      ERROR_MESSAGE
    )
    VALUES
    (
      STATION_NUM,
      MACHINE,
      PPN,
      VER,
      EMP,
      substr(LOC,1,12) ,
      KPN,
      SN ,
      LINE,
      MESS
    );
--exception
--   when others then
--      RES := ' INSERT ERROR ';
end;
