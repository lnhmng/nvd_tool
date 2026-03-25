procedure       CHECK_PPN_2016(STATION_NUM in varchar2,MACHINE in varchar2,
                           PN in varchar2,VER in varchar2,EMP in varchar2,
                           LOC in varchar2,KPN in varchar2,SN in varchar2,
                           Line in varchar2,RES out varchar2) is
C_PPN varchar2(32);
C_OUTPUT varchar2(64);
begin
   select key_part_no into C_PPN from sfis1.c_smt_kp_t
      where   (key_part_no = PN || 'HF' OR key_part_no = PN || 'G' OR key_part_no = PN) and kp_distinct = '1'
         and rownum = 1;
   RES := 'OK';
exception
   when others then
      RES := ' NO PN';
      C_OUTPUT := RES || ' - ' || PN;
      INSERT_ERROR_MES(STATION_NUM,MACHINE ,
                           PN ,VER ,EMP ,
                           LOC ,KPN ,SN ,
                           Line , C_OUTPUT );

end; 