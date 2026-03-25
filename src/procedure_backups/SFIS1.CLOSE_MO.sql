PROCEDURE                           CLOSE_MO
is
	count1 int;
    count2 int;
    count3 int;
    count4 int;
	beginTime date;
    endTime date;
   CURSOR CUR1
   IS
       select distinct mo_number from sfism4.r_wip_tracking_t where in_station_time>sysdate-50; 
   ROW1   CUR1%ROWTYPE;
BEGIN

   OPEN CUR1;
   FETCH CUR1 INTO ROW1;

   IF CUR1%FOUND
   THEN
      LOOP
         EXIT WHEN CUR1%NOTFOUND;
        select count(*) into count2 from sfism4.r_sn_detail_T where in_station_time >sysdate -7 and  mo_number=row1.mo_number and group_name='WAREHOUSE';

        SELECT COUNT(*) into count3 FROM SFISM4.R_SN_DETAIL_t  A WHERE  in_station_time >sysdate -7 and  GROUP_NAME='SCRAP'  
        AND mo_number=row1.mo_number AND NOT EXISTS (SELECT 1 FROM SFISM4.R_SN_DETAIL_t B WHERE B.GROUP_NAME='WAREHOUSE' AND A.SERIAL_NUMBER=B.SERIAL_NUMBER);


           SELECT COUNT(*) into count4 FROM SFISM4.R_SN_DETAIL_t  A WHERE  in_station_time >sysdate -7 and  GROUP_NAME='BONEPILE_IN'  
        AND mo_number=row1.mo_number AND NOT EXISTS (SELECT 1 FROM SFISM4.R_SN_DETAIL_t B WHERE (B.GROUP_NAME='WAREHOUSE' or b.group_name='SCRAP' ) AND A.SERIAL_NUMBER=B.SERIAL_NUMBER); 

        select target_qty into count1 from sfism4.r_mo_base_t  where  mo_number=row1.mo_number;

        if  count1=count2+count3+count4
        then
                update sfism4.r_mo_base_t set close_flag='3' where mo_number=row1.mo_number ;   
                 COMMIT;
                   insert into SMTINFO.R_DML_COUNT(result,begin_time,count,end_time) values(row1.mo_number ,sysdate,3, sysdate);
                   commit;
        end if;

         FETCH CUR1 INTO ROW1;
      END LOOP;
   END IF;

   CLOSE CUR1;
   COMMIT;
END;