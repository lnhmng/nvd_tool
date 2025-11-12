class WebController {
    static async getDashboard(req, res) {
        const data = { title: 'Tổng Quan Hệ Thống' };
        res.render('pages/dashboard', data);
    }

    static async getOrderManagement(req, res) {
        const data = { title: 'Quản Lý Lệnh Sản Xuất' };
        res.render('pages/order_management', data);
    }
}

export default WebController;