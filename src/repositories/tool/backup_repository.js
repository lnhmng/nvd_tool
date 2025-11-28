import sequelize from "../../configs/oracle-connect.js";

class ToolRepository {

    /**
     * Function Repository: Get column headers from a table in the database
     */

    static async get_column_header_repository() {
        try {
            const sqlQuery = `
            SELECT
                t1.OWNER AS "schemaName",             
                t1.TABLE_NAME AS "tableName",        
                t1.COLUMN_NAME AS "columnName",       
                t1.DATA_TYPE AS "dataType",           
                t3.COMMENTS AS "columnComment",      
                t2.COMMENTS AS "tableComment"       
            FROM
                ALL_TAB_COLUMNS t1
            LEFT JOIN
                ALL_TAB_COMMENTS t2
                ON t1.OWNER = t2.OWNER AND t1.TABLE_NAME = t2.TABLE_NAME
            LEFT JOIN
                ALL_COL_COMMENTS t3
                ON t1.OWNER = t3.OWNER AND t1.TABLE_NAME = t3.TABLE_NAME AND t1.COLUMN_NAME = t3.COLUMN_NAME
            WHERE
                t1.OWNER IN ('SFIS1', 'SFISM4')   
                AND t2.TABLE_TYPE = 'TABLE'      
            ORDER BY
                t1.OWNER, t1.TABLE_NAME, t1.COLUMN_ID
        `
            const [results] = await sequelize.query(sqlQuery);
            return results;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Function Repository: Get column headers from a table in the database
     */

    static async get_procedures_repository() {
        try {
            const sqlQuery = `
                SELECT
                    obj.OWNER AS "schemaName",
                    obj.OBJECT_NAME AS "procedureName",
                    src.LINE AS "line",
                    src.TEXT AS "text"
                FROM
                    ALL_OBJECTS obj
                JOIN
                    ALL_SOURCE src
                    ON obj.OWNER = src.OWNER
                    AND obj.OBJECT_NAME = src.NAME
                    AND obj.OBJECT_TYPE = src.TYPE
                WHERE
                    obj.OBJECT_TYPE = 'PROCEDURE'
                    AND obj.OWNER = 'SFIS1'
                -- Bỏ điều kiện giới hạn dòng code (src.LINE <= MIN(line) WHERE TEXT LIKE 'BEGIN%')
                ORDER BY
                    obj.OWNER,
                    obj.OBJECT_NAME,
                    src.LINE
            `;
            const [results] = await sequelize.query(sqlQuery);
            return results;
        } catch (error) {
            throw error;
        }
    }

}

export default ToolRepository;