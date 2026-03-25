PROCEDURE       STN_REC_Z(LINE IN VARCHAR2,SECTION IN VARCHAR2,MYGROUP IN VARCHAR2,
   W_STATION IN VARCHAR2,MO IN VARCHAR2,SN IN VARCHAR2,MO_DATE IN VARCHAR2,
   W_SECTION IN NUMBER,F_FLAG IN VARCHAR2
   ) AS
---c_repair NUMBER;
---c_route_code NUMBER;
---c_step NUMBER;
---c_group VARCHAR2(25);
---c_current NUMBER;
C_ROWID VARCHAR2(25);
--Add some parameters by Jelly Meng for Barcode Link  on 2004/10/20
TYPE RC_CLASS IS REF CURSOR;
C_CURSOR RC_CLASS;
C_COUNT NUMBER(2);
C_INIT_SN VARCHAR2(25);
C_OLD_SN VARCHAR2(25);
C_OLD_MO VARCHAR2(25);
C_FLAG VARCHAR2(6);
--End add

BEGIN

   ---SELECT a.route_code,b.group_name INTO c_route_code,c_group
   ---FROM sfism4.r_mo_base_t a, sfism4.r_wip_tracking_t b
   ---WHERE b.serial_number = SN AND a.mo_number = b.mo_number;
   ---SELECT MAX(step_sequence) INTO c_step
   ---FROM c_route_control_t
   ---WHERE GROUP_NAME = MYGROUP AND ROUTE_CODE = C_ROUTE_CODE AND STATE_FLAG = '0'
   ---GROUP BY group_name;
   ---SELECT MAX(c.step_sequence) INTO c_repair
   ---FROM SFISM4.R_REPAIR_T a, C_STATION_CONFIG_T b , c_route_control_t c
   ---WHERE a.TEST_STATION = b.STATION_NAME and b.group_name = c.group_name
   ---   and c.route_code = C_ROUTE_CODE and c.state_flag = '0' and a.record_type = 'T'
   ---   and a.serial_number = SN
   ---group by a.serial_number;
   --Add some SQL by Jelly Meng for Barcode Link on 2004/10/20
   SELECT COUNT(OLD_SN) INTO C_COUNT
   FROM SFISM4.R_SN_LINK_T
   WHERE NEW_SN = SN;
   IF C_COUNT=0 THEN
   --End add
   SELECT ROWID INTO C_ROWID
      FROM SFISM4.R_WIP_LOG_T
      WHERE SERIAL_NUMBER = SN AND GROUP_NAME = MYGROUP AND
            MO_NUMBER=MO AND ROWNUM = 1;
   REINSERT_R102(LINE,SECTION,MYGROUP,MO,MO_DATE,W_SECTION,F_FLAG);
   --Add some SQL by Jelly Meng for Barcode Link on 2004/10/20
   ELSE
     C_FLAG:='FALSE';
     SELECT COUNT(*) INTO C_COUNT
     FROM SFISM4.R_WIP_LOG_T
     WHERE SERIAL_NUMBER = SN AND GROUP_NAME = MYGROUP AND MO_NUMBER=MO AND ROWNUM = 1;
	 IF C_COUNT>0 THEN
	   C_FLAG:='TRUE';
	 ELSE
	   SELECT INIT_SN INTO C_INIT_SN
       FROM SFISM4.R_SN_LINK_T
       WHERE NEW_SN = SN;
	   OPEN C_CURSOR FOR
	   SELECT OLD_SN,MO_NUMBER FROM SFISM4.R_SN_LINK_T WHERE INIT_SN=C_INIT_SN;
	   LOOP
	     FETCH C_CURSOR INTO C_OLD_SN,C_OLD_MO;
	     EXIT WHEN C_CURSOR%NOTFOUND;
	     SELECT COUNT(*) INTO C_COUNT
         FROM SFISM4.R_WIP_LOG_T
         WHERE SERIAL_NUMBER = C_OLD_SN AND GROUP_NAME = MYGROUP AND MO_NUMBER=C_OLD_MO AND ROWNUM = 1;
	     IF C_COUNT>0 THEN
	       C_FLAG:='TRUE';
	       EXIT;
	     END IF;
	   END LOOP;
	   CLOSE C_CURSOR;
	 END IF;
	 IF C_FLAG='TRUE' THEN
	   REINSERT_R102(LINE,SECTION,MYGROUP,MO,MO_DATE,W_SECTION,F_FLAG);
	 ELSE
	   INSERT_R102(LINE,SECTION,MYGROUP,MO,MO_DATE,W_SECTION,F_FLAG);
	   UPDATE_R105(MYGROUP,MO);
	 END IF;

   END IF;
   --End add


EXCEPTION

   WHEN NO_DATA_FOUND THEN

      INSERT_R102(LINE,SECTION,MYGROUP,MO,MO_DATE,W_SECTION,F_FLAG);
      UPDATE_R105(MYGROUP,MO);

   ---IF c_repair >= c_step THEN
   ---   REINSERT_R102(LINE,SECTION,MYGROUP,MO,MO_DATE,W_SECTION,F_FLAG);
   ---ELSE
   ---   SELECT MAX(step_sequence) INTO c_current
   ---   FROM sfis1.c_route_control_t
   ---   WHERE route_code = C_ROUTE_CODE and state_flag = '0' and group_name = c_group;
   ---   if c_current >= c_step then
   ---      REINSERT_R102(LINE,SECTION,MYGROUP,MO,MO_DATE,W_SECTION,F_FLAG);
   ---   else
   ---      INSERT_R102(LINE,SECTION,MYGROUP,MO,MO_DATE,W_SECTION,F_FLAG);
   ---      UPDATE_R105(MO,MYGROUP,1);
   ---   end if;
   ---END IF;
---exception
---   when others then
---      INSERT_R102(LINE,SECTION,MYGROUP,MO,MO_DATE,W_SECTION,F_FLAG);
-----      UPDATE_R105(MO,MYGROUP,1);
END;