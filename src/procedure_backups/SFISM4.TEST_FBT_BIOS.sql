PROCEDURE        Test_FBT_BIOS(
DATA   	  	         IN VARCHAR2,
NIC 	             IN VARCHAR2,
BIOS                 IN VARCHAR2,
MODEL_NAME           IN VARCHAR2,
RES		       	     OUT VARCHAR2
) AS
SN_COUNT	          VARCHAR(20);----SN count in SFISM4.R_MB_BIOSNIC_T
BIOS_COUNT            VARCHAR(20);
p_FIRST_BIOS          VARCHAR(20);
p_LAST_BIOS	          VARCHAR(20);
STANDARD_BIOS         VARCHAR(20);
v_SNCNT				  NUMBER(1,0);----SN count in SFISM4.R_WIP_TRACKING_T

e_NO_SN   			  EXCEPTION;
e_ERROR_BIOSVERSION   EXCEPTION;
e_ERROR_NOBIOSDATA 	  EXCEPTION;

BEGIN
--CHECK THE SERIAL NUMBER EXSISTANCE
SELECT COUNT(SERIAL_NUMBER)
INTO v_SNCNT
FROM SFISM4.R_WIP_TRACKING_T
WHERE SERIAL_NUMBER=DATA;

IF v_SNCNT=0 THEN
   RAISE e_NO_SN;
END IF;
-------------------BIOS Control --Added by Anthony on 2005-08-09----------------------
if LENGTH(BIOS)<2 then
   RES:='BIOS DATA NOT UPLOADED';
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
	  RAISE e_ERROR_NOBIOSDATA;
   end if;

   if SN_COUNT>0 then
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
			        RES:='BIOS VERSION WRONG';
			   END;
          WHEN e_ERROR_NOBIOSDATA THEN
		       BEGIN
			        RES:='BIOS DATA NOT FOUND';
			   END;
		  WHEN OTHERS THEN
		  	   RES:='DATA NOT FOUND';
END;
/* ******************************************************
Revision:1.0
CREATED BY: Anthony Zhang
CREATE DATE: 08-09-2005

FOR: M/b BIOS VERSION Control
******************************************************** */
