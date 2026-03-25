procedure       PS2_CHECK_PPN (STATION_NUM in varchar2,MACHINE in varchar2,
                           PPN in varchar2,VER in varchar2,EMP in varchar2,
                           LOC in varchar2,KPN in varchar2,SN in varchar2,
                           Line in varchar2,RES out varchar2) is
C_PPN varchar2(32);
C_OUTPUT varchar2(64);
KPN_NEW varchar2(32);
begin
   KPN_NEW:=SFIS1.GETKEYPART(KPN);
   select key_part_no into C_PPN from sfis1.c_smt_kp_t
      where key_part_no = PPN and kp_distinct = '0'
         and rownum = 1;
   RES := 'OK';
exception
   when others then
      RES := ' NO PPN';
      C_OUTPUT := RES || ' - ' || PPN;
      INSERT_ERROR_MES(STATION_NUM,MACHINE ,
                           PPN ,VER ,EMP ,
                           LOC ,KPN_NEW ,SN ,
                           Line , C_OUTPUT );

end;
