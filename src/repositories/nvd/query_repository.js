import sequelize from "../../configs/oracle-connect.js";

class NVD_QUERY_REPOSITORY {

    /**
     * Function Repository: 
     */
    static async get_data_from_database(tableName, conditions = {}) {
        try {
            let whereClause = "1=1";
            let replacements = {};

            let idx = 0;
            for (const [key, value] of Object.entries(conditions)) {
                if (value === null || value === undefined) continue;

                if (typeof value === "object" && !Array.isArray(value)) {
                    if (value.type === "like") {
                        whereClause += ` AND ${key} LIKE :param${idx}`;
                        replacements[`param${idx}`] = `%${value.value}%`;
                    } else if (value.type === "in" && Array.isArray(value.value)) {
                        whereClause += ` AND ${key} IN (:param${idx})`;
                        replacements[`param${idx}`] = value.value;
                    } else if (value.type === "between" && Array.isArray(value.value) && value.value.length === 2) {
                        whereClause += ` AND ${key} BETWEEN :param${idx}_1 AND :param${idx}_2`;
                        replacements[`param${idx}_1`] = value.value[0];
                        replacements[`param${idx}_2`] = value.value[1];
                    }
                } else {
                    whereClause += ` AND ${key} = :param${idx}`;
                    replacements[`param${idx}`] = value;
                }

                idx++;
            }

            const sqlQuery = `SELECT * FROM ${tableName} WHERE ${whereClause}`;

            const results = await sequelize.query(sqlQuery, {
                replacements,
                type: sequelize.QueryTypes.SELECT,
            });
            return results;
        } catch (error) {
            throw error;
        }
    }


}

export default NVD_QUERY_REPOSITORY;