PROCEDURE       SMT_CAPACITY_SP --VAR_O_MESSAGE OUT VARCHAR2)
AS
   Var_Mes                     VARCHAR2 (800);

   TYPE TYP_SMTCODE IS TABLE OF VARCHAR (800);

   VAR_TYP_SMTCODE             TYP_SMTCODE;
   VAR_SMTCODE                 VARCHAR (50);
   VAR_STATION                 VARCHAR (30);
   VAR_BUILDING                VARCHAR (30);
   VAR_FLOOR                   VARCHAR (20);
   VAR_LASTEDITDATE            DATE;
   VAR_SEQUENCE                INT;
   VAR_QTYBYHOUR               INT;
   VAR_NOWTIME                 DATE;
   VAR_LASTHOUR                DATE;
   VAR_START_TIME              DATE;
   VAR_STOP_TIME               DATE;
   VAR_TEMP_UTILIZATION_TIME   NUMBER;
   VAR_UTILIZATION_TIME        FLOAT;
   VAR_ACTUAL_QUANTITY         INT;
   VAR_YIELD_QUANTITY          INT;
   
   VAR_FIRST_PASS_QUANTITY     INT;
   VAR_REWORK_PASS_QUANTITY    INT;
   VAR_START_TIME_QUANTITY     INT;
   VAR_STOP_TIME_QUANTITY      INT;   
   VAR_UPLOAD_STATUS                INT;
   VAR_INDEX                   INT;
