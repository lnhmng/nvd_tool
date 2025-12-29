import sequelize from "../../configs/oracle-connect.js";

class R_WIP_TRACKING_T_Repository {

    static buildWhere({ serialNumber, stationName, startDate, endDate }) {
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

    static async getFiltered({
        serialNumber,
        stationName,
        startDate,
        endDate,
        page,
        pageSize
    }) {
        const { whereSql, replacements } = this.buildWhere({
            serialNumber,
            stationName,
            startDate,
            endDate
        });

        const offset = (page - 1) * pageSize;

        const sql = `
            SELECT * FROM (
                SELECT a.*, ROWNUM rnum FROM (
                    SELECT *
                    FROM sfism4.R_WIP_TRACKING_T
                    ${whereSql}
                    ORDER BY IN_STATION_TIME DESC
                ) a
                WHERE ROWNUM <= :maxRow
            )
            WHERE rnum > :minRow
        `;

        replacements.minRow = offset;
        replacements.maxRow = offset + pageSize;

        const [rows] = await sequelize.query(sql, { replacements });
        return rows;
    }

    static async getTotalCount(filters) {
        const { whereSql, replacements } = this.buildWhere(filters);

        const sql = `
            SELECT COUNT(1) AS TOTAL
            FROM sfism4.R_WIP_TRACKING_T
            ${whereSql}
        `;

        const [rows] = await sequelize.query(sql, { replacements });
        return rows[0].TOTAL;
    }

    static async getAll(filters) {
        const { whereSql, replacements } = this.buildWhere(filters);

        const sql = `
            SELECT *
            FROM sfism4.R_WIP_TRACKING_T
            ${whereSql}
            ORDER BY IN_STATION_TIME DESC
        `;

        const [rows] = await sequelize.query(sql, { replacements });
        return rows;
    }
}

export default R_WIP_TRACKING_T_Repository;
