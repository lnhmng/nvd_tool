PROCEDURE       check_smt_pkg_feed (LINE   IN     VARCHAR2,
                                                RPN     IN     VARCHAR2,
                                                RES        OUT VARCHAR)
IS
   tmpVar   NUMBER;
   COUNT1   NUMBER;
   E_NULL   EXCEPTION;
   
  
/******************************************************************************
   NAME:       check_smt_pkg_feed
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        2012/8/7   Administrator       1. Created this procedure.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     check_smt_pkg_feed
      Sysdate:         2012/8/7
      Date and Time:   2012/8/7, 奻敁 09:28:00, and 2012/8/7 奻敁 09:28:00
      Username:        Administrator (set in TOAD Options, Procedure Editor)
      Table Name:       (set in the "New PL/SQL Object" dialog)

******************************************************************************/
BEGIN
   tmpVar := 0;

   SELECT COUNT (PRODUCT_NO)
     INTO tmpVar
     FROM SFISM4.R_SMT_PROD_BOM_T
    WHERE PRODUCT_NO = RPN AND LINE_NAME = LINE;

   IF tmpVar = 0
   THEN
      RES := 'NO SMT PPN or LINE MES';
      RAISE E_NULL;
   END IF;
   
   select  count(PKG_ID)  INTO   COUNT1  FROM  SMTINFO.R_SMT_PKGID_LOG_T
   WHERE  PRODUCT_NO = RPN AND LINE_NAME = LINE AND STATE_FLAG = 'R';
   IF COUNT1<1 THEN
      RES := 'NO SCAN IN KITING';
      RAISE E_NULL;
   END IF;

   UPDATE SMTINFO.R_SMT_PKGID_LOG_T
      SET STATE_FLAG = 'N', BEGIN_TIME = SYSDATE
    WHERE PRODUCT_NO = RPN AND LINE_NAME = LINE AND STATE_FLAG = 'R';
   COMMIT;
   RES:='OK';
EXCEPTION
   WHEN E_NULL
   THEN
      NULL;
   WHEN NO_DATA_FOUND
   THEN
      NULL;
   WHEN OTHERS
   THEN
      -- Consider logging the error and then re-raise
      RAISE;
END check_smt_pkg_feed; 