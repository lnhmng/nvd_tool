PROCEDURE        datalink 
 ----Added by Alex Wang on 2010/05/24 for 1TFE-100524-01 Begin
(
   emp       IN       VARCHAR2,
   DATA      IN       VARCHAR2,
   VALUE     IN       VARCHAR2,
   mygroup   IN       VARCHAR2,
   flag      IN       VARCHAR2,
   res       OUT      VARCHAR2
)
AS
   c_count0    NUMBER;
   c_count1    NUMBER;
   models      VARCHAR2 (20);
   keyvalue    VARCHAR2 (150);
   PB_NO_value    VARCHAR2 (50);
   keyvalue1   VARCHAR2 (50);
   keyvalue2   VARCHAR2 (50);
   keyvalue3   VARCHAR2 (50);
   keyvalue4   VARCHAR2 (50);
   keyvalue5   VARCHAR2 (50);
   keyvalue6   VARCHAR2 (50);
   keyvalue7   VARCHAR2 (50);
   keyvalue8   VARCHAR2 (50);
   keyvalue9   VARCHAR2 (50);
   v_flag      VARCHAR2 (15);
   c_init_sn   VARCHAR2 (25);
   c_group   VARCHAR2 (25);
   KK          VARCHAR2 (150);
BEGIN
   v_flag := flag;

   SELECT COUNT (*)
     INTO c_count1
     FROM sfism4.r_sn_link_t
    WHERE old_sn = DATA OR new_sn = DATA;

   IF c_count1 = 0
   THEN
      SELECT COUNT (*)
        INTO c_count0
        FROM sfism4.r_link_t
       WHERE serial_number = DATA
         AND flag = v_flag
         AND available = '0'
         AND group_name = mygroup;

      IF c_count0 > 0
      THEN
         UPDATE sfism4.r_link_t
            SET available = '1',
                last_edit_by = emp,
                last_edit_dt = SYSDATE
          WHERE serial_number = DATA
            AND flag = v_flag
            AND available = '0'
            AND group_name = mygroup;
      END IF;
   ELSE
      SELECT init_sn
        INTO c_init_sn
        FROM sfism4.r_sn_link_t
       WHERE (old_sn = DATA OR new_sn = DATA) AND ROWNUM = 1;

        --Modified by Alex Wang on 2010/11/2 for SQL optimize--Begin--
--         SELECT COUNT(*)
--        INTO   C_COUNT0
--        FROM   SFISM4.R_LINK_T A
--        WHERE  EXISTS (SELECT *
--                          FROM   SFISM4.R_SN_LINK_T B
--                       WHERE  (A.SERIAL_NUMBER = B.NEW_SN OR A.SERIAL_NUMBER = B.OLD_SN)
--                                 AND B.INIT_SN = C_INIT_SN)
--               AND FLAG = V_FLAG
--               AND AVAILABLE = '0'
--               AND GROUP_NAME = MYGROUP;

      --         IF C_COUNT0 > 0 THEN
--            UPDATE SFISM4.R_LINK_T A
--            SET    AVAILABLE = '1',LAST_EDIT_BY = EMP,LAST_EDIT_DT= SYSDATE
--            WHERE  EXISTS (SELECT *
--                              FROM   SFISM4.R_SN_LINK_T B
--                           WHERE  (A.SERIAL_NUMBER = B.NEW_SN OR A.SERIAL_NUMBER = B.OLD_SN)
--                                     AND B.INIT_SN = C_INIT_SN)
--                   AND FLAG = V_FLAG
--                   AND AVAILABLE = '0'
--                   AND GROUP_NAME = MYGROUP;
--        END IF;
      SELECT /*+use_nlindex(C SN_R_LINK_T_INDEX2) */
             COUNT (*)                                   --update  on 20150518
        INTO c_count0
        FROM sfism4.r_link_t
       WHERE serial_number IN (
                SELECT b.new_sn
                  FROM sfism4.r_link_t a, sfism4.r_sn_link_t b
                 WHERE (   a.serial_number = b.new_sn
                        OR a.serial_number = b.old_sn
                       )
                   AND b.init_sn = c_init_sn
                UNION
                SELECT b.old_sn
                  FROM sfism4.r_link_t a, sfism4.r_sn_link_t b
                 WHERE (   a.serial_number = b.new_sn
                        OR a.serial_number = b.old_sn
                       )
                   AND b.init_sn = c_init_sn)
         AND flag = v_flag
         AND available = '0'
         AND group_name = mygroup;

      IF c_count0 > 0
      THEN
         UPDATE sfism4.r_link_t
            SET available = '1',
                last_edit_by = emp,
                last_edit_dt = SYSDATE
          WHERE serial_number IN (
                   SELECT b.new_sn
                     FROM sfism4.r_link_t a, sfism4.r_sn_link_t b
                    WHERE (   a.serial_number = b.new_sn
                           OR a.serial_number = b.old_sn
                          )
                      AND b.init_sn = c_init_sn
                   UNION
                   SELECT b.old_sn
                     FROM sfism4.r_link_t a, sfism4.r_sn_link_t b
                    WHERE (   a.serial_number = b.new_sn
                           OR a.serial_number = b.old_sn
                          )
                      AND b.init_sn = c_init_sn)
            AND flag = v_flag
            AND available = '0'
            AND group_name = mygroup;
      END IF;
   --Modified by Alex Wang on 2010/11/2 for SQL optimize--End--
   END IF;


     --ADD   BY     2020-01-08     luoyang
 --  IF (SUBSTR (mygroup, 0, 3) = 'ICT') AND (v_flag = 'LOGNAME')
   IF (  (SUBSTR (mygroup, 0, 3) = 'ICT') AND (v_flag = 'LOGNAME')) OR (SUBSTR (mygroup, 0, 3) = 'MDA') OR (SUBSTR (mygroup, 0, 3) = 'DBA') OR (SUBSTR (mygroup, 0, 3) = 'ISP') OR (SUBSTR (mygroup, 0, 4) = 'BSIA') OR (SUBSTR (mygroup, 0, 4) = 'BSIB') AND (v_flag = 'LOGNAME')
   THEN
      SELECT model_name
        INTO models
        FROM sfism4.r_wip_tracking_t
       WHERE serial_number = DATA;

        --SELECT B.PO_NO INTO PB_NO_value FROM SFISM4.R_MO_BASE_T A, SFISM4.R_WIP_TRACKING_T B WHERE A.MO_NUMBER = B.MO_NUMBER AND A.PO_NO LIKE 'PB%' AND B.serial_number = DATA;
      SELECT COUNT (*) INTO c_count0 FROM SFISM4.R_MO_BASE_T A, SFISM4.R_WIP_TRACKING_T B WHERE A.MO_NUMBER = B.MO_NUMBER AND A.PO_NO LIKE 'PB%' AND B.serial_number = DATA;        
       IF  c_count0 > 0 THEN  
         BEGIN
            SELECT B.PO_NO INTO PB_NO_value FROM SFISM4.R_MO_BASE_T A, SFISM4.R_WIP_TRACKING_T B WHERE A.MO_NUMBER = B.MO_NUMBER AND A.PO_NO LIKE 'PB%' AND B.serial_number = DATA;         
         END;
         ELSE
          BEGIN   
               PB_NO_value:='NA';   
          END;

        END IF;

