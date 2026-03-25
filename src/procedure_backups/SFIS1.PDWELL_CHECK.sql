PROCEDURE       PDWELL_CHECK (
   W_FIX_ID            IN     VARCHAR2,
   RES                             OUT VARCHAR2)
AS
    W_FLAG   VARCHAR2(10 byte);
     W_value   VARCHAR2(200 byte);
    W_MEM   varchar2(200 byte);
    W_MOB   varchar2(200 byte);
    W_SSD   varchar2(200 byte);
    W_PSU   varchar2(200 byte);
    W_TOMB   varchar2(200 byte);
    W_TOMA   varchar2(200 byte);
    W_TOMC   varchar2(200 byte);
    W_MOBPN  varchar2(200 byte);
    TOM_PN   varchar2(200 byte);
   E_NOSN       EXCEPTION;

   CURSOR pwd_cursor IS
   SELECT value,flag FROM   bp_pdwell_storege WHERE FIXID=W_FIX_ID AND STATE=1 ORDER BY FLAG;

   ---ADD BY LSC 20200714 provide TE xiaoming in order to PDWELL machine check
BEGIN  
OPEN pwd_cursor;  
LOOP  
  FETCH pwd_cursor INTO  W_value,W_FLAG; 
  --退出循環的條件
  EXIT WHEN pwd_cursor%NOTFOUND;

        IF    W_FLAG='MEM' THEN
            IF  W_MEM IS NULL THEN
                W_MEM:=W_value;
            ELSE  
                 W_MEM:=W_MEM||';'||W_value;
             END IF;
          ELSIF(W_FLAG='MOB')    THEN
                W_MOB:=W_value;
          ELSIF(W_FLAG='PSU')    THEN
                W_PSU:=W_value;
          ELSIF(W_FLAG='SSD')    THEN
                W_SSD:=W_value;
          ELSIF(W_FLAG='TOMB')    THEN
                W_TOMB:=W_value;
          ELSIF(W_FLAG='TOMC')    THEN
               IF  W_TOMC IS NULL THEN
                    W_TOMC:=W_value;
                ELSE  
                     W_TOMC:=W_TOMC||';'||W_value;
                 END IF;
         ELSIF(W_FLAG='MOBPN')    THEN
               IF  W_MOBPN IS NULL THEN
                    W_MOBPN:=W_value;
                ELSE  
                     W_MOBPN:=W_MOBPN||';'||W_value;
                 END IF;
           ELSIF(W_FLAG='TOMPN')    THEN
               TOM_PN:=W_value;

      ELSE 
               IF  W_TOMA IS NULL THEN
                W_TOMA:=W_value;
            ELSE  
                 W_TOMA:=W_TOMA||';'||W_value;
             END IF;
       END IF;
END LOOP;
CLOSE pwd_cursor; 
 RES := W_FIX_ID || '\n' ||W_MOB||'\n'||W_MEM || '\n'||W_SSD || '\n' ||W_PSU || '\n'||W_TOMB || '\n'||W_TOMA || '\n'||W_TOMC|| '\n'||W_MOBPN || '\n'||TOM_PN;
EXCEPTION
   WHEN E_NOSN
   THEN
      NULL;
   WHEN OTHERS
   THEN
      RES := 'barcode ERROR';
END;
