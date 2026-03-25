PROCEDURE       CHECK_CMD (DATA      IN     VARCHAR2,
                                             LINE      IN     VARCHAR2,
                                             MYGROUP   IN     VARCHAR2,
                                             EMP       IN     VARCHAR2,
                                             RES          OUT VARCHAR2)
IS
   C_TEMP_COUNT   NUMBER;
   --add by wenliang 20131226 for tikcet S000001QSY
BEGIN
   RES := 'OK';

   IF TRIM(DATA) <> 'CLEAR'
   THEN
      RES := 'NO CMD';
      RETURN;
   END IF;

   SELECT COUNT (*)
     INTO C_TEMP_COUNT
     FROM SFIS1.C_PARAMETER_INI
    WHERE PRG_NAME = 'INPUT_TIME' AND VR_CLASS = MYGROUP AND VR_ITEM = LINE;

   IF C_TEMP_COUNT > 0
   THEN
      UPDATE SFIS1.C_PARAMETER_INI
         SET VR_NAME = EMP, VR_VALUE = TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS')
       WHERE     PRG_NAME = 'INPUT_TIME'
             AND VR_CLASS = MYGROUP
             AND VR_ITEM = LINE;
   ELSE
      INSERT INTO SFIS1.C_PARAMETER_INI (PRG_NAME,
                                         VR_CLASS,
                                         VR_ITEM,
                                         VR_NAME,
                                         VR_VALUE)
           VALUES ('INPUT_TIME',
                   MYGROUP,
                   LINE,
                   EMP,
                   TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      RES := 'OTHER ERROR ' || SUBSTR (SQLERRM, 1, 100);
END; 