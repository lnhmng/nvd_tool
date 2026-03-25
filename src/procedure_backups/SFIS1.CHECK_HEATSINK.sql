PROCEDURE       CHECK_HEATSINK (PPN     IN     VARCHAR2,
                                                   KPN     IN     VARCHAR2,
                                                   FANSN   IN     VARCHAR2,
                                                   RES        OUT VARCHAR2)

IS
   V_COUNT       NUMBER;
   E_EXCEPTION   EXCEPTION;
BEGIN
   SELECT COUNT (0)
     INTO V_COUNT
     FROM SFIS1.C_ACCESSORY_T A, WEB.C_MODEL_INFO_T B
    WHERE     A.MODEL_NAME_900 = B.PRODUCT_NAME
          AND B.MODEL_NAME = PPN
          AND A.ACCESSORY_CODE = KPN
          AND A.EMP_NO = SUBSTR (FANSN, 0, 2)
          AND A.ACCESSORY_NO = 1;
 
   IF V_COUNT = 0
   THEN
      RAISE E_EXCEPTION;
   END IF;
 
   RES := 'OK';

EXCEPTION
   WHEN E_EXCEPTION
   THEN
      RES :=PPN||'&'||KPN||'&'||SUBSTR (FANSN, 0, 2)|| ' NOT MATCH!';
   WHEN OTHERS
   THEN
      RES := 'OTHER ERROR ' || SUBSTR (SQLERRM, 1, 50);
END;