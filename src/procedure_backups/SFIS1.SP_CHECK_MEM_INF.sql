PROCEDURE       SP_CHECK_MEM_INF --Added by maggie  on 2015/11/09 for 3J5T-151113-01 Begin
                                                    (
   DATA   IN     VARCHAR2,
   LINE      IN     VARCHAR2,
   MYGROUP   IN     VARCHAR2,
   RES          OUT VARCHAR2)
AS
   p_BARCODE         VARCHAR2 (25);
   P_OLDSN           VARCHAR2 (25);
   C_MODEL                  VARCHAR2 (25);
   C_MEMPN                  VARCHAR2 (25);

   MEMCNT            NUMBER (2, 0);
   MEMCNT1           NUMBER (2, 0);
   MEMCNT2           NUMBER (2, 0);
   SNCNT             NUMBER (2, 0);
   MEMPNCNT         NUMBER(2, 0);
   MODEL_QTY          NUMBER;
   COUNT_690_VI       NUMBER;
   HOURS_DECIMAL      NUMBER(5,2);

   e_NULL            EXCEPTION;

BEGIN
    RES:='OK';

   SELECT COUNT (*)
     INTO SNCNT
     FROM SFISM4.R_SN_LINK_T
    WHERE NEW_SN = DATA;

   IF SNCNT = 0
   THEN                                           --The SN haven't been linked
      p_BARCODE := DATA;
   ELSE                                              --The SN have been linked
      SELECT INIT_SN, OLD_SN
        INTO p_BARCODE, P_OLDSN
        FROM SFISM4.R_SN_LINK_T
       WHERE NEW_SN = DATA AND ROWNUM = 1;
   END IF;

   SELECT MODEL_NAME
     INTO C_MODEL
     FROM SFISM4.R_WIP_TRACKING_T
    WHERE SERIAL_NUMBER = p_BARCODE;

   SELECT COUNT(MEM_PN)  INTO MEMPNCNT    --find this model need check MEMINFO or not
   FROM SFIS1.C_PTH_T
   WHERE    LINE_NAME = LINE
          AND (MODEL_NAME = C_MODEL OR LP_900MODEL= C_MODEL)
          AND STATION_NAME = MYGROUP;  

   IF MEMPNCNT = 0 THEN 
     RES:='OK';
     RETURN;
   END IF;      
   -- ling shi heng add control model name 900-21012-0000-000  20250813
    IF MYGROUP ='900_INPUT' AND C_MODEL='900-21012-0000-000' THEN 
        SELECT COUNT(*) INTO COUNT_690_VI FROM SFISM4.R_SN_DETAIL_T WHERE SERIAL_NUMBER=DATA AND MODEL_NAME=C_MODEL AND GROUP_NAME = '690_VI';

            IF COUNT_690_VI = 0  THEN 
                RES :='NOT SCAN 690_VI ,PLS CHECK' ;
                RAISE e_NULL;

            END IF;
        SELECT ROUND((SYSDATE - MAX(IN_STATION_TIME)) * 24, 2) INTO HOURS_DECIMAL  
        FROM SFISM4.R_SN_DETAIL_T 
        WHERE MODEL_NAME='900-21012-0000-000' AND 
        GROUP_NAME='690_VI'
        AND SERIAL_NUMBER = DATA;
            IF HOURS_DECIMAL < 24 THEN
                RES := 'FROM 690_VI STATION TO 900_INPUT STATION NOT ENOUGH TIME' ;
                RAISE e_NULL;
            END IF;
    END IF;
    -- END 20250813
   SELECT MEM_PN INTO C_MEMPN    --find this model 's memory
   FROM SFIS1.C_PTH_T
   WHERE    LINE_NAME = LINE
          AND (MODEL_NAME = C_MODEL OR LP_900MODEL= C_MODEL)
          AND STATION_NAME = MYGROUP;                  

   SELECT COUNT (*)
     INTO MEMCNT
     FROM SMTINFO.R_SN_PKG_DETAIL_T C, IQC.R_KPN_INCOMING_T D
    WHERE   C.SERIAL_NUMBER = p_BARCODE
          AND C.PKG_ID = D.PKG_ID
          AND D.HH_PN = C_MEMPN;

   IF MEMCNT = 0
   THEN
      IF SNCNT > 0
      THEN
         SELECT COUNT (*)
           INTO MEMCNT1
           FROM SMTINFO.R_SN_PKG_DETAIL_T C, IQC.R_KPN_INCOMING_T D
          WHERE     C.SERIAL_NUMBER = DATA
                AND C.PKG_ID = D.PKG_ID
                AND D.HH_PN = C_MEMPN;

         IF MEMCNT1 = 0
         THEN
            SELECT COUNT (*)
              INTO MEMCNT2
              FROM SMTINFO.R_SN_PKG_DETAIL_T C, IQC.R_KPN_INCOMING_T D
             WHERE     C.SERIAL_NUMBER = P_OLDSN
                   AND C.PKG_ID = D.PKG_ID
                   AND D.HH_PN = C_MEMPN;

            IF MEMCNT2 = 0
            THEN
               RES := 'MEMORY INF ERROR1' ;
               RAISE e_NULL;
            END IF;
         END IF;
      ELSE
         RES := 'MEMORY INF ERROR2';
         RAISE e_NULL;
      END IF;
   END IF;

EXCEPTION
   WHEN e_NULL
   THEN
      NULL;
   WHEN OTHERS
   THEN
      RES := 'OTHER ERROR:' ||SUBSTR(SQLERRM,1,60);
END;