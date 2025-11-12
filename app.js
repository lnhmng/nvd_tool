import express from "express";
import http from "http";
import bodyParser from 'body-parser';
import cors from 'cors';
import dotenv from "dotenv";
import { CONSTANTS } from './src/utils/constants.js';
import routes from './src/routes/index.js';
import path from "path";

import { swaggerUi, swaggerSpec } from "./src/services/swagger.js";
import sequelize from "./src/configs/oracle-connect.js"; 

dotenv.config();

const app = express();
const __dirname = path.resolve();

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'src' ,'views'));
app.use('/public', express.static(path.join(__dirname, 'src', 'public')));

app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec));
app.use(bodyParser.json({ limit: CONSTANTS.MAX_JSON_BODY_REQUEST }));
app.use(cors({ origin: "*" }));
app.use('/', routes);

const startServer = async () => {
    try {
        await sequelize.authenticate();
        console.log('Kết nối Oracle đã được thiết lập thành công.');

        const server = http.createServer(app);
        const PORT = process.env.APP_PORT || 3300;

        server.listen(PORT, () => {
            console.log(`Server is running on ${PORT}`);
        });

    } catch (error) {
        console.error('Lỗi: ', error.message);
        process.exit(1);
    }
};

startServer();