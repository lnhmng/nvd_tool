PROCEDURE        BAR_CODE_BINDING_EIGENVALUE2_S (
   W_TEST_FIXTURE_ID            IN     VARCHAR2,
   W_TEST_BARCODE               IN     VARCHAR2,
   W_TEST_MODEL                 IN     VARCHAR2,
   W_TEST_CHARACTERISTICVALUE   IN     VARCHAR2,
   W_TEST_EMP                   IN     VARCHAR2,
   o_flag         OUT      VARCHAR2,   
   RES                             OUT VARCHAR2)
AS
   COUN         INT;
   COUN1        INT;
   COUNT2     INT;
   MAXID        VARCHAR2 (25);
   MAXSEQNO     VARCHAR2 (25);
   TEST_TYPE1   VARCHAR2 (5);
   MOB_TEMP   VARCHAR2 (25);
   E_NOSN       EXCEPTION;
   E_ERROR     EXCEPTION;
   E_ERROR2     EXCEPTION;
BEGIN
   o_flag := '-1';
   IF    W_TEST_BARCODE = 'N/A'
      OR W_TEST_BARCODE = ''
      OR W_TEST_BARCODE IS NULL
      OR W_TEST_BARCODE = 'NULL'
      OR W_TEST_BARCODE = ' '
   THEN
      RES := W_TEST_BARCODE || '\nIncorrectly !';
      RAISE E_NOSN;
   END IF;



   IF SUBSTR (W_TEST_BARCODE, 1, 3) = 'MOB'
   THEN
      TEST_TYPE1 := 'MOB';
   END IF;

   IF SUBSTR (W_TEST_BARCODE, 1, 3) = 'MEM'
   THEN
      TEST_TYPE1 := 'MEM';
   END IF;

   IF SUBSTR (W_TEST_BARCODE, 1, 3) = 'CPU'
   THEN
      TEST_TYPE1 := 'CPU';
   END IF;

   IF SUBSTR (W_TEST_BARCODE, 1, 3) = 'HDD'
   THEN
      TEST_TYPE1 := 'HDD';
   END IF;

   IF TEST_TYPE1 = ''
   THEN
      RES := W_TEST_BARCODE || '\nIncorrectly !';
      RAISE E_NOSN;
   END IF;


   --？脤？徨岆瘁?？ ADD BY LSC 20200709 provide by TE xiaoming
  select count(*) into count2 from  sfis1.bp_storage_detail  where 
  SN = W_TEST_BARCODE and IO_FLAG=1;

  IF count2 < 1
   THEN
      RAISE E_ERROR;
   END IF;

IF TEST_TYPE1= 'MOB'
THEN 
 SELECT COUNT (1)
     INTO COUN1
     FROM SFIS1.FIXTURE_BIND
    WHERE FIXTURE_ID = W_TEST_FIXTURE_ID AND FLAG = '1' AND SUBSTR( MODEL_BARCODE,1,3)='MOB';

   IF COUN1 >= 1
   THEN
     RAISE E_ERROR2;  
   END IF;
END IF;
   --？徨?隅？？徨
   SELECT COUNT (1)
     INTO COUN
     FROM SFIS1.FIXTURE_SN_BINDING_TEST
    WHERE TEST_BARCODE = W_TEST_BARCODE;


   IF COUN >= 1
   THEN
      DELETE FROM SFIS1.FIXTURE_SN_BINDING_TEST
            WHERE TEST_BARCODE = W_TEST_BARCODE;

      COMMIT;
   END IF;

   --？徨?隅？怢?

   SELECT COUNT (1)
     INTO COUN1
     FROM SFIS1.FIXTURE_BIND
    WHERE MODEL_BARCODE = W_TEST_BARCODE AND FLAG = '1';

   IF COUN1 >= 1
   THEN
      DELETE FROM SFIS1.FIXTURE_BIND
            WHERE MODEL_BARCODE = W_TEST_BARCODE AND FLAG = '1';

      COMMIT;
   END IF;



   --/*SELECT MAX (ID) + 1 INTO MAXID FROM SFIS1.FIXTURE_BIND;*/

   SELECT SFIS1.SEQ_FIXTURE_BIND.NEXTVAL INTO MAXID FROM DUAL;

   SELECT MAX (SEQNO) + 1
     INTO MAXSEQNO
     FROM SFIS1.FIXTURE_BIND
    WHERE FIXTURE_ID = W_TEST_FIXTURE_ID;

   IF MAXSEQNO IS NULL
   THEN
      MAXSEQNO := 1;
   END IF;

   INSERT INTO SFIS1.FIXTURE_BIND (ID,
                                   FIXTURE_ID,
                                   SEQNO,
                                   MODEL_BARCODE,
                                   LASTEDITDT,
                                   FLAG)
        VALUES (MAXID,
                W_TEST_FIXTURE_ID,
                MAXSEQNO,
                W_TEST_BARCODE,
                SYSDATE,
                '1');

   COMMIT;


   INSERT INTO SFIS1.FIXTURE_SN_BINDING_TEST (TEST_BARCODE,
                                              TEST_MODEL,
                                              TEST_CHARACTERISTICVALUE,
                                              TEST_TYPE,
                                              TEST_EMP)
        VALUES (W_TEST_BARCODE,
                W_TEST_MODEL,
                W_TEST_CHARACTERISTICVALUE,
                TEST_TYPE1,
                W_TEST_EMP);

   COMMIT;
   RES := 'OK!';
   o_flag := '0';
EXCEPTION
   WHEN E_NOSN
   THEN
      NULL;
    WHEN E_ERROR
   THEN
      RES := 'Barcode not storage';
       WHEN E_ERROR2
   THEN
      RES := 'MOB BINDED!';
   WHEN OTHERS
   THEN
      RES := 'barcode ERROR';
END;
