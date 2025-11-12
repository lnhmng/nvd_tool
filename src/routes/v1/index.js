import express from 'express';
import {CONSTANTS} from '../../utils/constants.js';

import nvd_APIs from './nvd/index.js';
import tool_APIs from './tools/index.js';
import site_APIs from './sites/index.js';

const router = express.Router();

router.use(CONSTANTS.API_NVD, nvd_APIs);
router.use(CONSTANTS.API_TOOLS, tool_APIs);
router.use(CONSTANTS.API_SITES, site_APIs);

export default router