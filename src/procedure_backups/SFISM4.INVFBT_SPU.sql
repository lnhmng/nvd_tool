PROCEDURE        INVFBT_SPU (MACHINE_CODE     IN     VARCHAR2,
                                           MODEL_NAME       IN     VARCHAR2, ----MODEL_NAME
                                           BARCODE          IN     VARCHAR2,
                                           TESTTIME_BEGIN   IN     VARCHAR2, ----BASIC_TESTTIME_BEGIN
                                           TESTTIME_END     IN     VARCHAR2, ----BASIC_TESTTIME_END
                                           RESULT           IN     VARCHAR2,
                                           RETEST           IN     VARCHAR2,
                                           WORKSCHED        IN     VARCHAR2, ----BIOS
                                           EMP              IN     VARCHAR2,
                                           ERRORCODE        IN     VARCHAR2, ----Error_code
                                           END_FLAG         IN     VARCHAR2,
                                           DIAG             IN     VARCHAR2, ----DIAG EDITION
                                           ECID             IN     VARCHAR2, ----ECID
                                           MARKETNAME       IN     VARCHAR2,
                                           MEM_VENDOR       IN     VARCHAR2,
                                           MEM_PART         IN     VARCHAR2,
                                           MEM_DATECODE     IN     VARCHAR2, ----MEMORY_DATACODE
                                           P_COLLECT        IN     VARCHAR2, -----BY 2018-07-04 MAC  MODIFICATION   P_COLLECT
                                           TEST_LOGNAME     IN     VARCHAR2,  ---------BY TANZISONG 2019-05-06  ADD ??LOGNAME  
                                           DISPOSITION      IN     VARCHAR2,--------BY  LUO YANG  2019-05-06  ADD ??LOGNAME
                                           DUPPY      IN     VARCHAR2,--------BY  liushichang      2021-11-12 ADD ????????
                                           MAC              IN     VARCHAR2,    --  add mac info --liujinag 20220419
                                           MAC_QTY          IN     VARCHAR2,    --  add mac info --liujinag 20220419
                                            o_flag         OUT      VARCHAR2,  
                                           RES                 OUT VARCHAR2)
IS
   p_ERRORCODE         VARCHAR2 (25);
   p_MODATE            VARCHAR2 (8);
   p_DATETIME          VARCHAR2 (16);
   p_WSECTION          VARCHAR2 (2);
   p_WORKTIME1         VARCHAR2 (6);                               --ADD BY RT
   p_MACHINECODE       VARCHAR2 (10);
   p_MODEL_NAME        VARCHAR2 (50);
   p_RETESTTIME        NUMBER (2, 0);                              --ADD BY RT

   v_FIXID             VARCHAR2 (16);                              --ADD BY RT
   iPOS                NUMBER (2, 0);                              --ADD BY RT
   v_FIXRES            VARCHAR2 (50);                              --ADD BY RT

   p_STATION           VARCHAR2 (16);
   p_LINE              VARCHAR2 (10);
   p_SECTION           VARCHAR2 (16);
   p_GROUP             VARCHAR2 (16);

   p_BARCODE           VARCHAR2 (25);
     P_ERRORDESC         VARCHAR2 (100);   --ADD BY LSC 20220302
    temp      VARCHAR2 (100);
   --p_WIP_LINE      VARCHAR2(10);
   --p_WIP_GROUP      VARCHAR2(10);


   V_collect               VARCHAR2 (100);
   V_collect2              VARCHAR2 (100);
   V_TEMP                  VARCHAR2 (50);
   V_TEMP2                 VARCHAR2 (50);
   V_VALUE                 VARCHAR2 (50);
   V_VALUE2                VARCHAR2 (50);


   STNCNT              NUMBER (2, 0);
   MKTCNT              NUMBER (2, 0);
   MEMCNT              NUMBER (2, 0);
   SNCNT               NUMBER (2, 0);
   BIOSCNT             NUMBER (2, 0);                    --ADD BY TANRONGLIANG
   EXISTCNT            NUMBER (2, 0);                    --ADD BY TANRONGLIANG
   FAILTIMECNT         NUMBER (2, 0);                    --ADD BY TANRONGLIANG
   FAILECEXISTCNT      NUMBER (2, 0);                    --ADD BY TANRONGLIANG
   FAILECCNT           NUMBER (2, 0);                    --ADD BY TANRONGLIANG

   ECNP                NUMBER (2, 0);
   ECNF                NUMBER (2, 0);
   P_MO                VARCHAR2 (30);
   p_DATE              DATE;

   EMPRES              VARCHAR2 (20);

   ROUTERES            VARCHAR2 (30);
   PRORES              VARCHAR2 (30);
   H1RES               VARCHAR2 (30);
   V_LINE              VARCHAR2 (30);
   V_GROUP             VARCHAR2 (30);

   HRES                VARCHAR2 (20);
   INPUTRES            VARCHAR2 (100);
   V_MODEL_NAME        VARCHAR2 (30);
   --V_MODEL_NAME_TEST VARCHAR2(30);--ADD BY RT
   --Added by songFengLiu 2013-8-8  for S000001C2H-2130808-01 begin
   V_900MODEL_POS      NUMBER (2, 0);
   V_900_MODEL_NAME    VARCHAR2 (30);
   --Added by songFengLiu 2013-8-8  for S000001C2H-130808-01 end
   ---ADD BY LLF 2017-09-28 BEGIN
   v_ECIDRES           VARCHAR2 (100);
   v_DIAGRES           VARCHAR2 (100);
   --ADD BY LLF 2017-09-28 END
   error_code_1        VARCHAR2 (30);
   error_desc_2        VARCHAR2 (200);
   W_SYSDATE            VARCHAR2(30) ;
   Z_SYSDATE            VARCHAR2(30) ;
   c_error_code        NUMBER;
   --ADD BY WZW 2018-04-26
   i_mac_qty        NUMBER;

   e_FILE_ERROR        EXCEPTION;
   e_H1_ERROR          EXCEPTION;
   e_STN_DUP           EXCEPTION;
   e_NO_STN            EXCEPTION;
   e_EMP_ERROR         EXCEPTION;
   e_INPUT_ERROR       EXCEPTION;
   e_NULL              EXCEPTION;
   e_BIOSCHECK_ERROR   EXCEPTION;
   e_FIXID_ERROR       EXCEPTION;
   e_DATETIME_ERROR    EXCEPTION;
   e_TIME_ERROR        EXCEPTION;
