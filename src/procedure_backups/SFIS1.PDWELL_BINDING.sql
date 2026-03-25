PROCEDURE       PDWELL_BINDING (
   W_FIX_ID  IN     VARCHAR2,
   W_MOB     IN     VARCHAR2,
   W_MEM     IN     VARCHAR2,
   W_SSD     IN     VARCHAR2,
   W_PSU     IN     VARCHAR2,
   W_TOMB    IN     VARCHAR2,
   W_TOMA    IN     VARCHAR2,
   W_TOMC    IN     VARCHAR2, 
   MOB_PN    IN     VARCHAR2,
   TOM_PN    IN     VARCHAR2,
   RES       OUT    VARCHAR2)
AS
   W_MEM1  VARCHAR2(40);
   W_TEMP_TOMA VARCHAR2(300);
    W_TEMP_TOMC VARCHAR2(300);
   W_TEMP_MEM  VARCHAR2(300);
   W_TOMA1    VARCHAR2(40);
   W_TOMC1    VARCHAR2(40);
   W_MOB_PN  VARCHAR2(40);
   W_MOB_TEMP  VARCHAR2(40);
   COUNT1 INT;
   E_NOSN       EXCEPTION;

   ---ADD BY LSC 20200710 provide TE xiaoming in order to PDWELL machine BINGING
BEGIN
   IF   W_FIX_ID= '' OR  W_FIX_ID IS NULL OR  W_FIX_ID= 'NULL' OR  W_FIX_ID = ' ' OR  W_FIX_ID = 'N/A'
        OR W_MOB= '' OR W_MOB IS NULL OR W_MOB = 'NULL' OR W_MOB = ' '  OR  W_MOB = 'N/A'
        OR W_MEM= '' OR W_MEM IS NULL OR W_MEM = 'NULL' OR W_MEM = ' '  OR  W_MEM = 'N/A'
        OR W_SSD= '' OR W_SSD IS NULL OR W_SSD = 'NULL' OR W_SSD = ' '  OR  W_SSD  = 'N/A'
        OR W_PSU= '' OR W_PSU IS NULL OR W_PSU = 'NULL' OR W_PSU = ' '   OR   W_PSU  = 'N/A'
        OR W_TOMB= '' OR W_TOMB IS NULL OR W_TOMB = 'NULL' OR W_TOMB = ' '   OR  W_TOMB = 'N/A'
   THEN
        RES :=  'barcode ERROR!';
         RAISE E_NOSN;
   END IF;
   select count(*) INTO COUNT1 from  bp_pdwell_storege where FIXID=W_FIX_ID;
   IF COUNT1>0
   THEN
            UPDATE bp_pdwell_storege SET STATE=0  where FIXID=W_FIX_ID;
   END IF;
BEGIN
        W_TEMP_MEM :=W_MEM;
         W_TEMP_TOMA:=W_TOMA;
         W_TEMP_TOMC:=W_TOMC;  
         W_MOB_PN:=MOB_PN;
      IF INSTR(W_TEMP_MEM,';')>0
      THEN
       WHILE(INSTR(W_TEMP_MEM,';')>0)
       LOOP
            W_MEM1:=SUBSTR(W_TEMP_MEM,1,INSTR(W_TEMP_MEM,';')-1);
            INSERT INTO bp_pdwell_storege
                (FIXID,
                    FLAG,
                    VALUE,
                    INTO_TIME,state)
                 VALUES(W_FIX_ID,'MEM',W_MEM1,SYSDATE,1);
                   COMMIT;
            W_TEMP_MEM:=SUBSTR(W_TEMP_MEM,INSTR(W_TEMP_MEM,';')+1);
       END LOOP;
      ELSE
            INSERT INTO bp_pdwell_storege
                (FIXID,
                    FLAG,
                    VALUE,
                    INTO_TIME,state)
                 VALUES(W_FIX_ID,'MEM',W_TEMP_MEM,SYSDATE,1);
      END IF;

IF  INSTR(W_TOMA,';')>0
THEN
WHILE(INSTR( W_TEMP_TOMA,';')>0)
       LOOP
            W_TOMA1:=SUBSTR( W_TEMP_TOMA,1,INSTR( W_TEMP_TOMA,';')-1);
            INSERT INTO bp_pdwell_storege
                (FIXID,
                    FLAG,
                    VALUE,
                    INTO_TIME,state)
                 VALUES(W_FIX_ID,'TOMA',W_TOMA1,SYSDATE,1);
                 COMMIT;
             W_TEMP_TOMA:=SUBSTR(W_TEMP_TOMA,INSTR(W_TEMP_TOMA,';')+1);
       END LOOP;
