PROCEDURE       get_output_lost_v1(dtime IN DATE,shift IN VARCHAR2,res OUT VARCHAR2) AS

c_line     VARCHAR2(8);
c_model    VARCHAR2(25);
c_shift    VARCHAR2(1);
t_date     VARCHAR2(12);
c_section  VARCHAR2(16);
c_group    VARCHAR2(16);
w_start    VARCHAR2(4);
w_end      VARCHAR2(4);
dt_start   VARCHAR2(11);
dt_end     VARCHAR2(11);

c_qty      NUMBER;
s_qty      NUMBER;
c_count1   NUMBER;
c_count2   NUMBER;
c_strdtime NUMBER;
s_time     NUMBER;
s_stoptime NUMBER;
v_stoptime NUMBER;
outputtime NUMBER;
inputtime  NUMBER;
limittime  NUMBER;
ignoretime NUMBER;
v_times        NUMBER;
TYPE cursor_class IS REF CURSOR;
cur0 cursor_class;

--get the output qty and group by line_name,model_name,output_station

CURSOR cur1 IS SELECT a.line_name,a.model_name,a.group_name,SUM(NVL(a.pass_qty,0)+NVL(a.fail_qty,0)) AS outqty
    FROM sfism4.r_station_rec_t a,web.c_line_group_map_t b
    WHERE a.line_name=b.line_name
    AND a.group_name = b.output_station
	AND (a.work_date||LPAD(work_section,2,0)) >= dt_start||SUBSTR(w_start,1,2)
	AND (a.work_date||LPAD(work_section,2,0)) < dt_end||SUBSTR(w_end,1,2)
    AND b.line_type=c_section
    GROUP BY a.line_name,a.model_name,a.group_name;

BEGIN

t_date:=TO_CHAR(dtime,'YYYY/MM/DD');
IF shift='D' THEN
    dt_start:= TO_CHAR(dtime,'YYYYMMDD');
    dt_end:= TO_CHAR(dtime,'YYYYMMDD');
ELSE
    dt_start:= TO_CHAR(dtime,'YYYYMMDD');
    dt_end:= TO_CHAR(dtime+1,'YYYYMMDD');
END IF;

  DELETE FROM sfism4.r_ppm_t WHERE work_date=t_date AND shift_flag=shift;

  OPEN cur0 FOR SELECT section_name,work_time_start,work_time_end,sheet_type
                FROM sfis1.c_section_department_t,web.c_division_worktime_t
                WHERE depart_name = department_name AND sheet_type=shift;
  LOOP
      FETCH cur0 INTO c_section,w_start,w_end,c_shift;
      EXIT WHEN cur0%NOTFOUND;

        --get input_time,ignore_time,limit_time

        SELECT COUNT(*) INTO c_count1 FROM sfis1.c_line_input_time_t WHERE section_name=c_section AND shift_type=c_shift;
        IF c_count1 > 0 THEN
           SELECT input_time,ignore_time,limit_time*60 INTO inputtime,ignoretime,limittime
           FROM sfis1.c_line_input_time_t WHERE section_name=c_section AND shift_type=c_shift;
        ELSE
           inputtime:=0;
           limittime:=120;
           ignoretime:=0;
        END IF;

        OPEN cur1;
        LOOP
        FETCH cur1 INTO c_line,c_model,c_group,c_qty;
        EXIT WHEN cur1%NOTFOUND;

         outputtime:=0;
         s_qty:=0;
         s_time:=0;
         s_stoptime:=0;

         --get the standard time
         SELECT DECODE(COUNT(standard_time),0,0,SUM(standard_time)) INTO c_strdtime
         FROM sfis1.c_standard_worktime_t
         WHERE line_name=c_line AND model_name=c_model;

         s_time:=s_time+c_strdtime*c_qty;
         s_qty:=s_qty+c_qty;
         outputtime:=TRUNC(s_time/3600,2);

         --get the lost time

         SELECT SUM(line_stop_time)AS sumstoptime,COUNT(ROWID) AS times INTO v_stoptime,v_times
         FROM web.c_line_stop_t
         WHERE reason_type <> '12' AND line_stop_time >= limittime AND model_name_start = c_model
         AND in_station_time_start BETWEEN TO_DATE(dt_start||w_start,'YYYYMMDDHH24mi') AND TO_DATE(dt_end||w_end,'YYYYMMDDHH24mi')
         AND line_name = c_line;

         IF v_times != 0 THEN
             s_stoptime:=TRUNC((v_stoptime-v_times*c_strdtime)/3600,2);
         END IF;

         --insert/update the data into the table sfism4.r_ppm_t

        SELECT COUNT(*) INTO c_count2 FROM sfism4.r_ppm_t
         WHERE line_name=c_line  AND shift_flag=c_shift AND work_date=t_date;
        IF (c_count2=0) THEN
            INSERT INTO sfism4.r_ppm_t(work_date,line_name,section_name,group_name,input_time,lost_time,output_time,output_qty,emp_qty,shift_flag)
            VALUES(t_date,c_line,c_section,c_group,inputtime,s_stoptime,outputtime,s_qty,'0',c_shift);
            COMMIT;
         ELSE
            UPDATE sfism4.r_ppm_t SET lost_time=lost_time+s_stoptime,output_time=output_time+outputtime,output_qty=output_qty+s_qty
            WHERE work_date=t_date AND line_name=c_line  AND shift_flag=c_shift;
            COMMIT;
        END IF;
    END LOOP;
    CLOSE cur1;

    --update the lost_time without the ignoretime

    UPDATE sfism4.r_ppm_t SET lost_time = lost_time - ignoretime
    WHERE work_date = t_date AND section_name = c_section AND shift_flag=c_shift;
    COMMIT;

  END LOOP;
  CLOSE cur0;
  res:='OK';
  EXCEPTION
     WHEN OTHERS THEN
      res:='Fail';
END;
