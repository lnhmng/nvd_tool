PROCEDURE                                    IAUTOTEST_DME (
                                           P_MACHINE_CODE     IN     VARCHAR2,
                                           P_FUNCTION_TEST    IN     VARCHAR2,
                                           P_SN               IN     VARCHAR2,
                                           P_MAC              IN     VARCHAR2, 
                                           P_TESTTIME         IN     DATE,
                                           P_RESULT_CODE      IN     VARCHAR2,
                                           P_ERRORCODE        IN     VARCHAR2,
                                           P_EMP              IN     VARCHAR2,
   RES                         OUT VARCHAR2)
AS

    V_STATION       VARCHAR2 (16);
    V_LINE          VARCHAR2 (10);
    V_SECTION       VARCHAR2 (16);
    V_GROUP         VARCHAR2 (16);

    V_MODEL         VARCHAR2 (32);
    V_MO            VARCHAR2 (32);
    V_PASSQTY       NUMBER (1, 0);
    V_FAILQTY       NUMBER (1, 0);
    V_ROUTE         NUMBER (4, 0);
    V_STATE         VARCHAR2 (1);
    V_NEXTSTATION   VARCHAR2 (32);
    V_NEXTGROUP     VARCHAR2 (32);
    V_TEMP_EC       VARCHAR2 (64);
    V_LASTGROUP         VARCHAR2 (56);
    V_ERROR_NUM     NUMBER;
    v_COUNT         NUMBER;

    v_MACRES            VARCHAR2 (50);
    v_DARES             VARCHAR2 (50);
    v_GROUPRES          VARCHAR2 (32);

    e_ROUTE_ERROR       EXCEPTION;
    e_NULL              EXCEPTION;

