import { Router } from "express";
import ToolController from "../../controllers/tool/get-table-info.js";

const router = Router();

/**
 * @swagger
 * /tools/export:
 *   get:
 *     summary: Get database table info
 *     description: Lấy thông tin table và column, có thể export ra Excel.
 *     parameters:
 *       - in: query
 *         name: export
 *         schema:
 *           type: string
 *           enum: [true, false]
 *         required: false
 *         description: Nếu = true thì tải file Excel, mặc định trả JSON.
 *     responses:
 *       200:
 *         description: Trả về danh sách table info (JSON hoặc Excel)
 *       404:
 *         description: Không tìm thấy dữ liệu
 */
router.get("/export", ToolController.get_table_info);

export default router;
