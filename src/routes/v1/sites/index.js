import express from 'express';
import site from './site.js';

const router = express.Router();

router.use("/", site)

export default router;