BEGIN

    SELECT STATION_NAME,
          LINE_NAME,
          SECTION_NAME,
          GROUP_NAME
     INTO V_STATION,
          V_LINE,
          V_SECTION,
          V_GROUP
     FROM SFIS1.C_ICT_STATION_T
    WHERE STATION_CODE = P_MACHINE_CODE;

     SELECT 
          MODEL_NAME,
          MO_NUMBER,
          NVL (PASS_QTY, 0),
          NVL (FAIL_QTY, 0),
          GROUP_NAME,
          SPECIAL_ROUTE,
          ERROR_FLAG,
          NEXT_STATION
     INTO V_MODEL,
          V_MO,
          V_PASSQTY,
          V_FAILQTY,
          V_LASTGROUP,
          V_ROUTE,
          V_STATE,
          V_NEXTSTATION
     FROM SFISM4.R_WIP_TRACKING_T
     WHERE SERIAL_NUMBER = p_SN;

    --CHECK ROUTE BEGIN
    SFISM4.Sn_Station_Test (V_GROUP,
                           V_LASTGROUP,
                           V_STATE,
                           V_ROUTE,
                           v_GROUPRES);
    V_NEXTGROUP := v_GROUPRES;

    IF V_NEXTGROUP<>V_GROUP
    THEN
        RES := V_NEXTGROUP;
        RAISE e_ROUTE_ERROR;
    END IF;


   IF (V_NEXTSTATION <> 'N/A' AND V_NEXTSTATION IS NOT NULL)
   THEN
      RES := V_NEXTSTATION;
      RAISE e_NULL;
   END IF;

   --CHECK ROUTE END--

    --0 pass 1 fail
   IF P_RESULT_CODE ='P'
   THEN
      V_TEMP_EC := 'N/A';

      IF V_MODEL='1022298-01' AND P_MAC='N/A' THEN

        RES := 'MAC IS NULL' ;
        RAISE e_NULL;

      END IF;


   ELSE

      SELECT COUNT(1) INTO V_ERROR_NUM FROM SFIS1.C_ERROR_CODE_T WHERE ERROR_CODE=p_ERRORCODE;   

       IF V_ERROR_NUM =0
       THEN
          RES := 'ERROR_CODE IS NOT EXIST:' || p_ERRORCODE ;
          RAISE e_NULL;

       END IF;

      V_TEMP_EC := p_ERRORCODE;
   END IF;

 IF (P_FUNCTION_TEST <> 'N/A') OR (P_FUNCTION_TEST <> '')
   THEN
   IF V_GROUP='FCT2' THEN
      DELETE FROM SFISM4.R_SN_FIXTURE_T
      WHERE SERIAL_NUMBER=P_SN AND GROUP_NAME=V_GROUP AND IN_STATION_TIME=IN_STATION_TIME;

      DELETE FROM SFISM4.R_TEST_TEMP_T
      WHERE SERIAL_NUMBER=P_SN AND STATION_TYPE=V_GROUP AND TEST_DATE=TO_CHAR(P_TESTTIME,'YYYYMMDD') AND TEST_TIME =TO_CHAR(P_TESTTIME,'HH24MISS');

      COMMIT;

      --FUNCTION_TEST
      INSERT INTO SFISM4.R_SN_FIXTURE_T (SERIAL_NUMBER,
                                         FIXID,
                                         GROUP_NAME,
                                         STATION_NAME,
                                         STATION_CODE,
                                         EMP,
                                         IN_STATION_TIME,
                                         ERROR_FLAG,
                                         MODEL_NAME)
           VALUES (P_SN,
                   P_FUNCTION_TEST,
                   V_GROUP,
                   V_STATION,
                   P_MACHINE_CODE,
                   P_EMP,
                   P_TESTTIME,      /* LOG FILE TIME  */
                   P_RESULT_CODE,
                   V_MODEL);

      COMMIT;

      INSERT INTO SFISM4.R_TEST_TEMP_T (SERIAL_NUMBER,
                                     STATION_ID,
                                     TEST_DATE,
                                     TEST_TIME,
                                     RESULT,
                                     ERROR_CODE,
                                     MODEL_NAME,
                                     STATION_TYPE,
                                     WORK_STATION,
                                     OPERATOR,
                                     RETEST,
                                     FAILDESC,
                                     MO_NUMBER,
                                     MARKET_NAME,
                                     MEM_VENDOR_ID,
                                     MEM_PART_ID,
                                     MEM_DC,
                                     BASIC_TESTTIME_BEGIN,
                                     BASIC_TESTTIME_END)
        VALUES (P_SN,
                1000,
                TO_CHAR(P_TESTTIME,'YYYYMMDD'),
                TO_CHAR(P_TESTTIME,'HH24MISS'),
                P_RESULT_CODE,
                V_TEMP_EC,
                V_MODEL,
                V_GROUP,
                0,
                P_EMP,
                '0',
                'N/A',
                V_MO,
                'N/A',
                'N/A',
                'N/A',
                'N/A',
                '',
                '');

        COMMIT;

       SFISM4.DA_LINK (P_EMP,
                       P_SN,
                       V_GROUP,
                       v_DARES);

       IF v_DARES <> 'OK'
       THEN
          RES := 'DA_LINK ERROR:' || v_DARES;
          RAISE e_NULL;


       END IF;



        IF p_MAC IS NOT NULL AND p_MAC <>'N/A'
        THEN
               SELECT COUNT (0)
                INTO v_COUNT
                FROM SFISM4.R_LINK_T
               WHERE KEY_VALUE = p_MAC AND FLAG = 'MAC' AND SERIAL_NUMBER<>P_SN AND AVAILABLE=0 AND KEY_VALUE<>'N/A';

              IF (v_COUNT > 0)
              THEN                                               --be used
                 RES := 'MAC IS USED ONCE!';
                 RAISE e_NULL;
              ELSE                                           --not be used
                 SFISM4.DATALINK (P_EMP,
                                  P_SN,
                                  P_MAC,
                                  V_GROUP,
                                  'MAC',
                                  v_MACRES);

                 IF (v_MACRES <> 'OK')
                 THEN
                    RES := v_MACRES || '(RUN SFISM4.DATALINK MAC ERROR)';
                    RAISE e_NULL;
                 END IF;
              END IF;

        END IF;

        IF (P_RESULT_CODE='P') THEN

          SFIS1.STN_REC_Z(V_LINE,V_SECTION,V_GROUP,V_STATION,V_MO,P_SN, TO_CHAR(P_TESTTIME,'YYYYMMDD'),TO_CHAR(P_TESTTIME,'HH24'),'0');
          SFIS1.UPDATE_R107(P_EMP,V_LINE,V_SECTION,V_GROUP,V_STATION,V_MO,P_SN,'0',P_TESTTIME);
          RES := 'OK';

        ELSIF (P_RESULT_CODE = 'F') THEN

            SFIS1.STN_REC_Z(V_LINE,V_SECTION,V_GROUP,V_STATION,V_MO,P_SN, TO_CHAR(P_TESTTIME,'YYYYMMDD'),TO_CHAR(P_TESTTIME,'HH24'),'1');
            SFIS1.UPDATE_R107(P_EMP,V_LINE,V_SECTION,V_GROUP,V_STATION,V_MO,P_SN,'1',P_TESTTIME);

            DELETE SFISM4.R_REPAIR_T WHERE SERIAL_NUMBER=p_SN AND TEST_TIME=P_TESTTIME AND TEST_CODE=V_TEMP_EC AND TEST_STATION=V_STATION AND REPAIRER IS NULL;

            INSERT INTO SFISM4.R_REPAIR_T (SERIAL_NUMBER,
                                          MO_NUMBER,
                                          TEST_TIME,
                                          TEST_CODE,
                                          TEST_STATION,
                                          TEST_LINE,
                                          RECORD_TYPE,
                                          MODEL_NAME)
                VALUES (p_SN,
                        V_MO,
                        P_TESTTIME,
                        V_TEMP_EC,
                        V_STATION,
                        V_LINE,
                        'T',
                        V_MODEL);

            COMMIT;
            RES:='OK';
        END IF; 


       END IF;

   END IF;


EXCEPTION
   WHEN e_NULL
   THEN
      NULL;
   WHEN e_ROUTE_ERROR
   THEN
      BEGIN
         IF V_NEXTGROUP = 'RETEST'
         THEN
            RES := '2';
         ELSIF SUBSTR (V_NEXTGROUP, 1, 2) = 'R_'
         THEN
            RES := 'GOTO-' || V_NEXTGROUP;
         ELSE
            BEGIN
               IF SUBSTR (V_NEXTGROUP, 1, 4) <> 'GOTO'
               THEN
                  V_NEXTGROUP := 'GOTO-' || V_NEXTGROUP;
               END IF;

               RES := V_NEXTGROUP;
            END;
         END IF;
      END;
   WHEN NO_DATA_FOUND
   THEN
      IF V_NEXTGROUP IS NULL
      THEN
         RES := 'ROUTE ERROR';
      ELSIF V_ROUTE IS NULL
      THEN
         RES := 'NO ROUTE';
      ELSE
         RES := 'INPUT ERROR';
      END IF;
   WHEN OTHERS
   THEN
      RES := SUBSTR (SQLERRM, 1, 100);
END;