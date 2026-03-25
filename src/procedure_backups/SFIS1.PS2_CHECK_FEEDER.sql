procedure PS2_CHECK_FEEDER(STATION_NUM in varchar2,MACHINE in varchar2,
                           PPN in varchar2,VER in varchar2,EMP in varchar2,
                           LOC in varchar2,KPN in varchar2,SN in varchar2,
                           Line in varchar2,RES out varchar2) is
C_KPN varchar2(32);
C_OUTPUT varchar2(64);
KPN_NEW VARCHAR2(32);
begin
   KPN_NEW:=SFIS1.GETKEYPART(KPN);

   select bom.key_part_no into C_KPN
      from sfis1.c_smt_bom_t bom,sfism4.r_smt_prod_bom_t prod
      where bom.feeder_no = LOC and bom.bom_no = prod.bom_no
         and prod.product_no = PPN and prod.ver = VER and BOM.machine_code = MACHINE
         and rownum = 1;
   RES := 'OK';
exception
   when others then
      RES := ' NO FEEDER';
      C_OUTPUT:= RES || ' - ' || LOC;
      INSERT_ERROR_MES(STATION_NUM,MACHINE ,
                           PPN ,VER ,EMP ,
                           LOC ,KPN_NEW ,SN ,
                           Line , C_OUTPUT );

end;
