import wipTrackingTRepository from "../../repositories/nvd/R_WIP_TRACKING_T.js";
import ApiResponse from "../../utils/apiResponse.js";
import ErrorCode from "../../utils/errorCode.js";

class R_WIP_TRACKING_T_Controller {

    static async getResult(req, res) {
        try {
            let {
                serialNumber,
                stationName,
                startDate,
                endDate,
                page = 1,
                pageSize = 20,
                exportAll = false
            } = req.query;

            page = Number(page);
            pageSize = Number(pageSize);
            exportAll = exportAll === "true" || exportAll === true;

            if (page <= 0 || pageSize <= 0) {
                return res.status(400).json(
                    ApiResponse.fail(
                        ErrorCode.INVALID_PAGING,
                        "page và pageSize phải lớn hơn 0"
                    )
                );
            }

            if (startDate) {
                startDate = new Date(startDate);
                startDate.setHours(0, 0, 0, 0);
            }

            if (endDate) {
                endDate = new Date(endDate);
                endDate.setHours(23, 59, 59, 999);
            }

            let data;
            let totalItems = 0;

            const filters = {
                serialNumber,
                stationName,
                startDate,
                endDate
            };

            if (exportAll) {
                data = await wipTrackingTRepository.getAll(filters);
                totalItems = data.length;
            } else {
                totalItems = await wipTrackingTRepository.getTotalCount(filters);

                data = await wipTrackingTRepository.getFiltered({
                    ...filters,
                    page,
                    pageSize
                });
            }

            if (!data || data.length === 0) {
                return res.json(
                    ApiResponse.fail(
                        ErrorCode.NO_DATA,
                        "Không tìm thấy dữ liệu"
                    )
                );
            }

            return res.json(
                ApiResponse.ok(
                    data,
                    "Get data successfully",
                    exportAll
                        ? null
                        : {
                            page,
                            pageSize,
                            totalItems,
                            totalPages: Math.ceil(totalItems / pageSize)
                        }
                )
            );

        } catch (error) {
            return res.status(500).json(
                ApiResponse.fail(
                    ErrorCode.SYSTEM_ERROR,
                    error.message
                )
            );
        }
    }
}

export default R_WIP_TRACKING_T_Controller;
