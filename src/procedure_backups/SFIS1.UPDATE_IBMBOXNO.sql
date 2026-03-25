PROCEDURE update_IBMBoxNo (vimodel_name IN VARCHAR2,nipackQty IN number,RES OUT VARCHAR2)
AS
   	p_tqty        number(8);
	p_pqty        number(8);

BEGIN
    select total_qty,packing_qty into p_tqty,p_pqty from sfism4.r_ship_to_t
	         where model_name=vimodel_name and sort_no =
			 (select min(sort_no) from sfism4.r_ship_to_t where model_name=vimodel_name and close_flag=0);
	if p_tqty>p_pqty+nipackQty then
	    update sfism4.r_ship_to_t set packing_box_qty=packing_box_qty+1,
             packing_qty=packing_qty+nipackQty where model_name=vimodel_name and sort_no =
			 (select min(sort_no) from sfism4.r_ship_to_t where model_name=vimodel_name and close_flag=0);
	else
	    update sfism4.r_ship_to_t set packing_box_qty=packing_box_qty+1,close_flag=1,
             packing_qty=packing_qty+nipackQty where model_name=vimodel_name and sort_no =
			 (select min(sort_no) from sfism4.r_ship_to_t where model_name=vimodel_name and close_flag=0);
	end if;
	commit;
	res:='OK';
exception
   when others then
      RES :='SP Error';
END;
