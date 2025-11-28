import express from 'express';

import { CONSTANTS } from '../../../utils/constants.js';

import ToolController from '../../../controllers/tool/backup_controller.js';

const tool = express.Router();

tool.get(
    CONSTANTS.API_COLUMNS,
    ToolController.get_column_header_controller
)

tool.get(
    CONSTANTS.API_PROCEDURES,
    ToolController.get_procedures_controller
)

export default tool;