PROCEDURE         CHECK_SMT_KPN_LOT (STATION_NUM in varchar2,MACHINE in varchar2,
                           PPN in varchar2,VER in varchar2,EMP in varchar2,
                           LOC in varchar2,KPN in varchar2,SN in varchar2,
                           Line in varchar2,RES out varchar2) is
C_KPN varchar2(32);
C_OUTPUT varchar2(64);
V_TEMP_KP varchar2(32);
V_TEMP_KP2 varchar2(32);
C_COUNT  number ;
begin
   if substr(KPN,1,3)='3N1' then 
      IF substr(KPN,4,1)=' ' then
         IF substr(KPN,6,1)='-' then
             V_TEMP_KP:=substr(KPN,5,12); 
         else   
            V_TEMP_KP:=substr(KPN,5,9); 
         end if;
      else
         IF substr(KPN,5,1)='-' then
             V_TEMP_KP:=substr(KPN,4,12); 
         else   
            V_TEMP_KP:=substr(KPN,4,9); 
         end if;
      end if;              
      IF substr(V_TEMP_KP,2,1)='-' THEN
         V_TEMP_KP2:=V_TEMP_KP;
      ELSE 
         V_TEMP_KP2:=substr(V_TEMP_KP,1,1) || '-' || substr(V_TEMP_KP,2,3) || '-' || substr(V_TEMP_KP,5,3) || '-' || substr(V_TEMP_KP,8,2);       
      END IF;

      select key_part_no into C_KPN from sfis1.c_smt_kp_t
      where (key_part_no =V_TEMP_KP OR key_part_no=V_TEMP_KP2) and kp_distinct = '1'
         and rownum = 1;
      select count(*) into C_COUNT
      from sfis1.c_smt_bom_t bom,sfism4.r_smt_prod_bom_t prod,sfis1.c_smt_kp_spare_t spare
      where bom.feeder_no = LOC 
            and (bom.key_part_no =V_TEMP_KP or bom.key_part_no =V_TEMP_KP2 or((spare.spare_key_part_no=V_TEMP_KP)or(spare.spare_key_part_no=V_TEMP_KP2) and spare.valid_date>=sysdate))
            and bom.key_part_no=spare.key_part_no(+)
           and bom.bom_no = prod.bom_no  and prod.product_no = PPN
           and prod.ver = VER and BOM.machine_code = MACHINE;
   else 
      select key_part_no into C_KPN from sfis1.c_smt_kp_t
      where key_part_no = KPN and kp_distinct = '1'
         and rownum = 1;
      select count(*) into C_COUNT
      from sfis1.c_smt_bom_t bom,sfism4.r_smt_prod_bom_t prod,sfis1.c_smt_kp_spare_t spare
      where bom.feeder_no = LOC 
            and (bom.key_part_no = KPN or (spare.spare_key_part_no=KPN and spare.valid_date>=sysdate))
            and bom.key_part_no=spare.key_part_no(+)
           and bom.bom_no = prod.bom_no  and prod.product_no = PPN
           and prod.ver = VER and BOM.machine_code = MACHINE;
    end if;   
   IF C_COUNT=0 THEN
      RES := 'KPN NG ';  
      C_OUTPUT := RES || ' - ' || V_TEMP_KP2 ;
      INSERT_ERROR_MES(STATION_NUM,MACHINE ,
                           PPN ,VER ,EMP ,
                           LOC ,KPN ,SN ,
                           Line , C_OUTPUT );
   ELSE
       RES := 'OK';
   END IF;
exception
   when others then
      RES := ' NO KPN';
      C_OUTPUT:= RES || ' - ' || KPN; 
      INSERT_ERROR_MES(STATION_NUM,MACHINE ,
                           PPN ,VER ,EMP ,
                            LOC ,KPN ,SN ,
                           Line , C_OUTPUT );

end;

