import express from 'express';
import {CONSTANTS} from '../../utils/constants.js';

import tool_APIs from './tools/index.js';

const router = express.Router();

router.use(CONSTANTS.API_TOOLS, tool_APIs);

export default router