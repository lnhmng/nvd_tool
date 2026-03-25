PROCEDURE               Test_Aoi_TEMP (
p_SERIALNUMBER    IN VARCHAR2,
p_STATION_ID 	  IN NUMBER,
p_TEST_DATE 	  IN VARCHAR2,
p_TEST_TIME 	  IN VARCHAR2,
p_RESULT 	      IN VARCHAR2,
p_STATION_TYPE    IN VARCHAR2,
p_WORK_STATION    IN NUMBER,
p_OPERATORID 	  IN VARCHAR2,
p_RETEST	      IN VARCHAR2,
p_FAILDESC	      IN VARCHAR2,
RES		          OUT VARCHAR2) AS

p_CALLRES	      VARCHAR2(48);

TEMP_SN			  VARCHAR2(30); -----add for multiboard
RepairT_Err_Cnt	  NUMBER(2,0);

QAERR_CNT		  NUMBER(2,0);
QAERROR_CODE	  VARCHAR2(10);
ERROR_CODE		  VARCHAR2(500);
TEMP_ERROR		  VARCHAR2(30);
ERRCNT			  NUMBER(2,0);
erri			  NUMBER(2,0);
errj			  NUMBER(2,0);

aoi_no			  varchar2(10);
i				  NUMBER(2,0);  -----add for multiboard
j				  NUMBER(2,0);  -----add for multiboard
k				  NUMBER(2,0);  -----add for multiboard

REAL_STATION_TYPE VARCHAR2(32);
GROUP_ID		  VARCHAR2(16);
p_LINE		      VARCHAR2(16);
p_SECTION	      VARCHAR2(32);
p_GROUP		      VARCHAR2(32);
p_STATION	      VARCHAR2(32);
p_LASTGROUP	      VARCHAR2(56);
p_ROUTE		      NUMBER(4,0);
p_STATE		      VARCHAR2(1);
P_STATION_T       VARCHAR2(32);

p_WORKDATE	      VARCHAR2(8);
p_WORKTIME	      VARCHAR2(6);

p_MODEL		      VARCHAR2(32);
p_MO		      VARCHAR2(32);
p_PASSQTY	      NUMBER(1,0);
p_FAILQTY	      NUMBER(1,0);

i_time            DATE;
i_weekcode        VARCHAR2(2);
p_DATE		      DATE;
p_DATE1           DATE;
p_MAXTESTTIME 	  VARCHAR2(20);
p_TEST_DATE_T     DATE;
p_TEST_TIME_T     VARCHAR2(20);
p_CNTREPAIR       NUMBER(8,0);
p_WORKSECT	      NUMBER(2,0);

PASSCOUNT		  NUMBER(2,0);
v_SNCNT		      NUMBER(2,0);
v_STNCNT	  	  NUMBER(2,0);

e_NO_SN		      EXCEPTION;
e_NO_STATION      EXCEPTION;
e_ROUTE_ERROR     EXCEPTION;
e_NO_TIME         EXCEPTION;

CURSOR CUR1(p_SN VARCHAR2) IS-----add for multiboard   (Cursor with parameter)
       SELECT SERIAL_NUMBER FROM SFISM4.R_PCB_DATECODE_T
	   WHERE GROUP_ID IN
       (SELECT GROUP_ID FROM SFISM4.R_PCB_DATECODE_T WHERE SERIAL_NUMBER=p_SN);-----add for multiboard
    ROW1 CUR1%ROWTYPE;

BEGIN


v_SNCNT:=0;
v_STNCNT:=0;
p_DATE:=SYSDATE;
p_WORKDATE:=TO_DATE(p_TEST_DATE,'YYYYMMDD');
p_WORKTIME:=TO_DATE(p_TEST_TIME,'HH24MISS');

--p_WORKDATE:=p_TEST_DATE;
--p_WORKTIME:=p_TEST_TIME;
--p_DATE:=TO_DATE(p_WORKDATE || p_WORKTIME,'YYYYMMDDHH24MISS');

p_WORKSECT:=SUBSTR(p_WORKTIME,1,2);
TEMP_SN:=p_SERIALNUMBER;


--CHECK THE SERIAL NUMBER EXSISTANCE
SELECT COUNT(SERIAL_NUMBER) INTO v_SNCNT
FROM SFISM4.R_WIP_TRACKING_T
WHERE SERIAL_NUMBER=TEMP_SN;


IF v_SNCNT=0 THEN
   RAISE e_NO_SN;
END IF;

