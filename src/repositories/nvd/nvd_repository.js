import sequelize from "../../configs/oracle-connect.js";

class SN_DETAIL_INFO_REPOSITORY {

    static async buildWhere({ serialNumber, stationName, startDate, endDate }) {
        const where = [];
        const replacements = {};

        if (serialNumber) {
            where.push("SERIAL_NUMBER = :serialNumber");
            replacements.serialNumber = serialNumber;
        }

        if (stationName) {
            where.push("STATION_NAME = :stationName");
            replacements.stationName = stationName;
        }

        if (startDate) {
            where.push("IN_STATION_TIME >= :startDate");
            replacements.startDate = startDate;
        }

        if (endDate) {
            where.push("IN_STATION_TIME <= :endDate");
            replacements.endDate = endDate;
        }

        return {
            whereSql: where.length ? `WHERE ${where.join(" AND ")}` : "",
            replacements
        };
    }

    static async getSNDetailInfo(serialNumber) {
        try {

            const { whereSql, replacements } = this.buildWhere({
                serialNumber
            });

            const sqlQuery = `
                SELECT * FROM SFISM4.R_SN_DETAIL_T 
                ${whereSql}
                ORDER BY IN_STATION_TIME
            `
            const [results] = await sequelize.query(sqlQuery, { replacements });

            return results;
        } catch (error) {
            throw error;
        }
    }

}

export default SN_DETAIL_INFO_REPOSITORY;