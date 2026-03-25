procedure       export_to_csv( P_DIR in VARCHAR2)
IS
cursor mycur is select * from SFISM4.r_wip_tracking_t;
myrecord SFISM4.r_wip_tracking_t%rowtype;
CSV_OUTPUT UTL_FILE.FILE_TYPE;
MAX_LINE number:=100;
OUT_FILE_NAME VARCHAR2(20);
OBJ_SIZE NUMBER;
COUNT_NUM number;
OBJ_DATE VARCHAR2(20);？
BEGIN_TIME number;
END_TIME number;？
BEGIN_TIME:=？dbms_utility.get_time;？？
open mycur;
？？？？？？？？FOR？I？IN？0..99？loop？？
？？？？--拼接文件名？？
    OUT_FILE_NAME:='DBMS'||i||'.csv';
    COUNT_NUM:=0;
    CSV_OUTPUT？:=？UTL_FILE.FOPEN(P_DIR,？OUT_FILE_NAME,？'W',？MAX_LINE);
    ？--每10條寫一個文件？？
？？？？while？COUNT_NUM？<？10？loop？？
    ？--逐條叫游標記？放入記？中？？
        FETCH MYCUR IN myrecord;
        OBJ_SIZE？:=？myrecord.OBJ_SIZE*10？+？myrecord.MS_VERSION;？？
        OBJ_DATE？:=？TO_CHAR(TO_DATE('19700101','yyyymmdd')？+？myrecord.OBJ_TIME/86400,'yyyy-MM-dd？HH24:mi');？？
        UTL_FILE.PUT_LINE(CSV_OUTPUT,myrecord.OBJ_ID？||？'|'？||？myrecord.OBJ_NAME？||？','？||？OBJ_SIZE？||？','？||？OBJ_DATE？||？','？||？myrecord.OBJ_NAME);？？
        COUNT_NUM=COUNT_NUM+1;
？？？？？？？--取游標中下一條記？？？
        FETCH mycur into myrecord;
        end loop;
        utl_file.fclose(CSV_OUTPUT);
    END LOOP;
？？？？？？--關閉游標？？
    CLOSE mycur;？
    END_TIME？:=？dbms_utility.get_time;？？
    DBMS_output.put_line('Total？time='？||？(END_TIME-BEGIN_TIME)*10？||？'ms.');？？
END;？？