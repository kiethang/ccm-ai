CREATE DATABASE Cost_Central;
USE Cost_Central;


CREATE TABLE Providers (
    provider_id INTEGER PRIMARY KEY AUTOINCREMENT,                     -- Mã định danh duy nhất của nhà cung cấp
    provider_name VARCHAR(100) NOT NULL,                                 -- Tên của nhà cung cấp
    contact_info VARCHAR(255),                                           -- Thông tin liên hệ của nhà cung cấp
    website VARCHAR(255),                                               -- Trang web của nhà cung cấp
    provider_type VARCHAR(50) NOT NULL CHECK(provider_type IN ('Cloud', 'SaaS', 'Hardware')), -- Loại nhà cung cấp
    account_manager_name VARCHAR(100),                                   -- Tên quản lý tài khoản
    account_manager_email VARCHAR(100),                                  -- Email của quản lý tài khoản
    contract_start_date DATE NOT NULL,                                   -- Ngày bắt đầu hợp đồng
    contract_end_date DATE NOT NULL,                                     -- Ngày kết thúc hợp đồng
    payment_terms VARCHAR(50) NOT NULL,                                  -- Điều khoản thanh toán
    status VARCHAR(50) DEFAULT 'Active' CHECK(status IN ('Active', 'Inactive', 'Suspended')), -- Trạng thái nhà cung cấp
    -- Ràng buộc: ngày kết thúc lớn hơn ngày bắt đầu
    CHECK (contract_end_date > contract_start_date), 
    -- Ràng buộc: kiểm tra định dạng email
    CHECK (account_manager_email LIKE '%@%.%')
);

CREATE TABLE Projects (
    project_id INTEGER PRIMARY KEY AUTOINCREMENT,                 -- Mã định danh duy nhất của dự án
    project_name TEXT NOT NULL,                                     -- Tên dự án
    description TEXT,                                               -- Mô tả chi tiết về dự án
    start_date DATE NOT NULL,                                        -- Ngày bắt đầu dự án
    end_date DATE,                                                  -- Ngày kết thúc dự án
    project_manager TEXT NOT NULL,                                  -- Tên quản lý dự án
    department TEXT NOT NULL,                                       -- Phòng ban chịu trách nhiệm
    priority TEXT CHECK(priority IN ('Low', 'Medium', 'High', 'Critical')) DEFAULT 'Medium', -- Mức độ ưu tiên
    status TEXT CHECK(status IN ('Planning', 'In Progress', 'Completed', 'On Hold', 'Cancelled')) DEFAULT 'Planning', -- Trạng thái của dự án
    budget_allocated DECIMAL(15, 2) NOT NULL DEFAULT 0.00,           -- Ngân sách được phân bổ
    client_name TEXT,                                               -- Tên khách hàng
    CHECK (end_date > start_date),                                  -- Ràng buộc: ngày kết thúc lớn hơn ngày bắt đầu
    CHECK (budget_allocated >= 0)                                    -- Kiểm tra ngân sách phải >= 0
);

CREATE TABLE Resources (
    resource_id INTEGER PRIMARY KEY AUTOINCREMENT,                       -- Mã định danh duy nhất của tài nguyên
    resource_name VARCHAR(100) NOT NULL,                                   -- Tên của tài nguyên
    fk_provider_id INTEGER NOT NULL,                                       -- Khóa ngoại liên kết với bảng nhà cung cấp
    resource_type VARCHAR(50) NOT NULL,                                     -- Loại tài nguyên
    configuration TEXT,                                                    -- Cấu hình chi tiết của tài nguyên
    subscription_type VARCHAR(50) NOT NULL CHECK(subscription_type IN ('Monthly', 'Yearly')), -- Loại hình đăng ký
    unit_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK(unit_price >= 0), -- Giá trên mỗi đơn vị
    recommended_capacity INT NOT NULL DEFAULT 1 CHECK(recommended_capacity > 0), -- Dung lượng khuyến nghị
    efficiency_rating DECIMAL(3, 2) NOT NULL CHECK(efficiency_rating BETWEEN 0.00 AND 1.00), -- Chỉ số hiệu suất
    -- Ràng buộc kiểm tra giá trị cho efficiency_rating
    CHECK (efficiency_rating BETWEEN 0.00 AND 1.00),
    -- Ràng buộc kiểm tra unit_price phải >= 0
    CHECK (unit_price >= 0),
    -- Ràng buộc kiểm tra recommended_capacity phải > 0
    CHECK (recommended_capacity > 0),
    -- Khóa ngoại liên kết với bảng Providers
    FOREIGN KEY (fk_provider_id) REFERENCES Providers(provider_id)
);