BEGIN
 --  VAR_STATION := 'PCB_OPEN';
   VAR_BUILDING := 'F20';
   VAR_FLOOR := '3';
   VAR_LASTEDITDATE := sysdate;
   VAR_SEQUENCE := 0;
   VAR_QTYBYHOUR := 0;
   VAR_NOWTIME := sysdate;
  -- VAR_LASTHOUR :=VAR_NOWTIME- 1/24;
   VAR_LASTHOUR := sysdate-1/24;
   VAR_START_TIME := '';
   VAR_STOP_TIME := '';
   VAR_UTILIZATION_TIME := 0;
   VAR_ACTUAL_QUANTITY := 0;
   VAR_YIELD_QUANTITY := 0;
   VAR_UPLOAD_STATUS := 0;

   SELECT TO_CHAR (VAR_NOWTIME, 'hh24') INTO VAR_SEQUENCE FROM DUAL;

  /*
 每天零點時計算前一天的產量,良率
   */
   IF VAR_SEQUENCE = '0'    
   THEN
  /*拿到前一天生產的所有纖體*/     
      /*
      SELECT DISTINCT LINE_NAME
        BULK COLLECT INTO VAR_TYP_SMTCODE
        FROM SFISM4.R_SN_DETAIL_T
       WHERE     GROUP_NAME in ('PCB_OPEN','S_VI_T')
             AND IN_STATION_TIME >= VAR_NOWTIME - 1
             AND IN_STATION_TIME < VAR_NOWTIME;
      */
      
      SELECT LINE_NAME
      BULK COLLECT INTO VAR_TYP_SMTCODE
      FROM SFIS1.C_SMT_HAINA_LINE
     WHERE PARAMETER = 'GET_HAINA_LINE'; 
      
     
      FOR VAR_INDEX IN 1 .. VAR_TYP_SMTCODE.COUNT
      LOOP
         VAR_SMTCODE :=TRIM(VAR_TYP_SMTCODE (VAR_INDEX));
         
         SELECT START_STATION INTO VAR_STATION FROM SFIS1.C_SMT_HAINA_LINE WHERE LINE_NAME=VAR_SMTCODE;

         VAR_SEQUENCE := 24;

         SELECT COUNT (*)
           INTO VAR_ACTUAL_QUANTITY
           FROM (SELECT DISTINCT SERIAL_NUMBER
                   FROM SFISM4.R_SN_DETAIL_T
                  WHERE     GROUP_NAME  IN('PCB_OPEN','S_INPUT_T')
                       AND IN_STATION_TIME >= VAR_NOWTIME - 1
                        AND IN_STATION_TIME < VAR_NOWTIME
                        AND LINE_NAME = VAR_SMTCODE) A;  ---計算每天的產量

         SELECT COUNT (*)
           INTO VAR_YIELD_QUANTITY
           FROM (SELECT DISTINCT SERIAL_NUMBER
                   FROM SFISM4.R_SN_DETAIL_T
                  WHERE     GROUP_NAME IN('AOI_B','AOI_T')
                        AND IN_STATION_TIME >= VAR_NOWTIME - 1
                        AND IN_STATION_TIME < VAR_NOWTIME
                        AND ERROR_FLAG = 0
                        AND LINE_NAME = VAR_SMTCODE) A;  ---記算每天的良品數量

         SELECT COUNT (*)
           INTO VAR_FIRST_PASS_QUANTITY
           FROM (SELECT DISTINCT SERIAL_NUMBER
                   FROM SFISM4.R_SN_DETAIL_T
                  WHERE     GROUP_NAME IN('AOI_B','AOI_T')
                        AND SERIAL_NUMBER NOT IN (SELECT SERIAL_NUMBER
                                                  FROM SFISM4.R_SN_DETAIL_T
                                                 WHERE     GROUP_NAME IN('AOI_B','AOI_T')
                                                       AND ERROR_FLAG = 1
                                                       AND LINE_NAME =
                                                              VAR_SMTCODE)
                        AND IN_STATION_TIME >= VAR_NOWTIME - 1
                        AND IN_STATION_TIME < VAR_NOWTIME
                        AND ERROR_FLAG = 0
                        AND LINE_NAME = VAR_SMTCODE) A; ---記算每天的良品數量


         SELECT COUNT (*)
           INTO VAR_REWORK_PASS_QUANTITY
           FROM (SELECT DISTINCT SERIAL_NUMBER
                   FROM SFISM4.R_SN_DETAIL_T
                  WHERE     GROUP_NAME IN('AOI_B','AOI_T')
                  AND SERIAL_NUMBER IN (SELECT SERIAL_NUMBER
                                              FROM SFISM4.R_SN_DETAIL_T
                                             WHERE      GROUP_NAME IN('AOI_B','AOI_T')
                                                   AND ERROR_FLAG = 1
                                                   AND LINE_NAME =
                                                          VAR_SMTCODE)
                        AND IN_STATION_TIME >= VAR_NOWTIME - 1
                        AND IN_STATION_TIME < VAR_NOWTIME
                        AND LINE_NAME = VAR_SMTCODE) A; ----記算每天重工良品數量

       --  SELECT IN_STATION_TIME
       --    INTO VAR_START_TIME
        --   FROM (  SELECT IN_STATION_TIME
       --              FROM SFISM4.R_SN_DETAIL_T
       --             WHERE     IN_STATION_TIME >= VAR_NOWTIME - 1
        --                  AND IN_STATION_TIME < VAR_NOWTIME
        --                  AND LINE_NAME = VAR_SMTCODE
         --        ORDER BY IN_STATION_TIME ASC) A
        --  WHERE ROWNUM = 1;  --計算每天該纖體的開線時間
        
          SELECT COUNT (*)
           INTO VAR_START_TIME_QUANTITY
           FROM (  SELECT IN_STATION_TIME
                     FROM SFISM4.R_SN_DETAIL_T
                    WHERE IN_STATION_TIME >= VAR_NOWTIME - 1
                          AND IN_STATION_TIME < VAR_NOWTIME
                          AND GROUP_NAME IN ('PCB_OPEN','S_INPUT_T','AOI_B','AOI_T')
                          AND LINE_NAME = VAR_SMTCODE
                          ORDER BY IN_STATION_TIME ASC) A
          WHERE ROWNUM = 1;  ---計算每天該纖體的開線時間（該線體投入工站 或 產出工站 掃描的最小時間）

         IF VAR_START_TIME_QUANTITY > 0
         THEN 
             SELECT IN_STATION_TIME
               INTO VAR_START_TIME
               FROM (  SELECT IN_STATION_TIME
                         FROM SFISM4.R_SN_DETAIL_T
                        WHERE IN_STATION_TIME >= VAR_NOWTIME - 1
                              AND IN_STATION_TIME < VAR_NOWTIME
                              AND GROUP_NAME IN ('PCB_OPEN','S_INPUT_T','AOI_B','AOI_T')
                              AND LINE_NAME = VAR_SMTCODE
                              ORDER BY IN_STATION_TIME ASC) A
              WHERE ROWNUM = 1;  --計算每天該纖體的開線時間（該線體投入工站 或 產出工站 掃描的最小時間）
         ELSE
           VAR_START_TIME :=SYSDATE-1;    
         END IF;        
       
        -- SELECT IN_STATION_TIME
        --   INTO VAR_STOP_TIME
         --  FROM (  SELECT IN_STATION_TIME
         --            FROM SFISM4.R_SN_DETAIL_T
         --           WHERE     IN_STATION_TIME >= VAR_NOWTIME - 1
         --                 AND IN_STATION_TIME < VAR_NOWTIME
         --                 AND LINE_NAME = VAR_SMTCODE
         --        ORDER BY IN_STATION_TIME DESC) A
          --WHERE ROWNUM = 1;  ---計算每天該纖體的停線時間
          
           SELECT COUNT(*)
           INTO VAR_STOP_TIME_QUANTITY
           FROM (  SELECT IN_STATION_TIME
                     FROM SFISM4.R_SN_DETAIL_T
                    WHERE IN_STATION_TIME >= VAR_NOWTIME - 1
                          AND IN_STATION_TIME < VAR_NOWTIME
                          AND GROUP_NAME IN ('PCB_OPEN','S_INPUT_T','AOI_B','AOI_T')
                          AND LINE_NAME = VAR_SMTCODE
                          ORDER BY IN_STATION_TIME DESC) A
          WHERE ROWNUM = 1;  ---計算每天該纖體的停線時間（該線體投入工站 或 產出工站 掃描的最大時間）

         IF VAR_STOP_TIME_QUANTITY > 0
         THEN
             SELECT IN_STATION_TIME
               INTO VAR_STOP_TIME
               FROM (  SELECT IN_STATION_TIME
                         FROM SFISM4.R_SN_DETAIL_T
                        WHERE IN_STATION_TIME >= VAR_NOWTIME - 1
                              AND IN_STATION_TIME < VAR_NOWTIME
                              AND GROUP_NAME IN ('PCB_OPEN','S_INPUT_T','AOI_B','AOI_T')
                              AND LINE_NAME = VAR_SMTCODE
                              ORDER BY IN_STATION_TIME DESC) A
              WHERE ROWNUM = 1;  ---計算每天該纖體的停線時間（該線體投入工站 或 產出工站 掃描的最大時間）
         ELSE
           VAR_STOP_TIME :=SYSDATE;
         END IF; 
          
       
         --SELECT   TO_CHAR (VAR_STOP_TIME, 'hh24')
         --      - TO_CHAR (VAR_START_TIME, 'hh24')
         -- INTO VAR_UTILIZATION_TIME
         --  FROM DUAL;---計算稼動率
         
         select (VAR_STOP_TIME - VAR_START_TIME)*24  INTO VAR_UTILIZATION_TIME FROM DUAL;  ---?呾歐？薹

         SELECT COUNT (*)
           INTO VAR_QTYBYHOUR
           FROM (SELECT DISTINCT SERIAL_NUMBER
                   FROM SFISM4.R_SN_DETAIL_T
                  WHERE     GROUP_NAME IN('PCB_OPEN','S_INPUT_T')
                       AND IN_STATION_TIME >= VAR_LASTHOUR
                        AND IN_STATION_TIME < VAR_NOWTIME
                                        
                        AND LINE_NAME = VAR_SMTCODE) A; --記錄產量by小時

         INSERT INTO SFISM4.H_SMT_CAPACITY (STATION,
                                              BUILDING,
                                              FLOOR,
                                              SMTCODE,
                                              LASTEDITDATE,
                                              SEQUENCE,
                                              QTYBYHOUR,
                                              START_TIME,
                                              STOP_TIME,
                                              UTILIZATION_TIME,
                                              ACTUAL_QUANTITY,
                                              YIELD_QUANTITY,
                                              FIRST_PASS_QUANTITY,
                                              REWORK_PASS_QUANTITY,
                                              UPLOAD_STATUS)
               VALUES (--(CASE 
                       -- WHEN TRIM(VAR_SMTCODE) LIKE '%01' THEN 'PCB_OPEN'
                        --WHEN TRIM(VAR_SMTCODE) LIKE '%B' THEN 'PCB_OPEN'
                        --ELSE 'S_INPUT_T'
                        --END),
                      VAR_STATION,
                      VAR_BUILDING,
                      VAR_FLOOR,
                      VAR_SMTCODE,
                      VAR_LASTEDITDATE,
                      VAR_SEQUENCE,
                      VAR_QTYBYHOUR,
                      VAR_START_TIME,
                      VAR_STOP_TIME,
                      VAR_UTILIZATION_TIME,
                      VAR_ACTUAL_QUANTITY,
                      VAR_YIELD_QUANTITY,
                      VAR_FIRST_PASS_QUANTITY,
                      VAR_REWORK_PASS_QUANTITY,
                      VAR_UPLOAD_STATUS);
      END LOOP;
   ELSE
          
      SELECT LINE_NAME
      BULK COLLECT INTO VAR_TYP_SMTCODE
      FROM SFIS1.C_SMT_HAINA_LINE
      WHERE PARAMETER = 'GET_HAINA_LINE';     


      FOR VAR_INDEX IN 1 .. VAR_TYP_SMTCODE.COUNT
      LOOP
         VAR_SMTCODE := VAR_TYP_SMTCODE (VAR_INDEX);
         
          SELECT START_STATION INTO VAR_STATION FROM SFIS1.C_SMT_HAINA_LINE WHERE LINE_NAME=VAR_SMTCODE;


         SELECT COUNT (*)
           INTO VAR_QTYBYHOUR
           FROM (SELECT DISTINCT SERIAL_NUMBER
                   FROM SFISM4.R_SN_DETAIL_T
                  WHERE   GROUP_NAME IN('PCB_OPEN','S_INPUT_T')
                        AND IN_STATION_TIME >= VAR_LASTHOUR
                       AND IN_STATION_TIME < VAR_NOWTIME
                                          
                        AND LINE_NAME = VAR_SMTCODE) A;  ---記錄每個小時的產量


         INSERT INTO SFISM4.H_SMT_CAPACITY (STATION,
                                              BUILDING,
                                              FLOOR,
                                              SMTCODE,
                                              LASTEDITDATE,
                                              SEQUENCE,
                                              QTYBYHOUR,
                                              START_TIME,
                                              STOP_TIME,
                                              UTILIZATION_TIME,
                                              ACTUAL_QUANTITY,
                                              YIELD_QUANTITY,
                                              UPLOAD_STATUS)
              VALUES (VAR_STATION,
                      VAR_BUILDING,
                      VAR_FLOOR,
                      VAR_SMTCODE,
                      VAR_LASTEDITDATE,
                      VAR_SEQUENCE,
                      VAR_QTYBYHOUR,
                      VAR_START_TIME,
                      VAR_STOP_TIME,
                      VAR_UTILIZATION_TIME,
                      VAR_ACTUAL_QUANTITY,
                      VAR_YIELD_QUANTITY,
                      VAR_UPLOAD_STATUS);
                      
      END LOOP;
   END IF;
   
      
   
   

   COMMIT;
END;