PROCEDURE UPDATE_AGENCY

is

BEGIN

  update sfism4.r_wip_tracking_t set line_name='NVS02',section_name='LOOPBACK_IN',group_name='LOOPBACK_IN',
  STATION_name='LOOPBACK_IN',error_flag=0,next_station='N/A',pass_qty=0,fail_qty=0,emp_no='IT',carton_no='N/A',in_station_time=SYSDATE WHERE serial_number in ( select serial_number  FROM sfism4.r_wip_tracking_t WHERE  mo_number='006560017914-1' and group_name='S_VI_T' 
);
end;