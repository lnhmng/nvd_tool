import express from 'express';
import { CONSTANTS } from '../../../utils/constants.js';

import webController from '../../../controllers/site/webController.js';


const site = express.Router();

site.get('/', (req, res) => {
    res.json({ message: 'Hello World', status: 'OK' });
})

site.get('/admin', webController.getDashboard)

site.get('/manage', webController.getOrderManagement)

export default site;