SELECT MODEL_NAME,MO_NUMBER,NVL(PASS_QTY,0),NVL(FAIL_QTY,0), GROUP_NAME,SPECIAL_ROUTE,ERROR_FLAG,LINE_NAME
INTO p_MODEL,p_MO,p_PASSQTY,p_FAILQTY ,p_LASTGROUP,p_ROUTE,p_STATE,p_LINE
FROM SFISM4.R_WIP_TRACKING_T
WHERE SERIAL_NUMBER=TEMP_SN;


   SELECT COUNT(*) INTO v_STNCNT
   FROM SFIS1.C_STATION_CONFIG_T
   WHERE STATION_NUMBER=p_WORK_STATION;

     IF v_STNCNT=0 THEN
        RAISE e_NO_STATION;
     END IF;

	 REAL_STATION_TYPE:=p_STATION_TYPE;

     SELECT SECTION_NAME,GROUP_NAME,STATION_NAME,LINE_NAME
     INTO p_SECTION,p_GROUP,p_STATION, p_LINE
     FROM SFIS1.C_STATION_CONFIG_T
     WHERE STATION_NUMBER=p_WORK_STATION;


--------------Below are check_route

       SFIS1.CHECK_ROUTE(p_LINE, p_GROUP,TEMP_SN,p_CALLRES);
       IF p_CALLRES<>'OK' THEN
         RAISE e_ROUTE_ERROR;
       END IF;


      OPEN CUR1(TEMP_SN);
      FETCH CUR1 INTO ROW1;
        IF CUR1%NOTFOUND THEN
	       ---***********************Below part is for SINGLE BOARD  **********************************

           INSERT INTO SFISM4.R_TEST_RESULT_T(SERIAL_NUMBER,STATION_ID,TEST_DATE,TEST_TIME,RESULT,MODEL_NAME,STATION_TYPE,WORK_STATION,OPERATOR,RETEST,FAILDESC,MO_NUMBER)
           VALUES(p_SERIALNUMBER,p_STATION_ID,p_WORKDATE,p_WORKTIME,p_RESULT,p_MODEL,REAL_STATION_TYPE,p_WORK_STATION,p_OPERATORID,p_RETEST,p_FAILDESC,p_MO);
           COMMIT;

           -- CHECK IF THE TEST RESULT PASS OR FAIL
           IF (p_RESULT='P') THEN
              SFIS1.STN_REC_Z(p_LINE,p_SECTION,p_GROUP,p_STATION,p_MO,p_SERIALNUMBER, p_WORKDATE,p_WORKSECT,'0');
              SFIS1.UPDATE_R107(p_OPERATORID,p_LINE,p_SECTION,p_GROUP,p_STATION,p_MO,p_SERIALNUMBER,'0',p_DATE);
              RES := 'OK';
           ELSIF p_RESULT='F' THEN
              BEGIN
                SFIS1.STN_REC_Z(p_LINE,p_SECTION,p_GROUP,p_STATION,p_MO,p_SERIALNUMBER, p_WORKDATE,p_WORKSECT,'1');
                SFIS1.UPDATE_R107(p_OPERATORID,p_LINE,p_SECTION,p_GROUP,p_STATION,p_MO,p_SERIALNUMBER,'1',p_DATE);

				ERROR_CODE:=p_FAILDESC;

				select STATION_NAME
				into   AOI_No
				FROM   SFIS1.C_TEST_STATION
  				where  STATION_ID =p_STATION_ID  and
  					   STATION_TYPE=p_STATION_TYPE and
  					   WORK_STATION=p_WORK_STATION;

				------(AOIOUT) INI file format use comma to separate
				------For example :  U23-PIN105 15,U07-PIN07 13,
				if  AOI_No='AOI06' or AOI_No='AOI08' or AOI_No='AOI10' or AOI_No='AOI16' or AOI_No='AOI18' or AOI_No='AOI118' or AOI_No='AOI116'  then
				    /******************* ????? ','  ?????????**************/
					if INSTR(ERROR_CODE,',')<=0 then
                	   INSERT INTO SFISM4.R_REPAIR_T(SERIAL_NUMBER,MO_NUMBER,TEST_TIME, TEST_CODE,TEST_STATION,TEST_LINE,RECORD_TYPE,MODEL_NAME)
                	   VALUES(p_SERIALNUMBER,p_MO,p_DATE,'AR013',p_STATION,p_LINE,'T',p_MODEL);
					   commit;
					end if;

				   if (INSTR(ERROR_CODE,','))>0 then
    				   while (INSTR(ERROR_CODE,','))>1
    				   loop
    					   erri:=INSTR(ERROR_CODE,',');
    					   TEMP_ERROR:=SUBSTR(ERROR_CODE,1,erri-1);--U23-PIN105 15
    					   errj:=INSTR(TEMP_ERROR,' ');
    					   TEMP_ERROR:=SUBSTR(TEMP_ERROR,errj+1,length(TEMP_ERROR)-errj);

    					   ERROR_CODE:=SUBSTR(ERROR_CODE,erri+1,length(ERROR_CODE)-erri);
    					   select count(*)
    					   into QAERR_CNT
    					   from sfis1.AOI_ERROR_CODE
    					   WHERE STATION_TYPE='AOIOUT' AND TESTERRORCODE=TEMP_ERROR;

    					   if QAERR_CNT<1 then
    					   	  QAERROR_CODE:='AR013';
    					   end if;

    					   if QAERR_CNT>0 then
    					   	  select NVL(QAERRORCODE,'AR013')
    					   	  into   QAERROR_CODE
    					   	  FROM   SFIS1.AOI_ERROR_CODE
    					   	  where  STATION_TYPE='AOIOUT' AND TESTERRORCODE=TEMP_ERROR;
    					   end if;

    					   select count(*)
    					   into RepairT_Err_Cnt
    					   from SFISM4.R_REPAIR_T
    					   where serial_number=p_SERIALNUMBER and TEST_CODE=QAERROR_CODE;

    					   if RepairT_Err_Cnt=0 then
                    	   	  INSERT INTO SFISM4.R_REPAIR_T(SERIAL_NUMBER,MO_NUMBER,TEST_TIME, TEST_CODE,TEST_STATION,TEST_LINE,RECORD_TYPE,MODEL_NAME)
                    	   	  VALUES(p_SERIALNUMBER,p_MO,p_DATE,QAERROR_CODE,p_STATION,p_LINE,'T',p_MODEL);
    					   	  commit;
    					   end if;
    				   end loop;
					end if;

				end if;

				------(AOIOUT) TXT file format use semicolon to separate
				------For example: C118;C0603_B;14;null;null;null;
				if  AOI_No='AOI02' or AOI_No='AOI12' or AOI_No='AOI14' or AOI_No='AOI04'  then
				   /******************* ????? ';'  ?????????**************/
				   if INSTR(ERROR_CODE,';')<=0 then
                	   INSERT INTO SFISM4.R_REPAIR_T(SERIAL_NUMBER,MO_NUMBER,TEST_TIME, TEST_CODE,TEST_STATION,TEST_LINE,RECORD_TYPE,MODEL_NAME)
                	   VALUES(p_SERIALNUMBER,p_MO,p_DATE,'AR013',p_STATION,p_LINE,'T',p_MODEL);
				   end if;

				   if (INSTR(ERROR_CODE,';'))>0 then
     				   errj:=0;
     				   while (INSTR(ERROR_CODE,';'))>1
     				   loop
     				   	   errj:=errj+1;
     					   erri:=INSTR(ERROR_CODE,';');

     					   if (mod(errj,3)=0) then
     					   	  TEMP_ERROR:=SUBSTR(ERROR_CODE,1,erri-1);
     					   else
     					   	  TEMP_ERROR:=NULL;
     					   end if;

     					   ERROR_CODE:=SUBSTR(ERROR_CODE,erri+1,length(ERROR_CODE)-erri);

     					   IF (TEMP_ERROR<>'null') and (TEMP_ERROR is not null) then
     					   	  select count(*)
     					   	  into QAERR_CNT
     					   	  from sfis1.AOI_ERROR_CODE
     					   	  WHERE STATION_TYPE='AOIOUT' AND TESTERRORCODE=TEMP_ERROR;

     					   	  if QAERR_CNT<1 then
     					   	  	 QAERROR_CODE:='AR013';
     					   	  end if;

     					   	  if QAERR_CNT>0 then
     					   	  	 select NVL(QAERRORCODE,'AR013')
     					   	  	 into   QAERROR_CODE
     					   	  	 FROM   SFIS1.AOI_ERROR_CODE
     					   	  	 where  STATION_TYPE='AOIOUT' AND TESTERRORCODE=TEMP_ERROR;
     					      end if;

     					   	  select count(*)
     					   	  into RepairT_Err_Cnt
     					   	  from SFISM4.R_REPAIR_T
     					   	  where serial_number=p_SERIALNUMBER and TEST_CODE=QAERROR_CODE;

     					   	  if RepairT_Err_Cnt=0 then
                     	   	  	 INSERT INTO SFISM4.R_REPAIR_T(SERIAL_NUMBER,MO_NUMBER,TEST_TIME, TEST_CODE,TEST_STATION,TEST_LINE,RECORD_TYPE,MODEL_NAME)
                     	   	  	 VALUES(p_SERIALNUMBER,p_MO,p_DATE,QAERROR_CODE,p_STATION,p_LINE,'T',p_MODEL);
     					   	  	 commit;
     					   	  end if;
     					   end if;
     				   end loop;
				   end if;

				end if;

				------(AOIIN) TXT file format use semicolon to separate
				------For example: C118;C0603_B;14;null;null;null;
				if  AOI_No='AOI01' or AOI_No='AOI05' or AOI_No='AOI07' or AOI_No='AOI09' or AOI_No='AOI11' or AOI_No='AOI13' or AOI_No='AOI03' or AOI_No='AOI15' or AOI_No='AOI103' or AOI_No='AOI115' then
					/******************* ????? '?'  ?????????**************/
					if ((INSTR(ERROR_CODE,';'))=0)  then
                	    INSERT INTO SFISM4.R_REPAIR_T(SERIAL_NUMBER,MO_NUMBER,TEST_TIME, TEST_CODE,TEST_STATION,TEST_LINE,RECORD_TYPE,MODEL_NAME)
                	    VALUES(p_SERIALNUMBER,p_MO,p_DATE,'AR013',p_STATION,p_LINE,'T',p_MODEL);
					end if;

					if ((INSTR(ERROR_CODE,';'))>0)  then
    				   errj:=0;
    				   while (INSTR(ERROR_CODE,';'))>1
    				   loop
    				   	   errj:=errj+1;
    					   erri:=INSTR(ERROR_CODE,';');

    					   if (mod(errj,3)=0) then
    					   	  TEMP_ERROR:=SUBSTR(ERROR_CODE,1,erri-1);
    					   else
    					   	  TEMP_ERROR:=NULL;
    					   end if;

    					   ERROR_CODE:=SUBSTR(ERROR_CODE,erri+1,length(ERROR_CODE)-erri);

    					   IF (TEMP_ERROR<>'null') and (TEMP_ERROR is not null) then
    					   	  select count(*)
    					   	  into QAERR_CNT
    					   	  from sfis1.AOI_ERROR_CODE
    					   	  WHERE STATION_TYPE='AOIIN' AND TESTERRORCODE=TEMP_ERROR;

    					   	  if QAERR_CNT<1 then
    					   	  	 QAERROR_CODE:='AP005';
    					   	  end if;

    					   	  if QAERR_CNT>0 then
    					   	  	 select NVL(QAERRORCODE,'AP005')
    					   	  	 into   QAERROR_CODE
    					   	  	 FROM   SFIS1.AOI_ERROR_CODE
    					   	  	 where  STATION_TYPE='AOIIN' AND TESTERRORCODE=TEMP_ERROR;
    					      end if;

    					   	  select count(*)
    					   	  into RepairT_Err_Cnt
    					   	  from SFISM4.R_REPAIR_T
    					   	  where serial_number=p_SERIALNUMBER and TEST_CODE=QAERROR_CODE;

    					   	  if RepairT_Err_Cnt=0 then
                    	   	  	 INSERT INTO SFISM4.R_REPAIR_T(SERIAL_NUMBER,MO_NUMBER,TEST_TIME, TEST_CODE,TEST_STATION,TEST_LINE,RECORD_TYPE,MODEL_NAME)
                    	   	  	 VALUES(p_SERIALNUMBER,p_MO,p_DATE,QAERROR_CODE,p_STATION,p_LINE,'T',p_MODEL);
    					   	  	 commit;
    					   	  end if;

    					   	  select count(*)
    					   	  into RepairT_Err_Cnt
    					   	  from SFISM4.R_REPAIR_T
    					   	  where serial_number=p_SERIALNUMBER and TEST_CODE=QAERROR_CODE;

    					   	  if RepairT_Err_Cnt=0 then
                    	   	  	 INSERT INTO SFISM4.R_REPAIR_T(SERIAL_NUMBER,MO_NUMBER,TEST_TIME, TEST_CODE,TEST_STATION,TEST_LINE,RECORD_TYPE,MODEL_NAME)
                    	   	  	 VALUES(p_SERIALNUMBER,p_MO,p_DATE,QAERROR_CODE,p_STATION,p_LINE,'T',p_MODEL);
    					   	  	 commit;
    					   	  end if;

    					   end if;
    				   end loop;
					end if;

				end if;

				IF p_GROUP='AOIIN_T' OR p_GROUP='AOIIN_B' THEN

                    SELECT COUNT(*)
			        INTO p_CNTREPAIR
                    FROM SFISM4.R_TEST_F_LASTRESULT
                    WHERE SERIAL_NUMBER=p_SERIALNUMBER ;

                    IF p_CNTREPAIR<>0 THEN
                       UPDATE SFISM4.R_TEST_F_LASTRESULT
                       SET SERIAL_NUMBER=P_SERIALNUMBER ,LINE_NAME=p_LINE, STATION_TYPE=REAL_STATION_TYPE
                       WHERE SERIAL_NUMBER=p_SERIALNUMBER;
                       COMMIT;
                    ELSE
                       INSERT INTO SFISM4.R_TEST_F_LASTRESULT(SERIAL_NUMBER,LINE_NAME,STATION_TYPE)
	                   VALUES(p_SERIALNUMBER ,p_LINE,REAL_STATION_TYPE);
                      COMMIT;
					END IF;

                END IF;
                COMMIT;
                RES:='OK';
              END;
           END IF;
        ELSE     ---IF IT SI MULTIBOARD
	       ---***********************Below part is for MULTIBOARD
		  IF (p_RESULT='P') THEN------Multiboard Pass Process
	      	 LOOP
		  	 EXIT WHEN CUR1%NOTFOUND;

          	 INSERT INTO SFISM4.R_TEST_RESULT_T(SERIAL_NUMBER,STATION_ID,TEST_DATE,TEST_TIME,RESULT,MODEL_NAME,STATION_TYPE,WORK_STATION,OPERATOR,RETEST,FAILDESC,MO_NUMBER)
          	 VALUES(ROW1.SERIAL_NUMBER,p_STATION_ID,p_WORKDATE,p_WORKTIME,p_RESULT,p_MODEL,REAL_STATION_TYPE,p_WORK_STATION,p_OPERATORID,p_RETEST,p_FAILDESC,p_MO);
          	 COMMIT;

          	 -- CHECK IF THE TEST RESULT PASS OR FAIL

             SFIS1.STN_REC_Z(p_LINE,p_SECTION,p_GROUP,p_STATION,p_MO,ROW1.SERIAL_NUMBER, p_WORKDATE,p_WORKSECT,'0');
             SFIS1.UPDATE_R107(p_OPERATORID,p_LINE,p_SECTION,p_GROUP,p_STATION,p_MO,ROW1.SERIAL_NUMBER,'0',p_DATE);
             RES := 'OK';

			 FETCH CUR1 INTO ROW1;

		     END LOOP;
		     CLOSE CUR1;

		  ELSIF p_RESULT='F' THEN------Multiboard Fail Process ,only process the actual failed SN
               BEGIN
		  	   --BACKUP THE TEST RESULT
	      	   LOOP
		  	   EXIT WHEN CUR1%NOTFOUND;

					   ERROR_CODE:=p_FAILDESC;

              	   	   INSERT INTO SFISM4.R_TEST_RESULT_T(SERIAL_NUMBER,STATION_ID,TEST_DATE,TEST_TIME,RESULT,MODEL_NAME,STATION_TYPE,WORK_STATION,OPERATOR,RETEST,FAILDESC,MO_NUMBER)
              	   	   VALUES(ROW1.SERIAL_NUMBER,p_STATION_ID,p_WORKDATE,p_WORKTIME,p_RESULT,p_MODEL,REAL_STATION_TYPE,p_WORK_STATION,p_OPERATORID,p_RETEST,p_FAILDESC,p_MO);
              	   	   COMMIT;

                   	   SFIS1.STN_REC_Z(p_LINE,p_SECTION,p_GROUP,p_STATION,p_MO,TEMP_SN, p_WORKDATE,p_WORKSECT,'1');
                   	   SFIS1.UPDATE_R107(p_OPERATORID,p_LINE,p_SECTION,p_GROUP,p_STATION,p_MO,ROW1.SERIAL_NUMBER,'1',p_DATE);

        				select STATION_NAME
        				into   AOI_No
        				FROM SFIS1.C_TEST_STATION
          				where STATION_ID =p_STATION_ID  and
          					  STATION_TYPE=p_STATION_TYPE and
          					  WORK_STATION=p_WORK_STATION;

        				------(AOIOUT) INI file format use comma to separate
        				------For example :  U23-PIN105 15,U07-PIN07 13,
        				if  AOI_No='AOI06' or AOI_No='AOI08' or AOI_No='AOI10' or AOI_No='AOI16' or AOI_No='AOI18' or AOI_No='AOI118' or AOI_No='AOI116' then
        				    /******************* ????? ','  ?????????**************/
        					if INSTR(ERROR_CODE,',')<=0 then
                        	   INSERT INTO SFISM4.R_REPAIR_T(SERIAL_NUMBER,MO_NUMBER,TEST_TIME, TEST_CODE,TEST_STATION,TEST_LINE,RECORD_TYPE,MODEL_NAME)
                        	   VALUES(ROW1.SERIAL_NUMBER,p_MO,p_DATE,'AR013',p_STATION,p_LINE,'T',p_MODEL);
        					   commit;
        					end if;

        				   if (INSTR(ERROR_CODE,','))>0 then
            				   while (INSTR(ERROR_CODE,','))>1
            				   loop
            					   erri:=INSTR(ERROR_CODE,',');
            					   TEMP_ERROR:=SUBSTR(ERROR_CODE,1,erri-1);--U23-PIN105 15
            					   errj:=INSTR(TEMP_ERROR,' ');
            					   TEMP_ERROR:=SUBSTR(TEMP_ERROR,errj+1,length(TEMP_ERROR)-errj);

            					   ERROR_CODE:=SUBSTR(ERROR_CODE,erri+1,length(ERROR_CODE)-erri);

            					   select count(*)
            					   into QAERR_CNT
            					   from sfis1.AOI_ERROR_CODE
            					   WHERE STATION_TYPE='AOIOUT' AND TESTERRORCODE=TEMP_ERROR;

            					   if QAERR_CNT<1 then
            					   	  QAERROR_CODE:='AR013';
            					   end if;

            					   if QAERR_CNT>0 then
            					   	  select NVL(QAERRORCODE,'AR013')
            					   	  into   QAERROR_CODE
            					   	  FROM   SFIS1.AOI_ERROR_CODE
            					   	  where  STATION_TYPE='AOIOUT' AND TESTERRORCODE=TEMP_ERROR;
            					   end if;

            					   select count(*)
            					   into RepairT_Err_Cnt
            					   from SFISM4.R_REPAIR_T
            					   where serial_number=ROW1.SERIAL_NUMBER and TEST_CODE=QAERROR_CODE;

            					   if RepairT_Err_Cnt=0 then
                            	   	  INSERT INTO SFISM4.R_REPAIR_T(SERIAL_NUMBER,MO_NUMBER,TEST_TIME, TEST_CODE,TEST_STATION,TEST_LINE,RECORD_TYPE,MODEL_NAME)
                            	   	  VALUES(ROW1.SERIAL_NUMBER,p_MO,p_DATE,QAERROR_CODE,p_STATION,p_LINE,'T',p_MODEL);
            					   	  commit;
            					   end if;
            				   end loop;
        					end if;

        				end if;

        				------(AOIOUT) TXT file format use semicolon to separate
        				------For example: C118;C0603_B;14;null;null;null;
        				if  AOI_No='AOI02' or AOI_No='AOI12' or AOI_No='AOI14' or AOI_No='AOI04'  then
        				   /******************* ????? ';'  ?????????**************/
        				   if INSTR(ERROR_CODE,';')<=0 then
                        	   INSERT INTO SFISM4.R_REPAIR_T(SERIAL_NUMBER,MO_NUMBER,TEST_TIME, TEST_CODE,TEST_STATION,TEST_LINE,RECORD_TYPE,MODEL_NAME)
                        	   VALUES(ROW1.SERIAL_NUMBER,p_MO,p_DATE,'AR013',p_STATION,p_LINE,'T',p_MODEL);
        				   end if;

        				   if (INSTR(ERROR_CODE,';'))>0 then
             				   errj:=0;
             				   while (INSTR(ERROR_CODE,';'))>1
             				   loop
             				   	   errj:=errj+1;
             					   erri:=INSTR(ERROR_CODE,';');

             					   if (mod(errj,3)=0) then
             					   	  TEMP_ERROR:=SUBSTR(ERROR_CODE,1,erri-1);
             					   else
             					   	  TEMP_ERROR:=NULL;
             					   end if;

             					   ERROR_CODE:=SUBSTR(ERROR_CODE,erri+1,length(ERROR_CODE)-erri);

             					   IF (TEMP_ERROR<>'null') and (TEMP_ERROR is not null) then
             					   	  select count(*)
             					   	  into QAERR_CNT
             					   	  from sfis1.AOI_ERROR_CODE
             					   	  WHERE STATION_TYPE='AOIOUT' AND TESTERRORCODE=TEMP_ERROR;

             					   	  if QAERR_CNT<1 then
             					   	  	 QAERROR_CODE:='AR013';
             					   	  end if;

             					   	  if QAERR_CNT>0 then
             					   	  	 select NVL(QAERRORCODE,'AR013')
             					   	  	 into   QAERROR_CODE
             					   	  	 FROM   SFIS1.AOI_ERROR_CODE
             					   	  	 where  STATION_TYPE='AOIOUT' AND TESTERRORCODE=TEMP_ERROR;
             					      end if;

             					   	  select count(*)
             					   	  into RepairT_Err_Cnt
             					   	  from SFISM4.R_REPAIR_T
             					   	  where serial_number=ROW1.SERIAL_NUMBER and TEST_CODE=QAERROR_CODE;

             					   	  if RepairT_Err_Cnt=0 then
                             	   	  	 INSERT INTO SFISM4.R_REPAIR_T(SERIAL_NUMBER,MO_NUMBER,TEST_TIME, TEST_CODE,TEST_STATION,TEST_LINE,RECORD_TYPE,MODEL_NAME)
                             	   	  	 VALUES(ROW1.SERIAL_NUMBER,p_MO,p_DATE,QAERROR_CODE,p_STATION,p_LINE,'T',p_MODEL);
             					   	  	 commit;
             					   	  end if;
             					   end if;
             				   end loop;
        				   end if;

        				end if;

        				------(AOIIN) TXT file format use semicolon to separate
        				------For example: C118;C0603_B;14;null;null;null;
        				if  AOI_No='AOI01' or AOI_No='AOI05' or AOI_No='AOI07' or AOI_No='AOI09' or AOI_No='AOI11' or AOI_No='AOI13' or AOI_No='AOI03' or AOI_No='AOI15' or AOI_No='AOI103' or AOI_No='AOI115' then
        					/******************* ????? '?'  ?????????**************/
        					if INSTR(ERROR_CODE,';')<=0  then
                        	    INSERT INTO SFISM4.R_REPAIR_T(SERIAL_NUMBER,MO_NUMBER,TEST_TIME, TEST_CODE,TEST_STATION,TEST_LINE,RECORD_TYPE,MODEL_NAME)
                        	    VALUES(ROW1.SERIAL_NUMBER,p_MO,p_DATE,'AR013',p_STATION,p_LINE,'T',p_MODEL);
        					end if;

        					if ((INSTR(ERROR_CODE,';'))>0)  then
            				   errj:=0;
            				   while (INSTR(ERROR_CODE,';'))>1
            				   loop
            				   	   errj:=errj+1;
            					   erri:=INSTR(ERROR_CODE,';');

            					   if (mod(errj,3)=0) then
            					   	  TEMP_ERROR:=SUBSTR(ERROR_CODE,1,erri-1);
            					   else
            					   	  TEMP_ERROR:=NULL;
            					   end if;

            					   ERROR_CODE:=SUBSTR(ERROR_CODE,erri+1,length(ERROR_CODE)-erri);

            					   IF (TEMP_ERROR<>'null') and (TEMP_ERROR is not null) then
            					   	  select count(*)
            					   	  into QAERR_CNT
            					   	  from sfis1.AOI_ERROR_CODE
            					   	  WHERE STATION_TYPE='AOIIN' AND TESTERRORCODE=TEMP_ERROR;

            					   	  if QAERR_CNT<1 then
            					   	  	 QAERROR_CODE:='AP005';
            					   	  end if;

            					   	  if QAERR_CNT>0 then
            					   	  	 select NVL(QAERRORCODE,'AP005')
            					   	  	 into   QAERROR_CODE
            					   	  	 FROM   SFIS1.AOI_ERROR_CODE
            					   	  	 where  STATION_TYPE='AOIIN' AND TESTERRORCODE=TEMP_ERROR;
            					      end if;

            					   	  select count(*)
            					   	  into RepairT_Err_Cnt
            					   	  from SFISM4.R_REPAIR_T
            					   	  where serial_number=ROW1.SERIAL_NUMBER and TEST_CODE=QAERROR_CODE;

            					   	  if RepairT_Err_Cnt=0 then
                            	   	  	 INSERT INTO SFISM4.R_REPAIR_T(SERIAL_NUMBER,MO_NUMBER,TEST_TIME, TEST_CODE,TEST_STATION,TEST_LINE,RECORD_TYPE,MODEL_NAME)
                            	   	  	 VALUES(ROW1.SERIAL_NUMBER,p_MO,p_DATE,QAERROR_CODE,p_STATION,p_LINE,'T',p_MODEL);
            					   	  	 commit;
            					   	  end if;

            					   	  select count(*)
            					   	  into RepairT_Err_Cnt
            					   	  from SFISM4.R_REPAIR_T
            					   	  where serial_number=ROW1.SERIAL_NUMBER and TEST_CODE=QAERROR_CODE;

            					   	  if RepairT_Err_Cnt=0 then
                            	   	  	 INSERT INTO SFISM4.R_REPAIR_T(SERIAL_NUMBER,MO_NUMBER,TEST_TIME, TEST_CODE,TEST_STATION,TEST_LINE,RECORD_TYPE,MODEL_NAME)
                            	   	  	 VALUES(ROW1.SERIAL_NUMBER,p_MO,p_DATE,QAERROR_CODE,p_STATION,p_LINE,'T',p_MODEL);
            					   	  	 commit;
            					   	  end if;

            					   end if;
            				   end loop;
        					end if;

        				end if;

    			       IF p_GROUP='AOIIN_T' OR p_GROUP='AOIIN_B' THEN

                           SELECT COUNT(*)
    			           INTO p_CNTREPAIR
                           FROM SFISM4.R_TEST_F_LASTRESULT
                           WHERE SERIAL_NUMBER=ROW1.SERIAL_NUMBER ;

                           IF p_CNTREPAIR<>0 THEN
                              UPDATE SFISM4.R_TEST_F_LASTRESULT
                              SET SERIAL_NUMBER=ROW1.SERIAL_NUMBER,LINE_NAME=p_LINE, STATION_TYPE=REAL_STATION_TYPE
                              WHERE SERIAL_NUMBER=ROW1.SERIAL_NUMBER;
                              COMMIT;
                           ELSE
                              INSERT INTO SFISM4.R_TEST_F_LASTRESULT(SERIAL_NUMBER,LINE_NAME,STATION_TYPE)
    	                      VALUES(ROW1.SERIAL_NUMBER,p_LINE,REAL_STATION_TYPE);
                              COMMIT;
                           END IF;
    				   END IF;
                       COMMIT;
                       RES:='OK';
			   FETCH CUR1 INTO ROW1;

		       END LOOP;
		       CLOSE CUR1;

               END;
		  END IF;
     	END IF;

