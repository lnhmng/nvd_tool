PROCEDURE       cold_sink_UPDATE (
   EMP       IN     VARCHAR2,
   LINE      IN     VARCHAR2,
   SECTION   IN     VARCHAR2,
   MYGROUP   IN     VARCHAR2,
   SN        IN     VARCHAR2,
   SIN       IN     VARCHAR2,
   DATA      IN     VARCHAR2,
   RES          OUT VARCHAR2)
AS
   e_null              EXCEPTION;
   V_TIMES             NUMBER;
   V_IN_STATION_TIME   DATE;
   v_date              DATE;
   c_count0            NUMBER;
BEGIN
   SELECT COUNT (*)
   INTO c_count0
     FROM SFIS1.C_COLD_SINK_T
    WHERE SN = SIN;

   IF (c_count0 = 0 OR c_count0 > 1)
   THEN
      RES := 'ERROR1:SN NO EXISTS OR MORE';
      RAISE e_null;
   ELSE
      SELECT TIMES, IN_STATION_TIME
        INTO V_TIMES, V_IN_STATION_TIME
        FROM SFIS1.C_COLD_SINK_T
       WHERE SN = SIN;

      SELECT SYSDATE INTO v_date FROM DUAL;

      INSERT INTO SFISM4.R_COLD_SINK_T
           VALUES (SIN,
                   DATA,
                   EMP,
                   v_date);

      UPDATE SFIS1.C_COLD_SINK_T
         SET TIMES = V_TIMES + 1, IN_STATION_TIME = v_date
       WHERE SN = SIN;

      RES := 'OK';
   END IF;
EXCEPTION
   WHEN e_null
   THEN
      NULL;
   WHEN OTHERS
   THEN
      RES := 'INSERT  COLD_SINK FAIL';
END;