PROCEDURE                   sp_nvd_f21_csn_send_to_b2b (
   i_cartonno   IN       VARCHAR2,
   i_dn_no      IN       VARCHAR2,
   i_custpo IN       VARCHAR2,
   i_pallet_no  IN       VARCHAR2,
   i_empno  IN       VARCHAR2,
   o_res        OUT      VARCHAR2
)
IS
   p_serial_number   VARCHAR2 (30);
   p_pallet_no         VARCHAR2 (30);
   p_carton_no        VARCHAR2 (30);
   p_work_date       VARCHAR2 (30);
 --  p_emp           VARCHAR2 (30);
   p_model_name      VARCHAR2 (30);
   p_mo_number       VARCHAR2 (30);

   v_asn_id          VARCHAR2 (50);

   T_PONO           VARCHAR2 (20);

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

   M_model_name      VARCHAR2 (30);
   M_pallet_no      VARCHAR2 (30);

   P_ALL_QTY       NUMBER;
   M_ACT_QTY       NUMBER;
   STR_PALLET_QTY       NUMBER;
   STR_CARTON_QTY       NUMBER;

   T_CUNIT_CODE3          VARCHAR2 (20);
   T_ITEM_NUMBER          VARCHAR2 (20);
   T_COSTPARTNUMBER          VARCHAR2 (20);
   T_VENDOR_PART         VARCHAR2 (20);
   T_UNIT_CODE1          VARCHAR2 (20);
   T_UNIT_CODE2          VARCHAR2 (20);
   T_Order_qty         NUMBER;
   T_BOL            VARCHAR2 (20);
   P_PACK           VARCHAR2 (20);
   P_SHIPEDQTY      VARCHAR2 (20);
   P_ACT_PALLET_QTY  NUMBER;

   T_PALLET_QTY       NUMBER;
   T_CARTON_QTY       NUMBER;

   CURSOR ssn_cur
   IS

     SELECT distinct(serial_number),model_name,carton_no  FROM sfism4.r_f21_pro_detail_t  WHERE carton_no = i_cartonno;


