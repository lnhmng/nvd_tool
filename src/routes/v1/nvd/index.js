import express from 'express';

import nvd from './nvd.js';

const router = express.Router();

router.use("/", nvd);

export default router;