PROCEDURE       CHECK_MIX 
                                           (
   PKG    IN       VARCHAR2,
   LINE   IN       VARCHAR2,
   RES    OUT      VARCHAR2,
   DATA   IN       VARCHAR2
)
AS
   E_NULL   EXCEPTION;
BEGIN
   IF DATA <> 'MIX'
   THEN
      RES:=' NO MIX ';
      RAISE E_NULL;
   ELSE
      UPDATE SFIS1.C_COLD_SINK_T
         SET TIMES = 1 , in_station_time = SYSDATE
       WHERE SN = PKG;
   END IF;

   RES := 'OK';
EXCEPTION
   WHEN E_NULL
   THEN
      NULL;
   WHEN OTHERS
   THEN
     RES:=' NO MIX ';
END;