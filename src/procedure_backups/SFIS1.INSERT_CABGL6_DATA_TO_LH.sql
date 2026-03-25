PROCEDURE                                     insert_cabgl6_data_to_lh
AS
   v_sn        VARCHAR2 (100);
   v_group     VARCHAR2 (100);
   v_mo        VARCHAR2 (100);
   res          VARCHAR2 (100);
   v_count     INTEGER;
   v_count1    INTEGER;
   last_date   DATE;
   curr_date   DATE;

   CURSOR sapwo
   IS
      SELECT MO_NO
        FROM KITTING.M_MO_T@L6
       WHERE C_DATE >= last_date;

   CURSOR sfcwo
   IS
      SELECT MO_NUMBER
        FROM sfism4.r_mo_base_t@L6
       WHERE MO_CREATE_DATE >= last_date AND mo_type = 'NORMAL';

   CURSOR sn_detail
   IS
      SELECT serial_number, group_name, in_station_time
        FROM sfism4.r_sn_detail_t@L6
       WHERE in_station_time >= last_date AND mo_number = v_mo;
BEGIN
   last_date := SYSDATE - 1;
   curr_date := SYSDATE-0.004;

   SELECT COUNT (1)
     INTO v_count
     FROM sfis1.C_PARAMETER_INI
    WHERE     PRG_NAME = 'COPY_DATA'
          AND VR_CLASS = 'CABG L6'
          AND VR_ITEM = 'CABG L6'
          AND VR_NAME = 'CABG L6';

   IF v_count > 0
   THEN
      SELECT CREATE_DATE
        INTO last_date
        FROM sfis1.C_PARAMETER_INI
       WHERE     PRG_NAME = 'COPY_DATA'
             AND VR_CLASS = 'CABG L6'
             AND VR_ITEM = 'CABG L6'
             AND VR_NAME = 'CABG L6'
             AND ROWNUM = 1;
   ELSE
      INSERT INTO sfis1.C_PARAMETER_INI (PRG_NAME,
                                         VR_CLASS,
                                         VR_ITEM,
                                         VR_NAME,
                                         CUST_NO,
                                         CREATE_DATE)
           VALUES ('COPY_DATA',
                   'CABG L6',
                   'CABG L6',
                   'CABG L6',
                   'CABG L6',
                   last_date);
   END IF;

   res := 'get sap wo error ';

   FOR temp IN sapwo
   LOOP
      DELETE sfism4.WIP_D_WO_MASTER
       WHERE WORK_ORDER = temp.MO_NO;

      INSERT INTO sfism4.WIP_D_WO_MASTER (WORK_ORDER,
                                               PART_NO,
                                               QTY,                                               
                                               CPO_TYPE,                                               
                                               WO_STATUS, 
                                               PART_VERSION,
                                               CREATOR,
                                               CREATE_DATE, 
                                               PLANT_CODE,
                                               SAP_CREATE_DATE,
                                               SAP_WO_STATUS,
                                               BU)
         SELECT MO_NO,
                P_GNO,
                NUM,
                PC,
                STATE,
                'N/A'
                USER1,
                C_DATE,
                PLANT_CODE,
                SAP_CREATE_DATE,
                SAP_WO_STATUS,
                'CABG L6'
           FROM KITTING.M_MO_T@L6
          WHERE MO_NO = temp.MO_NO;
   END LOOP;

   res := 'get sfc wo error ';

   FOR temp IN sfcwo
   LOOP
      v_mo := temp.mo_number;

      DELETE sfism4.R_MO_BASE_T
       WHERE mo_number = v_mo;

      INSERT INTO sfism4.R_MO_BASE_T (MO_NUMBER,
                                         MO_TYPE,
                                         MODEL_NAME,
                                         VERSION_CODE,
                                         TARGET_QTY,
                                         MO_CREATE_DATE,
                                         MO_SCHEDULE_DATE,
                                         MO_DUE_DATE,
                                         MO_START_DATE,
                                         MO_TARGET_DATE,
                                         MO_CLOSE_DATE,
                                         ROUTE_CODE,
                                         INPUT_QTY,
                                         OUTPUT_QTY,
                                         TURN_OUT_QTY,
                                         TOTAL_SCRAP_QTY,
                                         START_SN,
                                         END_SN,
                                         SHIPPING_START_SN,
                                         SHIPPING_QTY,
                                         WORK_FLAG,
                                         CLOSE_FLAG,
                                         DEFAULT_LINE,
                                         DEFAULT_GROUP,
                                         ORDER_NO,
                                         BOM_NO,
                                         MASTER_FLAG,
                                         MASTER_MO,
                                         END_GROUP,
                                         PO_NO,
                                         UPC_CO,
                                         KEY_PART_NO,
                                         SN_RULE,
                                         REWORK_QTY,
                                         MO_OPTION,                                         
                                         CUST_NO,
                                         BU)
         SELECT MO_NUMBER,
                MO_TYPE,
                MODEL_NAME,
                VERSION_CODE,
                TARGET_QTY,
                MO_CREATE_DATE,
                MO_SCHEDULE_DATE,
                MO_DUE_DATE,
                MO_START_DATE,
                MO_TARGET_DATE,
                MO_CLOSE_DATE,
                ROUTE_CODE,
                INPUT_QTY,
                OUTPUT_QTY,
                TURN_OUT_QTY,
                TOTAL_SCRAP_QTY,
                START_SN,
                END_SN,
                SHIPPING_START_SN,
                SHIPPING_QTY,
                WORK_FLAG,
                CLOSE_FLAG,
                DEFAULT_LINE,
                DEFAULT_GROUP,                
                ORDER_NO,
                BOM_NO,
                MASTER_FLAG,
                MASTER_MO,
                END_GROUP,
                PO_NO,  
                UPC_CO,
                KEY_PART_NO,
                SN_RULE,
                REWORK_QTY,
                MO_OPTION,
                CUST_CODE,  
                'CABG L6'
           FROM sfism4.R_MO_BASE_T@L6
          WHERE mo_number = v_mo;

      res := 'get sn_detail error ';

      FOR sn IN sn_detail
      LOOP
         SELECT COUNT (1)
           INTO v_count
           FROM sfism4.r_sn_detail_t@L6
          WHERE     serial_number = sn.serial_number
                AND group_name = sn.group_name
                AND in_station_time < sn.in_station_time;

         SELECT COUNT (1)
           INTO v_count1
           FROM sfism4.r_sn_detail_t
          WHERE serial_number = sn.serial_number
                AND group_name = sn.group_name;

         IF (v_count = 0) AND (v_count1 = 0)
         THEN
            INSERT INTO sfism4.r_sn_detail_t (SERIAL_NUMBER,
                                                 SECTION_FLAG,
                                                 MO_NUMBER,
                                                 MODEL_NAME,
                                                 TYPE,
                                                 VERSION_CODE,
                                                 LINE_NAME,
                                                 SECTION_NAME,
                                                 GROUP_NAME,
                                                 STATION_NAME,
                                                 LOCATION,
                                                 STATION_SEQ,
                                                 ERROR_FLAG,
                                                 IN_STATION_TIME,
                                                 IN_LINE_TIME,
                                                 OUT_LINE_TIME,
                                                 SHIPPING_SN,
                                                 WORK_FLAG,
                                                 FINISH_FLAG,
                                                 ENC_CNT,
                                                 SPECIAL_ROUTE,
                                                 PALLET_NO,
                                                 CONTAINER_NO,
                                                 QA_NO,
                                                 QA_RESULT,
                                                 SCRAP_FLAG,
                                                 NEXT_STATION,
                                                 WORK_DATE,
                                                 WORK_SECTION,
                                                 PASS_QTY,
                                                 FAIL_QTY,
                                                 REPASS_QTY,
                                                 REFAIL_QTY,
                                                 ECN_PASS_QTY,
                                                 ECN_FAIL_QTY,
                                                 KEY_PART_NO,
                                                 CARTON_NO,
                                                 WARRANTY_DATE,
                                                 BOM_NO,
                                                 PO_NO,
                                                 REWORK_NO,
                                                 EMP_NO,
                                                 CUST_NO,                                                 
                                                 BU)
               SELECT SERIAL_NUMBER,
                        SECTION_FLAG,
                        MO_NUMBER,
                        MODEL_NAME,
                        TYPE,
                        VERSION_CODE,
                        LINE_NAME,
                        SECTION_NAME,
                        GROUP_NAME,
                        STATION_NAME,
                        LOCATION,
                        STATION_SEQ,
                        ERROR_FLAG,
                        IN_STATION_TIME,
                        IN_LINE_TIME,
                        OUT_LINE_TIME,
                        SHIPPING_SN,
                        WORK_FLAG,
                        FINISH_FLAG,
                        ENC_CNT,
                        SPECIAL_ROUTE,
                        PALLET_NO,
                        CONTAINER_NO,
                        QA_NO,
                        QA_RESULT,
                        SCRAP_FLAG,
                        NEXT_STATION,                    
                        WORK_DATE,
                        WORK_SECTION,
                        PASS_QTY,
                        FAIL_QTY,
                        REPASS_QTY,
                        REFAIL_QTY,
                        ECN_PASS_QTY,
                        ECN_FAIL_QTY,
                        KEY_PART_NO,
                        CARTON_NO,
                        WARRANTY_DATE,
                        BOM_NO,
                        PO_NO,
                        REWORK_NO,
                        EMP_NO,
                        CUSTOMER_NO,
                      'CABG L6'
                 FROM sfism4.r_sn_detail_t@L6
                WHERE     serial_number = sn.serial_number
                      AND group_name = sn.group_name
                      AND in_station_time = sn.in_station_time;
         END IF;
      END LOOP;
   END LOOP;

    res := 'OK,tranfer data successfully';

   UPDATE sfis1.C_PARAMETER_INI
      SET CREATE_DATE = curr_date,VR_DESC = res
    WHERE     PRG_NAME = 'COPY_DATA'
          AND VR_CLASS = 'CABG L6'
          AND VR_ITEM = 'CABG L6'
          AND VR_NAME = 'CABG L6';

   COMMIT;
EXCEPTION
   WHEN OTHERS
   THEN
      UPDATE sfis1.C_PARAMETER_INI
         SET VR_DESC = res
       WHERE     PRG_NAME = 'COPY_DATA'
             AND VR_CLASS = 'CABG L6'
             AND VR_ITEM = 'CABG L6'
             AND VR_NAME = 'CABG L6';
END;