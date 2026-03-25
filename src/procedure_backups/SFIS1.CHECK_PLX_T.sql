PROCEDURE       CHECK_PLX_T (p_STNTYP     IN     VARCHAR2,
                                               LINE         IN     VARCHAR2,
                                               SN           IN     VARCHAR2,
                                               PLX          IN     VARCHAR2,
                                               MYGROUP      IN     VARCHAR2,
                                               MODEL_NAME   IN     VARCHAR2,
                                               CHECKSUM     IN     NUMBER,
                                               RES             OUT VARCHAR2)
IS
   tmpVar             NUMBER;
   v_PLXCNT           NUMBER;
   v_PLXSET           NUMBER;
   V_COUNT            NUMBER;
   e_PLX_MODELNAME    EXCEPTION;
   e_CHECKSUM_ERROR   EXCEPTION;
/******************************************************************************
   NAME:       check_PLX_T
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        2013/11/19   Administrator       1. Created this procedure.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     check_PLX_T
      Sysdate:         2013/11/19
      Date and Time:   2013/11/19, 9:08:17, and 2013/11/19 9:08:17
      Username:        Administrator (set in TOAD Options, Procedure Editor)
      Table Name:       (set in the "New PL/SQL Object" dialog)

******************************************************************************/
BEGIN
   tmpVar := 0;

   SELECT COUNT (*)
     INTO v_PLXCNT
     FROM SFISM4.R_NVBIOS_MODEL_T
    WHERE SERIAL_NUMBER = SN;

   IF v_PLXCNT = 0
   THEN
      IF (LENGTH (CHECKSUM) > 1 AND TRIM (CHECKSUM) <> '0')
      THEN
         INSERT INTO SFISM4.R_NVPLX_MODEL_T (SERIAL_NUMBER,
                                             INIT_MODEL_NAME,
                                             FIRST_PLX,
                                             SECOND_PLX,
                                             LAST_MODEL_NAME,
                                             DATETIME,
                                             RESERVE1,
                                             RESERVE2,
                                             FLAG,
                                             GROUP_NAME)
              VALUES (SN,
                      MODEL_NAME,
                      PLX,
                      '',
                      '',
                      SYSDATE,
                      CHECKSUM,
                      '',
                      '0',
                      MYGROUP);
      ELSE
         INSERT INTO SFISM4.R_NVPLX_MODEL_T (SERIAL_NUMBER,
                                             INIT_MODEL_NAME,
                                             FIRST_PLX,
                                             SECOND_PLX,
                                             LAST_MODEL_NAME,
                                             DATETIME,
                                             RESERVE1,
                                             RESERVE2,
                                             FLAG,
                                             GROUP_NAME)
              VALUES (SN,
                      MODEL_NAME,
                      PLX,
                      '',
                      '',
                      SYSDATE,
                      '',
                      '',
                      '0',
                      MYGROUP);
      END IF;
   END IF;

   IF v_PLXCNT > 0
   THEN
      IF (LENGTH (CHECKSUM) > 1 AND TRIM (CHECKSUM) <> '0')
      THEN
         UPDATE SFISM4.R_NVPLX_MODEL_T
            SET SECOND_PLX = PLX,
                DATETIME = SYSDATE,
                FLAG = '1',
                GROUP_NAME = MYGROUP,
                RESERVE2 = CHECKSUM
          WHERE SERIAL_NUMBER = SN;
      ELSE
         UPDATE SFISM4.R_NVPLX_MODEL_T
            SET SECOND_PLX = PLX,
                DATETIME = SYSDATE,
                FLAG = '1',
                GROUP_NAME = MYGROUP,
                RESERVE2 = ''
          WHERE SERIAL_NUMBER = SN;
      END IF;
   END IF;

   SELECT COUNT (*)
     INTO v_PLXSET
     FROM SFIS1.C_NV_MODESC_T
    WHERE     (CUSTOMER_PN = MODEL_NAME OR L600_690_PN = MODEL_NAME)
          AND PLX_VERSION = PLX;

   IF v_PLXSET = 0
   THEN
      RAISE e_PLX_MODELNAME;
   END IF;

   IF (LENGTH (CHECKSUM) > 1 AND TRIM (CHECKSUM) <> '0')
   THEN
      SELECT COUNT (*)
        INTO v_COUNT
        FROM SFIS1.C_NV_MODESC_T
       WHERE     (CUSTOMER_PN = MODEL_NAME OR L600_690_PN = MODEL_NAME)
             AND PLX_VERSION = PLX
             AND INSTR (CHECK_SUM, CHECKSUM) > 0;

      IF (V_COUNT <= 0)
      THEN
         RAISE e_CHECKSUM_ERROR;
      END IF;
   END IF;

   res := 'OK';
EXCEPTION
   WHEN e_PLX_MODELNAME
   THEN
      BEGIN
         RES := 'PLX NOT MATCH MODEL_NAME';
      END;
   WHEN e_CHECKSUM_ERROR
   THEN
      BEGIN
         RES := 'PLX CHECKSUM ERROR';
      END;
   WHEN NO_DATA_FOUND
   THEN
      NULL;
   WHEN OTHERS
   THEN
      -- Consider logging the error and then re-raise
      RAISE;
END check_PLX_T; 