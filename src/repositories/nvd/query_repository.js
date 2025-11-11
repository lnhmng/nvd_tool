import sequelize from "../../configs/oracle-connect.js";

class NVD_QUERY_REPOSITORY {

    /**
     * Function Repository
     */

    static async get_data_from_database(query) {
        try {
            if (!query || typeof query !== "string" || query.trim() === "") {
                throw new Error("Invalid SQL query.");
            }

            const [results] = await sequelize.query(query, {
                raw: true,
                logging: false, 
            });

            return results;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Function Repository: WEIGHT_LOG
     */

    static async r_weight_log_t(sn) {
        try {
            const serialNumbers = Array.isArray(sn) ? sn : [sn];

            const SNs = serialNumbers.map(() => '?').join(',');

            const query = `
                SELECT * FROM SFISM4.R_WEIGHT_LOG_T WHERE SERIAL_NUMBER IN (${SNs})
            `;

            const [results] = await sequelize.query(query, {
                replacements: serialNumbers,
                type: sequelize.QueryTypes.SELECT,
            });

            return results;
        } catch (error) {
            throw error;
        }
    }

}

export default NVD_QUERY_REPOSITORY;