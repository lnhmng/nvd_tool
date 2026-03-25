procedure       CHECK_PPN_ONLINE_KITTING(STATION_NUM in varchar2,MACHINE in varchar2,
                           PPN in varchar2,VER in varchar2,EMP in varchar2,PLINE in varchar2,
                           LOC in varchar2,KPN in varchar2,SN in varchar2,
                           Line in varchar2,RES out varchar2) is
C_PPN varchar2(32);
C_OUTPUT varchar2(64);
begin

  
   select product_no into C_PPN from sfism4.r_smt_prod_bom_t
      where product_no = PPN  and rownum = 1;
   RES := 'OK';
exception
   when others then
      RES := 'PPN NG ';
      C_OUTPUT:=RES || ' - ' || PPN;
      INSERT_ERROR_MES(STATION_NUM,MACHINE ,
                           PPN ,VER ,EMP ,
                           LOC ,KPN ,SN ,
                           PLINE , C_OUTPUT );

end; 