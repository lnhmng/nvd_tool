PROCEDURE        Test_BIOS(
DATA   	  	         IN VARCHAR2,
NIC 	             IN VARCHAR2,
BIOS                 IN VARCHAR2,
MODEL_NAME           IN VARCHAR2,
RES		       	     OUT VARCHAR2
) AS
SN_COUNT	         VARCHAR(20);----SN count in SFISM4.R_MB_BIOSNIC_T
BIOS_COUNT            VARCHAR(20);
p_FIRST_BIOS          VARCHAR(20);
p_LAST_BIOS	         VARCHAR(20);
STANDARD_BIOS         VARCHAR(20);
v_SNCNT				 NUMBER(1,0);----SN count in SFISM4.R_WIP_TRACKING_T

e_NO_SN   			 EXCEPTION;
e_ERROR_BIOSVERSION   EXCEPTION;
BEGIN
--CHECK THE SERIAL NUMBER EXSISTANCE
SELECT COUNT(SERIAL_NUMBER)
INTO v_SNCNT
FROM SFISM4.R_WIP_TRACKING_T
WHERE SERIAL_NUMBER=DATA;

IF v_SNCNT=0 THEN
   RAISE e_NO_SN;
END IF;
-------------------BIOS Control --Added by Anthony on 2005-08-08----------------------
if LENGTH(BIOS)<2 then
   RES:='OK';
end if;

if LENGTH(BIOS)>1 then   ----Because not all the MB will upload NIC to SFC
   select BIOS_VERSION
   into STANDARD_BIOS
   from SFIS1.C_MB_BIOSNIC_T
   where rownum=1;

   select Count(*)
   into SN_COUNT
   from SFISM4.R_MB_BIOSNIC_T
   where SERIAL_NUMBER=DATA;

   if SN_COUNT=0 then
   	  insert into sfism4.R_MB_BIOSNIC_T(SERIAL_NUMBER,MODEL_NAME,FIRST_BIOS,LAST_BIOS,FIRST_NIC,LAST_NIC,DATETIME,RESERVE1)
	  values(DATA,'',BIOS,'','','',sysdate,'');
	  commit;

	  if STANDARD_BIOS<>BIOS then
	     RAISE e_ERROR_BIOSVERSION;
	  end if;
	  RES:='OK';
   end if;

   if SN_COUNT>0 then

	  select FIRST_BIOS,LAST_BIOS
	  into p_FIRST_BIOS,p_LAST_BIOS
	  from SFISM4.R_MB_BIOSNIC_T
	  where SERIAL_NUMBER=DATA;

      if (p_FIRST_BIOS is null) and (p_LAST_BIOS is null) then
          update sfism4.R_MB_BIOSNIC_T
    	  set FIRST_BIOS=BIOS,DATETIME=sysdate
    	  WHERE SERIAL_NUMBER=DATA;
    	  commit;
	  end if;

      if (p_FIRST_BIOS is not null) or (p_LAST_BIOS is not null) then
          update sfism4.R_MB_BIOSNIC_T
    	  set LAST_BIOS=BIOS,DATETIME=sysdate
    	  WHERE SERIAL_NUMBER=DATA;
    	  commit;
	  end if;

	  if STANDARD_BIOS<>BIOS then
	     RAISE e_ERROR_BIOSVERSION;
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
          WHEN e_ERROR_BIOSVERSION THEN
		       BEGIN
			        RES:='BIOS VERSION ERROR';
			   END;
		  WHEN OTHERS THEN
		  	   RES:='DATA NO FOUND';
END;
/* ******************************************************
Revision:1.0
CREATED BY: Anthony Zhang
CREATE DATE: 08-08-2005

FOR: M/b BIOS VERSION Control
******************************************************** */
