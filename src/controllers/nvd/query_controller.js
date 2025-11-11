import multer from "multer";
import xlsx from "xlsx";
import fs from "fs";
import path from "path";

import NVD_QUERY_REPOSITORY from "../../repositories/nvd/query_repository.js";
import ReturnResponseUtil from "../../utils/return-response-util.js";

const upload = multer({ dest: "uploads/" });

class NVD_QUERY_CONTROLLER {

    /**
     * Function Controller: 
     * Thực thi truy vấn SQL bất kỳ
     */
    static async get_data_from_database(req, res) {
        try {
            const { query } = req.body;

            if (!query || typeof query !== "string" || query.trim() === "") {
                return ReturnResponseUtil.returnResponse(
                    res,
                    400,
                    false,
                    "Truy vấn không hợp lệ",
                    []
                );
            }

            const results = await NVD_QUERY_REPOSITORY.get_data_from_database(query);

            if (!results || results.length === 0) {
                return ReturnResponseUtil.returnResponse(res, 404, false, "Không tìm thấy dữ liệu.", []);
            }

            return ReturnResponseUtil.returnResponse(res, 200, true, "Truy vấn thành công.", results);

        } catch (error) {
            console.error("Error when executing SQL query:", error);
            return ReturnResponseUtil.returnResponse(
                res,
                500,
                false,
                "Lỗi máy chủ hoặc câu truy vấn không hợp lệ.",
                error.message || error
            );
        }
    }

    /**
     * Function Controller: 
     * Nhận danh sách SN từ body hoặc file .txt / .xlsx
     */
    static async r_weight_log_t(req, res) {
        try {
            let snList = [];

            // --- Lấy SN từ body ---
            if (req.body?.sn) {
                const sn = req.body.sn;
                if (Array.isArray(sn)) {
                    snList = sn.map(s => s.trim()).filter(Boolean);
                } else {
                    snList = sn.split(/[\r\n,; ]+/).map(s => s.trim()).filter(Boolean);
                }
            }

            // ---  Lấy SN từ file upload ---
            if (req.file) {
                const filePath = req.file.path;
                const ext = path.extname(req.file.originalname).toLowerCase();

                if (ext === ".txt") {
                    const content = fs.readFileSync(filePath, "utf8");
                    snList = content.split(/[\r\n,; ]+/).map(s => s.trim()).filter(Boolean);
                } else if (ext === ".xlsx" || ext === ".xls") {
                    const workbook = xlsx.readFile(filePath);
                    const sheetName = workbook.SheetNames[0];
                    const sheet = xlsx.utils.sheet_to_json(workbook.Sheets[sheetName], { header: 1 });
                    snList = sheet.flat().map(s => String(s).trim()).filter(Boolean);
                } else {
                    fs.unlinkSync(filePath);
                    return ReturnResponseUtil.returnResponse(res, 400, false, "Chỉ hỗ trợ file .txt hoặc .xlsx/.xls");
                }

                fs.unlinkSync(filePath);
            }

            if (!snList || snList.length === 0) {
                return ReturnResponseUtil.returnResponse(res, 400, false, "Không tìm thấy SN hợp lệ!");
            }

            const results = NVD_QUERY_CONTROLLER.r_weight_log_t(snList);

            return ReturnResponseUtil.returnResponse(res, 200, true, "Lấy dữ liệu SN thành công", results);

        } catch (error) {
            console.error("Error in r_weight_log_t:", error);
            return ReturnResponseUtil.returnResponse(res, 500, false, "Server Error", error.message);
        }
    }
}

export { upload };
export default NVD_QUERY_CONTROLLER;
