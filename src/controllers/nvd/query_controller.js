import NVD_QUERY_REPOSITORY from "../../repositories/nvd/query_repository.js";

import ReturnResponseUtil from "../../utils/return-response-util.js";

class NVD_QUERY_CONTROLLER {

    /**
     * Function Controller:
     * 
     */
    static async get_data_from_database(req, res) {
        try {
            const { tableName, conditions } = req.body;

            if (!tableName) {
                return ReturnResponseUtil.returnResponse(res, 400, false, "Missing tableName");
            }

            const results = await NVD_QUERY_REPOSITORY.get_data_from_database(tableName, conditions || {});
            if (!results || results.length === 0) {
                return ReturnResponseUtil.returnResponse(res, 404, false, "Not found", []);
            }

            return ReturnResponseUtil.returnResponse(res, 200, true, "Successfully", results);

        } catch (error) {
            console.error("Error when fetching data:", error);
            return ReturnResponseUtil.returnResponse(res, 500, false, "Server Error", error);
        }
    }

}


export default NVD_QUERY_CONTROLLER;
