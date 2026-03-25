procedure       PS2_CHECK_LINE_ONLINE(STATION_NUM in varchar2,MACHINE in varchar2,
                           PPN in varchar2,VER in varchar2,EMP in varchar2,
                           LOC in varchar2,KPN in varchar2,SN in varchar2,
                           Line in varchar2,RES out varchar2) is
C_LINE varchar2(32);
C_OUTPUT varchar2(64);
KPN_NEW VARCHAR2(32);
begin
   KPN_NEW:=SFIS1.GETKEYPART(KPN);

   select LINE_NAME into C_LINE from sfism4.r_smt_prod_bom_t A,sfis1.c_smt_bom_t b
      where a.LINE_NAME = LINE  and a.PRODUCT_NO= PPN AND a.BOM_NO=b.BOM_NO AND
            b.MACHINE_CODE=MACHINE  and rownum = 1;
   RES := 'OK';
exception
   when others then
      RES := ' NO LINE ';
      C_OUTPUT := RES || ' - ' || LINE;
      INSERT_ERROR_MES(STATION_NUM,MACHINE ,
                           PPN ,VER ,EMP ,
                           LOC ,KPN_NEW ,SN ,
                           Line , C_OUTPUT );

end;
