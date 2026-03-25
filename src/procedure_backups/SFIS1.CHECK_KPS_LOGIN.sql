PROCEDURE       check_kps_login 
(EMP IN VARCHAR,
PWD  IN VARCHAR,
RES  OUT VARCHAR 
)IS
tmpVar NUMBER;
E_ERROR  EXCEPTION;
C_PWD VARCHAR2(10);
/******************************************************************************
   NAME:       check_kps_login
   PURPOSE:    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        2011/7/30          1. Created this procedure.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     check_kps_login
      Sysdate:         2011/7/30
      Date and Time:   2011/7/30, 上午 09:35:58, and 2011/7/30 上午 09:35:58
      Username:         (set in TOAD Options, Procedure Editor)
      Table Name:       (set in the "New PL/SQL Object" dialog)

******************************************************************************/
BEGIN
   tmpVar := 0;
    C_PWD :=PWD;
   
   
   if EMP IS NULL then
    RES:='please enter EMP';
    raise  E_ERROR;
   end if ;
   
   
   if pwd IS NULL then
   RES := 'please enter PWD';
   raise  E_ERROR;
   end if ;
   
   
SELECT COUNT(0) 
INTO tmpVar
FROM KITTING.USER_RULE 
WHERE upper(user_name) =upper(trim(EMP)) ;
IF tmpVar<1 THEN
RES:='emp not exist' ;
raise  E_ERROR;
END IF ;


SELECT COUNT(0) 
INTO tmpVar
FROM KITTING.USER_RULE 
WHERE upper(user_name) =upper(trim(EMP))AND PWD=C_PWD ;
IF tmpVar<1 THEN
RES:='pwd error' ;
raise  E_ERROR;
else
RES:= 'OK';
END IF;


   EXCEPTION
    when E_ERROR then null ;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END ; 