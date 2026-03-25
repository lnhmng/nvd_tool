PROCEDURE                      Get_SAMPLESN_TESTINFO(
SSN             IN  VARCHAR2,
PN              IN  VARCHAR2,
TESTTIME_BEGIN  IN  VARCHAR2,----BASIC_TESTTIME_BEGIN
TESTTIME_END    IN  VARCHAR2,----BASIC_TESTTIME_END
RESULT          IN  VARCHAR2,
MACHINE_CODE    IN  VARCHAR2,
ERROR_CODE      IN  VARCHAR2,
DIAGS           IN  VARCHAR2,
RES             OUT VARCHAR2
) 
IS
v_count         int;
prefix          varchar2(30);
snlen           varchar2(30);
p_controltime   int;
ex              exception;
BEGIN
    RES:='0';
 
    select count(*) into v_count from sfis1.C_SAMPLESN_SET where SKUNO=PN;
    if v_count>0 then
        select PREFIX,SNLEN,CONTROL_TIMES INTO prefix,snlen,p_controltime from sfis1.C_SAMPLESN_SET where SKUNO=PN;
                
        if SUBSTR(SSN,1,length(PREFIX))<>PREFIX then
            RES:='Sample SN '||SSN||' prefix not match SN RULE,Contact TE';
            raise ex;  
        end if;
                
        if length(SSN)<>snlen then
            RES:='Sample SN '||SSN||' length not match SN RULE,Contact TE';
            raise ex;  
        end if;
                
        
        INSERT INTO SFISM4.R_TEST_SAMPLESN_T(SERIAL_NUMBER,PN,BEGIN_TESTTIME,END_TESTTIME,STATUS,MACHINE_CODE,ERROR_CODE,DIAGS,UPLOADDATE,VALID,LASTEDITDT)
        VALUES(SSN,PN,TESTTIME_BEGIN,TESTTIME_END,RESULT,MACHINE_CODE,ERROR_CODE,DIAGS,SYSDATE,'0',SYSDATE);
       
        COMMIT;
        
        if RESULT='P' then
            RES:=SSN||'\n'||'0'||'\n'||'**END**'||'\n';
        ELSE
            RES:=SSN||'\n'||'1'||'\n'||'**END**'||'\n'; 
        end if;
    else
         RES:='PN '||PN||' TE not set SN RULE,Contact TE';
         raise ex;  
    end if;   


   EXCEPTION
    WHEN ex
    then RES:=RES;
     WHEN OTHERS
        THEN NULL;
END Get_SAMPLESN_TESTINFO;