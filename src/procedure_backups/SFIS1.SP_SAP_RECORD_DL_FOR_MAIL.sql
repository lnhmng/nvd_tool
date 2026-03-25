PROCEDURE       sp_sap_record_dl_for_mail (
   i_plantid        IN       VARCHAR2,
   i_functionname   IN       VARCHAR2,
   i_pktype         IN       VARCHAR2,
   i_pk             IN       VARCHAR2,
   i_faileddesc     IN       VARCHAR2,
   i_op_id          IN       VARCHAR2,
   o_error_detail   OUT      VARCHAR2
)
AS
   v_record_count   INTEGER;
BEGIN
   SELECT COUNT (0)
     INTO v_record_count
     FROM sfism4.wip_d_mail_master
    WHERE plant_id = i_plantid
      AND function_name = i_functionname
      AND pk_type = i_pktype
      AND pk = i_pk
      AND failed_desc = i_faileddesc;
      --AND send_mail_status = '1';

   IF v_record_count < 1
   THEN
      o_error_detail :=
            'Insert error,plant_id:'
         || i_plantid
         || ',function_name:'
         || i_functionname
         || ',pk_type:'
         || i_pktype
         || ',pk:'
         || i_pk
         || ',failed_desc:'
         || i_faileddesc;

      INSERT INTO sfism4.wip_d_mail_master
                  (plant_id, function_name, pk_type, pk, send_mail_status,
                   send_mail_count, failed_time, failed_desc, OPERATOR,mail_batch
                  )
           VALUES (i_plantid, i_functionname, i_pktype, i_pk, '0',
                   0, SYSDATE, i_faileddesc, i_op_id,'N/A'
                  );
   ELSE 

      o_error_detail :=
            'Update error,plant_id:'
         || i_plantid
         || ',function_name:'
         || i_functionname
         || ',pk_type:'
         || i_pktype
         || ',pk:'
         || i_pk
         || ',failed_desc:'
         || i_faileddesc;

      UPDATE sfism4.wip_d_mail_master
         SET send_mail_status = '0',
             failed_time = SYSDATE,
             mail_batch = 'N/A',
             OPERATOR = i_op_id
       WHERE plant_id = i_plantid
         AND function_name = i_functionname
         AND pk_type = i_pktype
         AND pk = i_pk
         AND failed_desc = i_faileddesc
         AND send_mail_status = '1';
   END IF;
   o_error_detail := '';
EXCEPTION
   WHEN OTHERS
   THEN
      o_error_detail :=
                      'sp_sap_record_dl_for_mail:' + o_error_detail||'['||sqlerrm||']';
END;
