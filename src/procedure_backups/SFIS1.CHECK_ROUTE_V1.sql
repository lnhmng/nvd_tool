PROCEDURE             CHECK_ROUTE_V1 (LINE      IN     VARCHAR2,  --add by maggiechang on 20141219 for S000002VBL
                                                MYGROUP   IN     VARCHAR2,
                                                DATA      IN     VARCHAR2,
                                                RES          OUT VARCHAR2)
AS
   CURRENT_F   VARCHAR2 (1);
   CURRENT_G   VARCHAR2 (25);
   GROUP_N           VARCHAR2 (100);
   N_GROUP           VARCHAR2 (25);
   R_CODE      NUMBER;
   MO          VARCHAR2 (25);

   CURSOR NEXTGROUP
   IS
      SELECT GROUP_NEXT
        FROM SFIS1.C_ROUTE_CONTROL_T
       WHERE     STATE_FLAG = CURRENT_F
             AND ROUTE_CODE = R_CODE
             AND GROUP_NAME = CURRENT_G;
BEGIN
   SELECT ERROR_FLAG, GROUP_NAME, MO_NUMBER
     INTO CURRENT_F, CURRENT_G, MO
     FROM SFISM4.R_WIP_TRACKING_T
    WHERE SERIAL_NUMBER = SUBSTR(DATA,1,13);

   SELECT ROUTE_CODE
     INTO R_CODE
     FROM SFISM4.R_MO_BASE_T
    WHERE MO_NUMBER = MO AND ROWNUM = 1;

   SELECT GROUP_NEXT
     INTO GROUP_N
     FROM C_ROUTE_CONTROL_T
    WHERE     STATE_FLAG = CURRENT_F
          AND ROUTE_CODE = R_CODE
          AND GROUP_NAME = CURRENT_G
          AND GROUP_NEXT = MYGROUP;

   RES := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      BEGIN
         FOR N_GROUP IN NEXTGROUP
         LOOP
            GROUP_N := GROUP_N || N_GROUP.GROUP_NEXT || ',';
         END LOOP;
         GROUP_N := 'GO-' || GROUP_N;
      EXCEPTION
         WHEN OTHERS
         THEN
            GROUP_N := CURRENT_G || '(' || CURRENT_F || ')';
      END;

      RES := GROUP_N;
END;