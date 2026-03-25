PROCEDURE       INSERT_QT_YIELD
AS
    V_ERROR_FLAG  VARCHAR2(1);
     V_APY        VARCHAR2(20); 
     V_LPY        VARCHAR2(20);
     V_DATE       VARCHAR2(22);    
    -- CURSOR1: 抓取所有有PB的MO
    CURSOR CUR1 IS
        SELECT DISTINCT a.model_name, a.mo_number
        FROM sfism4.r_mo_base_t a
        WHERE a.mo_create_date > SYSDATE - 365
          AND a.po_no LIKE 'PB%'
          ;
    ROW1 CUR1%ROWTYPE;

    -- CURSOR2: 抓取有過站紀錄的PB之MO良率
    CURSOR CUR2(p_MODEL_NAME VARCHAR2, p_MO_NUMBER VARCHAR2) IS



           SELECT 
                model_name,
                mo_number,
                group_name,  
                input_qty, 
                first_failure_qty, 
                adjusted_failure_qty,  
                repaired_ok_qty,  
                Output_qty,    
                --cast((1-First_Failure_Qty/Input_QTY) as decimal(10,5)) as FPY,               
                TRUNC( NVL(Output_qty,0)  * 1.0 / NULLIF(NVL(input_qty,0),0), 2 ) AS LPY,
                TRUNC( (NVL(output_qty,0) - NVL(repaired_ok_qty,0)) * 1.0 / NULLIF(NVL(input_qty,0),0), 2 ) AS APY
            FROM 
                 (  
                    SELECT  m.model_name, m.mo_number,m.group_name,  m.input_qty, 
                        (CASE WHEN n.first_failure_qty IS NULL THEN 0 ELSE n.first_failure_qty END) AS first_failure_qty, 
                        (CASE WHEN e.adjusted_failure_qty IS NULL THEN 0 ELSE e.adjusted_failure_qty END) AS adjusted_failure_qty, 
                        (CASE WHEN o.repaired_ok_qty IS NULL THEN 0 ELSE o.repaired_ok_qty END) AS repaired_ok_qty, 
                        (CASE WHEN f.Output_qty IS NULL THEN 0 ELSE f.Output_qty END) AS Output_qty, p.STATION_NV 
                    FROM 
                    (
                        select model_name, mo_number,group_name,count(serial_number) AS input_qty 
                        from sfism4.o_input_detail_t 

                        WHERE CREATE_DATE > SYSDATE-365
                        AND model_name = p_MODEL_NAME AND mo_number = p_MO_NUMBER
                        GROUP BY group_name,model_name, mo_number
                    ) m 
                   LEFT JOIN 
                   (
                         SELECT  a.model_name, a.mo_number,a.group_name, COUNT (b.serial_number) AS first_failure_qty 
                                 FROM (SELECT DISTINCT model_name, mo_number, group_name, serial_number,in_station_time  
                                  FROM sfism4.o_input_detail_t 
                                  WHERE model_name = p_MODEL_NAME AND mo_number = p_MO_NUMBER
                                  and CREATE_DATE > SYSDATE-365
                                   ) a 
                         LEFT JOIN  (SELECT DISTINCT model_name, mo_number, group_name, serial_number,in_station_time  
                                     FROM sfism4.o_fail_detail_t  
                                     --WHERE  model_name ='699-2G540-0243-TS1' and mo_number = '002430000482-1' 
                                     WHERE CREATE_DATE > SYSDATE-365
                                     AND model_name = p_MODEL_NAME AND mo_number = p_MO_NUMBER
                                     AND fail_type = 'FIRST'  AND NOT REGEXP_LIKE (test_code, '98[A-Za-z]{1}') 
                                     ) b 
                        ON a.group_name = b.group_name 
                        AND a.model_name = b.model_name  
                        AND a.mo_number = b.mo_number 
                        AND a.in_station_time = b.in_station_time  
                        WHERE a.serial_number = b.serial_number 
                        GROUP BY a.group_name,a.model_name, a.mo_number
                     ) n 
                     ON m.group_name = n.group_name 
                     and m.model_name = n.model_name 
                     and m.mo_number = n.mo_number 
                     LEFT JOIN 
                    (  
                               SELECT   a.model_name, a.mo_number,a.group_name,count (b.serial_number) as adjusted_failure_qty 
                                FROM
                                (SELECT distinct model_name,  mo_number,  group_name, serial_number,   in_station_time 
                                FROM sfism4.O_INPUT_DETAIL_T 
                                WHERE model_name = p_MODEL_NAME AND mo_number = p_MO_NUMBER
                                and CREATE_DATE > SYSDATE-365
                                ) a 
                                LEFT JOIN (SELECT distinct model_name, MO_NUMBER,  group_name,  serial_number 
                                            FROM (SELECT distinct model_name,  mo_number,  group_name,  serial_number, in_station_time 
                                            FROM sfism4.O_FAIL_DETAIL_T 
                                            WHERE CREATE_DATE > SYSDATE-365
                                            AND model_name = p_MODEL_NAME AND mo_number = p_MO_NUMBER
                                            AND fail_type = 'ADJUST' and not regexp_like(TEST_CODE,'98[A-Za-z]{1}')) 
                                            GROUP BY model_name, MO_NUMBER, group_name,serial_number
                                            ) b 
                                 ON  a.group_name = b.group_name  
                                 AND a.model_name = b.model_name  
                                 AND a.mo_number = b.mo_number 
                                 AND a.serial_number=b.serial_number 
                                 GROUP BY a.group_name,a.model_name, a.mo_number
                    ) e 
                     ON  m.group_name = e.group_name  
                     and m.model_name = e.model_name 
                     and m.mo_number = e.mo_number 
                     LEFT JOIN 
                           ( 
                                SELECT DISTINCT c.model_name, c.MO_NUMBER, c.group_name,count(d.serial_number) as Output_qty 
                                FROM 
                                (
                                    SELECT distinct model_name,mo_number, group_name, serial_number, in_station_time 
                                    FROM sfism4.O_INPUT_DETAIL_T 
                                    WHERE CREATE_DATE > SYSDATE-365
                                    AND model_name = p_MODEL_NAME AND mo_number = p_MO_NUMBER
                                ) c 
                                left join 
                                ( 
                                    SELECT distinct model_name,mo_number, 
                                    group_name,  serial_number, in_station_time from sfism4.O_OUTPUT_DETAIL_T 
                                    WHERE CREATE_DATE > SYSDATE-365
                                    AND model_name = p_MODEL_NAME AND mo_number = p_MO_NUMBER
                                 )d 
                                ON  c.group_name = d.group_name  
                                AND c.model_name = d.model_name  
                                AND c.mo_number = d.mo_number 
                                AND c.serial_number=d.serial_number  
                                group by  c.group_name,c.model_name, c.MO_NUMBER
                      ) f 
                      ON  m.group_name = f.group_name 
                      and m.model_name = f.model_name 
                      and m.mo_number = f.mo_number 
                      LEFT JOIN 
                      (  
                            SELECT a.model_name,  a.mo_number,a.group_name,  count (c.serial_number) as repaired_ok_qty 
                                        FROM 
                                        (SELECT distinct model_name,  mo_number,  group_name, serial_number, in_station_time 
                                        FROM sfism4.O_INPUT_DETAIL_T 
                                        WHERE CREATE_DATE > SYSDATE-365
                                        AND model_name = p_MODEL_NAME AND mo_number = p_MO_NUMBER
                                        ) a 
                            LEFT JOIN (
                                        SELECT distinct model_name,  mo_number,  group_name,  serial_number, in_station_time 
                                        FROM sfism4.O_FAIL_DETAIL_T 
                                        --WHERE  model_name ='699-2G540-0243-TS1' and mo_number = '002430000482-1'  
                                        WHERE CREATE_DATE > SYSDATE-365
                                        --and model_name ='699-2G540-0243-TS1' and mo_number = '002430000482-1'
                                        AND model_name = p_MODEL_NAME AND mo_number = p_MO_NUMBER
                                        AND fail_type = 'ADJUST' AND  not regexp_like(TEST_CODE,'98[A-Za-z]{1}')
                                        ) b 
                                        ON  a.group_name = b.group_name 
                                        AND a.model_name = b.model_name 
                                        AND a.mo_number = b.mo_number 
                                        AND a.serial_number=b.serial_number 
                                        LEFT JOIN 
                                        (
                                            SELECT distinct model_name, mo_number,  group_name,  serial_number,  in_station_time 
                                            from sfism4.O_OUTPUT_DETAIL_T 
                                            WHERE CREATE_DATE > SYSDATE-365
                                            AND model_name = p_MODEL_NAME AND mo_number = p_MO_NUMBER
                                        )c 
                                        ON b.group_name = c.group_name  
                                        AND b.model_name = c.model_name  
                                        AND b.mo_number = c.mo_number 
                                        AND b.serial_number=c.serial_number 
                                        GROUP BY a.group_name, a.model_name,  a.mo_number
                    )o  
                    ON  m.group_name = o.group_name 
                    and m.model_name = o.model_name 
                    and m.mo_number = o.mo_number 
                    LEFT JOIN 
                    (
                      select distinct STATION_SFC,STATION_NV from sfis1.C_STATION_MAPPING_T where AREA='F20' 
                    ) p 
                    on m.group_name=p.STATION_SFC 

                    GROUP BY  m.group_name, m.input_qty, n.first_failure_qty, e.adjusted_failure_qty, f.Output_qty, 
                              o.repaired_ok_qty, p.STATION_NV, m.model_name, m.mo_number, 
                             (CASE WHEN n.first_failure_qty IS NULL THEN 0 ELSE n.first_failure_qty END), 
                             (CASE WHEN e.adjusted_failure_qty IS NULL THEN 0 ELSE e.adjusted_failure_qty END), 
                             (CASE WHEN o.repaired_ok_qty IS NULL THEN 0 ELSE o.repaired_ok_qty END), 
                             (CASE WHEN f.Output_qty IS NULL THEN 0 ELSE f.Output_qty END)
                    ) 
                    WHERE STATION_NV IS NOT NULL
                    AND model_name = p_MODEL_NAME AND mo_number = p_MO_NUMBER
                     AND GROUP_NAME NOT LIKE 'R_%';



    ROW2 CUR2%ROWTYPE;

