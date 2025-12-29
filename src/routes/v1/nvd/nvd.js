import express from 'express';

import { CONSTANTS } from '../../../utils/constants.js';

import NVDController from '../../../controllers/nvd/R_WIP_TRACKING_T.js';

const nvd = express.Router();

nvd.get(
    CONSTANTS.API_SN_INFORMATION,
    NVDController.getResult
)

export default nvd;