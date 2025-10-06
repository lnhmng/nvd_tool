import express from 'express';

import { CONSTANTS } from '../../../utils/constants.js';

import ToolController from '../../../controllers/tool/get-table-info.js';

const tool = express.Router();

tool.get(
    CONSTANTS.API_TABLE_INFO,
    ToolController.get_table_info
)

export default tool;