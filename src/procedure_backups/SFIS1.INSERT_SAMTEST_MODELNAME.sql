PROCEDURE             INSERT_SAMTEST_MODELNAME AS 
 low_seq INT;
 high_seq INT;
 temp_group_next varchar(50);
 count1 int;
  CURSOR mycur
   IS
     select  model_name,route_code ,mo_create_date,mo_number  from sfism4.r_mo_base_t 
   WHERE MO_CREATE_DATE > (select last_modify_date-7 from sfis1.c_parameter_ini where prg_name  ='samtest') and (model_name like '6__-%' or model_name like '7__-%' or model_name like '9__-%');



BEGIN

For item in mycur LOOP

   for jump in (
   SELECT * from 
   (   SELECT GROUP_NAME,GROUP_NEXT,STATE_FLAG,step_sequence,route_code,Rank() Over( PARTITION BY GROUP_NAME ORDER BY step_sequence ASC ) as RANK ,
   COUNT(1) OVER (PARTITION BY GROUP_NAME) AS RankMax
    FROM sfis1.c_route_control_t  
   WHERE route_code =item.route_code and state_flag =0 --找出排名為最大值的的跳躍工站,取出要跳最遠的工站
   and group_name not  like 'R_%' --排除工站是維修工站
   ORDER BY GROUP_name   ) 
   where rank = rankmax  and rank >=2 ) 
   LOOP --找出跳躍工站 取出loop

      select  min(step_sequence) into low_seq from sfis1.c_route_control_t where group_name =jump.group_name and route_code =jump.route_code group by group_name; 


      select  count(*) into count1  from sfis1.c_route_control_t where group_name =jump.group_next and route_code =jump.route_code;

      IF count1 = 0 then
           select  min(step_sequence) into high_seq from sfis1.c_route_control_t where group_next =jump.group_next and route_code =jump.route_code group by group_next;
      ELSE 
           select  min(step_sequence) into high_seq from sfis1.c_route_control_t where group_name =jump.group_next and route_code =jump.route_code group by group_name;
      END IF ;
      --MODIFY BY NICK11 2022-09-19 
      --NVD 5.3.3 文件只許'S_X-RAY_O','P_X-RAY_O','690_FQC','900_FQC','OBA','OQA','IOT','ACT','APT','PCL','FLK','SFL','S3S' 為跳耀工站
      for samp in (   
      select group_name ,route_code  from sfis1.c_route_control_t where route_code =jump.route_code and step_sequence between  low_seq and high_seq 
      and group_name <> jump.group_name and group_name <> jump.group_next 
      AND GROUP_NAME IN (SELECT STATION_SFC  FROM SFIS1.C_STATION_MAPPING_T WHERE STATION_NV IN ('S_X-RAY_O','P_X-RAY_O','690_FQC','900_FQC','OBA','OQA','IOT','ACT','APT','PCL','FLK','SFL','S3S','DG3','DG4','GN3','GN4','NVL','LED') ) 
      group by group_name ,route_code )
      LOOP
      MERGE  INTO  sfis1.c_samtest_t a 
        USING ( SELECT    item.model_name as model_name , samp.group_name as group_name ,item.mo_number as mo_number  , samp.route_code as route_code from dual  ) b
         ON  (a.model_name = b.model_name and a.sampling_station = b.group_name and a.mo_number = b.mo_number and a.route_code = b.route_code and a.route_code<>'QA MAINTAIN')
         WHEN  MATCHED  THEN
           UPDATE   SET   update_time = sysdate
         WHEN   NOT  MATCHED  THEN  
           INSERT  (model_name,sampling_station,route_code,mo_number)  VALUES (item.model_name , samp.group_name , samp.route_code , item.mo_number );

         -- insert into sfis1.c_samtest_t (model_name,sampling_station,route_code,mo_number) select item.model_name,samp.group_name ,samp.route_code,item.mo_number from dual
       --   WHERE NOT EXISTS ( SELECT 1
        --                  FROM sfis1.c_samtest_t   WHERE model_name = item.model_name and sampling_station = samp.group_name and mo_number=item.mo_number  );
      end loop;
      --MODIFY BY NICK11 2022-09-19 
   end loop;

END LOOP;
update  sfis1.c_parameter_ini set  last_modify_date = sysdate where   prg_name ='samtest';    
commit; 
EXCEPTION
     WHEN OTHERS THEN  -- handles all other errors
     DBMS_OUTPUT.PUT_LINE (SQLERRM);
     DBMS_OUTPUT.PUT_LINE (SQLCODE);
      ROLLBACK;
END INSERT_SAMTEST_MODELNAME;