-- EXCEPTION HANDLE BLOCK
EXCEPTION
		  WHEN e_NO_SN THEN
		  	   BEGIN
		  	   		RES:='NO SN';
			   END;
		  WHEN e_ROUTE_ERROR THEN
		  	   RES:=p_CALLRES;
            WHEN e_NO_TIME    THEN
                 RES:='TIME<30';
		  WHEN e_NO_STATION THEN
		  	   BEGIN
			   		RES:='NO STATION';
			   END;
		   WHEN NO_DATA_FOUND THEN
			   	  RES:='INPUT ERROR1';
		   WHEN OTHERS THEN
		  	   RES:='INPUT ERROR2';
END;
/* ******************************************************
Revision:1.0
CREATED BY: SHUI CAI LI
CREATE DATE: 01, 13,2004

UPDATE BY :Anthony Zhang
CREATE DATE:8.13.2004
FOR MULTIBOARD AOI INPUT & OUTPUT

UPDATE BY :Anthony Zhang
CREATE DATE:8.23.2004
FOR DIFFICULT ROUTE CONTROL

UPDATED BY :Anthony Zhang
CREATE DATE:9.20.2004
FOR CHECK TIME <30 AFTER REPAIR IN AOIIN_T AND AOIIN_B STATION

UPDATED BY :Anthony Zhang
CREATE DATE:3.7.2005
NEW DESIGN FOR MULTIBOARD PROCESS

UPDATED BY :Anthony Zhang
CREATE DATE:7.8.2005
NEW DESIGN FOR HMD AOI Station (Machine ID is AOI04)

UPDATED BY :Anthony Zhang
CREATE DATE:11.5.2005
Set all board is fail when one board is fail in MultiBoard

******************************************************** */