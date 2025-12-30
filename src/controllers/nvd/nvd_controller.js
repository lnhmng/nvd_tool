import SNInfoRepo from '../../repositories/nvd/nvd_repository.js'
import ApiResponse from '../../utils/apiResponse.js';
import ErrorCode from '../../utils/errorCode.js';

class SN_DETAIL_INFO_CONTROLLER {

    static async getSNDetailInfo(req, res) {
        try {

            const SERIAL_NUMBER = req.query.SERIAL_NUMBER;

            const results = await SNInfoRepo.getSNDetailInfo(SERIAL_NUMBER);

            console.log(results)

        } catch (error) {
            console.log(error.message)
            return 
        }
    }

}

export default SN_DETAIL_INFO_CONTROLLER;