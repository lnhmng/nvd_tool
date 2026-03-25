PROCEDURE CHECK_SMT_EMP(STATION_NUM in varchar2,MACHINE in varchar2,
                           PPN in varchar2,VER in varchar2,EMP in varchar2,
                           LOC in varchar2,KPN in varchar2,SN in varchar2,
                           Line in varchar2,RES out varchar2) IS

   C_EMP_ID    VARCHAR2(25);
   C_OUTPUT varchar2(64);
BEGIN

   SELECT EMP_NO  INTO C_EMP_ID
      FROM SFIS1.C_EMP_DESC_T
      WHERE EMP_NO = EMP  AND ROWNUM = 1;

   RES:='OK';

exception

   when NO_DATA_FOUND then
      RES:=' NO EMP';
  C_OUTPUT :=RES || ' - ' || EMP;
  INSERT_ERROR_MES(STATION_NUM,MACHINE ,
                           PPN ,VER ,EMP ,
                           LOC ,KPN ,SN ,
                           Line , C_OUTPUT );


END;
