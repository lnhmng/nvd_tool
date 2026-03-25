PROCEDURE       CHECK_cold_sink (line      IN     VARCHAR2,
                                                   mygroup   IN     VARCHAR2,
                                                   DATA      IN     VARCHAR2,
                                                   RES          OUT VARCHAR2)
AS

   C_SN                VARCHAR2 (25);
   C_TIMES             NUMBER;
   C_IN_STATION_TIME   DATE;
   v_date              DATE;
   e_null              EXCEPTION;
   c_count0            NUMBER;
BEGIN
   SELECT COUNT (*)
     INTO c_count0
     FROM SFIS1.C_cold_sink_t
    WHERE SN = DATA;

   IF c_count0 = 0
   THEN
      --RES := 'ERROR1:NO SN';
     -- RAISE e_null;
     INSERT INTO SFIS1.C_COLD_SINK_T VALUES (DATA,'0','');
   END IF;

   SELECT SN, TIMES, IN_STATION_TIME TIMES
     INTO C_SN, C_TIMES, C_IN_STATION_TIME
     FROM SFIS1.C_cold_sink_t
    WHERE SN = DATA;
   
   SELECT SYSDATE - 30 / 24 / 60  INTO v_date FROM DUAL;
       
   IF v_date < C_IN_STATION_TIME
   THEN
      RES := 'ERROR2:TIME IS NOT OVER 30 MINUTE';
      RAISE e_null;
   END IF;

   IF mygroup = '690_SINK'
   THEN
      IF C_TIMES > 7
      THEN
         RES := 'ERROR3:COUNT IS  OVER 8 ';
         RAISE e_null;
      END IF;
   ELSE
      IF mygroup = '900_SINK'
      THEN
         IF C_TIMES > 49
         THEN
            RES := 'ERROR4:COUNT IS  OVER 50 ';
            RAISE e_null;
         END IF;
      END IF;
   END IF;
   RES := 'OK';
EXCEPTION
   WHEN e_null
   THEN
      NULL;
   WHEN OTHERS
   THEN
      RES := ' OTHER ERROR ';
END; 