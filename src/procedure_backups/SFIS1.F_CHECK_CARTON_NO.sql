PROCEDURE F_CHECK_CARTON_NO(DATA IN VARCHAR2,
   RES OUT VARCHAR2) AS
p_FLAG VARCHAR2(1);
BEGIN
   p_FLAG:= substr(DATA, 11,1);
   if (p_FLAG <> 'C') then
      RES := ' NO CTN';
   else
      RES := 'OK';
   end if;
exception
   when others then
      RES:=' NO CTN';
END;

