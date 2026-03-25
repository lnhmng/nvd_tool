PROCEDURE       Check_Line_kitting(STATION_NUM IN VARCHAR2,MACHINE IN VARCHAR2,
                           PPN IN VARCHAR2,VER IN VARCHAR2,EMP IN VARCHAR2,PLINE in varchar2,
                           LOC IN VARCHAR2,KPN IN VARCHAR2,SN IN VARCHAR2,
                           Line IN VARCHAR2,RES OUT VARCHAR2) IS
C_line_name VARCHAR2(32);
C_OUTPUT VARCHAR2(64);
BEGIN
   SELECT line_name INTO C_line_name FROM sfis1.C_LINE_DESC_T
      WHERE line_name = PLINE AND ROWNUM = 1;
      Insert_Error_Mes(STATION_NUM,MACHINE ,
                           PPN ,VER ,EMP ,
                           LOC ,KPN ,SN ,
                           PLINE , C_OUTPUT );
   RES := 'OK';
EXCEPTION
   WHEN OTHERS THEN
      RES := ' NO LINE';
      C_OUTPUT := RES || ' - ' || LINE ;
      Insert_Error_Mes(STATION_NUM,MACHINE ,
                           PPN ,VER ,EMP ,
                           LOC ,KPN ,SN ,
                           PLINE , C_OUTPUT );

END; 