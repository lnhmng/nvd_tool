import express from 'express';
import { CONSTANTS } from '../../../utils/constants.js';

import NVD_QUERY_CONTROLLER from '../../../controllers/nvd/query_controller.js';

const nvd = express.Router();

nvd.get('/', (req, res) => {
    res.json({ message: 'Hello World', status: 'OK' });
})

nvd.post(CONSTANTS.API_RESULT, NVD_QUERY_CONTROLLER.get_data_from_database)

export default nvd;