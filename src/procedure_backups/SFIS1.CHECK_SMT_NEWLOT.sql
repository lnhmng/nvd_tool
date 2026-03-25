PROCEDURE         CHECK_SMT_NEWLOT (STATION_NUM in varchar2,MACHINE in varchar2,
                           PPN in varchar2,VER in varchar2,EMP in varchar2,
                           LOC in varchar2,KPN in varchar2,LOT in varchar2,
                           Line in varchar2,RES out varchar2) is
C_KPN varchar2(32);
C_OUTPUT varchar2(64);
V_TEMP_KP varchar2(9);
V_TEMP_KP2 varchar2(12);
begin
   if substr(KPN,1,3)='3N1' then
             if substr(LOT,1,3)='3N2' then 
                  RES:='OK';
             else
                 C_OUTPUT := RES || ' - ' || LOT ;
                  RES :='LOT NG';
             end if;  
   else 
             RES:='OK'; 
   end if; 
   IF RES='OK' THEN 
                 INSERT_SMTLOG_MES(STATION_NUM,MACHINE ,
                           PPN ,VER ,EMP ,
                           LOC ,KPN ,LOT ,
                           Line); 
   ELSE 
                 INSERT_ERROR_MES(STATION_NUM,MACHINE ,
                           PPN ,VER ,EMP ,
                           LOC ,KPN ,LOT ,
                           Line , C_OUTPUT );

   END IF; 
exception
   when others then
      RES :='LOT NG ';
      C_OUTPUT := RES || ' - ' || LOT ;
      INSERT_ERROR_MES(STATION_NUM,MACHINE ,
                           PPN ,VER ,EMP ,
                           LOC ,KPN ,LOT ,
                           Line,C_OUTPUT);

end;

