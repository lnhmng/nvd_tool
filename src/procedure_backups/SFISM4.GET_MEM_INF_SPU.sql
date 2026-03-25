PROCEDURE                             GET_MEM_INF_SPU --Added by Alex Wang on 010/03/03 for 1HWT-100226-01 Begin
                                               (BARCODE   IN     VARCHAR2,
                                                o_flag         OUT      VARCHAR2,
                                                RES          OUT VARCHAR2)
AS
   p_MARKET_NAME     VARCHAR2 (25);
   p_MEM_VENDOR_ID   VARCHAR2 (25);            --isn't be used,fix it with '0'
   p_MEM_PART_ID     VARCHAR2 (25);
   p_MEM_DC          VARCHAR2 (100);

   p_BARCODE         VARCHAR2 (25);
   P_OLDSN           VARCHAR2 (25);
   p_DC_TEMP         VARCHAR2 (25);

   bom_rev           VARCHAR2 (20);
   bom_mo            VARCHAR2 (20);  --add  by  ly   202005/08
   pbr               VARCHAR2 (20);

   MKTCNT            NUMBER (2, 0);
   MET_EXITCNT       NUMBER (2, 0);
   MEMCNT            NUMBER (2, 0);
   MEMCNT1           NUMBER (2, 0);
   MEMCNT2           NUMBER (2, 0);
   SNCNT             NUMBER (2, 0);
   HH_PN_CNT         NUMBER (2, 0);
   SDTIME            VARCHAR2 (25);

   e_NULL            EXCEPTION;

   CURSOR GET_DC
   IS
      SELECT DISTINCT D.DATE_CODE
        FROM SMTINFO.R_SN_PKG_DETAIL_T C, IQC.R_KPN_INCOMING_T D
       WHERE     C.SERIAL_NUMBER = p_BARCODE
             AND C.PKG_ID = D.PKG_ID
             AND D.HH_PN LIKE '161%';
BEGIN
   o_flag := '-1'; 
   p_MEM_VENDOR_ID := '0';

   -- P_OLDSN :='0';

   SELECT COUNT (*)
     INTO SNCNT
     FROM SFISM4.R_SN_LINK_T
    WHERE NEW_SN = BARCODE;

   IF SNCNT = 0
   THEN                                           --The SN haven't been linked
      p_BARCODE := BARCODE;
   ELSE                                              --The SN have been linked
      SELECT INIT_SN, OLD_SN
        INTO p_BARCODE, P_OLDSN
        FROM SFISM4.R_SN_LINK_T
       WHERE NEW_SN = BARCODE AND ROWNUM = 1;
   END IF;



   SELECT COUNT (*)
     INTO MEMCNT
     FROM SMTINFO.R_SN_PKG_DETAIL_T C, IQC.R_KPN_INCOMING_T D
    WHERE     C.SERIAL_NUMBER = p_BARCODE
          AND C.PKG_ID = D.PKG_ID
          AND D.HH_PN LIKE '161%';


   IF MEMCNT = 0
   THEN
      IF SNCNT > 0
      THEN
         SELECT COUNT (*)
           INTO MEMCNT1
           FROM SMTINFO.R_SN_PKG_DETAIL_T C, IQC.R_KPN_INCOMING_T D
          WHERE     C.SERIAL_NUMBER = BARCODE
                AND C.PKG_ID = D.PKG_ID
                AND D.HH_PN LIKE '161%';

         IF MEMCNT1 = 0
         THEN
            SELECT COUNT (*)
              INTO MEMCNT2
              FROM SMTINFO.R_SN_PKG_DETAIL_T C, IQC.R_KPN_INCOMING_T D
             WHERE     C.SERIAL_NUMBER = P_OLDSN
                   AND C.PKG_ID = D.PKG_ID
                   AND D.HH_PN LIKE '161%';

            IF MEMCNT2 = 0
            THEN
                p_MEM_PART_ID:= '0';
               --RES := 'ERROR1:NO MEMORY(INFORMATION) EXIST!' || '\n' || '**END**';
              -- RAISE e_NULL;
            ELSE
               p_BARCODE := P_OLDSN;
            END IF;
         ELSE
            p_BARCODE := BARCODE;
         END IF;
      ELSE
         p_MEM_PART_ID:= '0';
         --RES := 'NO MEMORY(INFORMATION) EXIST!' || '\n' || '**END**';
         --RAISE e_NULL;
      END IF;
   END IF;

   -- get MARKET NAMe begin--
   SELECT COUNT (*)
     INTO MET_EXITCNT
     FROM SFISM4.R_WIP_TRACKING_T A, SFIS1.C_NV_MODESC_T B
    WHERE   --    A.SERIAL_NUMBER = p_BARCODE
             A.SERIAL_NUMBER = BARCODE -- Modefied By Derrick Chow 2013-05-15
          AND A.MODEL_NAME = B.L600_690_PN;

   IF MET_EXITCNT = 0
   THEN
      RES := 'NO MARKET NAME EXIST!' || '\n' || '**END**';
      RAISE e_NULL;
   END IF;

   SELECT COUNT (*)
     INTO MKTCNT
     FROM SFISM4.R_WIP_TRACKING_T A, SFIS1.C_NV_MODESC_T B
    WHERE    -- A.SERIAL_NUMBER = p_BARCODE
           A.SERIAL_NUMBER = BARCODE -- Modefied By Derrick Chow 2013-05-15
          AND A.MODEL_NAME = B.L600_690_PN
          AND B.PRODUCT_DESC <> 'N/A';

   IF MKTCNT = 0
   THEN
      p_MARKET_NAME := '(NULL)';
   ELSE
      SELECT B.PRODUCT_DESC
        INTO p_MARKET_NAME
        FROM SFISM4.R_WIP_TRACKING_T A, SFIS1.C_NV_MODESC_T B
       WHERE   --  A.SERIAL_NUMBER = p_BARCODE
            A.SERIAL_NUMBER = BARCODE -- Modefied By Derrick Chow 2013-05-15
             AND A.MODEL_NAME = B.L600_690_PN
             AND B.PRODUCT_DESC <> 'N/A'
             AND ROWNUM = 1;
   END IF;

