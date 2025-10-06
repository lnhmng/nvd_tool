import sequelize from "../../configs/oracle-connect.js";

class ToolRepository {

    /**
     * Function Repository: 
     */

    static async get_table_info() {
        try {
            const sqlQuery = `
            SELECT
                t1.OWNER AS "schemaName",             -- Schema (Owner)
                t1.TABLE_NAME AS "tableName",         -- Tên bảng
                t1.COLUMN_NAME AS "columnName",       -- Tên cột
                t1.DATA_TYPE AS "dataType",           -- Kiểu dữ liệu
                t3.COMMENTS AS "columnComment",       -- Comment của cột
                t2.COMMENTS AS "tableComment"         -- Comment của bảng
            FROM
                ALL_TAB_COLUMNS t1
            LEFT JOIN
                ALL_TAB_COMMENTS t2
                ON t1.OWNER = t2.OWNER AND t1.TABLE_NAME = t2.TABLE_NAME
            LEFT JOIN
                ALL_COL_COMMENTS t3
                ON t1.OWNER = t3.OWNER AND t1.TABLE_NAME = t3.TABLE_NAME AND t1.COLUMN_NAME = t3.COLUMN_NAME
            WHERE
                t1.OWNER IN ('SFIS1', 'SFISM4')   -- Lọc theo schema (owner)
                AND t2.TABLE_TYPE = 'TABLE'       -- Chỉ lấy thông tin TABLE
            ORDER BY
                t1.OWNER, t1.TABLE_NAME, t1.COLUMN_ID
        `
            const [results] = await sequelize.query(sqlQuery);
            return results;
        } catch (error) {
            throw error;
        }
    }

}

export default ToolRepository;