BEGIN
   o_flag := '-1';
   p_DATE := SYSDATE;


   IF    (    (MARKETNAME <> 'N/A')
          AND (MEM_VENDOR <> 'N/A')
          AND (MEM_PART <> 'N/A')
          AND (MEM_DATECODE <> 'N/A'))
      OR (    (MARKETNAME = 'N/A')
          AND (MEM_VENDOR = 'N/A')
          AND (MEM_PART = 'N/A')
          AND (MEM_DATECODE = 'N/A'))
   THEN
      IF END_FLAG <> '**END**'
      THEN
         RAISE e_FILE_ERROR;
      END IF;

      IF LENGTH (TESTTIME_BEGIN) = 14 AND LENGTH (TESTTIME_END) = 14
      THEN
         IF TO_DATE (TESTTIME_BEGIN, 'YYYYMMDDHH24MISS') >
               TO_DATE (TESTTIME_END, 'YYYYMMDDHH24MISS')
         THEN
            RAISE e_DATETIME_ERROR;
         END IF;


        -- ADD TANZISNG  2019-04-29  BEGIN

          IF TO_DATE (TESTTIME_BEGIN, 'YYYYMMDDHH24MISS') > p_DATE
         THEN
            RAISE e_DATETIME_ERROR;
         END IF;

         -- ADD TANZISNG  2019-04-29  END.

          --SELECT TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS') FROM DUAL


      END IF;



      SELECT TO_CHAR (p_DATE, 'YYYYMMDD'),
             TO_CHAR (p_DATE, 'YYYYMMDDHH24MISS'),
             TO_CHAR (p_DATE, 'HH24'),
             TO_CHAR (p_DATE, 'HH24MISS'),
             NVL (SUBSTR (RETEST, 0, 1), 0)
        INTO p_MODATE,
             p_DATETIME,
             p_WSECTION,
             p_WORKTIME1,
             p_RETESTTIME
        FROM DUAL;
      -- begin wzw 20180514  
      IF LENGTH (TESTTIME_BEGIN) = 14 AND LENGTH (TESTTIME_END) = 14 THEN

        W_SYSDATE := TO_CHAR (p_DATE-(12/24), 'YYYYMMDDHH24MISS');
        Z_SYSDATE := TO_CHAR (p_DATE+(12/24), 'YYYYMMDDHH24MISS');

        IF TO_DATE(TESTTIME_END,'YYYYMMDDHH24MISS') < TO_DATE(W_SYSDATE, 'YYYYMMDDHH24MISS')
                OR TO_DATE(TESTTIME_END,'YYYYMMDDHH24MISS') > TO_DATE(Z_SYSDATE, 'YYYYMMDDHH24MISS') THEN
            RAISE e_TIME_ERROR;
        END IF;
      END IF;
      -- end wzw 20180514

        /*
        -- begin add mac info --liujinag 20220419
        --if LENGTH(MAC)>0 then
        if MAC <> 'N/A' and MAC <>'' then

          if length(MAC)<>12 then   --??12
              RES := 'MAC LENGTH NOT MATCH!' || '\n' || '**END**';
              RAISE e_NULL;
          else

            --if LENGTH(MAC_QTY)=0 or to_number(mac_qty) <1 then      --??????1
            if MAC_QTY = 'N/A' or MAC_QTY ='' or to_number(mac_qty) <1 then
              RES := 'MAC QTY NOT MATCH!' || '\n' || '**END**';
              RAISE e_NULL;
            end if;  

          end if;  

        elsif MAC = 'N/A' or MAC = '' then
          --if LENGTH(MAC_QTY)<>0 then        --mac??,mac_qty???
          if MAC_QTY <>'N/A' and MAC_QTY <>'' then  
            RES := 'MAC_QTY must null when MAC is null!' || '\n' || '**END**';
            RAISE e_NULL;
          end if;

        end if;                

        SELECT 
         count(*)
        into i_mac_qty 
        FROM SFISM4.R_MAC_T where MAC1 = MAC and type = 'MAC';

        if i_mac_qty>0 then     --??????MAC
          RES := 'The MAC:'||MAC||' Has exist!' || '\n' || '**END**';
          RAISE e_NULL;
        end if;     
        */
        if MAC <> 'N/A' or MAC <>'' then

            if length(MAC)<>12 then   --??12
                RES := 'MAC LENGTH NOT MATCH!' || '\n' || '**END**';
                RAISE e_NULL;
            end if;

            if  LENGTH(MAC_QTY)=0 then







                 RES := 'MAC QTY NOT MATCH!' || '\n' || '**END**';
                 RAISE e_NULL;
            end if; 



        end if;        

        -- end add mac info --liujinag 20220419


      --Modified by Steven Hu on 2008-03-19 for TTE-080318-01 Begin
      --p_MACHINECODE:=SUBSTR(MACHINE_CODE,-4,4);
      p_MACHINECODE := MACHINE_CODE;

      --Modified by Steven Hu on 2008-03-19 for TTE-080318-01 End
      SELECT COUNT (*)
        INTO STNCNT
        FROM SFIS1.C_ICT_STATION_T
       WHERE STATION_CODE = p_MACHINECODE;

      IF STNCNT = 0
      THEN
         RAISE e_NO_STN;
      END IF;

      IF STNCNT > 1
      THEN
         RAISE e_STN_DUP;
      END IF;

      SELECT STATION_NAME,
             LINE_NAME,
             SECTION_NAME,
             GROUP_NAME
        INTO p_STATION,
             p_LINE,
             p_SECTION,
             p_GROUP
        FROM SFIS1.C_ICT_STATION_T
       WHERE STATION_CODE = p_MACHINECODE;

      ---  ADD LIUSHICHANG   2021-11-12 //??R_LINK_T???duppy????
     if duppy<>'N/A' and  duppy>1
     then
            insert into  sfism4.r_link_t(serial_Number,available,flag,create_by,create_dt,last_edit_by,last_edit_dt,group_name,key_value) values(barcode,1,'duppy',EMP,sysdate,EMP,sysdate,p_GROUP,DUPPY);
     end if;

      SFIS1.Check_Lsa_H1 (EMP,
                          p_LINE,
                          p_GROUP,
                          H1RES);

      IF H1RES <> 'OK'
      THEN
         RAISE e_H1_ERROR;
      END IF;

      -------------------EMP VERIFY
      SFIS1.CHECK_EMP_V3 (EMP, p_GROUP, EMPRES);

      IF EMPRES <> 'OK'
      THEN
         RAISE e_EMP_ERROR;      --------------------------------EMP Exception
      END IF;

      --being errorcode 20180426 wzw
      IF LENGTH(NVL(ERRORCODE,'')) > 0
      THEN
         IF INSTR (ERRORCODE, ';') > 0
         THEN
            IF SUBSTR (ERRORCODE, 1, 1) = 'E'
            THEN
               SELECT SUBSTR (ERRORCODE, 1, INSTR (ERRORCODE, ';') - 1)
                 INTO error_code_1
                 FROM DUAL;

               SELECT SUBSTR (
                         ERRORCODE,
                         INSTR (ERRORCODE, ';') + 1,
                         LENGTH (ERRORCODE) - INSTR (ERRORCODE, ';') + 1)
                 INTO error_desc_2
                 FROM DUAL;

               SELECT COUNT (*)
                 INTO c_error_code
                 FROM sfis1.c_error_code_t
                WHERE ERROR_CODE = error_code_1;

               p_ERRORCODE := error_code_1;

               IF NVL (c_error_code, 0) <= 0
               THEN
                  INSERT INTO sfis1.c_error_code_t (ERROR_CODE,
                                                    error_class,
                                                    error_item,
                                                    error_degree,
                                                    ERROR_TYPE,
                                                    error_desc,
                                                    error_desc2,
                                                    degree_flag)
                       VALUES (error_code_1,
                               'C',
                               '',
                               1,
                               'E',
                               '',
                               error_desc_2,
                               '');

                  COMMIT;

               END IF;

                 --add by lsc in order to  read error_code_description from test logfile2022/03/02
                 temp:=NVL(trim(error_desc_2),0);
               IF    (temp<>'N/A'  and temp<>'0')
               THEN
                       SELECT ERROR_DESC2
                         INTO P_ERRORDESC
                         FROM sfis1.c_error_code_t
                        WHERE ERROR_CODE = error_code_1;
                    IF P_ERRORDESC<>error_desc_2
                    THEN
                            update sfis1.c_error_code_t set error_desc2=error_desc_2   WHERE ERROR_CODE = error_code_1;
                            commit;
                    END IF;

                END IF;                    
            END IF;

         END IF;
         IF p_ERRORCODE IS NULL
         THEN
            p_ERRORCODE := ERRORCODE;
         END IF;

      ELSE 
      p_ERRORCODE := ERRORCODE;
    END IF; 
      --end errorcode 20180426 wzw

      --Added by Alex Wang on 2010/2/26 for 1HWT-100226-01 Begin
      --Check (MARKETNAME   MEM_VENDOR  MEM_PART  MEM_DATECODE)
      IF     (MARKETNAME <> 'N/A')
         AND (MEM_VENDOR <> 'N/A')
         AND (MEM_PART <> 'N/A')
         AND (MEM_DATECODE <> 'N/A')
      THEN
         SELECT COUNT (*)
           INTO SNCNT
           FROM SFISM4.R_SN_LINK_T
          WHERE NEW_SN = BARCODE;

         IF SNCNT = 0
         THEN                                     --The SN haven't been linked
            p_BARCODE := BARCODE;
         ELSE                                        --The SN have been linked
            SELECT INIT_SN
              INTO p_BARCODE
              FROM SFISM4.R_SN_LINK_T
             WHERE NEW_SN = BARCODE AND ROWNUM = 1;
         END IF;

         SELECT COUNT (*)
           INTO MKTCNT
           FROM SFISM4.R_WIP_TRACKING_T A, SFIS1.C_NV_MODESC_T B
          WHERE     A.SERIAL_NUMBER = p_BARCODE
                AND A.MODEL_NAME = B.L600_690_PN
                AND B.PRODUCT_DESC = MARKETNAME;

         IF MKTCNT = 0
         THEN
            RES := 'MARKET_NAME NOT MATCH!' || '\n' || '**END**';
            RAISE e_NULL;
         END IF;

         --Don't check MEM_DATECODE now(2010/3/4)
         SELECT COUNT (*)
           INTO MEMCNT
           FROM SMTINFO.R_SN_PKG_DETAIL_T C, IQC.R_KPN_INCOMING_T D
          WHERE     C.SERIAL_NUMBER = p_BARCODE
                AND C.PKG_ID = D.PKG_ID
                AND D.HH_PN = MEM_PART;

         IF MEMCNT = 0
         THEN
            RES := 'MEMORY(INFORMATION) NOT MATCH!' || '\n' || '**END**';
            RAISE e_NULL;
         END IF;
      END IF;

      --Added by Alex Wang on 2010/2/26 for 1HWT-100226-01 End

      --Added by songFengLiu 2013-8-8  for S000001C2H-130808-01 begin
      p_MODEL_NAME := MODEL_NAME;

      ---extract 900model
      V_900MODEL_POS := INSTR (MODEL_NAME, ';');

      IF V_900MODEL_POS > 0
      THEN
         p_MODEL_NAME := SUBSTR (model_name, 1, V_900MODEL_POS - 1);
         V_900_MODEL_NAME :=
            SUBSTR (model_name, V_900MODEL_POS + 1, LENGTH (model_name));

         IF INSTR (V_900_MODEL_NAME, '900') > 0
         THEN                                  -- check if it is the 900 model
            --bind 900 model name to sn
            SFISM4.DATALINK (emp,
                             barcode,
                             v_900_model_name,
                             p_group,
                             '900_MODEL_NAME',
                             RES);
         END IF;
      END IF;


      --Added by songFengLiu 2013-8-8  for S000001C2H-130808-01 end


      --Modfied  by songFengLiu 2013-8-8  for S000001C2H-130808-01 begin
      --p_MODEL_NAME:=MODEL_NAME||';'||WORKSCHED;
      p_MODEL_NAME := p_MODEL_NAME || ';' || WORKSCHED;

      --Modfied  by songFengLiu 2013-8-8  for S000001C2H-130808-01 end
      --------*****************************************************************----------
      --------*****************************************************************----------
      ------- -- this source code desgin for all group test twinces------------------------
      --------***********************ADD BY Derrick Chow 2012-1-3 begin ************----------


      --IF (p_GROUP<>'ICT'AND substr (p_GROUP,1,2)<>'5X' AND p_GROUP <>'OQA'
      -- AND p_GROUP <>'COQA' AND p_GROUP <>'OBA'AND p_GROUP <>'OBAT') THEN--OQA??COQA,OBA,OBAT DELETE BY RoyTan
      IF (p_GROUP <> 'ICT' AND SUBSTR (p_GROUP, 1, 2) <> '5X')
      THEN
         IF p_GROUP = 'FLASHROM' 
         OR p_GROUP = 'REFLASHROM'
         OR p_GROUP = 'CHILFLASH'
         OR p_GROUP = 'FLASH_PIC'
         OR p_GROUP ='SECOND_FLASH'
         OR p_GROUP ='SECOND_REFLASH'
         OR p_GROUP ='FLASH_BAT'
         THEN                                    --ADD BY TANRONGLIANG20170721
            SELECT COUNT (*)
              INTO BIOSCNT
              FROM SFIS1.C_PN_BIOS_NOCHECK_T
             WHERE PN = MODEL_NAME AND BIOS = WORKSCHED;

            IF BIOSCNT > 0
            THEN
               RAISE e_BIOSCHECK_ERROR;
            END IF;
         END IF;


         SELECT ECN_PASS_QTY,
                ECN_FAIL_QTY,
                line_name,
                GROUP_NAME,
                MODEL_NAME
           INTO ECNP,
                ECNF,
                V_LINE,
                V_GROUP,
                V_MODEL_NAME
           FROM SFISM4.R_WIP_TRACKING_T
          WHERE SERIAL_NUMBER = BARCODE;

         --SFIS1.CHECK_ROUTE(p_LINE,p_GROUP, BARCODE,RES);   --deleted by maggie on 2015/12/26  for S000003M3Z
         SFIS1.SP_TEST_CHECK_ROUTE (p_LINE,
                                    p_GROUP,
                                    BARCODE,
                                    RES); --added by maggie on 2015/12/26  for S000003M3Z

         IF RES <> 'OK'
         THEN
            RES := RES || '\n' || '**END**';
            RAISE e_NULL;
         END IF;

         IF RESULT = 'P'
         THEN
            IF ECNP IS NULL
            THEN
               IF ECNF IS NULL
               THEN
                  UPDATE SFISM4.R_WIP_TRACKING_T
                     SET ECN_PASS_QTY = 1, ECN_FAIL_QTY = 0
                   WHERE SERIAL_NUMBER = BARCODE;
               ELSE
                  UPDATE SFISM4.R_WIP_TRACKING_T
                     SET ECN_PASS_QTY = 1
                   WHERE SERIAL_NUMBER = BARCODE;
               END IF;
            ELSE
               UPDATE SFISM4.R_WIP_TRACKING_T
                  SET ECN_PASS_QTY = ECN_PASS_QTY + 1
                WHERE SERIAL_NUMBER = BARCODE;
            END IF;
         END IF;



         IF RESULT = 'F'
         THEN
            IF ECNF IS NULL
            THEN
               IF ECNP IS NULL
               THEN
                  UPDATE SFISM4.R_WIP_TRACKING_T
                     SET ECN_FAIL_QTY = 1, ECN_PASS_QTY = 0
                   WHERE SERIAL_NUMBER = BARCODE;
               ELSE
                  UPDATE SFISM4.R_WIP_TRACKING_T
                     SET ECN_FAIL_QTY = 1
                   WHERE SERIAL_NUMBER = BARCODE;
               END IF;
            ELSE
               UPDATE SFISM4.R_WIP_TRACKING_T
                  SET ECN_FAIL_QTY = ECN_FAIL_QTY + 1
                WHERE SERIAL_NUMBER = BARCODE;
            END IF;
         END IF;

         COMMIT;

         SELECT ECN_PASS_QTY, ECN_FAIL_QTY, MO_NUMBER
           INTO ECNP, ECNF, P_MO
           FROM SFISM4.R_WIP_TRACKING_T
          WHERE SERIAL_NUMBER = BARCODE;

         --Add by tanrongliang for Ticket #: S000004AVS begin
         IF RESULT = 'F'
         THEN
            SELECT COUNT (*)
              INTO EXISTCNT
              FROM SFIS1.C_FAILTIME_SET
             WHERE MODEL_NAME = V_MODEL_NAME AND GROUP_NAME = p_GROUP;

            IF EXISTCNT > 0
            THEN
               SELECT FAIL_TIME
                 INTO FAILTIMECNT
                 FROM SFIS1.C_FAILTIME_SET
                WHERE     MODEL_NAME = V_MODEL_NAME
                      AND GROUP_NAME = p_GROUP
                      AND ROWNUM = 1;
            ELSIF EXISTCNT = 0
            THEN
               SELECT COUNT (*)
                 INTO EXISTCNT
                 FROM SFIS1.C_FAILTIME_SET
                WHERE     MODEL_NAME = SUBSTR (V_MODEL_NAME, 5, 5)
                      AND GROUP_NAME = p_GROUP;

               IF EXISTCNT > 0
               THEN
                  SELECT FAIL_TIME
                    INTO FAILTIMECNT
                    FROM SFIS1.C_FAILTIME_SET
                   WHERE     MODEL_NAME = SUBSTR (V_MODEL_NAME, 5, 5)
                         AND GROUP_NAME = p_GROUP
                         AND ROWNUM = 1;
               ELSIF EXISTCNT = 0
               THEN
                  SELECT COUNT (*)
                    INTO EXISTCNT
                    FROM SFIS1.C_FAILTIME_SET
                   WHERE     MODEL_NAME = V_MODEL_NAME
                         AND TRIM (GROUP_NAME) = 'ALL';

                  IF EXISTCNT > 0
                  THEN
                     SELECT FAIL_TIME
                       INTO FAILTIMECNT
                       FROM SFIS1.C_FAILTIME_SET
                      WHERE     MODEL_NAME = V_MODEL_NAME
                            AND TRIM (GROUP_NAME) = 'ALL'
                            AND ROWNUM = 1;
                  ELSIF EXISTCNT = 0
                  THEN
                     SELECT COUNT (*)
                       INTO EXISTCNT
                       FROM SFIS1.C_FAILTIME_SET
                      WHERE     MODEL_NAME = SUBSTR (V_MODEL_NAME, 5, 5)
                            AND TRIM (GROUP_NAME) = 'ALL';

                     IF EXISTCNT > 0
                     THEN
                        SELECT FAIL_TIME
                          INTO FAILTIMECNT
                          FROM SFIS1.C_FAILTIME_SET
                         WHERE     MODEL_NAME = SUBSTR (V_MODEL_NAME, 5, 5)
                               AND TRIM (GROUP_NAME) = 'ALL'
                               AND ROWNUM = 1;
                     END IF;
                  END IF;
               END IF;
            END IF;

            iPOS := INSTR (RETEST, ';');

            IF iPOS <> 0
            THEN
               v_FIXID := SUBSTR (RETEST, iPOS + 1, LENGTH (RETEST) - iPOS);
            END IF;

            IF FAILTIMECNT >= 2
            THEN
               IF (ECNP = 0 AND ECNF < FAILTIMECNT)
               THEN
                  INSERT INTO SFISM4.H_TEST_TEMP_T (SERIAL_NUMBER,
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
                                                    BASIC_TESTTIME_END,
            MACHINE_CODE)
                       VALUES (BARCODE,
                               '1000',
                               p_MODATE,
                               p_WORKTIME1,
                               RESULT,
                               p_ERRORCODE,
                               V_MODEL_NAME,
                               p_GROUP,
                               '0',
                               EMP,
                               p_RETESTTIME,
                               '',
                               p_MO,
                               MARKETNAME,
                               MEM_VENDOR,
                               MEM_PART,
                               MEM_DATECODE,
                               TESTTIME_BEGIN,
                               TESTTIME_END,
        V_FIXID);

                  IF iPOS <> 0
                  THEN
                     SFIS1.CHECK_FIXTURE_NV (v_FIXID, v_FIXRES);

                     IF v_FIXRES <> 'OK'
                     THEN
                        ROLLBACK;
                        RAISE e_FIXID_ERROR;
                     END IF;


                     INSERT INTO SFISM4.H_SN_FIXTURE_T (SERIAL_NUMBER,
                                                        FIXID,
                                                        GROUP_NAME,
                                                        STATION_NAME,
                                                        STATION_CODE,
                                                        EMP,
                                                        IN_STATION_TIME)
                          VALUES (BARCODE,
                                  v_FIXID,
                                  p_GROUP,
                                  p_STATION,
                                  p_MACHINECODE,
                                  EMP,
                                  p_DATE);
                  END IF;

                  --add by LLF 2017-09-28 BEGIN
                  IF DIAG <> 'N/A'
                  THEN
                     SFISM4.DATALINK_firstfail (EMP,
                                                BARCODE,
                                                DIAG,
                                                p_GROUP,
                                                'DIAG',
                                                p_DATE,
                                                v_DIAGRES);

                     IF v_DIAGRES <> 'OK'
                     THEN
                        RES := 'ECID DATA_LINK ERROR:' || v_DIAGRES;
                        RAISE e_NULL;
                     END IF;
                  END IF;

                  --ADD BY LSC 20220121 add firstfail testlogname
                     IF  TEST_LOGNAME <> 'N/A'
                  THEN
                     SFISM4.DATALINK_firstfail (EMP,
                                                BARCODE,
                                                TEST_LOGNAME,
                                                p_GROUP,
                                                'LOGNAME',
                                                p_DATE,
                                                v_DIAGRES);

                     IF v_DIAGRES <> 'OK'
                     THEN
                        RES := 'TEST_LOGNAME_LINK ERROR:' || v_DIAGRES;
                        RAISE e_NULL;
                     END IF;
                  END IF;
                  IF ECID <> 'N/A'
                  THEN
                     SFISM4.DATALINK_firstfail (EMP,
                                                BARCODE,
                                                ECID,
                                                p_GROUP,
                                                'ECID',
                                                p_DATE,
                                                v_ECIDRES);

                     IF v_ECIDRES <> 'OK'
                     THEN
                        RES := 'ECID DATA_LINK ERROR:' || v_ECIDRES;
                        RAISE e_NULL;
                     END IF;
                  END IF;

                  --add by LLF 2017-09-28 END



                --ADD TANZISONG 2019-0502 BEGIN  // ??H_LINK_T ??BIN ??


                   -- **********by  2019-05-04 tzs add -***************************8--

                 IF LENGTH(p_collect)>0 AND p_collect<>'N/A' THEN 

                       IF INSTR(p_collect,'|')>0 THEN
                         begin
                           V_collect:=substr(p_collect,1,instr(p_collect,'|')-1);
                           V_collect2:=substr(p_collect,instr(p_collect,'|')+1,length(P_collect)-instr(P_collect,'|'));              
                     if length(V_collect)>0 and INSTR(V_collect,':')>0 then              

                   BEGIN
                       V_TEMP:=substr(V_collect,1,instr(V_collect,':')-1);
                       V_VALUE:=substr(V_collect,instr(V_collect,':')+1,length(V_collect)-instr(V_collect,':')); 

                       SFISM4.DATALINK_firstfail (EMP,BARCODE,V_VALUE,p_GROUP,'BIN',p_DATE,v_ECIDRES);

                       IF v_ECIDRES <> 'OK'
                        THEN
                        RES := 'BIN DATA_LINK ERROR:' || v_ECIDRES;
                        RAISE e_NULL;
                      END IF;

                    END;
                   END IF; 


                     if length(V_collect2)>0 and INSTR(V_collect2,':')>0 then
                       BEGIN
                          V_TEMP2:=substr(V_collect2,1,instr(V_collect2,':')-1);
                          V_VALUE2:=substr(V_collect2,instr(V_collect2,':')+1,length(V_collect2)-instr(V_collect2,':'));                  


                          SFISM4.DATALINK_firstfail (EMP,BARCODE,V_VALUE2,p_GROUP,'BIN',p_DATE,v_ECIDRES);

                          IF v_ECIDRES <> 'OK'
                           THEN
                              RES := 'BIN DATA_LINK ERROR:' || v_ECIDRES;
                              RAISE e_NULL;
                           END IF;

                       END;
                     END IF; 

                   end;           

                  else

                      begin

                         if length(p_collect)>0 and INSTR(p_collect,':')>0 then              

                          BEGIN
                            V_TEMP:=substr(p_collect,1,instr(p_collect,':')-1);
                            V_VALUE:=substr(p_collect,instr(p_collect,':')+1,length(p_collect)-instr(p_collect,':')); 

                               SFISM4.DATALINK_firstfail (EMP,BARCODE,V_VALUE,p_GROUP,'BIN',p_DATE,v_ECIDRES);

                              IF v_ECIDRES <> 'OK'
                               THEN
                                  RES := 'BIN DATA_LINK ERROR:' || v_ECIDRES;
                                  RAISE e_NULL;
                              END IF;     


                           END;
                        END IF; 
                     end;     

                      end IF;  


                    END IF;     

                    -- **********by  2019-05-04 tzs add -***************************8--

                    --ADD TANZISONG 2019-0502  END // ??H_LINK_T ??BIN ?? END.




                  COMMIT;

                  res :=
                        'Is '
                     || ECNF
                     || ' time(s) test fail,need to retest to confirm'
                     || '\n'
                     || '**END**';
                  RAISE e_NULL;
               END IF;
            ELSIF    FAILTIMECNT = 1
                  OR (    LENGTH (V_MODEL_NAME) = 18
                      AND SUBSTR (V_MODEL_NAME, 5, 1) = 2)
            THEN
               SELECT COUNT (*)
                 INTO FAILECEXISTCNT
                 FROM SFIS1.C_FAIL_EC_SET
                WHERE     MODEL_NAME = V_MODEL_NAME
                      AND GROUP_NAME = p_GROUP
                      AND ERROR_CODE =
                             SUBSTR (p_ERRORCODE, -LENGTH (ERROR_CODE));


               IF FAILECEXISTCNT > 0
               THEN
                  SELECT FAIL_TIME
                    INTO FAILECCNT
                    FROM SFIS1.C_FAIL_EC_SET
                   WHERE     MODEL_NAME = V_MODEL_NAME
                         AND GROUP_NAME = p_GROUP
                         AND ERROR_CODE =
                                SUBSTR (p_ERRORCODE, -LENGTH (ERROR_CODE))
                         AND ROWNUM = 1;
               ELSIF FAILECEXISTCNT = 0
               THEN
                  SELECT COUNT (*)
                    INTO FAILECEXISTCNT
                    FROM SFIS1.C_FAIL_EC_SET
                   WHERE     MODEL_NAME = SUBSTR (V_MODEL_NAME, 5, 5)
                         AND GROUP_NAME = p_GROUP
                         AND ERROR_CODE =
                                SUBSTR (p_ERRORCODE, -LENGTH (ERROR_CODE));

                  IF FAILECEXISTCNT > 0
                  THEN
                     SELECT FAIL_TIME
                       INTO FAILECCNT
                       FROM SFIS1.C_FAIL_EC_SET
                      WHERE     MODEL_NAME = SUBSTR (V_MODEL_NAME, 5, 5)
                            AND GROUP_NAME = p_GROUP
                            AND ERROR_CODE =
                                   SUBSTR (p_ERRORCODE, -LENGTH (ERROR_CODE))
                            AND ROWNUM = 1;
                  ELSIF FAILECEXISTCNT = 0
                  THEN
                     SELECT COUNT (*)
                       INTO FAILECEXISTCNT
                       FROM SFIS1.C_FAIL_EC_SET
                      WHERE     MODEL_NAME = V_MODEL_NAME
                            AND TRIM (GROUP_NAME) = 'ALL'
                            AND ERROR_CODE =
                                   SUBSTR (p_ERRORCODE, -LENGTH (ERROR_CODE));

                     IF FAILECEXISTCNT > 0
                     THEN
                        SELECT FAIL_TIME
                          INTO FAILECCNT
                          FROM SFIS1.C_FAIL_EC_SET
                         WHERE     MODEL_NAME = V_MODEL_NAME
                               AND TRIM (GROUP_NAME) = 'ALL'
                               AND ERROR_CODE =
                                      SUBSTR (p_ERRORCODE,
                                              -LENGTH (ERROR_CODE))
                               AND ROWNUM = 1;
                     ELSIF FAILECEXISTCNT = 0
                     THEN
                        SELECT COUNT (*)
                          INTO FAILECEXISTCNT
                          FROM SFIS1.C_FAIL_EC_SET
                         WHERE     MODEL_NAME = SUBSTR (V_MODEL_NAME, 5, 5)
                               AND TRIM (GROUP_NAME) = 'ALL'
                               AND ERROR_CODE =
                                      SUBSTR (p_ERRORCODE,
                                              -LENGTH (ERROR_CODE));

                        IF FAILECEXISTCNT > 0
                        THEN
                           SELECT FAIL_TIME
                             INTO FAILECCNT
                             FROM SFIS1.C_FAIL_EC_SET
                            WHERE     MODEL_NAME =
                                         SUBSTR (V_MODEL_NAME, 5, 5)
                                  AND TRIM (GROUP_NAME) = 'ALL'
                                  AND ERROR_CODE =
                                         SUBSTR (p_ERRORCODE,
                                                 -LENGTH (ERROR_CODE))
                                  AND ROWNUM = 1;
                        END IF;
                     END IF;
                  END IF;
               END IF;
            -- lingshiheng change error code firstfail into repair 
            -- BEGIN 20251120
            IF FAILECEXISTCNT = 0
                THEN 
                    IF (ECNP = 0 AND ECNF =1)
                    THEN 
                     INSERT INTO SFISM4.H_TEST_TEMP_T (SERIAL_NUMBER,
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
                                                       BASIC_TESTTIME_END,
            MACHINE_CODE)
                          VALUES (BARCODE,
                                  '1000',
                                  p_MODATE,
                                  p_WORKTIME1,
                                  RESULT,
                                  p_ERRORCODE,
                                  V_MODEL_NAME,
                                  p_GROUP,
                                  '0',
                                  EMP,
                                  p_RETESTTIME,
                                  '',
                                  p_MO,
                                  MARKETNAME,
                                  MEM_VENDOR,
                                  MEM_PART,
                                  MEM_DATECODE,
                                  TESTTIME_BEGIN,
                                  TESTTIME_END,
        V_FIXID);


                     IF iPOS <> 0
                     THEN
                        SFIS1.CHECK_FIXTURE_NV (v_FIXID, v_FIXRES);

                        IF v_FIXRES <> 'OK'
                        THEN
                           ROLLBACK;
                           RAISE e_FIXID_ERROR;
                        END IF;


                        INSERT INTO SFISM4.H_SN_FIXTURE_T (SERIAL_NUMBER,
                                                           FIXID,
                                                           GROUP_NAME,
                                                           STATION_NAME,
                                                           STATION_CODE,
                                                           EMP,
                                                           IN_STATION_TIME)
                             VALUES (BARCODE,
                                     v_FIXID,
                                     p_GROUP,
                                     p_STATION,
                                     p_MACHINECODE,
                                     EMP,
                                     p_DATE);
                     END IF;

                     --add by LLF 2017-09-28 BEGIN
                     IF DIAG <> 'N/A'
                     THEN
                        SFISM4.DATALINK_firstfail (EMP,
                                                   BARCODE,
                                                   DIAG,
                                                   p_GROUP,
                                                   'DIAG',
                                                   p_DATE,
                                                   v_DIAGRES);

                        IF v_DIAGRES <> 'OK'
                        THEN
                           RES := 'ECID DATA_LINK ERROR:' || v_DIAGRES;
                           RAISE e_NULL;
                        END IF;
                     END IF;

                 --ADD BY LSC 20220121 add firstfail testlogname
                                 IF  TEST_LOGNAME <> 'N/A'
                              THEN
                                 SFISM4.DATALINK_firstfail (EMP,
                                                            BARCODE,
                                                            TEST_LOGNAME,
                                                            p_GROUP,
                                                            'LOGNAME',
                                                            p_DATE,
                                                            v_DIAGRES);

                                 IF v_DIAGRES <> 'OK'
                                 THEN
                                    RES := 'TEST_LOGNAME_LINK ERROR:' || v_DIAGRES;
                                    RAISE e_NULL;
                                 END IF;
                              END IF;
                     IF ECID <> 'N/A'
                     THEN
                        SFISM4.DATALINK_firstfail (EMP,
                                                   BARCODE,
                                                   ECID,
                                                   p_GROUP,
                                                   'ECID',
                                                   p_DATE,
                                                   v_ECIDRES);

                        IF v_ECIDRES <> 'OK'
                        THEN
                           RES := 'ECID DATA_LINK ERROR:' || v_ECIDRES;
                           RAISE e_NULL;
                        END IF;
                     END IF;



                --ADD TANZISONG 2019-0502 BEGIN  // ?H_LINK_T ?BIN ?


                   -- **********by  2019-05-04 tzs add -***************************8--

                 IF LENGTH(p_collect)>0 AND p_collect<>'N/A' THEN 

                       IF INSTR(p_collect,'|')>0 THEN
                         begin
                           V_collect:=substr(p_collect,1,instr(p_collect,'|')-1);
                           V_collect2:=substr(p_collect,instr(p_collect,'|')+1,length(P_collect)-instr(P_collect,'|'));              
                     if length(V_collect)>0 and INSTR(V_collect,':')>0 then              

                   BEGIN
                       V_TEMP:=substr(V_collect,1,instr(V_collect,':')-1);
                       V_VALUE:=substr(V_collect,instr(V_collect,':')+1,length(V_collect)-instr(V_collect,':')); 

                       SFISM4.DATALINK_firstfail (EMP,BARCODE,V_VALUE,p_GROUP,'BIN',p_DATE,v_ECIDRES);

                       IF v_ECIDRES <> 'OK'
                        THEN
                        RES := 'BIN DATA_LINK ERROR:' || v_ECIDRES;
                        RAISE e_NULL;
                      END IF;

                    END;
                   END IF; 


                     if length(V_collect2)>0 and INSTR(V_collect2,':')>0 then
                       BEGIN
                          V_TEMP2:=substr(V_collect2,1,instr(V_collect2,':')-1);
                          V_VALUE2:=substr(V_collect2,instr(V_collect2,':')+1,length(V_collect2)-instr(V_collect2,':'));                  


                          SFISM4.DATALINK_firstfail (EMP,BARCODE,V_VALUE2,p_GROUP,'BIN',p_DATE,v_ECIDRES);

                          IF v_ECIDRES <> 'OK'
                           THEN
                              RES := 'BIN DATA_LINK ERROR:' || v_ECIDRES;
                              RAISE e_NULL;
                           END IF;

                       END;
                     END IF; 

                   end;           

                  else

                      begin

                         if length(p_collect)>0 and INSTR(p_collect,':')>0 then              

                          BEGIN
                            V_TEMP:=substr(p_collect,1,instr(p_collect,':')-1);
                            V_VALUE:=substr(p_collect,instr(p_collect,':')+1,length(p_collect)-instr(p_collect,':')); 

                               SFISM4.DATALINK_firstfail (EMP,BARCODE,V_VALUE,p_GROUP,'BIN',p_DATE,v_ECIDRES);

                              IF v_ECIDRES <> 'OK'
                               THEN
                                  RES := 'BIN DATA_LINK ERROR:' || v_ECIDRES;
                                  RAISE e_NULL;
                              END IF;     


                           END;
                        END IF; 
                     end;     

                      end IF;  


                    END IF;     

                    -- **********by  2019-05-04 tzs add -***************************8--

               --ADD TANZISONG 2019-0502  END // ?H_LINK_T ?BIN ? END.



                     --add by LLF 2017-09-28 END
                     COMMIT;

                     res :=
                           'Is '
                        || ECNF
                        || ' time(s) test fail,need to retest to confirm'
                        || '\n'
                        || '**END**';
                     RAISE e_NULL;
                  END IF;
                END IF;
                -- END  20251120
               IF FAILECEXISTCNT > 0
               THEN
                  IF (ECNP = 0 AND ECNF < FAILECCNT)
                  THEN
                     INSERT INTO SFISM4.H_TEST_TEMP_T (SERIAL_NUMBER,
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
                                                       BASIC_TESTTIME_END,
            MACHINE_CODE)
                          VALUES (BARCODE,
                                  '1000',
                                  p_MODATE,
                                  p_WORKTIME1,
                                  RESULT,
                                  p_ERRORCODE,
                                  V_MODEL_NAME,
                                  p_GROUP,
                                  '0',
                                  EMP,
                                  p_RETESTTIME,
                                  '',
                                  p_MO,
                                  MARKETNAME,
                                  MEM_VENDOR,
                                  MEM_PART,
                                  MEM_DATECODE,
                                  TESTTIME_BEGIN,
                                  TESTTIME_END,
        V_FIXID);


                     IF iPOS <> 0
                     THEN
                        SFIS1.CHECK_FIXTURE_NV (v_FIXID, v_FIXRES);

                        IF v_FIXRES <> 'OK'
                        THEN
                           ROLLBACK;
                           RAISE e_FIXID_ERROR;
                        END IF;


                        INSERT INTO SFISM4.H_SN_FIXTURE_T (SERIAL_NUMBER,
                                                           FIXID,
                                                           GROUP_NAME,
                                                           STATION_NAME,
                                                           STATION_CODE,
                                                           EMP,
                                                           IN_STATION_TIME)
                             VALUES (BARCODE,
                                     v_FIXID,
                                     p_GROUP,
                                     p_STATION,
                                     p_MACHINECODE,
                                     EMP,
                                     p_DATE);
                     END IF;

                     --add by LLF 2017-09-28 BEGIN
                     IF DIAG <> 'N/A'
                     THEN
                        SFISM4.DATALINK_firstfail (EMP,
                                                   BARCODE,
                                                   DIAG,
                                                   p_GROUP,
                                                   'DIAG',
                                                   p_DATE,
                                                   v_DIAGRES);

                        IF v_DIAGRES <> 'OK'
                        THEN
                           RES := 'ECID DATA_LINK ERROR:' || v_DIAGRES;
                           RAISE e_NULL;
                        END IF;
                     END IF;

                 --ADD BY LSC 20220121 add firstfail testlogname
                                 IF  TEST_LOGNAME <> 'N/A'
                              THEN
                                 SFISM4.DATALINK_firstfail (EMP,
                                                            BARCODE,
                                                            TEST_LOGNAME,
                                                            p_GROUP,
                                                            'LOGNAME',
                                                            p_DATE,
                                                            v_DIAGRES);

                                 IF v_DIAGRES <> 'OK'
                                 THEN
                                    RES := 'TEST_LOGNAME_LINK ERROR:' || v_DIAGRES;
                                    RAISE e_NULL;
                                 END IF;
                              END IF;
                     IF ECID <> 'N/A'
                     THEN
                        SFISM4.DATALINK_firstfail (EMP,
                                                   BARCODE,
                                                   ECID,
                                                   p_GROUP,
                                                   'ECID',
                                                   p_DATE,
                                                   v_ECIDRES);

                        IF v_ECIDRES <> 'OK'
                        THEN
                           RES := 'ECID DATA_LINK ERROR:' || v_ECIDRES;
                           RAISE e_NULL;
                        END IF;
                     END IF;



                --ADD TANZISONG 2019-0502 BEGIN  // ??H_LINK_T ??BIN ??


                   -- **********by  2019-05-04 tzs add -***************************8--

                 IF LENGTH(p_collect)>0 AND p_collect<>'N/A' THEN 

                       IF INSTR(p_collect,'|')>0 THEN
                         begin
                           V_collect:=substr(p_collect,1,instr(p_collect,'|')-1);
                           V_collect2:=substr(p_collect,instr(p_collect,'|')+1,length(P_collect)-instr(P_collect,'|'));              
                     if length(V_collect)>0 and INSTR(V_collect,':')>0 then              

                   BEGIN
                       V_TEMP:=substr(V_collect,1,instr(V_collect,':')-1);
                       V_VALUE:=substr(V_collect,instr(V_collect,':')+1,length(V_collect)-instr(V_collect,':')); 

                       SFISM4.DATALINK_firstfail (EMP,BARCODE,V_VALUE,p_GROUP,'BIN',p_DATE,v_ECIDRES);

                       IF v_ECIDRES <> 'OK'
                        THEN
                        RES := 'BIN DATA_LINK ERROR:' || v_ECIDRES;
                        RAISE e_NULL;
                      END IF;

                    END;
                   END IF; 


                     if length(V_collect2)>0 and INSTR(V_collect2,':')>0 then
                       BEGIN
                          V_TEMP2:=substr(V_collect2,1,instr(V_collect2,':')-1);
                          V_VALUE2:=substr(V_collect2,instr(V_collect2,':')+1,length(V_collect2)-instr(V_collect2,':'));                  


                          SFISM4.DATALINK_firstfail (EMP,BARCODE,V_VALUE2,p_GROUP,'BIN',p_DATE,v_ECIDRES);

                          IF v_ECIDRES <> 'OK'
                           THEN
                              RES := 'BIN DATA_LINK ERROR:' || v_ECIDRES;
                              RAISE e_NULL;
                           END IF;

                       END;
                     END IF; 

                   end;           

                  else

                      begin

                         if length(p_collect)>0 and INSTR(p_collect,':')>0 then              

                          BEGIN
                            V_TEMP:=substr(p_collect,1,instr(p_collect,':')-1);
                            V_VALUE:=substr(p_collect,instr(p_collect,':')+1,length(p_collect)-instr(p_collect,':')); 

                               SFISM4.DATALINK_firstfail (EMP,BARCODE,V_VALUE,p_GROUP,'BIN',p_DATE,v_ECIDRES);

                              IF v_ECIDRES <> 'OK'
                               THEN
                                  RES := 'BIN DATA_LINK ERROR:' || v_ECIDRES;
                                  RAISE e_NULL;
                              END IF;     


                           END;
                        END IF; 
                     end;     

                      end IF;  


                    END IF;     

                    -- **********by  2019-05-04 tzs add -***************************8--

               --ADD TANZISONG 2019-0502  END // ??H_LINK_T ??BIN ?? END.



                     --add by LLF 2017-09-28 END
                     COMMIT;

                     res :=
                           'Is '
                        || ECNF
                        || ' time(s) test fail,need to retest to confirm'
                        || '\n'
                        || '**END**';
                     RAISE e_NULL;
                  END IF;

               ELSE
                  IF ECNF = 1
                  THEN
                     res := 'OK';
                  ELSE
                     --RES:= 'Route ERROR for twince test '||'\n'||'**END**';
                     RES := 'OK';
                  END IF;
               END IF;
            ELSE
               IF (ECNF = 2)
               THEN
                  res := 'OK';
               ELSIF (ECNP = 0 AND ECNF = 1)
               THEN
                  INSERT INTO SFISM4.H_TEST_TEMP_T (SERIAL_NUMBER,
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
                                                    BASIC_TESTTIME_END,
            MACHINE_CODE)
                       VALUES (BARCODE,
                               '1000',
                               p_MODATE,
                               p_WORKTIME1,
                               RESULT,
                               p_ERRORCODE,
                               V_MODEL_NAME,
                               p_GROUP,
                               '0',
                               EMP,
                               p_RETESTTIME,
                               '',
                               p_MO,
                               MARKETNAME,
                               MEM_VENDOR,
                               MEM_PART,
                               MEM_DATECODE,
                               TESTTIME_BEGIN,
                               TESTTIME_END,
        V_FIXID);

                  IF iPOS <> 0
                  THEN
                     SFIS1.CHECK_FIXTURE_NV (v_FIXID, v_FIXRES);

                     IF v_FIXRES <> 'OK'
                     THEN
                        ROLLBACK;
                        RAISE e_FIXID_ERROR;
                     END IF;


                     INSERT INTO SFISM4.H_SN_FIXTURE_T (SERIAL_NUMBER,
                                                        FIXID,
                                                        GROUP_NAME,
                                                        STATION_NAME,
                                                        STATION_CODE,
                                                        EMP,
                                                        IN_STATION_TIME)
                          VALUES (BARCODE,
                                  v_FIXID,
                                  p_GROUP,
                                  p_STATION,
                                  p_MACHINECODE,
                                  EMP,
                                  p_DATE);
                  END IF;

                  --add by LLF 2017-09-28 BEGIN
                  IF DIAG <> 'N/A'
                  THEN
                     SFISM4.DATALINK_firstfail (EMP,
                                                BARCODE,
                                                DIAG,
                                                p_GROUP,
                                                'DIAG',
                                                p_DATE,
                                                v_DIAGRES);

                     IF v_DIAGRES <> 'OK'
                     THEN
                        RES := 'ECID DATA_LINK ERROR:' || v_DIAGRES;
                        RAISE e_NULL;
                     END IF;
                  END IF;

                     --ADD BY LSC 20220121 add firstfail testlogname
                     IF  TEST_LOGNAME <> 'N/A'
                  THEN
                     SFISM4.DATALINK_firstfail (EMP,
                                                BARCODE,
                                                TEST_LOGNAME,
                                                p_GROUP,
                                                'LOGNAME',
                                                p_DATE,
                                                v_DIAGRES);

                     IF v_DIAGRES <> 'OK'
                     THEN
                        RES := 'TEST_LOGNAME_LINK ERROR:' || v_DIAGRES;
                        RAISE e_NULL;
                     END IF;
                  END IF;
                  IF ECID <> 'N/A'
                  THEN
                     SFISM4.DATALINK_firstfail (EMP,
                                                BARCODE,
                                                ECID,
                                                p_GROUP,
                                                'ECID',
                                                p_DATE,
                                                v_ECIDRES);

                     IF v_ECIDRES <> 'OK'
                     THEN
                        RES := 'ECID DATA_LINK ERROR:' || v_ECIDRES;
                        RAISE e_NULL;
                     END IF;
                  END IF;


                 --add by LLF 2017-09-28 END


                --ADD TANZISONG 2019-0502 BEGIN  // ??H_LINK_T ??BIN ??


                   -- **********by  2019-05-04 tzs add -***************************8--

                 IF LENGTH(p_collect)>0 AND p_collect<>'N/A' THEN 

                       IF INSTR(p_collect,'|')>0 THEN
                         begin
                           V_collect:=substr(p_collect,1,instr(p_collect,'|')-1);
                           V_collect2:=substr(p_collect,instr(p_collect,'|')+1,length(P_collect)-instr(P_collect,'|'));              
                     if length(V_collect)>0 and INSTR(V_collect,':')>0 then              

                   BEGIN
                       V_TEMP:=substr(V_collect,1,instr(V_collect,':')-1);
                       V_VALUE:=substr(V_collect,instr(V_collect,':')+1,length(V_collect)-instr(V_collect,':')); 

                       SFISM4.DATALINK_firstfail (EMP,BARCODE,V_VALUE,p_GROUP,'BIN',p_DATE,v_ECIDRES);

                       IF v_ECIDRES <> 'OK'
                        THEN
                        RES := 'BIN DATA_LINK ERROR:' || v_ECIDRES;
                        RAISE e_NULL;
                      END IF;

                    END;
                   END IF; 


                     if length(V_collect2)>0 and INSTR(V_collect2,':')>0 then
                       BEGIN
                          V_TEMP2:=substr(V_collect2,1,instr(V_collect2,':')-1);
                          V_VALUE2:=substr(V_collect2,instr(V_collect2,':')+1,length(V_collect2)-instr(V_collect2,':'));                  


                          SFISM4.DATALINK_firstfail (EMP,BARCODE,V_VALUE2,p_GROUP,'BIN',p_DATE,v_ECIDRES);

                          IF v_ECIDRES <> 'OK'
                           THEN
                              RES := 'BIN DATA_LINK ERROR:' || v_ECIDRES;
                              RAISE e_NULL;
                           END IF;

                       END;
                     END IF; 

                   end;           

                  else

                      begin

                         if length(p_collect)>0 and INSTR(p_collect,':')>0 then              

                          BEGIN
                            V_TEMP:=substr(p_collect,1,instr(p_collect,':')-1);
                            V_VALUE:=substr(p_collect,instr(p_collect,':')+1,length(p_collect)-instr(p_collect,':')); 

                               SFISM4.DATALINK_firstfail (EMP,BARCODE,V_VALUE,p_GROUP,'BIN',p_DATE,v_ECIDRES);

                              IF v_ECIDRES <> 'OK'
                               THEN
                                  RES := 'BIN DATA_LINK ERROR:' || v_ECIDRES;
                                  RAISE e_NULL;
                              END IF;     


                           END;
                        END IF; 
                     end;     

                      end IF;  


                    END IF;     

                    -- **********by  2019-05-04 tzs add -***************************8--

               --ADD TANZISONG 2019-0502  END // ??H_LINK_T ??BIN ?? END.



                  COMMIT;

                  INSERT INTO SFISM4.H_REPAIR_T (SERIAL_NUMBER,
                                                 MO_NUMBER,
                                                 TEST_TIME,
                                                 TEST_CODE,
                                                 TEST_STATION,
                                                 TEST_LINE,
                                                 RECORD_TYPE,
                                                 MODEL_NAME)
                       VALUES (BARCODE,
                               P_MO,
                               p_DATE,
                               p_ERRORCODE,
                               p_GROUP,
                               p_LINE,
                               'F',
                               V_MODEL_NAME);

                  COMMIT;
                  res :=
                        'First test fail,need to retest to confirm'
                     || '\n'
                     || '**END**';
                  RAISE e_NULL;
               ELSE
                  --RES:= 'Route ERROR for twince test '||'\n'||'**END**';
                  RES := 'OK';
               END IF;
            END IF;
         END IF;
      --Add by tanrongliang for Ticket #: S000004AVS end



      END IF;

      --------********************************************************************----------
      --------*****************************************************************----------
      --------***********************ADD BY Derrick Chow 2012-1-3  begin ************---------
      --Added by Alex Wang on 2011/2/18 for 2A3B-110218-01 (For 'Car') Begin
      SFISM4.Iautotest (BARCODE,
                        MACHINE_CODE,
                        TESTTIME_BEGIN,
                        TESTTIME_END,
                        RESULT,
                        p_ERRORCODE,
                        p_MODEL_NAME,
                        p_GROUP,
                        '0',
                        EMP,
                        RETEST,
                        '',
                        DIAG,
                        ECID,
                        MARKETNAME,
                        MEM_VENDOR,
                        MEM_PART,
                        MEM_DATECODE,
                        P_COLLECT,     ----BY 2018-07-04 MAC  MODIFICATION   P_COLLECT
                        TEST_LOGNAME,
                        DISPOSITION,---- BY 2019-10-28
                        INPUTRES);

      --Added by Alex Wang on 2011/2/18 for 2A3B-110218-01 (For 'Car') End
      IF INPUTRES <> '0'
      THEN
         --------*****************************************************************----------
         --------*****************************************************************----------
         ------- -- this source code desgin for all group test twinces------------------------
         --------***********************ADD BY Derrick Chow 2012-1-3 begin ************----------
         IF (p_GROUP <> 'ICT' AND SUBSTR (p_GROUP, 1, 2) <> '5X')
         THEN                                           -- AND p_GROUP <>'OQA'
            --AND p_GROUP <>'COQA' AND p_GROUP <>'OBA'AND p_GROUP <>'OBAT'
            IF INPUTRES <> '1' AND INPUTRES <> '2'
            THEN
               IF result = 'F'
               THEN
                  UPDATE SFISM4.R_WIP_TRACKING_T
                     SET ECN_FAIL_QTY = ECN_FAIL_QTY - 1
                   WHERE SERIAL_NUMBER = BARCODE;

                  COMMIT;
               END IF;

               IF result = 'P'
               THEN
                  UPDATE SFISM4.R_WIP_TRACKING_T
                     SET ECN_PASS_QTY = ECN_PASS_QTY - 1
                   WHERE SERIAL_NUMBER = BARCODE;

                  COMMIT;
               END IF;

               RAISE e_INPUT_ERROR;
            ELSE
               UPDATE SFISM4.R_WIP_TRACKING_T
                  SET ECN_FAIL_QTY = 0, ECN_PASS_QTY = 0
                WHERE SERIAL_NUMBER = BARCODE;

               COMMIT;
            END IF;
         END IF;
      ELSE
         UPDATE SFISM4.R_WIP_TRACKING_T
            SET ECN_FAIL_QTY = 0, ECN_PASS_QTY = 0
          WHERE SERIAL_NUMBER = BARCODE;

         COMMIT;
      --------********************************************************************----------
      --------*****************************************************************----------
      -----***********************ADD BY Derrick Chow 2012-1-3  begin ************----------

      END IF;

        -- begin add mac info --liujinag 20220419
      --  if LENGTH(MAC)=12 then     --??????,??????   

      --      Insert into SFISM4.R_MAC_T
      --         (SERIAL_NUMBER, TYPE, QTY, MAC1, LASTEDITBY, LASTEDITDT)
      --       Values
      --         (BARCODE, 'MAC', MAC_QTY, MAC, EMP, SYSDATE);        
      --  end if;        
        -- end add mac info --liujinag 20220419

        --BEGIN modify by liujiang20221213 SN????MAC,MAC????SN
        SELECT 
         count(*)
        into i_mac_qty 
        FROM SFISM4.R_MAC_T where SERIAL_NUMBER = BARCODE and type = 'MAC';

        if i_mac_qty>=1 then     --??????MAC
            if LENGTH(MAC)=12 then 
                UPDATE SFISM4.R_MAC_T
                   SET MAC1 = MAC,LASTEDITDT = SYSDATE
                 WHERE SERIAL_NUMBER = BARCODE and type = 'MAC';
            end if;         
        else
            SELECT 
             count(*)
            into i_mac_qty 
            FROM SFISM4.R_MAC_T where MAC1 = MAC and type = 'MAC';        

            if i_mac_qty>=1 then
                if LENGTH(MAC)=12 then
                    UPDATE SFISM4.R_MAC_T
                       SET SERIAL_NUMBER = BARCODE,LASTEDITDT = SYSDATE
                     WHERE MAC1 = MAC and type = 'MAC';    
                end if;                 
            else
                if LENGTH(MAC)=12 then     --??????,??????   

                    Insert into SFISM4.R_MAC_T
                       (SERIAL_NUMBER, TYPE, QTY, MAC1, LASTEDITBY, LASTEDITDT)
                     Values
                       (BARCODE, 'MAC', MAC_QTY, MAC, EMP, SYSDATE);        
                end if;            
            end if;

        end if;        
        --END modify by liujiang20221213 SN????MAC,MAC????SN  

      RES := INPUTRES || '\n' || '**END**';

      -------------------CHECK IF SHOULD BE STOP LINE
      SFIS1.Check_Lsa_H (EMP,
                         p_LINE,
                         p_GROUP,
                         HRES);

      IF HRES <> 'OK'
      THEN
         RES := HRES || '\n' || '**END**';
      END IF;
   --Added by Alex Wang on 2010/2/26 for 1HWT-100226-01 Begin
   ELSE
      RES := 'WRONG INPUT LINES!' || '\n' || '**END**';
      RAISE e_NULL;
   END IF;
