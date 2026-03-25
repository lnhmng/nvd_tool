PROCEDURE                   sp_get_mellanox_b2b_detail (
   i_cartonno   IN       VARCHAR2,
   i_dn_no      IN       VARCHAR2,
   i_INVOICE_NO IN       VARCHAR2,
   o_res        OUT      VARCHAR2
)
IS
   p_serial_number   VARCHAR2 (30);
   p_pallet_no         VARCHAR2 (30);
   p_carton_no        VARCHAR2 (30);
   p_work_date       VARCHAR2 (30);
   p_emp           VARCHAR2 (30);
   p_model_name      VARCHAR2 (30);
   p_mo_number       VARCHAR2 (30);

   v_asn_id          VARCHAR2 (50);

   T_PONO           VARCHAR2 (20);
 --  T_PO_DATE           VARCHAR2 (20);

   T_PGROSS_WEIGHT           VARCHAR2 (20);
   T_PUNIT_CODE1           VARCHAR2 (20);
   T_GROSS_VOLUME           VARCHAR2 (20);

   T_PUNIT_CODE2           VARCHAR2 (20);
   T_PLENGTH           VARCHAR2 (20);
   T_PWIDTH           VARCHAR2 (20);
   T_PHEIGHT          VARCHAR2 (20);
   T_PUNIT_CODE3          VARCHAR2 (20);
   T_CGROSS_WEIGHT          VARCHAR2 (20);
   T_CUNIT_CODE1          VARCHAR2 (20);
   T_CGROSS_VOLUME          VARCHAR2 (20);


   T_CUNIT_CODE2          VARCHAR2 (20);
   T_CLENGTH         VARCHAR2 (20);
   T_CWIDTH          VARCHAR2 (20);
   T_CHEIGHT          VARCHAR2 (20);

   T_CUNIT_CODE3          VARCHAR2 (20);
   T_ITEM_NUMBER          VARCHAR2 (20);
   T_COSTPARTNUMBER          VARCHAR2 (20);
   T_VENDOR_PART         VARCHAR2 (20);
   T_UNIT_CODE1          VARCHAR2 (20);
   T_UNIT_CODE2          VARCHAR2 (20);   

   M_model_name      VARCHAR2 (30);
   M_pallet_no      VARCHAR2 (30);
   P_ALL_QTY       NUMBER;
   M_ACT_QTY       NUMBER;

   STR_PALLET_QTY       NUMBER;
   STR_CARTON_QTY       NUMBER;

   p_add_sn   VARCHAR2 (30);
   
   T_Order_qty         NUMBER;
   T_BOL            VARCHAR2 (20);

   P_PACK           VARCHAR2 (20);
   P_SHIPEDQTY      VARCHAR2 (20);
   P_ACT_PALLET_QTY  NUMBER;

   T_PALLET_QTY       NUMBER;
   T_CARTON_QTY       NUMBER;

   CURSOR ssn_cur
   IS
      SELECT distinct(a.serial_number),a.mo_number,a.spare_model_name,a.pallet_no,a.carton_no,a.emp_no
                 FROM sfism4.r_wip_tracking_t a, sfis1.c_model_desc_t b
                WHERE a.model_name = b.model_name              
                  AND a.carton_no = i_cartonno;