BEGIN
   o_res := 'THIS CARTON IS EXIST，CHECK PLEASE?';

     SELECT DISTINCT(MODEL_NAME) INTO p_model_name
     FROM sfism4.r_f21_pro_detail_t WHERE carton_no = i_cartonno  AND ROWNUM = 1;



   select count(distinct(pallet_no)) as act_pallet_qty 

    into P_ACT_PALLET_QTY from sfism4.r_f21_pro_detail_t where PONO=i_custpo;



  SELECT PONO,PGROSS_WEIGHT,PUNIT_CODE1,PGROSS_VOLUME,ITEM_NUMBER,

          PUNIT_CODE2,PLENGTH,PWIDTH,PHEIGHT,PUNIT_CODE3,CGROSS_WEIGHT,CUNIT_CODE1,CGROSS_VOLUME,     

          CUNIT_CODE2,CLENGTH, CWIDTH, CHEIGHT,           

          CUNIT_CODE3,COSTPARTNUMBER,VENDOR_PART,UNIT_CODE1,UNIT_CODE2,SUM(ORDERED_QTY) AS ORDERED_QTY,BOL_NR,PALLET_QTY,CARTON_QTY            

       INTO T_PONO,T_PGROSS_WEIGHT,T_PUNIT_CODE1,T_GROSS_VOLUME,T_ITEM_NUMBER,

           T_PUNIT_CODE2,T_PLENGTH,T_PWIDTH,T_PHEIGHT,T_PUNIT_CODE3,T_CGROSS_WEIGHT,T_CUNIT_CODE1,T_CGROSS_VOLUME,

           T_CUNIT_CODE2,T_CLENGTH,T_CWIDTH,T_CHEIGHT,

           T_CUNIT_CODE3,T_COSTPARTNUMBER,T_VENDOR_PART,T_UNIT_CODE1,T_UNIT_CODE2,T_Order_qty,T_BOL,T_PALLET_QTY,T_CARTON_QTY

         FROM SFISM4.B2B_D_HEAD WHERE PONO=i_custpo AND MODEL_NAME=p_model_name GROUP BY PONO,PGROSS_WEIGHT,PUNIT_CODE1,PGROSS_VOLUME,ITEM_NUMBER,

          PUNIT_CODE2,PLENGTH,PWIDTH,PHEIGHT,PUNIT_CODE3,CGROSS_WEIGHT,CUNIT_CODE1,CGROSS_VOLUME,     

          CUNIT_CODE2,CLENGTH, CWIDTH, CHEIGHT,           

          CUNIT_CODE3,COSTPARTNUMBER,VENDOR_PART,UNIT_CODE1,UNIT_CODE2,BOL_NR,PALLET_QTY,CARTON_QTY; 


   o_res := 'Open Cursor Error.';

   OPEN ssn_cur;

   FETCH ssn_cur INTO p_serial_number,p_model_name,p_carton_no;


   WHILE ssn_cur%FOUND
   LOOP

       select count(distinct(carton_no)) into P_PACK from sfism4.r_f21_pro_detail_t where pallet_no in 
       (select pallet_no from sfism4.r_f21_pro_detail_t where serial_number=p_serial_number );   


       select count(distinct(SERIAL_NUMBER)) into P_SHIPEDQTY from sfism4.r_f21_pro_detail_t where CARTON_NO in 
       (select CARTON_NO from sfism4.r_f21_pro_detail_t where serial_number=p_serial_number );


        select A.MODEL_NAME,B.PALLET_NO,A.PALLET_QTY,A.CARTON_QTY,(A.PALLET_QTY*A.CARTON_QTY) AS P_QTY,B.ACT_QTY INTO M_model_name,M_pallet_no,STR_PALLET_QTY,STR_CARTON_QTY,P_ALL_QTY,M_ACT_QTY 
           from sfism4.b2b_d_head A,
             (
          select MODEL_NAME,PALLET_NO, COUNT(*) AS ACT_QTY from sfism4.r_f21_pro_detail_t where PALLET_NO in 
          (select PALLET_NO from sfism4.r_f21_pro_detail_t where serial_number=p_serial_number) GROUP BY MODEL_NAME,PALLET_NO

          ) B WHERE A.MODEL_NAME=B.MODEL_NAME AND A.dn=i_dn_no AND ROWNUM=1;

         IF P_ALL_QTY=M_ACT_QTY
          THEN
              p_pallet_no := i_pallet_no;
           ELSE
              IF (M_ACT_QTY>=4*STR_CARTON_QTY) AND (M_ACT_QTY<P_ALL_QTY)
               THEN
                p_pallet_no := i_pallet_no;
              ELSE

              p_pallet_no := 'NP'||SUBSTR(i_pallet_no,3,10);
              END IF;

        END IF;


        o_res := 'Insert  SFISM4.B2B_D_DETAIL Error';


          Insert into SFISM4.B2B_D_DETAIL_T

        (DN,COSTPART_NUMBER,PONO,PO_DATE,AGREEMENT_ID,PGROSS_WEIGHT,PUNIT_CODE1,PGROSS_VOLUME,PUNIT_CODE2,PLENGTH, PWIDTH, PHEIGHT,     --11111

            PUNIT_CODE3,PCONTAINER_CODE,PGLOBAL_INDIVIDUAL_ASSET_ID,PACK, CGROSS_WEIGHT,                               --22222

            CUNIT_CODE1,CGROSS_VOLUME,CUNIT_CODE2,CLENGTH,CWIDTH, CHEIGHT,CUNIT_CODE3,CCONTAINER_CODE,CGLOBAL_INDIVIDUAL_ASSET_ID,           --33333

            ITEM_NUMBER,VENDOR_PART,SERIALNO,SERIAL_QTY,UNIT_CODE1,EMPNO,ORDERED_QTY,BOL_NR,STD_PALLET_QTY,STD_CARTON_QTY,ACT_PALLET_QTY,

            LASTEDITDT)                                --44444      

          Values

           (i_dn_no,p_model_name,T_PONO,TO_CHAR(sysdate,'YYYYMMDD'),T_PONO,T_PGROSS_WEIGHT,T_PUNIT_CODE1,T_GROSS_VOLUME,T_PUNIT_CODE2,T_PLENGTH,T_PWIDTH,T_PHEIGHT,   --1111111

             T_PUNIT_CODE3,p_pallet_no,p_pallet_no, P_PACK, T_CGROSS_WEIGHT,

             T_CUNIT_CODE1,T_CGROSS_VOLUME,T_CUNIT_CODE2,T_CLENGTH,T_CWIDTH,T_CHEIGHT,T_CUNIT_CODE3,p_carton_no,p_carton_no,    

             TO_NUMBER(T_ITEM_NUMBER),T_VENDOR_PART,p_serial_number,P_SHIPEDQTY,T_UNIT_CODE1,i_empno,T_Order_qty,T_BOL,T_PALLET_QTY,T_CARTON_QTY,P_ACT_PALLET_QTY,         

             SYSDATE );          

      FETCH ssn_cur
       INTO p_serial_number,p_model_name,p_carton_no;

   END LOOP;

   CLOSE ssn_cur;

   o_res := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      o_res := o_res;
      ROLLBACK;
END;