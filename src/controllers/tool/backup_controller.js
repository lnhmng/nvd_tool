import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url'; 
import ToolRepository from "../../repositories/tool/backup_repository.js";
import ExcelJS from "exceljs";

import ReturnResponseUtil from "../../utils/return-response-util.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

class ToolController {

    /**
     * Function Controller: Get column headers from a table in the database
     */

    static async get_column_header_controller(req, res) {
        try {
            const results = await ToolRepository.get_column_header_repository();

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

    /**
     * Function Controller: Get all stored procedures source code.
     */

    static async get_procedures_controller(req, res) {
        try {
            const rawResults = await ToolRepository.get_procedures_repository();

            if (!rawResults || rawResults.length === 0) {
                return ReturnResponseUtil.returnResponse(res, 404, false, "Not found", []);
            }

            const groupedProcedures = rawResults.reduce((acc, row) => {
                const key = `${row.schemaName}.${row.procedureName}`;

                if (!acc[key]) {
                    acc[key] = {
                        schemaName: row.schemaName,
                        procedureName: row.procedureName,
                        sourceCodeLines: [] 
                    };
                }
                
                acc[key].sourceCodeLines.push(row.text);
                
                return acc;
            }, {});

            const finalResults = Object.values(groupedProcedures).map(proc => ({
                schemaName: proc.schemaName,
                procedureName: proc.procedureName,
                fullSource: proc.sourceCodeLines.join('') 
            }));

            const outputFolderName = 'procedure_backups';
            const outputDir = path.join(__dirname, '..', '..', outputFolderName); 

            await fs.mkdir(outputDir, { recursive: true });
            const savePromises = finalResults.map(proc => {
                const filename = `${proc.schemaName}.${proc.procedureName}.sql`;
                const filePath = path.join(outputDir, filename);
                const fileContent = proc.fullSource;

                return fs.writeFile(filePath, fileContent)
                    .then(() => {
                        console.log(`[File Save Success]: Đã lưu ${filename}`);
                    })
                    .catch(err => {
                        console.error(`[File Save Error] Lỗi khi lưu ${filename}:`, err);
                    });
            });


            await Promise.all(savePromises);
            return ReturnResponseUtil.returnResponse(res, 200, true, 
                 `Đã lưu thành công ${finalResults.length} thủ tục vào thư mục: ${outputFolderName} trong src/`, 
                 finalResults);

        } catch (error) {
            console.error("Server error:", error);
            return ReturnResponseUtil.returnResponse(res, 500, false, "Server Error");
        }
    }
}

export default ToolController;