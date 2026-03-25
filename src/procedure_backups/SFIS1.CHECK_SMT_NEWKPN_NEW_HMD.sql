PROCEDURE       CHECK_SMT_NEWKPN_NEW_HMD(STATION_NUM IN VARCHAR2,MACHINEFEEDER IN VARCHAR2,
                           PPN IN VARCHAR2,VER IN VARCHAR2,EMP IN VARCHAR2,
                           KPN IN VARCHAR2,SN IN VARCHAR2,
                           LINE IN VARCHAR2,RES OUT VARCHAR2) IS
C_MACHINE VARCHAR2(32);
C_LOC VARCHAR2(32);
ISTRPOSITION INTEGER;
C_KPN VARCHAR2(32);
C_OUTPUT VARCHAR2(64);
V_TEMP_KP VARCHAR2(32);
C_COUNT_1 NUMBER;
C_COUNT  NUMBER ;
BEGIN

    --THE FOLLOWING STATEMENT WILL SORT THE MACHINE CODE
	--FROM THE VARIABLE MACHINEFEEDER.
    SELECT INSTR(MACHINEFEEDER,'&') INTO ISTRPOSITION FROM DUAL;
    SELECT SUBSTR(MACHINEFEEDER,1,ISTRPOSITION-1) INTO C_MACHINE FROM DUAL;
	SELECT SUBSTR(MACHINEFEEDER,ISTRPOSITION+1) INTO C_LOC FROM DUAL;

   /* FOR THE KP ADD 'P'  ,BY ZHANGYUN 2003-10-15 ----- IN THE OLD ONLY 1 LINE,*/
/*    V_TEMP_KP:=SUBSTR(TRIM(KPN),2);*/
    IF SUBSTR(TRIM(KPN),1,1)='P' THEN
     V_TEMP_KP:=TRIM(SUBSTR(TRIM(KPN),2));
	 ELSE
	 V_TEMP_KP:=TRIM(KPN);
	 END IF;
/*---------------ZY---------------*/
     /* SELECT KEY_PART_NO INTO C_KPN FROM SFIS1.C_SMT_KP_T
                                                                WHERE KEY_PART_NO = KPN AND KP_DISTINCT = '1' AND ROWNUM = 1;*/

     /*  LF MODIFY ON 20020531 */
  SELECT COUNT(*)  INTO C_COUNT_1  FROM SFIS1.C_SMT_KP_T
  WHERE KEY_PART_NO = V_TEMP_KP AND KP_DISTINCT = '1' ;
  IF  C_COUNT_1=0 THEN

            SELECT HH_PART INTO C_KPN  FROM SFIS1.C_KPN_T WHERE P_PART=V_TEMP_KP;

      SELECT KEY_PART_NO INTO V_TEMP_KP  FROM SFIS1.C_SMT_KP_T
                                                                   WHERE KEY_PART_NO =C_KPN AND KP_DISTINCT = '1' AND ROWNUM = 1;

  END IF;

   /*LF MODIFY ON 20020531*/

     SELECT COUNT(*) INTO C_COUNT   FROM SFIS1.C_SMT_BOM_T BOM,SFISM4.R_SMT_PROD_BOM_T PROD,SFIS1.KPN_SPN_MODEL_V SPARE
                                                       WHERE BOM.FEEDER_NO = C_LOC
                                                              AND (BOM.KEY_PART_NO = V_TEMP_KP OR (SPARE.SPARE_KEY_PART_NO=V_TEMP_KP  AND SPARE.MODEL_NAME=PPN AND SPARE.VALID_DATE>=SYSDATE))
                                                              AND BOM.KEY_PART_NO=SPARE.KEY_PART_NO(+)
                                                              AND BOM.BOM_NO = PROD.BOM_NO  AND PROD.PRODUCT_NO = PPN
                                                              AND PROD.VER = VER AND BOM.MACHINE_CODE = C_MACHINE;

 /*-----------------------------------------------------------------*/
      IF C_COUNT=0 THEN

             RES := 'KPN NG ';
             C_OUTPUT := RES || ' - ' || V_TEMP_KP ;
             INSERT_ERROR_MES(STATION_NUM,C_MACHINE ,
                           PPN ,VER ,EMP ,
                           C_LOC ,KPN ,SN ,
                           LINE , C_OUTPUT );
       ELSE

              RES := 'OK';

        END IF;

EXCEPTION
   WHEN OTHERS THEN
      RES := ' NO KPN';
      C_OUTPUT:= RES || ' - ' || KPN;
      INSERT_ERROR_MES(STATION_NUM,C_MACHINE ,
                           PPN ,VER ,EMP ,
                           C_LOC ,KPN ,SN ,
                           LINE , C_OUTPUT );

END;
/*************************************************************
CREATED BY: SUN FANRONG
CREATE DATE: OCT 17,2002
UPDATE DATE: OCT 17,2002
FOR SMT MATERIAL CHECK
*************************************************************/ 