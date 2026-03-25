PROCEDURE       SP_TMS_CHECK_ID (
   DATA         IN       VARCHAR2,
   res          OUT      VARCHAR2
)
/* 
 NAME:       SFIS1.Sp_Tms_Check_Id
 PURPOSE:    CHECK TOOLS ID

  REVISIONS:
  TaskID           Ver        Date        Author           Description
   -------------------------------------------------------------
  ITDB20101011001 1.0       2010/10/6    tangyanjun   CHECK TOOLS ID.
*/
-- ITDB20101011001 Added by tangyanjun on 2010/10/6 -??EPD3 PTH INPUT ????SN ???ID??????- BEGIN

IS
   v_res        VARCHAR2 (200);

BEGIN
   res := 'CHECK TOOLS ID ERROR ';
   tms.check_tms_online (data, v_res);
   IF TRIM (v_res) <> 'OK'
   THEN
      res := v_res;
      RETURN;
   END IF;
   res := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      res := 'ERROR ' || res;
END;
-- ITDB20101011001 Added by tangyanjun on 2010/10/6 -??EPD3 PTH INPUT ????SN ???ID??????- END
