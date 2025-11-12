// src/controllers/WebController.js

class WebController {
    // Dữ liệu người dùng giả định dùng chung
    static DUMMY_USER = {
        id: 'Y1800649',
        name: 'Nguyễn Văn A'
    };

    // Dữ liệu bảng Order giả định
    static DUMMY_ORDERS = [
        { id: 1, no: '00010007484', process: 'FDFE127776-003', plannedQty: 2000, plannedStartDate: '2025-11-26 16:35:29', plannedFinishDate: '2025-11-26 16:35:29', customer: 'AMAZON', orderType: 'NORMAL', orderStatus: '创建', productLine: 'HUAYI HOPPER/49' },
        { id: 2, no: '00010007453', process: 'AQYCC-A90', plannedQty: 1000, plannedStartDate: '2025-11-25 09:15:24', plannedFinishDate: '2025-11-25 09:15:24', customer: 'DELL', orderType: 'NORMAL', orderStatus: '创建', productLine: 'ACQUA' },
        { id: 3, no: 'W0225111007', process: 'M12789403-G3-E', plannedQty: 24, plannedStartDate: '2025-11-11 00:00:00', plannedFinishDate: '2025-11-11 00:00:00', customer: 'MICROSOFT', orderType: 'REWORK', orderStatus: '进行中', productLine: 'NME C2100' },
        { id: 4, no: 'W0225111006', process: 'M127B28-001', plannedQty: 2, plannedStartDate: '2025-11-11 00:00:00', plannedFinishDate: '2025-11-11 00:00:00', customer: 'MICROSOFT', orderType: 'REWORK', orderStatus: '进行中', productLine: 'NME C2140' },
        { id: 5, no: 'W0225111005', process: '68B.24875-0009-3AB3', plannedQty: 8500, plannedStartDate: '2025-11-17 08:35:25', plannedFinishDate: '2025-11-17 08:35:25', customer: 'MICROSOFT', orderType: 'NORMAL', orderStatus: '创建', productLine: 'NME CA514' },
    ];
    
    // Dữ liệu Status Card giả định cho Dashboard
    static DUMMY_STATUS = {
        pendingCount: 15,
        completeCount: 450,
        totalComplete: 5000,
        currentTime: new Date().toLocaleTimeString('vi-VN', {hour: '2-digit', minute: '2-digit', second: '2-digit'}),
        currentDate: new Date().toLocaleDateString('vi-VN', { year: 'numeric', month: 'numeric', day: 'numeric' })
    };


    static async getDashboard(req, res) {
        const data = { 
            title: 'Tổng Quan Hệ Thống',
            activeMenu: 'dashboard', // Highlight 'Trang chủ' trên Sidebar
            user: WebController.DUMMY_USER,
            statusData: WebController.DUMMY_STATUS
        };
        // Render file dashboard.ejs. Giả sử nó được nhúng vào main_layout.ejs
        res.render('pages/dashboard', data);
    }

    static async getOrderManagement(req, res) {
        const data = { 
            title: 'Quản Lý Công Lệnh', // Đã sửa tên title cho đúng với giao diện
            activeMenu: 'order_management', // Highlight 'Quản lý lệnh sản xuất' trên Sidebar
            user: WebController.DUMMY_USER,
            orders: WebController.DUMMY_ORDERS // Truyền dữ liệu bảng vào EJS
        };
        // Render file order_management.ejs
        res.render('pages/order_management', data);
    }
}

export default WebController;