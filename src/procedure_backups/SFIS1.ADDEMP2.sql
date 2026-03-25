PROCEDURE       addEMP2 (
    eno      IN NUMBER,
    addsal   IN number
) AS
    oldsal   emp.sal%TYPE;
    nowsal   emp.sal%TYPE;

BEGIN 
SELECT sal INTO oldsal FROM emp WHERE empno = eno;
update emp SET sal = sal + addsal WHERE  empno = eno;
SELECT  sal INTO nowsal FROM  emp WHERE empno = eno;
 
    nowsal := oldsal + addsal;
    dbms_output.put_line('漲前工資：'
                         || oldsal
                         || ',漲后工資'
                         || nowsal);
END;