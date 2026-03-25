PROCEDURE             npi_check (
   line      IN       VARCHAR2,
   mygroup   IN       VARCHAR2,
   DATA      IN       VARCHAR2,
   res       OUT      VARCHAR2
)
AS
   group_name        VARCHAR (20);
   line_name         VARCHAR (10);
   sn1               VARCHAR (20);
   sn_count1         VARCHAR (20);
   station           VARCHAR (20);
   key_diag          VARCHAR (100);
   group_name1       VARCHAR (20);
   countdiag         VARCHAR (20);
   countecid         VARCHAR (20);
   key_ecid          VARCHAR (100);
   countbios         VARCHAR (20);
   counsndiag        VARCHAR (10);
   flag              VARCHAR (2);
   models            VARCHAR (20);
   bioss             VARCHAR (20);
   biosss            VARCHAR (20);
   modelss           VARCHAR (20);
   flag1             VARCHAR (20);
   p_CALLRES         VARCHAR (20);
   P_line            VARCHAR (20);
   e_error           EXCEPTION;
   station_error     EXCEPTION;
   station_correct   EXCEPTION;
   sn_error          EXCEPTION;

   CURSOR carton
   IS
      SELECT serial_number
        FROM sfism4.r_wip_tracking_t
       WHERE carton_no = DATA;

   row1              carton%ROWTYPE;
BEGIN
   SELECT DISTINCT (group_name)
              INTO station
              FROM sfism4.r_wip_tracking_t
             WHERE (serial_number = DATA OR carton_no = DATA);

   IF (station IS NULL or station not in('TVI' ,'NG_SAMPLE'))
   THEN
      RAISE station_error;
   END IF;


 IF station NOT IN ('OUT', 'PACKING')
   THEN
      UPDATE sfism4.r_wip_tracking_t
         SET section_name = mygroup,
             group_name = mygroup,
             station_name=mygroup,
             in_station_time = SYSDATE
       WHERE serial_number = DATA;

      RAISE station_correct;
   END IF;
EXCEPTION

   WHEN station_error
   THEN
      res := 'NPI NEED AFTER TVI !!!';
   WHEN station_correct
   THEN
      res := 'OK';
   WHEN OTHERS
   THEN
      ROLLBACK;
      res := 'SFIS1.NPI_CHECK ERROR';
END; 