ELSIF(W_TOMA<>'N/A')
THEN
  INSERT INTO bp_pdwell_storege
                (FIXID,
                    FLAG,
                    VALUE,
                    INTO_TIME,state)
                 VALUES(W_FIX_ID,'TOMA',W_TOMA,SYSDATE,1);
                 COMMIT;
END IF;
IF  INSTR(W_TOMC,';')>0
THEN
WHILE(INSTR( W_TEMP_TOMC,';')>0)
       LOOP
            W_TOMC1:=SUBSTR( W_TEMP_TOMC,1,INSTR( W_TEMP_TOMC,';')-1);
            INSERT INTO bp_pdwell_storege
                (FIXID,
                    FLAG,
                    VALUE,
                    INTO_TIME,state)
                 VALUES(W_FIX_ID,'TOMC',W_TOMC1,SYSDATE,1);
                 COMMIT;
             W_TEMP_TOMC:=SUBSTR(W_TEMP_TOMC,INSTR(W_TEMP_TOMC,';')+1);
       END LOOP;
ELSIF(W_TOMC<>'N/A')
THEN
  INSERT INTO bp_pdwell_storege
                (FIXID,
                    FLAG,
                    VALUE,
                    INTO_TIME,state)
                 VALUES(W_FIX_ID,'TOMC',W_TOMC,SYSDATE,1);
                 COMMIT;
END IF;
-- add by LSC in order  to  add MOB_PN binding 20200821
     IF INSTR(MOB_PN,';')>0
      THEN
       WHILE(INSTR(W_MOB_PN,';')>0)
       LOOP
            W_MOB_TEMP:=SUBSTR(W_MOB_PN,1,INSTR(W_MOB_PN,';')-1);
            INSERT INTO bp_pdwell_storege
                (FIXID,
                    FLAG,
                    VALUE,
                    INTO_TIME,state)
                 VALUES(W_FIX_ID,'MOBPN',W_MOB_TEMP,SYSDATE,1);
                   COMMIT;
            W_MOB_PN:=SUBSTR(W_MOB_PN,INSTR(W_MOB_PN,';')+1);
       END LOOP;
      ELSIF(MOB_PN<>'N/A')
      THEN
            INSERT INTO bp_pdwell_storege
                (FIXID,
                    FLAG,
                    VALUE,
                    INTO_TIME,state)
                 VALUES(W_FIX_ID,'MOBPN',MOB_PN,SYSDATE,1);
      END IF;

   INSERT INTO bp_pdwell_storege
                (FIXID,
                    FLAG,
                    VALUE,
                    INTO_TIME,state)
                 VALUES(W_FIX_ID,'MOB',W_MOB,SYSDATE,1);
                   COMMIT;
 INSERT INTO bp_pdwell_storege
                (FIXID,
                    FLAG,
                    VALUE,
                    INTO_TIME,state)
                 VALUES(W_FIX_ID,'SSD',W_SSD,SYSDATE,1);
                   COMMIT;
  INSERT INTO bp_pdwell_storege
                (FIXID,
                    FLAG,
                    VALUE,
                    INTO_TIME,state)
                 VALUES(W_FIX_ID,'PSU',W_PSU,SYSDATE,1);
                   COMMIT;
INSERT INTO bp_pdwell_storege
                (FIXID,
                    FLAG,
                    VALUE,
                    INTO_TIME,state)
                 VALUES(W_FIX_ID,'TOMB',W_TOMB,SYSDATE,1);
                   COMMIT;
              IF TOM_PN<>'N/A'
              THEN
                   INSERT INTO bp_pdwell_storege
                (FIXID,
                    FLAG,
                    VALUE,
                    INTO_TIME,state)
                 VALUES(W_FIX_ID,'TOMPN',TOM_PN,SYSDATE,1);     
              END IF;
END;
   RES := 'OK!';

EXCEPTION
   WHEN E_NOSN
   THEN
      NULL;
   WHEN OTHERS
   THEN
      RES := 'barcode2222 ERROR';
END;