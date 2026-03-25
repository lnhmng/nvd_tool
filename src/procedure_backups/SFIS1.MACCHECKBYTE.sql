PROCEDURE       MacCheckByte
(
 MACAddr	  IN VARCHAR2,
 RES 	  	  OUT VARCHAR2
)IS
 MACLEN		  NUMBER(2,0);
 I 			  NUMBER(2,0);
 CurLetter	  CHAR(1);
BEGIN
	RES:='true';
	MACLEN:=LENGTH(MACAddr);
	I:=1;
	WHILE I<MACLEN+1
	LOOP
		CurLetter:=SUBSTR(MACAddr,I,1);
		--IF CurLetter<>'0' and CurLetter<>'1' and CurLetter<>'2' and CurLetter<>'3' and CurLetter<>'4' and CurLetter<>'5' and CurLetter<>'6' and
		--CurLetter<>'7' and CurLetter<>'8' and CurLetter<>'9' and CurLetter<>'A' and CurLetter<>'B' and CurLetter<>'C' and CurLetter<>'D' and
		--CurLetter<>'E' and CurLetter<>'F' THEN
		IF CurLetter not in ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F') THEN
		   RES:='false';
		END IF;
        I:=I+1;
	END LOOP;
EXCEPTION
   WHEN OTHERS THEN
      RES:='false';
END;
/************************************************
VERSION:1.0
PROCEDURE FOR: ICT INTEGRATED FOE MAC FLASH
CREATE DATE: NOV,5,2005
CREATED BY: Anthony Zhang
*************************************************/
