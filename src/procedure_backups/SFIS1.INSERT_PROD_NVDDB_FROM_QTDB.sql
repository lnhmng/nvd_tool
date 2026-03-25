PROCEDURE                   INSERT_PROD_NVDDB_FROM_QTDB
IS
CHECK_DATA_FLAG VARCHAR2(5);
BEGIN


--為避免重複,是用刪除本地NVDSFC DB 的資料後,再撈取QTDB上的資料後, insert進本地資料庫 
DELETE  FROM sfis1.C_STATION_GROUP_T;

insert into sfis1.C_STATION_GROUP_T
    (select * from sfis1.C_STATION_GROUP_T@qtdb minus select * from sfis1.C_STATION_GROUP_T);
commit;


END;