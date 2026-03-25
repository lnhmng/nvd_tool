PROCEDURE       MacCharCnt
(
 MACAddr	  IN VARCHAR2,
 LETTER 	  IN VARCHAR2,
 NUMRES 	  OUT NUMBER
)IS
 LetterCNT	  number(2,0);
 MACLEN		  NUMBER(2,0);
 I 			  NUMBER(2,0);
 CurLetter	  CHAR(1);
BEGIN
	MACLEN:=LENGTH(MACAddr);
	I:=1;
	LetterCNT:=0;
	WHILE I<MACLEN+1
	LOOP
		CurLetter:=SUBSTR(MACAddr,I,1);
		IF CurLetter=LETTER THEN
		   LetterCNT:=LetterCNT+1;
		END IF;
        I:=I+1;
	END LOOP;
	NUMRES:=LetterCNT;
EXCEPTION
   WHEN OTHERS THEN
    NUMRES:=12;
END;
/************************************************
VERSION:1.0
PROCEDURE FOR: ICT INTEGRATED FOE MAC FLASH
CREATE DATE: NOV,5,2005
CREATED BY: Anthony Zhang
*************************************************/
