import ToolRepository from "../../repositories/tool/get-table-info.js";
import ExcelJS from "exceljs";

import ReturnResponseUtil from "../../utils/return-response-util.js";

class ToolController {
    /**
     * Function Controller:
     * 
     */

    static async get_table_info(req, res) {
        try {
            const results = await ToolRepository.get_table_info();

            if (!results || results.length === 0) {
                return ReturnResponseUtil.returnResponse(res, 404, false, "Not found", []);
            }

            const groupedData = results.reduce((acc, current) => {
                const { schemaName, tableName, columnName, dataType, columnComment, tableComment } = current;

                if (!acc[schemaName]) acc[schemaName] = {};
                if (!acc[schemaName][tableName]) {
                    acc[schemaName][tableName] = {
                        comment: tableComment,
                        columns: []
                    };
                }
                acc[schemaName][tableName].columns.push({ columnName, dataType, columnComment });

                return acc;
            }, {});

            if (req.query.export === "true") {
                const workbook = new ExcelJS.Workbook();

                for (const schemaName in groupedData) {
                    const worksheet = workbook.addWorksheet(schemaName);

                    worksheet.columns = [
                        { header: "Table name", key: "tableName", width: 30 },
                        { header: "Column", key: "columnName", width: 25 },
                        { header: "Data type", key: "dataType", width: 20 },
                        { header: "Column Comment", key: "columnComment", width: 50 },
                        { header: "Table Comment", key: "tableComment", width: 50 }
                    ];

                    worksheet.getRow(1).eachCell((cell) => {
                        cell.font = { bold: true, color: { argb: "FFFFFFFF" } };
                        cell.fill = {
                            type: "pattern",
                            pattern: "solid",
                            fgColor: { argb: "FF4472C4" }
                        };
                        cell.alignment = { vertical: "middle", horizontal: "center" };
                        cell.border = {
                            top: { style: "thin" },
                            left: { style: "thin" },
                            bottom: { style: "thin" },
                            right: { style: "thin" }
                        };
                    });

                    let startRow = 2;

                    for (const tableName in groupedData[schemaName]) {
                        const tableData = groupedData[schemaName][tableName];
                        const numColumns = tableData.columns.length;

                        tableData.columns.forEach((column, index) => {
                            const row = worksheet.getRow(startRow + index);
                            row.getCell("B").value = column.columnName;
                            row.getCell("C").value = column.dataType;
                            row.getCell("D").value = column.columnComment || "";
                            row.getCell("E").value = tableData.comment || "";

                            row.eachCell((cell) => {
                                cell.border = {
                                    top: { style: "thin" },
                                    left: { style: "thin" },
                                    bottom: { style: "thin" },
                                    right: { style: "thin" }
                                };
                            });
                        });

                        if (numColumns > 0) {
                            const endRow = startRow + numColumns - 1;

                            worksheet.mergeCells(`A${startRow}:A${endRow}`);
                            worksheet.getRow(startRow).getCell("A").value = tableName;

                            if (numColumns > 1) {
                                worksheet.mergeCells(`E${startRow}:E${endRow}`);
                            }
                        }

                        startRow += numColumns;
                    }
                }

                res.setHeader(
                    "Content-Type",
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                );
                res.setHeader(
                    "Content-Disposition",
                    `attachment; filename=database_schema.xlsx`
                );

                await workbook.xlsx.write(res);
                return res.end();
            }

            return ReturnResponseUtil.returnResponse(res, 200, true, "Successfully", results);

        } catch (error) {
            console.error("Error when exporting Excel:", error);
            return ReturnResponseUtil.returnResponse(res, 500, false, "Server Error");
        }
    }

}

export default ToolController;
