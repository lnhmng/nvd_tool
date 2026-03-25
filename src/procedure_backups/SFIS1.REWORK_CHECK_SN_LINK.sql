PROCEDURE       REWORK_CHECK_SN_LINK (SN IN VARCHAR2, res  OUT VARCHAR2) AS

temp_new_sn    VARCHAR2 (30);
time_init_sn1   NUMBER(20);
time_init_sn2   NUMBER(20);
time_new_sn   NUMBER(20);
c_count        NUMBER (8);

/******************************************************************************
   NAME:       REWORK_CHECK_SN_LINK
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        2006/10/17          1. Created this procedure.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     REWORK_CHECK_SN_LINK
      Sysdate:         2006/10/17
      Date and Time:   2006/10/17, ?? 03:14:20, and 2006/10/17 ?? 03:14:20
      Username:         (set in TOAD Options, Procedure Editor)
      Table Name:       (set in the "New PL/SQL Object" dialog)

******************************************************************************/
BEGIN

   SELECT COUNT (*)  INTO c_count FROM sfism4.r_sn_link_t WHERE init_sn = SN;

   IF c_count = 0  THEN
      res := 'No Link';
   ELSE
      SELECT NEW_SN INTO temp_new_sn FROM sfism4.r_sn_link_t  WHERE init_sn = SN;

   select TO_NUMBER (TO_CHAR(IN_STATION_TIME,'yyyymmddhhmiss'))
     into time_new_sn
     from sfism4.R_WIP_TRACKING_T where  SERIAL_NUMBER=temp_new_sn;

   SELECT COUNT(*) INTO c_count FROM SFISM4.R_SN_DETAIL_T WHERE GROUP_NAME='PACKING' AND SERIAL_NUMBER=SN AND Rownum=1;
   IF c_count >0 THEN

        SELECT TO_NUMBER (TO_CHAR (in_station_time - 5 / (24 * 3600),'yyyymmddhhmiss')),
             TO_NUMBER (TO_CHAR (in_station_time + 5 / (24 * 3600),'yyyymmddhhmiss'))
        INTO time_init_sn1,time_init_sn2
        FROM sfism4.r_sn_detail_t  WHERE group_name = 'PACKING' AND serial_number = SN and rownum=1;

     IF time_init_sn1<=time_new_sn and time_init_sn2>=time_new_sn THEN
       delete  from sfism4.R_SN_LINK_T where NEW_SN=temp_new_sn;
     END IF;

   update sfism4.R_WIP_TRACKING_T  set  SECTION_NAME='0',GROUP_NAME='0',STATION_NAME='0',CARTON_NO='N/A'
   where SERIAL_NUMBER=temp_new_sn;
   RES:='OK';
   ELSE
     RES:='NO PACKING SN';
  END IF;
   END IF;

EXCEPTION
   WHEN OTHERS
   THEN
     RES:='NO';
      -- Consider logging the error and then re-raise
     --RAISE;
END rework_check_sn_link;