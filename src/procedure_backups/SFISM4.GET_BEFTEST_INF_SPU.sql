PROCEDURE                                    GET_BEFTEST_INF_SPU (
   BARCODE   IN     VARCHAR2,
   o_flag         OUT      VARCHAR2,   
   RES          OUT VARCHAR2)
AS
   p_MARKET_NAME   VARCHAR2 (25);
   v_stationname   VARCHAR2 (25);
   v_modelname     VARCHAR2 (25);
   ressnout        VARCHAR2 (32);
   resrouteout     VARCHAR2 (48);
   resstationout   VARCHAR2 (32);
   resmodelout     VARCHAR2 (25);
   v_699PN         VARCHAR2 (30);
   v_PO            VARCHAR2 (30);      --Added "PO_NO" by Felix 2016-12-09
   v_SAMPLESNINFO  VARCHAR2 (100);     --Added SAMPLESNINFO BY LLF 2017-05-20
   v_count         NUMBER;             --Added SAMPLESNINFO BY LLF 2017-05-20
   v_count2        NUMBER;
   v_count3        NUMBER;
   v_count4        NUMBER;
   v_bios          VARCHAR2 (50); --add by flying 2018/02/01 
   INITSN          VARCHAR2 (25);  
   VENDOR_SN          VARCHAR2 (80); 
   VENDOR_INFO        VARCHAR2 (80); 
   V_TIME          NUMBER;
   SN              VARCHAR2 (100);
   NEWSN           VARCHAR2 (25);
   v_MAXDATE       DATE;
   v_heatsink     VARCHAR2 (150);
   HsInfo     VARCHAR2 (150);
   --SN1             VARCHAR2 (25); --add by flying 2018/02/01
   --SN2             VARCHAR2 (25); --add by flying 2018/02/01

   e_NULL          EXCEPTION;
   e_699error      EXCEPTION;