/*
      keyvalue1 := 'FXMG_';
      keyvalue2 := DATA || '_';
      keyvalue3 := models || '_';
      keyvalue4 := SUBSTR (VALUE, 15, 1);
      keyvalue5 :='_ICT';
      keyvalue6 := SUBSTR (VALUE, 19, 9);
      keyvalue7 := 'T'; 
      keyvalue8 := SUBSTR (VALUE, 28, 6) || 'Z';
      keyvalue9 := SUBSTR (VALUE, 34, 4);


      keyvalue := keyvalue1 ||PB_NO_value||'_'|| keyvalue3 || keyvalue2 || keyvalue4 || keyvalue5 || keyvalue6|| keyvalue7 || keyvalue8 || keyvalue9;

      --keyvalue := keyvalue1 || keyvalue3 || keyvalue2 || keyvalue4 || keyvalue5 || keyvalue6|| keyvalue7 || keyvalue8 || keyvalue9;   

       KK := keyvalue;
      --res := keyvalue;

*/
     --ADD BY 20250423 RUANSHIQIAO USER luoyang
      IF  (SUBSTR (mygroup, 0, 3) = 'ICT')
      THEN 
        IF mygroup = 'ICT_1'
            THEN c_group := 'FP_T';
            ELSIF mygroup = 'ICT_2'
            THEN c_group := 'FP_B';
            ELSE
                 c_group := 'ICT';

        END IF;

      keyvalue1 := 'FXMG_';
      keyvalue2 := DATA || '_';
      keyvalue3 := models || '_';
      keyvalue4 := SUBSTR (VALUE, 15, 1);
      keyvalue5 := '_' || c_group;
      keyvalue6 := SUBSTR (VALUE, 19, 9);
      keyvalue7 := 'T'; 
      keyvalue8 := SUBSTR (VALUE, 28, 6) || 'Z';
      keyvalue9 := SUBSTR (VALUE, 34, 4);  

      keyvalue := keyvalue1 ||PB_NO_value||'_'|| keyvalue3 || keyvalue2 || keyvalue4 || keyvalue5 || keyvalue6|| keyvalue7 || keyvalue8 || keyvalue9;
      KK := keyvalue;
      ELSE
      keyvalue1 := 'FXMG_';
      keyvalue2 := DATA || '_';
      keyvalue3 := models || '_';
      keyvalue4 := SUBSTR (VALUE, 15, 1);
      keyvalue5 := '_' || mygroup;
      keyvalue6 := SUBSTR (VALUE, 19, 9);
      keyvalue7 := 'T'; 
      keyvalue8 := SUBSTR (VALUE, 28, 6) || 'Z';
      keyvalue9 := SUBSTR (VALUE, 34, 4);

      --keyvalue := keyvalue1 || keyvalue3 || keyvalue2 || keyvalue4 || keyvalue5 || keyvalue6|| keyvalue7 || keyvalue8 || keyvalue9;

      keyvalue := keyvalue1 ||PB_NO_value||'_'|| keyvalue3 || keyvalue2 || keyvalue4 || keyvalue5 || keyvalue6|| keyvalue7 || keyvalue8 || keyvalue9;



      KK := keyvalue;
      --res := keyvalue;

      END IF;


       INSERT INTO sfism4.r_link_t
               (serial_number, key_value, available, flag, create_by,
                create_dt, last_edit_by, last_edit_dt, group_name
               )
        VALUES (DATA, KK, '0', 'LOGNAME', emp,
                sysdate, '', '', mygroup
               );


   ELSE   --ADD   BY     2020-01-08     luoyang



   INSERT INTO sfism4.r_link_t
               (serial_number, key_value, available, flag, create_by,
                create_dt, last_edit_by, last_edit_dt, group_name
               )
        VALUES (DATA, VALUE, '0', v_flag, emp,
                sysdate, '', '', mygroup
               );

   COMMIT;

   END  if ;
   res := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      res := 'OTHER ERROR ' || SUBSTR (SQLERRM, 1, 10) || '\n' || '**END**';
END;