BEGIN
    V_ERROR_FLAG := '0';

    OPEN CUR1;
    LOOP
        FETCH CUR1 INTO ROW1;
        EXIT WHEN CUR1%NOTFOUND;

        OPEN CUR2(ROW1.model_name, ROW1.mo_number);
        LOOP
            FETCH CUR2 INTO ROW2;
            EXIT WHEN CUR2%NOTFOUND;
            IF ROW2.output_qty=ROW2.input_qty THEN
                V_APY:=1;
            ELSE
                V_APY := ROUND( (ROW2.output_qty - ROW2.repaired_ok_qty) / ROW2.input_qty, 4 );
            END IF;   
             IF ROW2.output_qty=ROW2.input_qty THEN
                V_LPY:=1;
            ELSE
                V_LPY := ROUND((ROW2.output_qty)/ ROW2.input_qty, 4 );

            END IF;   
            V_DATE := TO_CHAR(sysdate ,'yyyy/mm/dd HH24')|| ':00:00'; 


            INSERT INTO sfis1.C_QT_YIELD_T
                (site, bu, model_name, mo_number, group_name, input_qty, first_failure_qty, adjusted_failure_qty, repaired_ok_qty, output_qty, apy,lpy,LAST_UPDATE_TIME)
            VALUES
                ('QuangChau', 'NVD', ROW2.model_name, ROW2.mo_number, ROW2.group_name,
                 ROW2.input_qty, ROW2.first_failure_qty, ROW2.adjusted_failure_qty,
                 ROW2.repaired_ok_qty, ROW2.output_qty, V_APY,V_LPY,TO_DATE(V_DATE, 'yyyy/mm/dd HH24:MI:SS'));
             COMMIT; 
        END LOOP;
        CLOSE CUR2;
    END LOOP;
    CLOSE CUR1;

END INSERT_QT_YIELD;