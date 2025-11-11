import express from 'express';
import { CONSTANTS } from '../../../utils/constants.js';

import NVD_QUERY_CONTROLLER, { upload } from '../../../controllers/nvd/query_controller.js';

const nvd = express.Router();

nvd.get('/', (req, res) => {
    res.json({ message: 'Hello World', status: 'OK' });
})

nvd.post(CONSTANTS.API_RESULT, NVD_QUERY_CONTROLLER.get_data_from_database)
nvd.post(CONSTANTS.API_WEIGHT_LOG, upload.single("file"), NVD_QUERY_CONTROLLER.r_weight_log_t)

export default nvd;