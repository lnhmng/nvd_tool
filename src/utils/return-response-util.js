class ReturnResponseUtil {
    static returnResponse(res, statusCode, isSuccess, message, data = []) {
      if (data.length !== 0) {
        res.status(statusCode).json({
          isSuccess: isSuccess,
          message: message,
          data: data,
        });
      } else {    
        res.status(statusCode).json({
          isSuccess: isSuccess,
          message: message,
        });
      }
    }
  }
  
export default ReturnResponseUtil;
  