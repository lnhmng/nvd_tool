import express from 'express';

import { CONSTANTS } from '../../../utils/constants.js';

import NVDController from '../../../controllers/nvd/nvd_controller.js';

const nvd = express.Router();

nvd.get(
    CONSTANTS.API_SN_INFORMATION,
    NVDController.getSNDetailInfo
)

export default nvd;