CREATE TABLE Costs (
    cost_id INTEGER PRIMARY KEY AUTOINCREMENT,
    fk_project_id INTEGER NOT NULL,
    fk_resource_id INTEGER NOT NULL,
    cost_amount DECIMAL(15, 2) NOT NULL CHECK (cost_amount > 0),
    cost_date DATE NOT NULL,
    cost_type TEXT NOT NULL CHECK (cost_type IN ('Operational', 'Subscription')),
    billing_cycle TEXT NOT NULL CHECK (billing_cycle IN ('Monthly', 'Quarterly', 'Annually')),
    payment_method TEXT NOT NULL CHECK (payment_method IN ('Credit Card', 'Bank Transfer')),
    invoice_number TEXT UNIQUE NOT NULL,
    notes TEXT,
    -- Ràng buộc khóa ngoại
    FOREIGN KEY (fk_project_id) REFERENCES Projects(project_id),
    FOREIGN KEY (fk_resource_id) REFERENCES Resources(resource_id),
    CHECK (cost_amount > 0)
);

CREATE TABLE Cost_Alerts (
    alert_id INTEGER PRIMARY KEY AUTOINCREMENT,                         -- Mã định danh duy nhất của cảnh báo chi phí
    fk_project_id INTEGER,                                              -- Khóa ngoại liên kết với bảng dự án
    fk_resource_id INTEGER,                                             -- Khóa ngoại liên kết với bảng tài nguyên
    alert_type TEXT NOT NULL CHECK (alert_type IN ('Budget Exceed', 'Unusual Spending')),  -- Loại cảnh báo
    threshold_amount DECIMAL(15, 2) CHECK (threshold_amount > 0),       -- Ngưỡng cảnh báo chi phí
    current_amount DECIMAL(15, 2) CHECK (current_amount >= 0),          -- Giá trị chi phí hiện tại
    alert_date DATETIME NOT NULL,                                       -- Ngày giờ tạo cảnh báo
    status TEXT DEFAULT 'Active' CHECK (status IN ('Active', 'Resolved', 'Ignored')),  -- Trạng thái của cảnh báo
    notification_sent BOOLEAN DEFAULT FALSE,                            -- Đã gửi thông báo chưa
    -- Ràng buộc khóa ngoại
    FOREIGN KEY (fk_project_id) REFERENCES Projects(project_id),
    FOREIGN KEY (fk_resource_id) REFERENCES Resources(resource_id),
    CHECK (threshold_amount > 0),                                       -- Ràng buộc: threshold_amount > 0
    CHECK (current_amount >= 0)                                         -- Ràng buộc: current_amount >= 0
);

CREATE TABLE Resource_Utilization (
    utilization_id INTEGER PRIMARY KEY AUTOINCREMENT,                  -- Mã định danh duy nhất của bản ghi sử dụng tài nguyên
    fk_resource_id INTEGER NOT NULL,                                    -- Khóa ngoại liên kết với bảng tài nguyên
    fk_project_id INTEGER NOT NULL,                                     -- Khóa ngoại liên kết với bảng dự án
    record_date DATE NOT NULL,                                           -- Ngày ghi nhận sử dụng tài nguyên
    cpu_utilization DECIMAL(5, 2) NOT NULL CHECK (cpu_utilization >= 0 AND cpu_utilization <= 100),  -- Tỷ lệ sử dụng CPU (%)
    memory_utilization DECIMAL(5, 2) NOT NULL CHECK (memory_utilization >= 0 AND memory_utilization <= 100),  -- Tỷ lệ sử dụng bộ nhớ (%)
    storage_utilization DECIMAL(5, 2) NOT NULL CHECK (storage_utilization >= 0 AND storage_utilization <= 100),  -- Tỷ lệ sử dụng bộ nhớ lưu trữ (%)
    network_traffic DECIMAL(15, 2) NOT NULL,                             -- Lượng dữ liệu truyền qua mạng
    active_users INT NOT NULL DEFAULT 0,                                 -- Số người dùng hoạt động
    performance_score DECIMAL(4, 2) NOT NULL CHECK (performance_score >= 0 AND performance_score <= 10), -- Điểm hiệu suất tài nguyên (0 - 10)
    -- Ràng buộc khóa ngoại
    FOREIGN KEY (fk_resource_id) REFERENCES Resources(resource_id),
    FOREIGN KEY (fk_project_id) REFERENCES Projects(project_id),
    CHECK (cpu_utilization >= 0 AND cpu_utilization <= 100),            -- Ràng buộc kiểm tra giá trị CPU
    CHECK (memory_utilization >= 0 AND memory_utilization <= 100),      -- Ràng buộc kiểm tra giá trị Memory
    CHECK (storage_utilization >= 0 AND storage_utilization <= 100)     -- Ràng buộc kiểm tra giá trị Storage
);