BEGIN
   o_res := 'THIS CARTON IS EXIST，CHECK PLEASE?';

   SELECT a.spare_model_name--b.MODEL_NAME
     INTO p_model_name
     FROM sfism4.r_wip_tracking_t a, sfism4.r_mo_base_t b
      WHERE a.mo_number = b.mo_number AND a.carton_no = i_cartonno AND ROWNUM = 1;


  -- select count(distinct(pallet_no)) as act_pallet_qty 

  -- into P_ACT_PALLET_QTY from sfism4.r_ship_detail_t where dn_no=i_dn_no;

     select count(distinct(pallet_no)) as act_pallet_qty 

      into P_ACT_PALLET_QTY from sfism4.r_wip_tracking_t where CONTAINER_NO in (select CONTAINER_NO from sfism4.r_shipping_t where po_number=i_dn_no);


  SELECT PONO,PGROSS_WEIGHT,PUNIT_CODE1,PGROSS_VOLUME,

           PUNIT_CODE2,PLENGTH,PWIDTH,PHEIGHT,PUNIT_CODE3,CGROSS_WEIGHT,CUNIT_CODE1,CGROSS_VOLUME,     

           CUNIT_CODE2,CLENGTH, CWIDTH, CHEIGHT,           

           CUNIT_CODE3,COSTPARTNUMBER,VENDOR_PART,UNIT_CODE1,UNIT_CODE2,SUM(ORDERED_QTY) AS ORDERED_QTY,BOL_NR,PALLET_QTY,CARTON_QTY            

           INTO T_PONO,T_PGROSS_WEIGHT,T_PUNIT_CODE1,T_GROSS_VOLUME,

           T_PUNIT_CODE2,T_PLENGTH,T_PWIDTH,T_PHEIGHT,T_PUNIT_CODE3,T_CGROSS_WEIGHT,T_CUNIT_CODE1,T_CGROSS_VOLUME,

           T_CUNIT_CODE2,T_CLENGTH,T_CWIDTH,T_CHEIGHT,

           T_CUNIT_CODE3,T_COSTPARTNUMBER,T_VENDOR_PART,T_UNIT_CODE1,T_UNIT_CODE2,T_Order_qty,T_BOL,T_PALLET_QTY,T_CARTON_QTY

         FROM SFISM4.B2B_D_HEAD WHERE DN=i_dn_no AND SAP_PN=p_model_name GROUP BY PONO,PGROSS_WEIGHT,PUNIT_CODE1,PGROSS_VOLUME,

           PUNIT_CODE2,PLENGTH,PWIDTH,PHEIGHT,PUNIT_CODE3,CGROSS_WEIGHT,CUNIT_CODE1,CGROSS_VOLUME,     

           CUNIT_CODE2,CLENGTH, CWIDTH, CHEIGHT,           

           CUNIT_CODE3,COSTPARTNUMBER,VENDOR_PART,UNIT_CODE1,UNIT_CODE2,BOL_NR,PALLET_QTY,CARTON_QTY; 


    o_res := 'Open Cursor Error.';

   OPEN ssn_cur;

   FETCH ssn_cur INTO p_serial_number,p_mo_number,p_model_name,p_pallet_no, p_carton_no, p_emp;


   WHILE ssn_cur%FOUND
   LOOP


       select count(distinct(carton_no)) into P_PACK from sfism4.r_wip_tracking_t where pallet_no in 
       (select pallet_no from sfism4.r_wip_tracking_t where serial_number=p_serial_number );       

       select count(distinct(SERIAL_NUMBER)) into P_SHIPEDQTY from sfism4.r_wip_tracking_t where CARTON_NO in 
       (select CARTON_NO from sfism4.r_wip_tracking_t where serial_number=p_serial_number );

        SELECT  CASE WHEN LENGTH(SERIAL_NUMBER)>=18 THEN ADD_SN    
            ELSE SERIAL_NUMBER END AS ADD_SN2 
           into p_add_sn            
         FROM SFISM4.R_WIP_TRACKING_T WHERE serial_number=p_serial_number;
       
       SELECT ITEM_NUMBER into T_ITEM_NUMBER  FROM  sfism4.b2b_d_head  WHERE DN=i_dn_no AND SAP_PN=p_model_name AND ROWNUM = 1;

     
     --   select SAP_PN,B.PALLET_NO,PALLET_QTY,CARTON_QTY,(PALLET_QTY*CARTON_QTY) AS P_QTY,B.ACT_QTY INTO M_model_name,M_pallet_no,STR_PALLET_QTY,STR_CARTON_QTY,P_ALL_QTY,M_ACT_QTY 
     --      from sfism4.b2b_d_head A,
     --     (select SPARE_MODEL_NAME,PALLET_NO, COUNT(*) AS ACT_QTY from sfism4.r_wip_tracking_t where pallet_no in 
     --   (select pallet_no from sfism4.r_wip_tracking_t where serial_number=p_serial_number) GROUP BY SPARE_MODEL_NAME,PALLET_NO
     --     ) B WHERE A.SAP_PN=B.SPARE_MODEL_NAME AND A.dn=i_dn_no AND ROWNUM=1;

     --   IF P_ALL_QTY=M_ACT_QTY
     --     THEN
     --        p_pallet_no := M_pallet_no;
     --      ELSE
     --         IF (M_ACT_QTY>=4*STR_CARTON_QTY) AND (M_ACT_QTY<P_ALL_QTY)
     --          THEN
     --           p_pallet_no := M_pallet_no;
     --         ELSE

     --         p_pallet_no := 'NP'||SUBSTR(M_pallet_no,3,10);
     --        END IF;

     --   END IF;

      o_res := 'Insert  SFISM4.B2B_D_DETAIL Error';


        Insert into SFISM4.B2B_D_DETAIL_T

        (DN,COSTPART_NUMBER,PONO,PO_DATE,AGREEMENT_ID,PGROSS_WEIGHT,PUNIT_CODE1,PGROSS_VOLUME,PUNIT_CODE2,PLENGTH, PWIDTH, PHEIGHT,        --11111

            PUNIT_CODE3,PCONTAINER_CODE,PGLOBAL_INDIVIDUAL_ASSET_ID,PACK, CGROSS_WEIGHT,                                                    --22222

            CUNIT_CODE1,CGROSS_VOLUME,CUNIT_CODE2,CLENGTH,CWIDTH, CHEIGHT,CUNIT_CODE3,CCONTAINER_CODE,CGLOBAL_INDIVIDUAL_ASSET_ID,           --33333

            ITEM_NUMBER,VENDOR_PART,SERIALNO,SERIAL_QTY,UNIT_CODE1,EMPNO,ORDERED_QTY,BOL_NR,STD_PALLET_QTY,STD_CARTON_QTY,ACT_PALLET_QTY,

            LASTEDITDT)                                --44444      
          Values

           (i_dn_no,p_model_name,i_INVOICE_NO,TO_CHAR(sysdate,'YYYYMMDD'),i_INVOICE_NO,T_PGROSS_WEIGHT,T_PUNIT_CODE1,T_GROSS_VOLUME,T_PUNIT_CODE2,T_PLENGTH,T_PWIDTH,T_PHEIGHT,   --1111111

             T_PUNIT_CODE3,p_pallet_no,p_pallet_no, P_PACK, T_CGROSS_WEIGHT,                                                                                           --22222222

              T_CUNIT_CODE1,T_CGROSS_VOLUME,T_CUNIT_CODE2,T_CLENGTH,T_CWIDTH,T_CHEIGHT,T_CUNIT_CODE3,p_carton_no,p_carton_no,    

              TO_NUMBER(T_ITEM_NUMBER),T_VENDOR_PART,p_add_sn,P_SHIPEDQTY,T_UNIT_CODE1,p_emp,T_Order_qty,T_BOL,T_PALLET_QTY,T_CARTON_QTY,P_ACT_PALLET_QTY,         

              SYSDATE );          

      FETCH ssn_cur
       INTO p_serial_number,p_mo_number,p_model_name,p_pallet_no, p_carton_no, p_emp;

   END LOOP;

   CLOSE ssn_cur;

   o_res := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      o_res := o_res;
      ROLLBACK;
END;