PROCEDURE             Check_Sn_Qty(GQTY IN VARCHAR2,RES OUT VARCHAR2)
IS
BEGIN
--Modified by Toly Lee on 2010/04/07 for 1NRC-100407-01 Begin
    IF GQTY > 0 AND GQTY <=100  THEN
     RES := 'OK';
--Modified by Toly Lee on 2010/04/07 for 1NRC-100407-01 End
 ELSE
     RES := 'GQTY ERROR';
 END IF;

EXCEPTION
 WHEN OTHERS THEN
        RES := 'GQTY ERROR';
END;
