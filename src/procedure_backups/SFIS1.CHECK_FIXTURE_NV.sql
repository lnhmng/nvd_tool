PROCEDURE       CHECK_FIXTURE_NV
(
  FIX            IN     VARCHAR2,
  RES            OUT VARCHAR2
)
AS
e_FIX_ERROR EXCEPTION;
BEGIN
    --Added by Steven Hu on 2009/9/18 for 1146-090918-01 Begin
    IF LENGTH(FIX) = 5 THEN
        RES:='OK';
        RETURN;
    END IF;
    --Added by Steven Hu on 2009/9/18 for 1146-090918-01 End
    --Modified by Alex Wnag on 2010/01/21 for 1ERY-100121-01 Begin
    
  /*  IF (LENGTH(FIX) = 8) THEN--  Modefied By DerricK chow 2013-04-29 for S0000013JT Begin  
        IF (SUBSTR(FIX,1,5) <> 'NV FT') OR (TO_NUMBER(SUBSTR(FIX,6,3)) > 999 OR TO_NUMBER(SUBSTR(FIX,6,3)) < 000) THEN
            RAISE e_FIX_ERROR;
        END IF;
    ELSIF (LENGTH(FIX) = 9) THEN
        IF (SUBSTR(FIX,1,5) <> 'NV FT') OR (TO_NUMBER(SUBSTR(FIX,6,4)) > 9999 OR TO_NUMBER(SUBSTR(FIX,6,4)) < 0000) THEN
            RAISE e_FIX_ERROR;
        END IF;
        -- ADD BY Derrick begin
        ELSIF (LENGTH(FIX) = 6) THEN */   -- Modefied By DerricK chow 2013-04-29 for S0000013JT end       
       IF (LENGTH(FIX) = 6) THEN
        IF (SUBSTR(FIX,1,2) <> 'NV') OR (TO_NUMBER(SUBSTR(FIX,3,4)) > 9999 OR TO_NUMBER(SUBSTR(FIX,3,4)) < 0000) THEN
            RAISE e_FIX_ERROR;
        END IF;
        --- add by Derrick end;
    ELSE
        RAISE e_FIX_ERROR;
    END IF;
    --Modified by Alex Wnag on 2010/01/21 for 1ERY-100121-01 End


     RES := 'OK';

EXCEPTION
         WHEN e_FIX_ERROR THEN
               RES := 'FLAT ERROR!';
         WHEN OTHERS THEN
              RES := 'SFIS1.CHECK_FIXTURE_NV OTHER ERROR '||SUBSTR(SQLERRM,1,10);
END; 