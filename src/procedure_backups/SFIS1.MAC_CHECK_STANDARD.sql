PROCEDURE       MAC_CHECK_STANDARD
(
 MACADDR      IN  VARCHAR2,
 RES          OUT VARCHAR2
)IS
 MACLEN       NUMBER(2,0);
 I            NUMBER(2,0);
 CURLETTER    CHAR(1);
 
 e_NULL       EXCEPTION;
BEGIN
    MACLEN:=LENGTH(MACADDR);
    IF MACLEN<>'12' THEN
        RES := 'MAC''S LENGTH MUST BE ''12''!';
        RAISE e_NULL;
    END IF;
    
    I:=1;
    WHILE I<MACLEN+1
    LOOP
        CURLETTER:=SUBSTR(MACADDR,I,1);
        IF CURLETTER NOT IN ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z') THEN
           RES:='MAC MUST BE BUILDUPED WITH ''FIGURE'' AND ''LETTER''.';
           RAISE e_NULL;
        END IF;
        I:=I+1;
    END LOOP;
        
    RES := 'OK';
EXCEPTION
    WHEN e_NULL THEN NULL;
    WHEN OTHERS THEN
        RES:='DB ERROR:'||SUBSTR(SQLERRM,1,50);
END; 