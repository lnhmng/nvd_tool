PROCEDURE       sp_wip_spot_check (
   mygroup   IN       VARCHAR2,
   DATA      IN       VARCHAR2,
   line      IN       VARCHAR2,
   emp       IN       VARCHAR2,
   ec        IN       VARCHAR2,
   res       OUT      VARCHAR2
)
IS
   v_count     NUMBER;
   v_qty       NUMBER;
   v_flag      VARCHAR2 (5);
   v_mo        VARCHAR2 (30);
   v_model     VARCHAR2 (30);
   v_rev       VARCHAR2 (20);
   v_type      VARCHAR2 (15);
   v_station   VARCHAR2 (16);
   v_apart     VARCHAR2 (16);
   v_jump      VARCHAR2 (16);
   v_route     VARCHAR2 (10);
   v_next      VARCHAR2 (16);
   v_rate      FLOAT;
   v_pcs       NUMBER;
   v_before    NUMBER;
   v_finish    NUMBER;
   v_target    NUMBER;
   v_model_flag      VARCHAR2 (1);
   v_mo_flag         VARCHAR2 (1);
   v_qty_motest      NUMBER;
BEGIN
   v_count := 0;

   v_model_flag :='N';  --按料號
   v_mo_flag :='N';     --按工單

   IF TRIM (ec) IS NOT NULL AND TRIM (ec) <> 'N/A'      --有 有效值，不處理。無 有效值，處理
   THEN
      res := 'OK';
      RETURN;
   END IF;

   BEGIN
      SELECT error_flag, mo_number, model_name, version_code, special_route
        INTO v_flag, v_mo, v_model, v_rev, v_route
        FROM sfism4.r_wip_tracking_t
       WHERE serial_number = DATA AND ROWNUM = 1;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         res := 'SN Not Exist ';
         RETURN;
   END;

/*  -- 不檢查,由上面ec參數決定，方便外部決定何時重置next_station  --20220210
--  檢查SN是否不良
   IF v_flag <> '0'
   THEN
      res := 'SN is Badness';
      RETURN;
   END IF;
*/

--  檢查是否是需要抽檢的料號版次及線別   抽測詳細標準
   BEGIN
      SELECT rate, from_pcs, test_station, apart_station ,normal_station
        INTO v_rate, v_pcs, v_station, v_apart ,v_jump
        FROM sfis1.wip_s_test_model_detail
       WHERE test_line IN ('ALL', line)
         AND model_name = v_model
         AND version_code = v_rev
         AND ROWNUM = 1;

      v_model_flag :='Y';

   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_model_flag :='N';
         res := 'OK';
         --RETURN;                 
   END;

   SELECT mo_type, target_qty
     INTO v_type, v_qty
     FROM sfism4.r_mo_base_t
    WHERE mo_number = v_mo AND ROWNUM = 1;

/*  -- 不檢查 --20220124
--  檢查是否待抽檢工令類型
   SELECT COUNT (0)
     INTO v_count
     FROM sfis1.wip_s_test_wo_type
    WHERE model_name = v_model AND version_code = v_rev AND mo_type = v_type;    

   IF v_count = 0
   THEN
      res := 'OK';
      RETURN;
   END IF;
   */