CREATE TABLE User (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,                            -- Mã định danh duy nhất của người dùng
    username VARCHAR(50) UNIQUE NOT NULL,                                  -- Tên đăng nhập của người dùng
    password_hash VARCHAR(255) NOT NULL,                                   -- Mã hóa mật khẩu
    email VARCHAR(100) UNIQUE NOT NULL,                                    -- Địa chỉ email của người dùng
    full_name VARCHAR(100) NOT NULL,                                       -- Họ và tên của người dùng
    role TEXT CHECK(role IN ('Admin', 'Project Manager', 'User')) NOT NULL, -- Vai trò của người dùng
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,                          -- Thời gian tạo tài khoản
    last_login DATETIME,                                                   -- Thời gian đăng nhập gần nhất
    status TEXT CHECK(status IN ('Active', 'Inactive', 'Suspended')) DEFAULT 'Active', -- Trạng thái của tài khoản
    -- Ràng buộc kiểm tra tên đăng nhập
    CHECK (username NOT LIKE '%[^A-Za-z0-9_]%'),                            -- Ràng buộc kiểm tra tính hợp lệ của tên đăng nhập (chỉ cho phép ký tự chữ, số và dấu gạch dưới)
    CHECK (email LIKE '%@%.%')                                              -- Ràng buộc kiểm tra định dạng email hợp lệ
);

CREATE TABLE User_Project_Access (
    access_id INTEGER PRIMARY KEY AUTOINCREMENT,                            -- Mã định danh duy nhất cho quyền truy cập
    fk_user_id INTEGER NOT NULL,                                             -- ID người dùng
    fk_project_id INTEGER NOT NULL,                                          -- ID dự án
    access_level TEXT CHECK(access_level IN ('Read-Only', 'Read-Write', 'Admin')) NOT NULL, -- Cấp độ truy cập vào dự án
    granted_by INTEGER NOT NULL,                                             -- ID của người cấp quyền truy cập
    granted_at DATETIME DEFAULT CURRENT_TIMESTAMP,                           -- Thời gian cấp quyền
    expires_at DATETIME,                                                     -- Thời gian hết hạn quyền truy cập
    status TEXT CHECK(status IN ('Active', 'Expired', 'Revoked')) DEFAULT 'Active', -- Trạng thái quyền truy cập
    -- Ràng buộc khóa ngoại
    FOREIGN KEY (fk_user_id) REFERENCES User(user_id),
    FOREIGN KEY (fk_project_id) REFERENCES Projects(project_id),
    CHECK (expires_at IS NULL OR expires_at > granted_at)                    -- Ràng buộc: expires_at phải lớn hơn granted_at nếu có giá trị
);



