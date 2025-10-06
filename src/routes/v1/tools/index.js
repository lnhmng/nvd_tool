import express from 'express';

import tool from './tool.js';

const router = express.Router();

router.use("/", tool);

export default router;