PROCEDURE        Test_FBT_NIC (
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
e_ERROR_NONICDATA 	 EXCEPTION;
BEGIN
--CHECK THE SERIAL NUMBER EXSISTANCE
SELECT COUNT(SERIAL_NUMBER)
INTO v_SNCNT
FROM SFISM4.R_WIP_TRACKING_T
WHERE SERIAL_NUMBER=DATA;

IF v_SNCNT=0 THEN
   RAISE e_NO_SN;
END IF;

if LENGTH(NIC)<2 then   -----NIC's lenght will not less than 2
   RES:='NIC NOT UPLOADED';
end if;

if LENGTH(NIC)>1 then
   select NIC_VERSION
   into STANDARD_NIC
   from SFIS1.C_MB_BIOSNIC_T
   where rownum=1;

   select Count(*)
   into SN_COUNT
   from SFISM4.R_MB_BIOSNIC_T
   where SERIAL_NUMBER=DATA;

   if SN_COUNT=0 then
	  RAISE e_ERROR_NONICDATA;
   end if;

   if SN_COUNT>0 then
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
			        RES:='NIC VERSION WRONG';
			   END;
          WHEN e_ERROR_NONICDATA THEN
		       BEGIN
			        RES:='NIC DATA NOT DOUND';
			   END;
		  WHEN OTHERS THEN
		  	   RES:='DATA NOT FOUND';
END;
/* ******************************************************
Revision:1.0
CREATED BY: Anthony Zhang
CREATE DATE: 08-09-2005

FOR: M/b NIC(FORMWARE) VERSION Control
RES:
0- OK
1- Error
*********************************************************/
