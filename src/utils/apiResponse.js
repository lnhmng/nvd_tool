class ApiResponse {

    constructor({ success, code, message, data = null, paging = null }) {
        this.Success = success;
        this.Code = code;
        this.Message = message;
        this.Data = data;
        this.Paging = paging;
    }

    static ok(data, message = "Success", paging = null) {
        return new ApiResponse({
            success: true,
            code: "SUCCESS",
            message,
            data,
            paging
        });
    }

    static fail(code, message) {
        return new ApiResponse({
            success: false,
            code,
            message,
            data: null,
            paging: null
        });
    }
}

export default ApiResponse;
