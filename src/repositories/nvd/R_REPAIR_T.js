import sequelize from "../../configs/oracle-connect.js";

class RepairRepository {

    static async getData() {
        try {

            const sqlQuery = `
                SELECT 
            `
            const [results] = await sequelize.query(sqlQuery);
            return results;
            
        } catch (error) {
            throw error;
        }
    }

}

export default RepairRepository;