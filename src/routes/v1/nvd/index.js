import express from 'express';
import nvd from './query.js';

const router = express.Router();

router.use("/", nvd)

export default router;