PROCEDURE                               SP_PLMS_AUTOLOGGING(
   i_user           IN     VARCHAR2,
   i_cust_code      IN     VARCHAR2,
   i_station_code   IN     VARCHAR2,
   i_host_name        IN     VARCHAR2,   
   i_sn             IN     VARCHAR2,   
   i_result         IN     VARCHAR2,
   i_bin_number        IN     VARCHAR2,
   i_bin_desc        IN     VARCHAR2,   
   i_remark         IN     VARCHAR2,
   i_test_length    IN     VARCHAR2,
   o_flag              OUT VARCHAR2,
   o_res               OUT VARCHAR2)
AS
   v_sn              VARCHAR2 (25);
   v_result          VARCHAR2 (25);

   v_count           NUMBER;         
   v_line            VARCHAR2 (25);
   v_section         VARCHAR2 (25);
   v_mygroup         VARCHAR2 (25);
   v_mystation         VARCHAR2 (25);
   v_mo              VARCHAR2 (25);
   v_model           VARCHAR2 (25);
   v_current_line    VARCHAR2 (25);
   v_current_group   VARCHAR2 (25);
   v_res             VARCHAR2 (25);
   SRES              VARCHAR2(100);--CZ 20220425

BEGIN             
   -- add by Liujiang in 20201123  for Mellanox PLMS auto logging

  ---------------------------------------


   v_sn := UPPER (i_sn);
   v_result := UPPER (i_result);
   o_flag := '-1';
   --o_res := 'STATION_CODE NOT EXIST';

   SELECT COUNT (1)
     INTO v_count
     FROM SFIS1.C_STATION_MAPPING_T             -- C_STATION_CUST_T -->> C_STATION_MAPPING_T  20201229
    WHERE STATION_NV = i_station_code;        --客？提供，暫由IT添加

   IF v_count < 1
   THEN
      o_flag := '-1';
      --o_res := 'Station_code:' || i_station_code || ' NOT EXIST';
      o_res := 'ERROR - unfamiliar station code';
      RETURN;
   END IF;   

   SELECT  SECTION_NAME, GROUP_NAME, STATION_SFC
     INTO  v_section, v_mygroup, v_mystation
     FROM SFIS1.C_STATION_MAPPING_T
    WHERE STATION_NV = i_station_code and rownum =1;


   SELECT COUNT (1)
     INTO v_count
     FROM SFISM4.R_WIP_TRACKING_T
    WHERE SERIAL_NUMBER = v_sn ;

   IF v_count < 1
   THEN
      o_flag := '-1';
      --o_res := 'SN:' || v_sn || ' NOT EXIST';
      o_res := 'ERROR - SN not found';
      RETURN;
   END IF;

   SELECT MO_NUMBER,
          MODEL_NAME,
          LINE_NAME,
          GROUP_NAME
     INTO v_mo,
          v_model,
          v_current_line,
          v_current_group
     FROM SFISM4.R_WIP_TRACKING_T
    WHERE SERIAL_NUMBER = v_sn;


   SELECT COUNT (1)
     INTO v_count
     FROM SFISM4.R_MO_BASE_T
    WHERE MO_NUMBER = v_mo AND (CLOSE_FLAG = '1' OR CLOSE_FLAG = '2');

   IF v_count < 1
   THEN
      o_flag := '-1';
      o_res :=
            'SN:'
         || v_sn
         || ' MO:'
         || v_mo
         || ' has be closed';
      RETURN;
   END IF;


   SFIS1.CHECK_ROUTE (v_current_line,
                      v_mygroup,
                      v_sn,
                      v_res);

   IF v_res <> 'OK'
   THEN
      o_flag := '-1';
      o_res := v_res;
      RETURN;
   END IF;

    sfis1.CHECK_STOP(v_sn,v_mygroup,v_res);--20220425  CZ add
    IF v_res <> 'OK'
    THEN
      o_flag := '-1';
      o_res := v_res;
      RETURN;
    END IF;--20220425  CZ add stop line yes or no


   IF (v_result <> 'PASS' AND v_result <> 'FAIL')
   THEN
      o_flag := '-1';
      o_res := 'Test result <'||v_result||'> not defined';    
      RETURN;
   END IF;


    INSERT INTO SFISM4.R_TEST_RESULT_PLMS (serial_number,
                                           mo_number,
                                           model_name,
                                           group_name,
                                           customer_code,
                                           station_id,
                                           host_name,
                                           result,
                                           error_code,
                                           bin_number,
                                           bin_description,
                                           remarks,
                                           test_duration,
                                           tester,
                                           create_date)
         VALUES ( v_sn,
                 v_mo,
                 v_model,
                 v_mygroup,
                 i_cust_code,
                 i_station_code,
                 i_host_name,
                 v_result,
                 '',
                 i_bin_number,
                 i_bin_desc,
                 i_remark,
                 i_test_length,
                 i_user,
                 sysdate);


   IF v_result = 'PASS'
   THEN
      o_res := 'Update tracking info error';
      UPDATE SFISM4.R_WIP_TRACKING_T
         SET LINE_NAME = v_current_line,
             SECTION_NAME = v_section,
             GROUP_NAME = v_mygroup,
             STATION_NAME = v_mystation,
             ERROR_FLAG = 0,
             IN_STATION_TIME = SYSDATE,
             NEXT_STATION = 'N/A',
             EMP_NO = i_user
       WHERE SERIAL_NUMBER = v_sn;

      -- UPDATE_R105(v_mygroup,v_mo);  --更新工令 投入 產出數量， 做完則關閉工令， 如果不需要，後續可屏蔽

      o_flag := '0';
      o_res := 'OK';
      RETURN;
   ELSIF v_result = 'FAIL'
   THEN
        o_res := 'Insert repair info error';       
        INSERT INTO SFISM4.R_REPAIR_T (SERIAL_NUMBER,
                                          MO_NUMBER,
                                          MODEL_NAME,
                                          TEST_TIME,
                                          TEST_CODE,
                                          TEST_STATION,
                                          TEST_LINE,
                                          TESTER,
                                          RECORD_TYPE,
                                          MACHINE
                                         )
                VALUES (v_sn,
                        v_mo,
                        v_model,                        
                        SYSDATE,
                        i_bin_number,       --lin  shi  , zan  wei  ding
                        v_mygroup,
                        -- v_mystation,
                        v_current_line,
                        i_user,
                        'F',
                        i_host_name
                       ); 

      o_res := 'Update tracking info error';
      UPDATE SFISM4.R_WIP_TRACKING_T
         SET LINE_NAME = v_current_line,
             SECTION_NAME = v_section,
             GROUP_NAME = v_mygroup,
             STATION_NAME = v_mystation,
             ERROR_FLAG = 1,
             IN_STATION_TIME = SYSDATE,
             NEXT_STATION = 'N/A',
             EMP_NO = i_user
       WHERE SERIAL_NUMBER = v_sn;

       COMMIT;
       SFIS1.stop_line(v_sn,v_mygroup,SRES);--CZ 20220425 STOP OR NOT STOP LINE

      o_flag := '0';
      o_res := 'OK';
      RETURN;

   END IF;

EXCEPTION
   WHEN OTHERS
   THEN
      o_flag := '-1';
      o_res := o_res;
END;