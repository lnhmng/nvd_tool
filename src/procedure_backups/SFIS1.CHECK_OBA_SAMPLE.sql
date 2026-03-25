PROCEDURE       CHECK_OBA_SAMPLE(DATA IN VARCHAR2,action IN VARCHAR2,failcode  IN VARCHAR2,descript  IN VARCHAR2,faillocation  IN VARCHAR2 ,EMP IN VARCHAR2,
   RES OUT VARCHAR2) AS 
    cou  VARCHAR2(25);
    snnum int;
    statu VARCHAR2(25);
    groupName VARCHAR2(25);
    E_ERROR     EXCEPTION;

BEGIN
   --按NVD流程，DFMS之前不能再按棧板號抽檢
    select count(*) into snnum from SFISM4.R_WIP_TRACKING_T where serial_number=data;
    if(snnum<=0) then
        res:='ERROR:sn:'||DATA||'不存在,請確認';
        raise E_ERROR;
    end if;

    if(action='PASS') THEN
        statu:='0';
    ELSIF(action='FAIL') THEN
        statu:='1';
    ELSE 
       res:='ERROR:Actioncode請掃描PASS或Fail';
       raise E_ERROR;
    END IF;

    IF statu='1' then
        SELECT count(*) into cou  FROM   sfis1.c_error_code_darcy_t  WHERE   error_code = failcode;
        if(cou<=0) then
           res:='ERROR:Failcode'||failcode||'不存在,請確認!';
           raise E_ERROR;
        end if;  
    END IF;

    select count(*) into cou  from SFISM4.R_WIP_TRACKING_T where serial_number=data and (error_flag=1  or fail_qty=1);
    if(cou>=1) then
       select group_name into groupName  from SFISM4.R_WIP_TRACKING_T where serial_number=data and (error_flag=1  or fail_qty=1);
        res:='ERROR:sn fail at '||groupName||',請確認';
        raise E_ERROR;
    end if;

    CHECK_ROUTE('','OBA',DATA,res);
    IF res!='OK' THEN
        res:='產品'||DATA||' ERROR:'||res;
        raise E_ERROR;
    END IF; 

     select  count(*) into snnum  from SFISM4.oba_sample_detail where serial_number=data;
        if(snnum<=0) then
           null;

        else
           res:='ERR:#'||DATA||'#該產品已抽檢';
          raise E_ERROR;
        end if;  

      IF statu='0' THEN
            insert into SFISM4.OBA_SAMPLE_DETAIL (SERIAL_NUMBER,MODEL_NAME,MO_NUMBER,STATUS,ERROR_CODE,DESCRIPTION,location,EMP_NO,TIME,event_pass) 
            SELECT SERIAL_NUMBER,MODEL_NAME,MO_NUMBER,statu as status ,'' as ERROR_CODE,'' as DESCRIPTION,'' as location,emp as emp_no,sysdate,0
            from SFISM4.R_WIP_TRACKING_T where serial_number=data;
        ELSE
              insert into SFISM4.OBA_SAMPLE_DETAIL (SERIAL_NUMBER,MODEL_NAME,MO_NUMBER,STATUS,ERROR_CODE,DESCRIPTION,location,EMP_NO,TIME,event_pass) 
            SELECT SERIAL_NUMBER,MODEL_NAME,MO_NUMBER,statu as status ,failcode as ERROR_CODE,descript as DESCRIPTION,faillocation as location,emp as emp_no,sysdate,0
            from SFISM4.R_WIP_TRACKING_T where serial_number=data;

           UPDATE sfism4.r_wip_tracking_t
            SET section_name='OBA',group_name='OBA',station_name='OBA1',in_station_time = sysdate,FAIL_QTY=1,ERROR_FLAG=1
            WHERE serial_number=data;

                INSERT INTO sfism4.r_repair_t (
                    serial_number,
                    model_name,
                    mo_number,
                    test_time,
                    test_code,
                    test_station,
                    test_line,
                    tester
                )  SELECT SERIAL_NUMBER,MODEL_NAME,MO_NUMBER,sysdate,failcode as test_code,'OBA' as test_station,'OBA' as test_line,emp as tester
            from SFISM4.R_WIP_TRACKING_T where serial_number=data;
        END IF;

    res:='OK';
EXCEPTION
     when E_ERROR
        then
        NULL;
     WHEN OTHERS THEN 
         res :=  SQLERRM;
END;
