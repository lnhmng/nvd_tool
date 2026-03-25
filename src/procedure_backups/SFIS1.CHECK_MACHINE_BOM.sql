procedure       CHECK_MACHINE_BOM(STATION_NUM in varchar2,MACHINE in varchar2,
                           PPN in varchar2,VER in varchar2,EMP in varchar2,
                           LOC in varchar2,KPN in varchar2,SN in varchar2,
                           Line in varchar2,RES out varchar2) is
C_BOM_NO varchar2(200);
C_OUTPUT varchar2(64);
begin
   select BOM_NO into C_BOM_NO from sfis1.C_SMT_BOM_T
      where machine_code = MACHINE and rownum = 1;
   RES := 'OK';
exception
   when others then
      RES := 'MAC NG ';
      C_OUTPUT := RES || ' - ' || MACHINE;
      INSERT_ERROR_MES(STATION_NUM,MACHINE ,
                           PPN ,VER ,EMP ,
                           LOC ,KPN ,SN ,
                           Line , C_OUTPUT );

end;
