PROCEDURE       THERMAL_GREASE_UPDATE (
   EMP       IN       VARCHAR2,
   LINE      IN       VARCHAR2,
   SECTION   IN       VARCHAR2,
   MYGROUP   IN       VARCHAR2,
   SN        IN       VARCHAR2,
   PKG       IN       VARCHAR2,
   DATA      IN       VARCHAR2,
   RES       OUT      VARCHAR2
)
AS
   E_NULL              EXCEPTION;
    C_SN                VARCHAR2 (25);
   C_TIMES             VARCHAR2 (1);
   V_DATE              DATE;
   C_IN_STATION_TIME   DATE;
   C_COUNT1            NUMBER;
BEGIN
   SELECT COUNT (*)
     INTO C_COUNT1
     FROM SFIS1.C_COLD_SINK_T
    WHERE SN = PKG;

   SELECT SYSDATE - 8 / 24
     INTO V_DATE
     FROM DUAL;

   IF (C_COUNT1 >= 1)
   THEN
      SELECT SN, TIMES, IN_STATION_TIME
        INTO C_SN, C_TIMES, C_IN_STATION_TIME
        FROM SFIS1.C_COLD_SINK_T
       WHERE SN = PKG;

      IF (C_IN_STATION_TIME < V_DATE)
      THEN
         UPDATE SFIS1.C_COLD_SINK_T
            SET TIMES = 0
          WHERE SN = PKG;

         RES := 'THERMAL_GREASE OVER 8 HOURS,PLEASE MIX!';
         RAISE E_NULL;
      ELSE
         IF (C_TIMES = 1)
         THEN
            INSERT INTO SFISM4.R_COLD_SINK_T
                 VALUES (PKG, DATA, EMP, SYSDATE);

           
         END IF;
      END IF;
   ELSE
      RES := 'ERROR1:NO PKG TO BIND';
      RAISE E_NULL;
   END IF;

   RES := 'OK';
EXCEPTION
   WHEN E_NULL
   THEN
      NULL;
   WHEN OTHERS
   THEN
      RES := 'INSERT THERMAL_GREASE FAIL';
END;