INSERT INTO Providers (provider_name, contact_info, website, provider_type, account_manager_name, account_manager_email, contract_start_date, contract_end_date, payment_terms, status)
VALUES
('CloudCorp', '123 Cloud Street, NY', 'http://cloudcorp.com', 'Cloud', 'John Doe', 'johndoe@cloudcorp.com', '2023-01-01', '2025-01-01', 'Net 30', 'Active'),
('SaaSGlobal', '456 SaaS Avenue, CA', 'http://saasglobal.com', 'SaaS', 'Jane Smith', 'janesmith@saasglobal.com', '2022-05-15', '2024-05-15', 'Net 60', 'Active'),
('HardwarePro', '789 Hardware Rd, TX', 'http://hardwarepro.com', 'Hardware', 'Mike Johnson', 'mikejohnson@hardwarepro.com', '2021-10-01', '2023-10-01', 'Net 45', 'Inactive'),
('TechSolutions', '101 Tech Blvd, FL', 'http://techsolutions.com', 'Cloud', 'Emily Davis', 'emilydavis@techsolutions.com', '2024-01-01', '2026-01-01', 'Net 30', 'Active'),
('SoftwaresInc', '102 Software Lane, CA', 'http://softwaresinc.com', 'SaaS', 'Robert Brown', 'robertbrown@softwaresinc.com', '2023-02-10', '2025-02-10', 'Net 90', 'Suspended'),
('DataSystems', '203 Data St, TX', 'http://datasystems.com', 'Cloud', 'Alice Wilson', 'alicewilson@datasystems.com', '2022-07-15', '2024-07-15', 'Net 60', 'Active'),
('QuantumTech', '304 Quantum Ave, IL', 'http://quantumtech.com', 'Hardware', 'David Clark', 'davidclark@quantumtech.com', '2023-06-01', '2025-06-01', 'Net 45', 'Active'),
('NextGenCloud', '505 Nextgen Blvd, NY', 'http://nextgencloud.com', 'Cloud', 'Sarah Lewis', 'sarahlewis@nextgencloud.com', '2022-11-10', '2024-11-10', 'Net 30', 'Active'),
('GlobalSaaS', '606 Global Rd, CA', 'http://globalsaas.com', 'SaaS', 'William Harris', 'williamharris@globalsaas.com', '2023-04-05', '2025-04-05', 'Net 90', 'Suspended'),
('FutureTech', '707 Future St, WA', 'http://futuretech.com', 'Hardware', 'Sophia Martinez', 'sophiamartinez@futuretech.com', '2021-12-20', '2023-12-20', 'Net 45', 'Inactive');


INSERT INTO Projects (project_name, description, start_date, end_date, project_manager, department, priority, status, budget_allocated, client_name)
VALUES
('CloudMigration', 'Migrate data to the cloud for better scalability.', '2024-01-01', '2025-01-01', 'John Doe', 'IT', 'High', 'In Progress', 50000.00, 'ABC Corp'),
('SaaS Integration', 'Integrate SaaS solutions into company workflows.', '2024-02-01', '2025-02-01', 'Jane Smith', 'IT', 'Medium', 'Planning', 30000.00, 'XYZ Ltd'),
('Hardware Setup', 'Setup hardware infrastructure for the new office.', '2024-03-01', '2025-03-01', 'Michael Lee', 'Operations', 'Low', 'Completed', 20000.00, 'LMN Group'),
('Data Security', 'Enhance data security measures and protocols.', '2024-04-01', '2025-04-01', 'Sarah Wong', 'Security', 'Critical', 'In Progress', 70000.00, 'PQR Corp'),
('Network Optimization', 'Improve network performance and reduce latency.', '2024-05-01', '2025-05-01', 'David Clark', 'Network', 'High', 'On Hold', 40000.00, 'DEF Solutions'),
('Software Development', 'Develop internal software to streamline operations.', '2024-06-01', '2025-06-01', 'Emily Davis', 'Development', 'Medium', 'In Progress', 60000.00, 'MNO Inc'),
('Cloud Infrastructure', 'Build cloud infrastructure for a scalable platform.', '2024-07-01', '2025-07-01', 'Robert Brown', 'Cloud', 'Critical', 'Planning', 80000.00, 'RST Ltd'),
('SaaS Optimization', 'Optimize the existing SaaS application for better performance.', '2024-08-01', '2025-08-01', 'Linda Green', 'Development', 'Low', 'Completed', 25000.00, 'JKL Tech');


