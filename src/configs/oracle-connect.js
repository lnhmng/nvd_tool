import { Sequelize } from 'sequelize';
import dotenv from 'dotenv';
import oracledb from 'oracledb'; 

dotenv.config();

try {
    oracledb.initOracleClient();
} catch (error) {
    console.error('Lỗi khi khởi tạo Oracle Client:', error);
}


const connectionUrl = process.env.ORACLE_CONNECTION_URL;

if (!connectionUrl) {
    throw new Error("Biến môi trường ORACLE_CONNECTION_URL không được định nghĩa trong file .env.");
}

const sequelize = new Sequelize(connectionUrl, {
    dialect: 'oracle',
    logging: false,
    dialectOptions: {
    }
});

export default sequelize;