--  檢查是否是需要抽檢的工單及類型   抽測詳細標準
   if v_model_flag ='N'
   THEN   
       BEGIN
        SELECT test_pcs, from_pcs, test_station, apart_station ,normal_station
          INTO v_qty_motest, v_pcs, v_station, v_apart ,v_jump
          FROM sfis1.wip_s_test_mo_detail
         WHERE test_line IN ('ALL',line)
           AND mo_number in ('ALL',v_mo)
           AND mo_type IN ('ALL',v_type)
           AND MO_LOW_LIMIT <=v_qty AND v_qty<=MO_UP_LIMIT
           AND ROWNUM = 1 ;

          v_mo_flag :='Y' ;

       EXCEPTION
          WHEN NO_DATA_FOUND
          THEN
             v_mo_flag :='N';
             res := 'OK';             
             RETURN;
       END;

   end if;


   BEGIN
      SELECT group_next
        INTO v_next
        FROM sfis1.c_route_control_t
       WHERE group_next <> v_station
         AND state_flag = '0'
         AND group_name = mygroup
         AND route_code = v_route
         AND ROWNUM = 1;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         res := 'Route Error!';
         RETURN;
   END;

   IF v_station = mygroup
   THEN
      res := 'Update Next Station Failed! ';

      UPDATE sfism4.r_wip_tracking_t
         SET next_station = 'N/A'
       WHERE serial_number = DATA;

      res := 'OK';
      RETURN;
   /**********  抽檢工站出口  ***********/
   END IF;

   IF v_jump = mygroup
   THEN
      res := 'Update Next Station Failed! ';

      UPDATE sfism4.r_wip_tracking_t
         SET next_station = 'N/A'
       WHERE serial_number = DATA;

      res := 'OK';
      RETURN;
   /**********  跳躍工站出口  ***********/
   END IF;   

   --  檢查是否已經開始抽檢
   SELECT COUNT (0)
     INTO v_count
     FROM sfis1.wip_s_test_current_status
    WHERE mo_number = v_mo;

   IF v_count = 0
   THEN
-- 抽檢工令第一片初始化狀態表
      --v_qty := CEIL (v_qty * v_rate);      
      if v_model_flag ='Y'
      then
        v_qty := CEIL (v_qty * v_rate);     --工單目標數量 * 比例
      else
        v_qty := v_qty_motest;              --工單目標數量不同階段，指定抽測數量
      end if;

      res := 'insert status table failed';

      INSERT INTO sfis1.wip_s_test_current_status
                  (mo_number, before_qty, finish_qty, target_qty,
                   update_emp, update_time, finish_flag
                  )
           VALUES (v_mo, v_pcs, 0, v_qty,
                   emp, SYSDATE, 'N'
                  );
   END IF;

   SELECT finish_flag, before_qty, finish_qty, target_qty
     INTO v_flag, v_before, v_finish, v_target
     FROM sfis1.wip_s_test_current_status
    WHERE mo_number = v_mo;

-- 工令抽檢完成,退出
   IF v_flag = 'Y'
   THEN
--  非v_station(抽檢工站),非v_apart(分板工站),則置為'N/A'
      IF mygroup <> v_apart
      THEN
         /**********  正常下一工站出口 ************/
         UPDATE sfism4.r_wip_tracking_t
            SET next_station = 'N/A'
          WHERE serial_number = DATA;
      ELSE
         /**********  抽檢完成的分板工站出口  ************/
         UPDATE sfism4.r_wip_tracking_t
            SET next_station = v_next
          WHERE serial_number = DATA;
      END IF;

      res := 'OK';
      RETURN;
   END IF;

   IF (v_finish = 0) AND (v_before >= 1)
   THEN
      UPDATE sfism4.r_wip_tracking_t
         SET next_station = v_next
       WHERE serial_number = DATA;

--  起抽數量未完則-1 退出;
      UPDATE sfis1.wip_s_test_current_status
         SET before_qty = before_qty - 1
       WHERE mo_number = v_mo;

      res := 'OK';
      RETURN;
   ELSE
--  去抽檢,更新next_station ,完成數量+1;
      UPDATE sfism4.r_wip_tracking_t
         SET next_station = v_station
       WHERE serial_number = DATA;

      UPDATE sfis1.wip_s_test_current_status
         SET finish_qty = finish_qty + 1,
             update_emp = emp,
             update_time = SYSDATE
       WHERE mo_number = v_mo;
   END IF;

--  如果抽檢完成,更新完成標志 FINISHU_FLAG = 'Y';
   UPDATE sfis1.wip_s_test_current_status
      SET finish_flag = 'Y'
    WHERE finish_qty >= target_qty AND mo_number = v_mo;

   /**********  抽檢未完成的分板工站出口  ************/
   res := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      res := 'Exception: ' || res;
END;
