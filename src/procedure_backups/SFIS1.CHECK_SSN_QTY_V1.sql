PROCEDURE             CHECK_SSN_QTY_V1 (DATA      IN     VARCHAR2,
                                                 LINE      IN     VARCHAR2,
                                                 MYGROUP   IN     VARCHAR2,
                                                 EMP       IN     VARCHAR2,
                                                 RES          OUT VARCHAR2)
--modified by maggie chang 20150203 for S000002XND
IS
   TEMP_COUNT   NUMBER;
    C_TEMP_COUNT   NUMBER;
   TEMP_TIME    DATE;
   C_MODEL   VARCHAR2(40);--add by maggie on 20150206
BEGIN
   RES := 'OK';

    SELECT MODEL_NAME
    INTO C_MODEL 
    FROM SFISM4.R_WIP_TRACKING_T
    WHERE SERIAL_NUMBER=DATA;

   SELECT NVL (TO_DATE(MAX (VR_VALUE),'YYYY/MM/DD HH24:MI:SS'), SYSDATE-10)
     INTO TEMP_TIME
     FROM SFIS1.C_PARAMETER_INI
    WHERE     PRG_NAME = 'CLEAR_TIME'
          AND VR_CLASS = MYGROUP
          AND VR_ITEM = LINE
          AND VR_DESC = C_MODEL
          AND ROWNUM = 1;

   SELECT COUNT (*)
     INTO TEMP_COUNT
     FROM SFISM4.R_SN_DETAIL_T
    WHERE     IN_STATION_TIME >= TEMP_TIME
          AND GROUP_NAME = MYGROUP
          AND LINE_NAME = LINE;
          
   IF TEMP_COUNT<> 0
    THEN
        IF (MYGROUP='P_VI') OR (MYGROUP='CHECK ICT') 
        THEN
           IF MOD (TEMP_COUNT, 50) = 0
           THEN
               SELECT COUNT (*)
                 INTO C_TEMP_COUNT
                 FROM SFIS1.C_PARAMETER_INI
                WHERE PRG_NAME = 'CLEAR_TIME' AND VR_CLASS = MYGROUP 
                            AND VR_ITEM = LINE
                            AND VR_DESC = C_MODEL;

               IF C_TEMP_COUNT > 0
               THEN
                  UPDATE SFIS1.C_PARAMETER_INI
                     SET VR_NAME = EMP, VR_VALUE = TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')
                   WHERE     PRG_NAME = 'CLEAR_TIME'
                         AND VR_CLASS = MYGROUP
                         AND VR_ITEM = LINE
                         AND VR_DESC = C_MODEL;
               ELSE
                  INSERT INTO SFIS1.C_PARAMETER_INI (PRG_NAME,
                                                     VR_CLASS,
                                                     VR_ITEM,
                                                     VR_NAME,
                                                     VR_VALUE,
                                                     VR_DESC)
                       VALUES ('CLEAR_TIME',
                               MYGROUP,
                               LINE,
                               EMP,
                               TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'),
                               C_MODEL);
               END IF; 
                          
              RES := '50 PCS,ATTENTION PLEASE!TOTAL:' || TEMP_COUNT;             
           END IF;         
        END IF;    
    END IF;
    
EXCEPTION
   WHEN OTHERS
   THEN
      RES := 'OTHER ERROR ' || SUBSTR (SQLERRM, 1, 100);
END;