BEGIN
   o_flag := '-1';
   ------------ Check sn-------------------
   SFIS1.CHECK_SN (TRIM (BARCODE), ressnout);

   IF ressnout <> 'OK'
   THEN
      RES := ressnout;
      RAISE e_NULL;
   END IF;

   ------------ check the route ---------
   SFIS1.SP_TEST_CHECK_ROUTE('N/A',
                       'N/A',
                       TRIM (BARCODE),
                       resrouteout);

   ----------- get the P/N---------------
   SELECT model_name
     INTO v_modelname
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = TRIM (BARCODE);

   --Added "PO_NO" by Felix 2016-12-09
   --ADDED BY GJ FOR 2ZY5 AT TJ 20150410 BEGIN
   SELECT A.KEY_PART_NO,B.PO_NO 
     INTO v_699PN,v_PO
     FROM SFISM4.R_MO_BASE_T A, SFISM4.R_WIP_TRACKING_T B
    WHERE A.MO_NUMBER = B.MO_NUMBER AND B.SERIAL_NUMBER = BARCODE AND ROWNUM = 1;

   --v_699PN := NVL(v_699PN,'');
   IF LENGTH (v_699PN) = 0
   THEN
      RAISE e_699error;
   END IF;

   v_PO := NVL(v_PO,'0');

   --ADDED BY GJ FOR 2ZY5 AT TJ 20150410 END
   resmodelout := v_modelname;

   SELECT count(*) into  v_count FROM SFIS1.C_SAMPLESN_BIND_SET WHERE PARENTPARTNO= v_modelname;

   if v_count>0 then
        SELECT count(*) into  v_count FROM SFISM4.R_SAMPLESN_BIND_DETAIL WHERE P_SN=BARCODE AND FLAG='1';
        IF v_count>0 THEN
            select replace(wm_concat(c_pn||':'||c_sn||':'||c_qty),',',';') into v_SAMPLESNINFO from
            (select * from 
            (SELECT p_sn,c_pn,c_sn  FROM SFISM4.R_SAMPLESN_BIND_DETAIL WHERE P_SN=BARCODE AND FLAG='1' )a
            left join  sfism4.R_SAMPLESN_BIND_QTY b on a.c_sn=b.sn order by a.c_pn);
        ELSE
            v_SAMPLESNINFO:='F';  
        END IF;
   ELSE
       v_SAMPLESNINFO:='N';  
   end if;



   SELECT COUNT (serial_number)
     INTO v_count
     FROM sfism4.r_nvbios_model_t
    WHERE serial_number = BARCODE;

        IF v_count=0 THEN
           SELECT COUNT (*)
            INTO v_count3
            FROM sfism4.r_sn_link_t
           WHERE new_sn = BARCODE;

          IF v_count3 > 0 THEN

           SELECT init_sn
            INTO INITSN
            FROM sfism4.r_sn_link_t
           WHERE new_sn = BARCODE;

           SELECT COUNT(*) INTO v_count4
                          FROM   SFISM4.R_NVBIOS_MODEL_T A,SFISM4.R_SN_LINK_T B
                          WHERE  A.SERIAL_NUMBER = B.OLD_SN AND B.INIT_SN = INITSN;
               IF v_count4 <= 0 THEN
                 V_BIOS:='N/A';
               ELSE
                 SELECT MAX(A.DATETIME) INTO v_MAXDATE
                 FROM SFISM4.R_NVBIOS_MODEL_T A,SFISM4.R_SN_LINK_T B
                 WHERE A.SERIAL_NUMBER = B.OLD_SN AND B.INIT_SN = INITSN;

                 SELECT NVL(A.SECOND_BIOS,A.FIRST_BIOS )INTO V_BIOS         
                 FROM SFISM4.R_NVBIOS_MODEL_T A,SFISM4.R_SN_LINK_T B
                 WHERE A.SERIAL_NUMBER = B.OLD_SN AND B.INIT_SN = INITSN AND A.DATETIME = v_MAXDATE ;

                END IF;

          ELSE
           V_BIOS:='N/A';
          END IF;

        ELSIF v_count>0 THEN 

            SELECT NVL(SECOND_BIOS,FIRST_BIOS )INTO V_BIOS 
            FROM sfism4.r_nvbios_model_t
            WHERE serial_number = BARCODE;

        END IF;
   ------------get bios end---------------

   -----------get link_sn start--------------
       SELECT COUNT(OLD_SN) INTO V_COUNT FROM SFISM4.R_SN_LINK_T
       WHERE NEW_SN=TRIM (BARCODE);

       IF V_COUNT>0 THEN


          SELECT INIT_SN,TIMES INTO INITSN,V_TIME FROM SFISM4.R_SN_LINK_T
          WHERE NEW_SN=TRIM (BARCODE) --AND NEWEST_SN_FLAG='T'
           AND ROWNUM=1;

          SN:=INITSN;

          FOR I IN 1..V_TIME LOOP

              SELECT COUNT(*) INTO V_COUNT2  FROM SFISM4.R_SN_LINK_T
              WHERE INIT_SN=INITSN AND TIMES=I AND ROWNUM=1;

              IF V_COUNT2>0 THEN

                SELECT NEW_SN INTO NEWSN  FROM SFISM4.R_SN_LINK_T
                WHERE INIT_SN=INITSN AND TIMES=I AND ROWNUM=1;
                SN:=SN||','||NEWSN;

              END IF;

          END LOOP;



       ELSE
          SN:='N/A';  
       END IF;
    ------------get link_sn end--------------- 

    ------ADD TZS-get link_sn 2D start 20210916--------------

       SELECT COUNT(SERIAL_NUMBER) INTO V_COUNT FROM SFISM4.R_SN_VENDOR_INFO
       WHERE SERIAL_NUMBER=TRIM (BARCODE);

       IF V_COUNT>0 THEN


          SELECT VENDOR_INFO INTO VENDOR_SN FROM SFISM4.R_SN_VENDOR_INFO
          WHERE SERIAL_NUMBER=TRIM (BARCODE) 
           AND ROWNUM=1;

          VENDOR_INFO:=VENDOR_SN;         

       ELSE
          VENDOR_INFO:='N/A'; 

       END IF;

     ------ADD TZS-get link_sn 2D END 20210916--------------

     ----ADD LSC get heatsink fro te  S0000X656-------
     select count(*) INTO V_COUNT from sfism4.r_wip_binding_sn_t where skuno like '110%'  AND  BINDING_SN=TRIM (BARCODE);
     IF  V_COUNT>0 THEN
        select KP_SN INTO v_heatsink from sfism4.r_wip_binding_sn_t where skuno like '110%'  AND  BINDING_SN=TRIM (BARCODE) AND ROWNUM=1; 

        HsInfo:=v_heatsink;
    ELSE
         HsInfo:='N/A';
    END IF;
    ----ADD LSC get heatsink fro te  S0000X656-------


 --  RES := resrouteout || '\n' || resmodelout || '\n' || v_699PN || '\n' || v_PO || '\n' || v_SAMPLESNINFO||'\n'||v_bios||'\n'||SN;

   RES := BARCODE || '\n' || resrouteout || '\n' || resmodelout || '\n' || v_699PN || '\n' || v_PO || '\n' || v_SAMPLESNINFO||'\n'||v_bios||'\n'||SN||'\n'||VENDOR_INFO||'\n'|| HsInfo;
   o_flag := '0';


EXCEPTION
   WHEN e_NULL
   THEN
      NULL;
   --ADDED BY GJ FOR 2ZY5 AT TJ 20150410 BEGIN
   WHEN e_699error
   THEN
      RES := 'NO 699 PART';
   --ADDED BY GJ FOR 2ZY5 AT TJ 20150410 END
   WHEN OTHERS
   THEN
      RES := 'OTHER ERROR!';
END;