INSERT INTO Resources (resource_name, fk_provider_id, resource_type, configuration, subscription_type, unit_price, recommended_capacity, efficiency_rating)
VALUES
('Cloud Storage', 1, 'Storage', '50 TB', 'Monthly', 1000.00, 50, 0.95),
('SaaS License', 2, 'Software', 'Team Collaboration', 'Yearly', 200.00, 100, 0.90),  -- changed 'Annual' to 'Yearly'
('Hardware Servers', 3, 'Hardware', 'Rackmount Servers', 'Yearly', 3000.00, 20, 0.85),  -- changed 'Annual' to 'Yearly'
('Firewall Protection', 1, 'Security', 'Advanced Firewall', 'Monthly', 500.00, 10, 0.98),
('Virtual Machines', 2, 'Cloud', 'Virtual Machine for Developers', 'Monthly', 1500.00, 30, 0.92),
('Data Backup', 3, 'Storage', 'Cloud Backup Services', 'Yearly', 800.00, 40, 0.91),  -- changed 'Annual' to 'Yearly'
('Server Hosting', 1, 'Hosting', 'Dedicated Server Hosting', 'Yearly', 1200.00, 25, 0.93),
('SaaS Management Tool', 2, 'Software', 'Project Management', 'Monthly', 350.00, 60, 0.89);


INSERT INTO Costs (fk_project_id, fk_resource_id, cost_amount, cost_date, cost_type, billing_cycle, payment_method, invoice_number, notes)
VALUES
(1, 1, 1000.00, '2024-01-15', 'Subscription', 'Monthly', 'Credit Card', 'INV1234', 'Cloud Storage for January'),
(2, 2, 500.00, '2024-02-10', 'Subscription', 'Quarterly', 'Bank Transfer', 'INV5678', 'SaaS License for Q1'),
(3, 3, 3000.00, '2024-03-05', 'Subscription', 'Annually', 'Credit Card', 'INV9101', 'Hardware Servers for 2024'),
(4, 4, 500.00, '2024-04-15', 'Operational', 'Monthly', 'Bank Transfer', 'INV1122', 'Firewall Protection for April'),
(5, 5, 1500.00, '2024-05-01', 'Subscription', 'Monthly', 'Credit Card', 'INV3344', 'Virtual Machines for May'),
(6, 6, 800.00, '2024-06-10', 'Subscription', 'Annually', 'Bank Transfer', 'INV5566', 'Data Backup Service for 2024'),
(7, 7, 1200.00, '2024-07-01', 'Subscription', 'Annually', 'Credit Card', 'INV7788', 'Server Hosting for 2024'),
(8, 8, 350.00, '2024-08-20', 'Operational', 'Monthly', 'Bank Transfer', 'INV9900', 'SaaS Management Tool for August');



INSERT INTO Cost_Alerts (fk_project_id, fk_resource_id, alert_type, threshold_amount, current_amount, alert_date, status, notification_sent)
VALUES
(1, 1, 'Budget Exceed', 1200.00, 1500.00, '2024-01-20', 'Active', FALSE),
(2, 2, 'Unusual Spending', 700.00, 500.00, '2024-02-15', 'Resolved', TRUE),
(3, 3, 'Budget Exceed', 3000.00, 3200.00, '2024-03-10', 'Active', FALSE),
(4, 4, 'Unusual Spending', 600.00, 500.00, '2024-04-18', 'Resolved', TRUE),
(5, 5, 'Budget Exceed', 1700.00, 1500.00, '2024-05-05', 'Active', FALSE),
(6, 6, 'Unusual Spending', 900.00, 800.00, '2024-06-15', 'Resolved', TRUE),
(7, 7, 'Budget Exceed', 1300.00, 1200.00, '2024-07-05', 'Active', FALSE),
(8, 8, 'Unusual Spending', 400.00, 350.00, '2024-08-25', 'Resolved', TRUE);


