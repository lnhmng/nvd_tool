import express from 'express'
import {CONSTANTS} from '../utils/constants.js'

import apiVersion1 from './v1/index.js'

const router = express.Router()

router.use(CONSTANTS.API_VERSION_V1, apiVersion1)

export default router