--Added by Alex Wang on 2010/2/26 for 1HWT-100226-01 End
   o_flag := '0';

EXCEPTION
   WHEN e_DATETIME_ERROR
   THEN
      RES := 'BEGINTIME GREATER THAN ENDTIME!' || '\n' || '**END**';
   WHEN e_FILE_ERROR
   THEN
      RES := 'WRONG FILE FORMAT!' || '\n' || '**END**';
   WHEN e_NO_STN
   THEN
      RES := 'NO Station' || '\n' || '**END**';
   WHEN e_STN_DUP
   THEN
      RES := 'Station DUPLICATED' || '\n' || '**END**';
   WHEN e_EMP_ERROR
   THEN
      RES := EMPRES || '\n' || '**END**';
   WHEN e_INPUT_ERROR
   THEN
      RES := INPUTRES || '\n' || '**END**';
   WHEN e_H1_ERROR
   THEN
      RES := H1RES || '\n' || '**END**';
   WHEN e_NULL
   THEN
      NULL;
   WHEN e_BIOSCHECK_ERROR
   THEN
      RES := 'BIOS CHECK NG' || '\n' || '**END**';
   WHEN e_FIXID_ERROR
   THEN
      BEGIN
         RES := v_FIXRES;
      END;
   WHEN e_TIME_ERROR
   THEN
      RES := 'TEST END TIME ERROR!' || '\n' || '**END**';
   WHEN OTHERS
   THEN
      --RES:='OTHERS ERROR'||'\n'||'**END**';
      RES := 'OTHER ERROR ' || SUBSTR (SQLERRM, 1, 50) || '\n' || '**END**';
END; 