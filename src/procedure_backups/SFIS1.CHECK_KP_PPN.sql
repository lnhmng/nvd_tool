procedure       CHECK_KP_PPN(STATION_NUM in varchar2,MACHINE in varchar2,
                           PN in varchar2,VER in varchar2,EMP in varchar2,
                           LOC in varchar2,DATA in varchar2,SN in varchar2,
                           Line in varchar2,RES out varchar2) is
C_PPN varchar2(32);
C_COUNT        NUMBER;

begin

SELECT   COUNT ( * )
  INTO   C_COUNT
  FROM   sfis1.C_ITEM_DESC_T a, SFIS1.C_PARAMETER_INI b
 WHERE       (a.item_serial = DATA OR a.item_serial =DATA||'HF')
         AND a.item_code = b.vr_name
         AND b.PRG_NAME = 'SMO'
         AND b.VR_CLASS = 'itemcode'
         AND b.VR_ITEM = 'itemcode';
    
     IF C_COUNT = 0 THEN
       res := DATA|| ' - ' ||'NO ITEM CODE';
       RETURN;
    END IF; 
  
  
   RES := 'OK';
exception
   when others then
      RES := DATA|| ' - ' ||' NO itemcode';

end;