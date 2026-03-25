PROCEDURE       sp_sap_dl_l6_packing_spec (
   i_plant_code       IN       VARCHAR2,
   i_part_no          IN       VARCHAR2,
   i_cust_no          IN       VARCHAR2,
   i_box_part_no      IN       VARCHAR2,
   i_box_qty          IN       NUMBER,
   
   i_box_weight       IN       NUMBER,
   i_box_weight_angle IN       NUMBER,
   i_box_length       IN       NUMBER,
   i_box_width        IN       NUMBER,
   i_box_height       IN       NUMBER,
   
   i_box_length_uint  IN       VARCHAR2,
   i_plt_part_no      IN       VARCHAR2,
   i_plt_weight       IN       NUMBER,
   i_plt_length       IN       NUMBER,
   i_plt_width        IN       NUMBER,
   
   i_layer            IN       NUMBER,
   i_plt_box_qty      IN       NUMBER,
   i_plt_weight_unit  IN       VARCHAR2,
   i_BLOCK_FLAG       IN       VARCHAR2,
   o_error_detail     OUT      VARCHAR2
   
)
IS
   --add by wangya 2023/03/30
   record_count       INTEGER;
   v_plant_code       VARCHAR2 (50);
   block_flag         VARCHAR2 (5);
   packing_cmd_code   VARCHAR2 (5);
   
BEGIN

   IF i_BLOCK_FLAG = 'X'
   THEN
      block_flag := 'Y';
   ELSE
      block_flag := 'N';
   END IF;

   SELECT COUNT (part_no)
     INTO record_count
     FROM sfis1.wip_s_l6_packing_spec
    WHERE  part_no =  i_part_no
      AND plant_code =  i_plant_code;    
    

   IF record_count > 0
   THEN
      o_error_detail :=
            'fail to update sfis1.wip_s_L6_packing_spec where PLANT_CODE='
         || i_plant_code
         || ',PART_NO='
         || i_part_no
         || ',updater='
         || 'System'
         || ',update_date'
         || sysdate||'.';
    
    
      UPDATE sfis1.wip_s_l6_packing_spec
         SET plant_code =  i_plant_code,
             part_no =  i_part_no,
             cust_no =  i_cust_no,
             BOX_PART_NO = i_box_part_no,
             STD_BOX_QTY =  i_box_qty,
             BOX_WEIGHT =  i_box_weight,
             BOX_WEIGHT_ANGLE =  i_box_weight_angle,
             BOX_LENGTH = i_box_length,
             BOX_WIDTH = i_box_width,
             BOX_HEIGHT = i_box_height,
             LENGTH_UOM =  i_box_length_uint,
             PLT_PART_NO =  i_plt_part_no,
             PLT_WEIGHT = i_plt_weight,
             PLT_LENGTH =  i_plt_length,
             PLT_WIDTH = i_plt_width,
             LAYER =  i_layer,
             STD_PLT_QTY =  i_plt_box_qty,
             WEIGHT_UOM =  i_plt_weight_unit,
             MIN_BOX_QTY = 1,
             BLOCK_FLAG = block_flag,
             updater = 'SYSTEM',
             update_date = SYSDATE,
             PARTS_WEIGHT= null  
       WHERE part_no = i_part_no
         AND plant_code = i_plant_code;  
         
   ELSE
      o_error_detail :=
            'fail to insert into sfis1.wip_s_L6_packing_spec where PLANT_CODE='
         || i_plant_code
         || ',PART_NO='
         || i_part_no
         || ',updater='
         || 'system'
         || ',update_date'
         || sysdate||'.';
    
   
      INSERT INTO sfis1.wip_s_l6_packing_spec
                  (PLANT_CODE,PART_NO,CUST_NO,BOX_PART_NO,
                  STD_BOX_QTY,BOX_WEIGHT,BOX_WEIGHT_ANGLE,BOX_LENGTH,
                  BOX_WIDTH,BOX_HEIGHT,LENGTH_UOM,PLT_PART_NO,
                  PLT_WEIGHT,PLT_LENGTH,PLT_WIDTH,LAYER,
                  STD_PLT_QTY,WEIGHT_UOM,MIN_BOX_QTY,BLOCK_FLAG,
                  CREATOR,CREATE_DATE,UPDATER,UPDATE_DATE,PARTS_WEIGHT
                  )
           VALUES (i_plant_code, i_part_no, i_cust_no,i_box_part_no,
                   i_box_qty, i_box_weight, i_box_weight_angle,i_box_length,
                   i_box_width, i_box_height, i_box_length_uint,i_plt_part_no,
                   i_plt_weight, i_plt_length, i_plt_width, i_layer,
                   i_plt_box_qty, i_plt_weight_unit,1, block_flag,
                   'SYSTEM', SYSDATE, 'SYSTEM', SYSDATE,null
                  );
   
   END IF;

       o_error_detail := 'OK';
   
EXCEPTION
   WHEN OTHERS
   THEN
      --o_error_detail:='sfis1.wip_s_L6_packing_spec:' || o_error_detail || SQLCODE;
      o_error_detail :=
         'sfis1.wip_s_L6_packing_spec:' || o_error_detail ||' '
         || SQLERRM;
END sp_sap_dl_l6_packing_spec;