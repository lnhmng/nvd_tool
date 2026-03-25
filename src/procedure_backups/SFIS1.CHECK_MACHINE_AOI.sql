procedure       CHECK_MACHINE_AOI(
                            MACHINE in varchar2,
                            Line    in VARCHAR2,
                            RES     out varchar2) is
C_MACHINE  varchar2(32);
C_OUTPUT   varchar2(64);

begin
   select station_code into C_MACHINE from sfis1.c_ict_station_t
      where station_code = MACHINE 
      AND LINE_NAME LIKE substr(Line,1,length(Line)-1)||'%' 
      AND GROUP_NAME LIKE 'AOI%';
      
   RES := 'OK';
exception
   when others then
      RES := 'NO MAC';
end;