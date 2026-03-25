PROCEDURE       CHECK_THERMAL_GREASE (
   EMP       IN       VARCHAR2,
   LINE      IN       VARCHAR2,
   STATION   IN       VARCHAR2,
   MYGROUP   IN       VARCHAR2,
   DATA      IN       VARCHAR2,
   RES       OUT      VARCHAR2
)
AS
   C_SN                VARCHAR2 (25);
   C_TIMES             VARCHAR2 (1);
   V_DATE              DATE;
   C_IN_STATION_TIME   DATE;
   E_NULL              EXCEPTION;
   C_COUNT0            NUMBER;
   C_COUNT1            NUMBER;
BEGIN
   SELECT COUNT (*)
     INTO C_COUNT0
     FROM IQC.R_KPN_INCOMING_T
    WHERE PKG_ID = DATA;

   IF C_COUNT0 = 0
   THEN
      RES := 'ERROR1:NO PKG';
      RAISE E_NULL;
   ELSE
      IF C_COUNT0 > 0
      THEN
         SELECT COUNT (*)
           INTO C_COUNT1
           FROM SFIS1.C_COLD_SINK_T
          WHERE SN = DATA;

        -- SELECT SYSDATE - 8 / 24
         --  INTO V_DATE
         --  FROM DUAL;

         IF C_COUNT1 = 0
         THEN
            --SELECT SN, TIMES, IN_STATION_TIME
             -- INTO C_SN, C_TIMES, C_IN_STATION_TIME
            --  FROM SFIS1.C_COLD_SINK_T
            -- WHERE SN = DATA;

          --  IF (C_IN_STATION_TIME < V_DATE)
          --  THEN
            --   UPDATE SFIS1.C_COLD_SINK_T
            --      SET TIMES = 0
              --  WHERE SN = DATA;

              -- RES := 'ERROR2:THERMAL_GREASE OVER 8 HOURS,PLEASE MIX!!';
              -- RAISE E_NULL;
           -- END IF;
         --ELSE
            INSERT INTO SFIS1.C_COLD_SINK_T
                 VALUES (DATA, 1, SYSDATE);

            INSERT INTO SFISM4.R_COLD_SINK_T
                 VALUES (DATA, 'N/A', EMP, SYSDATE);
         END IF;
      END IF;
   END IF;

   RES := 'OK';
EXCEPTION
   WHEN E_NULL
   THEN
      NULL;
   WHEN OTHERS
   THEN
      RES := ' OTHER ERROR ';
END;