PROCEDURE             CHECK_LINKS_INFO_T 
--Added by wenliang lei for TICKET S0000017R2 ?LINK ？棒摯眕奻ㄛ
--？笢嶲腔OLD_SN腔陓洘滖緻init_snㄛ旌轎？?？梑祥善窒煦陓洘
--?湔？蚕BARCODE LINK 捼蚚
                                                     (DATA   IN     VARCHAR2,
                                                      res       OUT VARCHAR2)
AS
   TEMP_COUNT   NUMBER;
   TEMP_COUNT1  NUMBER;
   C_OLD_SN_1   VARCHAR2 (32);
   C_OLD_SN_2   VARCHAR2 (32);
   C_INIT_SN    VARCHAR2 (32);
BEGIN
   RES := 'OK';

   SELECT COUNT (*)
     INTO TEMP_COUNT
     FROM sfism4.r_sn_link_t
    WHERE NEW_SN = DATA;

   IF TEMP_COUNT < 1
   THEN
      RETURN;
   END IF;

   SELECT OLD_SN, INIT_SN
     INTO C_OLD_SN_1, C_INIT_SN
     FROM SFISM4.R_SN_LINK_T
    WHERE NEW_SN = DATA;

   SELECT COUNT (*)
     INTO TEMP_COUNT
     FROM SFISM4.R_SN_LINK_T
    WHERE INIT_SN = C_INIT_SN;

   IF TEMP_COUNT < 3
   THEN
      RETURN;
   END IF;


   SELECT OLD_SN
     INTO C_OLD_SN_2
     FROM SFISM4.R_SN_LINK_T
    WHERE NEW_SN = C_OLD_SN_1 AND ROWNUM = 1;

   --陂？PCB陓洘
   SELECT COUNT (*)
     INTO TEMP_COUNT
     FROM sfism4.r_pcb_datecode_t
    WHERE serial_number = C_OLD_SN_2;

   IF TEMP_COUNT > 0
   THEN
      INSERT INTO sfism4.r_pcb_datecode_t (PKG_ID,
                                           SERIAL_NUMBER,
                                           LINE_NAME,
                                           IN_STATION_TIME,
                                           ERROR_CODE,
                                           INPUT_FLAG)
         SELECT PKG_ID,
                C_INIT_SN,
                LINE_NAME,
                IN_STATION_TIME,
                ERROR_CODE,
                INPUT_FLAG
           FROM sfism4.r_pcb_datecode_t
          WHERE serial_number = C_OLD_SN_2;
   END IF;

   --陂？MEN陓洘
   SELECT COUNT (*)
     INTO TEMP_COUNT
     FROM SMTINFO.R_SN_PKG_DETAIL_T C, IQC.R_KPN_INCOMING_T D
    WHERE     C.SERIAL_NUMBER = C_OLD_SN_2
          AND C.PKG_ID = D.PKG_ID
          AND D.HH_PN LIKE '161%'
          AND ROWNUM = 1;

   IF TEMP_COUNT > 0
   THEN
      INSERT INTO SMTINFO.R_SN_PKG_DETAIL_T (SERIAL_NUMBER,
                                             FEEDER_NUMBER,
                                             PKG_ID,
                                             MACHINE_CODE,
                                             IN_STATION_TIME,
                                             SECTION_NAME)
         SELECT C_INIT_SN,
                C.FEEDER_NUMBER,
                C.PKG_ID,
                C.MACHINE_CODE,
                C.IN_STATION_TIME,
                C.SECTION_NAME
           FROM SMTINFO.R_SN_PKG_DETAIL_T C, IQC.R_KPN_INCOMING_T D
          WHERE     C.SERIAL_NUMBER = C_OLD_SN_2
                AND C.PKG_ID = D.PKG_ID
                AND D.HH_PN LIKE '161%';
   END IF;

   --陂？BIOS陓洘
   SELECT COUNT (*)
     INTO TEMP_COUNT
     FROM SFISM4.R_NVBIOS_MODEL_T
    WHERE SERIAL_NUMBER = C_OLD_SN_2;

   IF TEMP_COUNT > 0
   THEN
      SELECT COUNT (*)
        INTO TEMP_COUNT1
        FROM SFISM4.R_NVBIOS_MODEL_T
       WHERE SERIAL_NUMBER = C_INIT_SN;

      IF TEMP_COUNT1 > 0
      THEN
         UPDATE SFISM4.R_NVBIOS_MODEL_T
            SET SERIAL_NUMBER = '`' || SERIAL_NUMBER
          WHERE SERIAL_NUMBER = C_INIT_SN;
      END IF;

      INSERT INTO SFISM4.R_NVBIOS_MODEL_T (SERIAL_NUMBER,
                                           INIT_MODEL_NAME,
                                           FIRST_BIOS,
                                           SECOND_BIOS,
                                           LAST_MODEL_NAME,
                                           DATETIME,
                                           FLAG,
                                           GROUP_NAME)
         SELECT C_INIT_SN,
                INIT_MODEL_NAME,
                FIRST_BIOS,
                SECOND_BIOS,
                LAST_MODEL_NAME,
                DATETIME,
                FLAG,
                GROUP_NAME
           FROM SFISM4.R_NVBIOS_MODEL_T
          WHERE SERIAL_NUMBER = C_OLD_SN_2;
   END IF;
   
   COMMIT;
   
EXCEPTION
   WHEN OTHERS
   THEN
      RES := SUBSTR (SQLERRM, 1, 100);
END;