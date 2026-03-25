PROCEDURE       sp_rollback_cwo (
   i_instore_scan_type   IN       VARCHAR2,
   i_cwo_batch           IN       VARCHAR2,
   i_pallet_no           IN       VARCHAR2,
   i_erp_wo              IN       VARCHAR2,
   i_sap_error           IN       VARCHAR2,
                                  --add by jean 11/06/10 for sap error message
   o_res                 OUT      VARCHAR2
)
IS
   sqls   VARCHAR2 (1000);

   /* 
 NAME:       sfis1.sp_rollback_cwo?
 PURPOSE:    ROLLBACK cwo data

  REVISIONS:
  TaskID           Ver        Date        Author           Description
   -------------------------------------------------------------
  xxxxxxxx     ??(1.0)   ??(2011/06/10)  Jean               ??
*/

BEGIN
   o_res := 'Rollback cwo failed!';
   sqls :=
         'update sfism4.wip_d_cwo_sn set cwo_flag = 0,cwo_batch =''N/A'' where 1=1 AND ERP_WO='''
      || TRIM (i_erp_wo)
      || '''';

   IF i_instore_scan_type = 'PPID'
   THEN
      sqls :=
            sqls || ' and sysserialno= ' || '''' || TRIM (i_pallet_no)
            || '''';
   END IF;

   IF i_instore_scan_type = 'PALLET'
   THEN
      sqls := sqls || ' and pallet_no= ' || '''' || TRIM (i_pallet_no)
              || '''';
   END IF;

   IF i_instore_scan_type = 'CARTON' OR i_instore_scan_type = 'POCARTON'
   THEN
      sqls := sqls || ' and carton_no= ' || '''' || TRIM (i_pallet_no)
              || '''';
   END IF;

   sqls := sqls || ' and cwo_batch= ' || '''' || TRIM (i_cwo_batch) || '''';

   EXECUTE IMMEDIATE sqls;

--add by jean 11/06/10 for sap error message begin
   INSERT INTO sfism4.wip_d_cwo_faillist
               (plant_code, erp_wo, part_no, qty, cwo_batch, cpo_no,
                pallet_no, creator, cwo_type, instore_scan_type, whid,
                sap_error_info)
      SELECT plant_code, erp_wo, part_no, qty, cwo_batch, cpo_no, pallet_no,
             creator, cwo_type, instore_scan_type, whid, i_sap_error
        FROM sfism4.wip_d_cwo_partlist
       WHERE cwo_batch = i_cwo_batch
         AND pallet_no = i_pallet_no
         AND erp_wo = i_erp_wo;

--add by jean 11/06/10 for sap error message end
   DELETE FROM sfism4.wip_d_cwo_partlist
         WHERE cwo_batch = i_cwo_batch
           AND pallet_no = i_pallet_no
           AND erp_wo = i_erp_wo;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      --o_res := 'sp_upload_cwo error';
      o_res := SQLCODE || SQLERRM;
END;