INSERT INTO User (username, password_hash, email, full_name, role, created_at, last_login, status)
VALUES
('admin_user', 'hashed_password_1', 'admin@example.com', 'Admin User', 'Admin', '2024-01-01 10:00:00', '2024-12-18 08:00:00', 'Active'),
('pm_user', 'hashed_password_2', 'pm@example.com', 'Project Manager', 'Project Manager', '2024-01-05 09:00:00', '2024-12-18 08:30:00', 'Active'),
('regular_user', 'hashed_password_3', 'user@example.com', 'Regular User', 'User', '2024-02-01 12:00:00', '2024-12-17 07:30:00', 'Active'),
('john_doe', 'hashed_password_4', 'john@example.com', 'John Doe', 'User', '2024-03-15 15:00:00', '2024-12-18 09:00:00', 'Active'),
('jane_doe', 'hashed_password_5', 'jane@example.com', 'Jane Doe', 'Project Manager', '2024-04-10 08:00:00', '2024-12-17 09:30:00', 'Inactive'),
('alice_smith', 'hashed_password_6', 'alice@example.com', 'Alice Smith', 'User', '2024-05-05 13:00:00', '2024-12-16 10:00:00', 'Active'),
('bob_jones', 'hashed_password_7', 'bob@example.com', 'Bob Jones', 'Admin', '2024-06-01 11:00:00', '2024-12-17 11:00:00', 'Suspended'),
('charlie_brown', 'hashed_password_8', 'charlie@example.com', 'Charlie Brown', 'Project Manager', '2024-07-20 14:00:00', '2024-12-18 07:45:00', 'Active'),
('david_wilson', 'hashed_password_9', 'david@example.com', 'David Wilson', 'User', '2024-08-11 16:00:00', '2024-12-18 08:00:00', 'Active'),
('eva_martin', 'hashed_password_10', 'eva@example.com', 'Eva Martin', 'User', '2024-09-22 17:00:00', '2024-12-18 09:30:00', 'Active');


INSERT INTO Resource_Utilization (fk_resource_id, fk_project_id, record_date, cpu_utilization, memory_utilization, storage_utilization, network_traffic, active_users, performance_score)
VALUES
(1, 1, '2024-01-10', 75.00, 60.00, 85.00, 5000.00, 10, 8.5),
(2, 2, '2024-02-20', 55.00, 65.00, 90.00, 4500.00, 15, 7.8),
(3, 3, '2024-03-05', 85.00, 80.00, 70.00, 6000.00, 12, 9.2),
(4, 1, '2024-04-15', 60.00, 50.00, 80.00, 4000.00, 9, 8.0),
(5, 2, '2024-05-10', 70.00, 55.00, 75.00, 4200.00, 14, 8.7),
(6, 3, '2024-06-25', 65.00, 60.00, 90.00, 4700.00, 11, 8.3),
(7, 2, '2024-07-12', 80.00, 70.00, 65.00, 4800.00, 16, 8.9),
(8, 1, '2024-08-22', 50.00, 60.00, 85.00, 3900.00, 8, 7.5),
(9, 3, '2024-09-18', 75.00, 75.00, 80.00, 5100.00, 13, 9.0),
(10, 2, '2024-10-05', 60.00, 55.00, 90.00, 4600.00, 10, 8.1);


INSERT INTO User_Project_Access (fk_user_id, fk_project_id, access_level, granted_by, granted_at, expires_at, status)
VALUES
(1, 1, 'Admin', 1, '2024-01-01 10:00:00', '2024-12-31 23:59:59', 'Active'),
(2, 2, 'Read-Write', 1, '2024-01-05 09:00:00', '2024-06-30 23:59:59', 'Active'),
(3, 3, 'Read-Only', 2, '2024-02-15 14:00:00', '2024-12-31 23:59:59', 'Active'),
(4, 1, 'Read-Write', 2, '2024-03-01 08:00:00', '2024-06-30 23:59:59', 'Active'),
(5, 2, 'Read-Only', 1, '2024-04-10 10:00:00', '2024-12-31 23:59:59', 'Expired'), -- Thay 'Inactive' bằng 'Expired'
(6, 3, 'Admin', 3, '2024-05-05 11:00:00', '2024-12-31 23:59:59', 'Active'),
(7, 1, 'Read-Write', 1, '2024-06-15 09:00:00', '2024-12-31 23:59:59', 'Revoked'), -- Thay 'Suspended' bằng 'Revoked'
(8, 2, 'Admin', 3, '2024-07-01 16:00:00', '2024-12-31 23:59:59', 'Active'),
(9, 3, 'Read-Only', 2, '2024-08-20 17:00:00', '2024-12-31 23:59:59', 'Active'),
(10, 2, 'Read-Write', 1, '2024-09-10 12:00:00', '2024-12-31 23:59:59', 'Active');


SELECT * FROM User_Project_Access
WHERE access_level = 'Admin';