-- get MARKET name end--

  select count(*)  -------ADD START BY ZC S000003TE5
   into HH_PN_CNT
    FROM SMTINFO.R_SN_PKG_DETAIL_T C, IQC.R_KPN_INCOMING_T D
    WHERE     C.SERIAL_NUMBER = p_BARCODE
          AND C.PKG_ID = D.PKG_ID
          AND D.HH_PN LIKE '161%'
          AND ROWNUM = 1;
  IF
      HH_PN_CNT = 0
   THEN p_MEM_PART_ID:= '0';
    ELSE
   SELECT D.HH_PN
     INTO p_MEM_PART_ID
     FROM SMTINFO.R_SN_PKG_DETAIL_T C, IQC.R_KPN_INCOMING_T D
    WHERE     C.SERIAL_NUMBER = p_BARCODE
          AND C.PKG_ID = D.PKG_ID
          AND D.HH_PN LIKE '161%'
          AND ROWNUM = 1;
  END IF;        -------ADD END BY ZC S000003TE5*/


   OPEN GET_DC;

   LOOP
      FETCH GET_DC INTO p_DC_TEMP;

      EXIT WHEN GET_DC%NOTFOUND;

      p_MEM_DC := p_MEM_DC || ',' || p_DC_TEMP;


   END LOOP;

   CLOSE GET_DC;

      IF p_MEM_DC IS NULL
       THEN p_MEM_DC :='0';
       END IF;
   ----------- add by Derrick 2012-05-07 begin-----
   SELECT TO_CHAR (in_station_time, 'YYYYMMDD')
     INTO SDTIME
     FROM SFISM4.R_PCB_DATECODE_T
    WHERE SERIAL_NUMBER = p_BARCODE;

   --AND GROUP_NAME = 'PCB_OPEN';
   ----------- add by Derrick 2012-05-07 end-----
   if (substr(barcode,0,3)='133') or (substr(barcode,0,3)='033')
   then 
   SELECT po_no
     INTO pbr
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = barcode;
   end if;


-- update  ly  20200508
   SELECT mo_number into bom_mo
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = barcode;

   select  SUBSTR (key_part_no,20)
     INTO bom_rev from SFISM4.R_MO_BASE_T 
     where mo_number=bom_mo;

-- update  ly  20200508
   res :=
         barcode
      || '\n'
      || p_market_name
      || '\n'
      || p_mem_vendor_id
      || '\n'
      || p_mem_part_id
      || '\n'
      || p_mem_dc
      || '\n'
      || sdtime
      || '\n'
      || bom_rev
      || '\n'
      || pbr
      || '\n'
      || '**END**';
   o_flag := '0'; 
EXCEPTION
   WHEN e_NULL
   THEN
      NULL;
   WHEN OTHERS
   THEN
      RES := 'OTHER ERROR!' || '\n' || '**END**';
END;