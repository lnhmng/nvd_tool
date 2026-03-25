PROCEDURE                         check_smt_linkmes
                                                    --Added by Alex Wang on 010/03/03 for 1HWT-100226-01 Begin
(
   DATA   IN       VARCHAR2,
   res    OUT      VARCHAR2
)
AS
   count1      NUMBER;
   count2      NUMBER;
   count3      NUMBER;
   count4      NUMBER;
   count5      NUMBER;
   count6      NUMBER;
   count7      NUMBER;
   sncnt       NUMBER;
   mncnt       NUMBER;
   vncnt       NUMBER;
   p_barcode   VARCHAR2 (32);
   v_barcode   VARCHAR2 (32);
   v_oldsn     VARCHAR2 (32);
   v_pkg       VARCHAR2 (32);
   h_pkg       VARCHAR2 (32);           --  bigSN  in SFISM4.R_PCB_DATECODE_T
   c_model     VARCHAR2 (32);
   e_null      EXCEPTION;
BEGIN
   SELECT model_name
     INTO c_model
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = DATA;

	v_oldsn := substr(c_model,1,3);

	SELECT COUNT(*)						-- add model_name prefix check , if exist, return OK . --Liujiang20211130
	  INTO count1
	  from sfis1.C_PARAMETER_INI a 
	 where a.PRG_NAME ='CMC' AND A.VR_CLASS='PCB_CHECK' and upper(a.VR_ITEM)='MODEL_PREFIX' 
           AND A.VR_VALUE = v_oldsn ;

	if count1 > 0
	then
		res := 'OK';
	else

	   SELECT COUNT (*)
		 INTO mncnt
		 FROM sfis1.c_model_desc_t
		WHERE model_name = c_model AND bom_no = '6';

	   IF mncnt > 0
	   THEN
		  SELECT COUNT (*)
			INTO vncnt
			FROM sfism4.r_sn_link_t
		   WHERE new_sn = DATA;

		  IF vncnt > 0
		  THEN
			 SELECT init_sn
			   INTO v_barcode
			   FROM sfism4.r_sn_link_t
			  WHERE new_sn = DATA AND ROWNUM = 1;

			 SELECT COUNT (*)
			   INTO count7
			   FROM sfism4.r_pcb_datecode_t
			  WHERE serial_number = v_barcode;

			 IF count7 > 0
			 THEN
				res := 'OK';
			 ELSE
				res := 'error4:' || v_barcode || 'NO SMT INFORMATION';
				RAISE e_null;
			 END IF;
		  ELSE
			 res := 'error3: ' || v_barcode || 'NO BARCODE LINK';
			 RAISE e_null;
		  END IF;
	   ELSE
			--------- Check SN whether exist  pcb_open mesaagae
		  SELECT COUNT (*)
			INTO count1
			FROM sfism4.r_pcb_datecode_t
		   WHERE serial_number = DATA;

			--- for  with  s_link station
		  IF count1 < 1
		  THEN
				--      SELECT COUNT (*)
				--        INTO count2
				--        FROM sfism4.r_pcb_datecode_t
				--       WHERE serial_number = DATA AND pkg_id LIKE 'N%';

						 -----------check sn whether exist  link message in s_link
				--      IF count2 < 1
				--      THEN
			 SELECT COUNT (*)
			   INTO sncnt
			   FROM sfism4.r_sn_link_t
			  WHERE new_sn = DATA;

			 IF sncnt = 0
			 THEN                                     --The SN haven't been linked
				p_barcode := DATA;
				res := 'error1: ' || p_barcode || 'NO BARCODE LINK';
				RAISE e_null;
			 ELSE
				SELECT init_sn
				  INTO p_barcode
				  FROM sfism4.r_sn_link_t
				 WHERE new_sn = DATA AND ROWNUM = 1;

				SELECT COUNT (*)
				  INTO count5
				  FROM sfism4.r_pcb_datecode_t
				 WHERE serial_number = p_barcode;

				IF count5 > 0
				THEN
				   res := 'OK';
				ELSE
				   res := 'error2:' || p_barcode || 'NO SMT INFORMATION';
				   RAISE e_null;
				END IF;
			 END IF;
			 --The SN have been linked
			 --ELSE
			 -- res := 'OK';
			 -- end if;
		   ELSE
				------- for  without s_link station using barcord_link  to  bing mes;
			 res := 'OK';
			END IF;
		END IF;	

	end if;

EXCEPTION
   WHEN e_null
   THEN
      NULL;
END;