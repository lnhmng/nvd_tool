PROCEDURE INSERT_SMTLOG2_MES (STATION_NUM IN VARCHAR2,MACHINE IN VARCHAR2,
                           PPN IN VARCHAR2,VER IN VARCHAR2,EMP IN VARCHAR2,
                           LOC IN VARCHAR2,KPN IN VARCHAR2,SN IN VARCHAR2,VC IN VARCHAR2,
                           LINE IN VARCHAR2) IS
BEGIN
   INSERT INTO SFISM4.R_SMT_LOG_T(
      STATION_NUMBER,
      MACHINE_CODE,
      PRODUCT_NO,
      VER,
      EMP_NO,
      FEEDER_NO,
      KEY_PART_NO,
      WORK_TIME,
      SN  ,
      LINE_NAME,
      LOT_NO
    )
    VALUES
    (
      STATION_NUM,
      MACHINE,
      PPN,
      VER,
      EMP,
      LOC,
      KPN,
      SYSDATE,
      VC,
      LINE,
      SN
    );
    COMMIT;
--EXCEPTION
--  WHEN OTHERS THEN
 --    RES := ' INSERT ERROR ';
END;
