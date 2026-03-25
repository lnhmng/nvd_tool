PROCEDURE Insert_Lsa_Alarm_H( LINE IN VARCHAR2,
MYGROUP  IN VARCHAR2,
T_VALUE  IN  NUMBER,
RES OUT VARCHAR2) AS
 HOST  NUMBER(8);
 K_NUMBER NUMBER(8);
BEGIN
  SELECT  HOST_ID ,KANBAN_NUMBER INTO HOST,K_NUMBER FROM SFIS1.C_LSA_ALARM
                                                        WHERE  LINE_NAME=LINE;
----------------------------------------
 IF  T_VALUE=0 THEN
     UPDATE SFIS1.C_KANBAN_VALUE SET VALUE1=0
                      WHERE HOST_ID=HOST AND KANBAN_NUMBER=K_NUMBER;
      IF SQL%NOTFOUND THEN
          INSERT INTO sfis1.C_KANBAN_VALUE
                 (host_id,kanban_number,page1,value1,job_no,intflag,status)
          VALUES(HOST,K_NUMBER,MYGROUP,0,1,0,'N');
		  COMMIT;
       END IF;
	  COMMIT;
 END IF;
 ----------------------------------------
 IF  T_VALUE=3 THEN
     UPDATE SFIS1.C_KANBAN_VALUE SET VALUE1=3
                      WHERE HOST_ID=HOST AND KANBAN_NUMBER=K_NUMBER;
     IF SQL%NOTFOUND THEN
        INSERT INTO sfis1.C_KANBAN_VALUE
                 (host_id,kanban_number,page1,value1,job_no,intflag,status)
         VALUES(HOST,K_NUMBER,MYGROUP,3,1,0,'N');
		 COMMIT;
     END IF;
	COMMIT;
 END IF;

  RES:='OK';
EXCEPTION
   WHEN OTHERS THEN
   RES := 'OK';
END;
