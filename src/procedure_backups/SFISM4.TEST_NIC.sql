PROCEDURE        Test_NIC (
DATA   	  	         IN VARCHAR2,
NIC 	             IN VARCHAR2,
BIOS                 IN VARCHAR2,
RESERVEDATA          IN VARCHAR2,
RES		       	     OUT VARCHAR2
) AS
SN_COUNT	         VARCHAR(20);----SN count in SFISM4.R_MB_BIOSNIC_T
NIC_COUNT            VARCHAR(20);
p_FIRST_NIC          VARCHAR(20);
p_LAST_NIC	         VARCHAR(20);
STANDARD_NIC         VARCHAR(20);
v_SNCNT				 NUMBER(1,0);----SN count in SFISM4.R_WIP_TRACKING_T

e_NO_SN   			 EXCEPTION;
e_ERROR_NICVERSION   EXCEPTION;
BEGIN
--CHECK THE SERIAL NUMBER EXSISTANCE
SELECT COUNT(SERIAL_NUMBER)
INTO v_SNCNT
FROM SFISM4.R_WIP_TRACKING_T
WHERE SERIAL_NUMBER=DATA;

IF v_SNCNT=0 THEN
   RAISE e_NO_SN;
END IF;
-------------------NIC Control --Added by Anthony on 2005-04-19----------------------
if LENGTH(NIC)<2 then
   RES:='OK';
end if;

if LENGTH(NIC)>1 then   ----Because not all the MB will upload NIC to SFC
   select NIC_VERSION
   into STANDARD_NIC
   from SFIS1.C_MB_BIOSNIC_T
   where rownum=1;

   select Count(*)
   into SN_COUNT
   from SFISM4.R_MB_BIOSNIC_T
   where SERIAL_NUMBER=DATA;

   if SN_COUNT=0 then
   	  insert into sfism4.R_MB_BIOSNIC_T(SERIAL_NUMBER,MODEL_NAME,FIRST_BIOS,LAST_BIOS,FIRST_NIC,LAST_NIC,DATETIME,RESERVE1)
	  values(DATA,'','','',NIC,'',sysdate,'');
	  commit;

	  if STANDARD_NIC<>NIC then
	     RAISE e_ERROR_NICVERSION;
	  end if;
	  RES:='OK';
   end if;

   if SN_COUNT>0 then

	  select FIRST_NIC,LAST_NIC
	  into p_FIRST_NIC,p_LAST_NIC
	  from SFISM4.R_MB_BIOSNIC_T
	  where SERIAL_NUMBER=DATA;

      if (p_FIRST_NIC is null) and (p_LAST_NIC is null) then
          update sfism4.R_MB_BIOSNIC_T
    	  set FIRST_NIC=NIC,DATETIME=sysdate
    	  WHERE SERIAL_NUMBER=DATA;
    	  commit;
	  end if;

      if (p_FIRST_NIC is not null) or (p_LAST_NIC is not null) then
          update sfism4.R_MB_BIOSNIC_T
    	  set LAST_NIC=NIC,DATETIME=sysdate
    	  WHERE SERIAL_NUMBER=DATA;
    	  commit;
	  end if;

	  if STANDARD_NIC<>NIC then
	     RAISE e_ERROR_NICVERSION;
	  end if;
	  RES:='OK';
   end if;
end if;
--------------------------------------------------------------------------------------
-- EXCEPTION HANDLE BLOCK
EXCEPTION
		  WHEN e_NO_SN THEN
		  	   BEGIN
		  	   		RES:='NO SN';
			   END;
          WHEN e_ERROR_NICVERSION THEN
		       BEGIN
			        RES:='NIC VERSION ERROR';
			   END;
		  WHEN OTHERS THEN
		  	   RES:='DATA NO FOUND';
END;
/* ******************************************************
Revision:1.0
CREATED BY: Anthony Zhang
CREATE DATE: 04-19-2005

FOR: M/b NIC(FORMWARE) VERSION Control
RES:
0- OK
1- Error
******************************************************** */
