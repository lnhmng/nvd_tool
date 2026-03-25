PROCEDURE       CHECK_PKG_MSD_V1(EMP IN VARCHAR2,PKG IN VARCHAR2,LINE IN VARCHAR2,PPN IN VARCHAR2,KPN IN VARCHAR2,RES OUT VARCHAR2) IS
C_COUNT NUMBER;
C_COUNT1 NUMBER;
C_COUNT2 NUMBER;
POSITION1 NUMBER;
C_MAXLIFETIME NUMBER;
V_USETIME  NUMBER;
C_HHPN VARCHAR2(30);
C_HHPN1 VARCHAR2(30);
C_ALARMCLASS VARCHAR2(10);
C_ALARMINFO VARCHAR2(50);
E_ERROR EXCEPTION;

BEGIN

   SELECT COUNT(*) INTO C_COUNT1 FROM IQC.R_KPN_INCOMING_T A,IQC.R_MSD_DETAIL_T B  WHERE  PKG_ID=TRIM(PKG) AND B.HHPN=A.HH_PN;
   IF C_COUNT1<1 THEN
       RES:='OK';
   ELSE
     --?????PKG LINK ?
      select count(*) into C_COUNT2 from iqc.R_MSD_PKGID_LINK_T where NEW_PKGID=PKG and FLAG='N';
      if C_COUNT2>0 then
          --RES:='?HH P/N?MSD??,?????????IQC??,???IQC??????!';
          RES:='LINKED PKG ID.,GOTO IQC CHECK AND SCAN';
          raise E_ERROR;
      end if;

       --????????
         SELECT MAX_LIFETIME INTO C_MAXLIFETIME FROM IQC.R_KPN_INCOMING_T A,IQC.R_MSD_DETAIL_T B  WHERE  PKG_ID=TRIM(PKG) AND B.HHPN=A.HH_PN  and rownum=1;
      C_MAXLIFETIME:=C_MAXLIFETIME-8;

      --????????
      select sum(to_number((case when end_time is null then sysdate else end_time end)-begin_time)*24) INTO V_USETIME from iqc.R_MSD_PKGID_LOG_T where  pkg_id=trim(PKG);
      IF V_USETIME>=C_MAXLIFETIME THEN
         -- RES:='?HH P/N?MSD????????????????';
         RES:='PKG ID USED TIME ABOVE LIFETIME ';
         raise E_ERROR;
      ELSE
        --???iqc emp.????????????
        /*select count(*) into C_COUNT1 from iqc.R_MSD_PKGID_LOG_T where pkg_id=trim(pkg) and iqc_flag='Y';
        IF C_COUNT1>0 THEN
           select sum(to_number((case when end_time is null then sysdate else end_time end)-begin_time)*24) INTO V_USETIME from iqc.R_MSD_PKGID_LOG_T where  pkg_id=trim(PKG) AND IQC_FLAG='Y';
           IF V_USETIME>1 THEN
              RES:='?PKG ID ??IQC???,????????????';
              raise E_ERROR;
           END IF;
        END IF;
        */
         SELECT INSTR(LINE,'S',1,1) INTO POSITION1  FROM DUAL;
         IF POSITION1>0 THEN
            --MARKED BY LLF 2017-09-10
            --INSERT INTO iqc.R_MSD_PKGID_LOG_T(PKG_ID,open_EMP_NO,begin_time,OPEN_LOCATION) VALUES(TRIM(PKG),EMP,sysdate,'SMT');
            RES:='OK';
         ELSE
            --INSERT INTO iqc.R_MSD_PKGID_LOG_T(PKG_ID,open_EMP_NO,begin_time,OPEN_LOCATION) VALUES(TRIM(PKG),EMP,sysdate,'PTH');
        RES:='OK';
         END IF;
         RES:='OK';
       END IF;
   END IF;

EXCEPTION
   WHEN E_ERROR THEN NULL;
   WHEN OTHERS THEN
     RES:='CHECK_PKG_MSD ERROR';
     RES:=RES||SUBSTR(SQLERRM,1,80);
END;