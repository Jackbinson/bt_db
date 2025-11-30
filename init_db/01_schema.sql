-- Tạo Database nếu chưa có (đề phòng)
CREATE DATABASE IF NOT EXISTS EmployeeDB;
USE EmployeeDB;

-- 1. Bảng Employee (Lưu thông tin nhân viên)
CREATE TABLE IF NOT EXISTS Employee (
    EmpID INT PRIMARY KEY,              -- Mã nhân viên
    FName VARCHAR(50),                  -- Tên
    MName VARCHAR(50),                  -- Tên lót
    LName VARCHAR(50),                  -- Họ
    DOB DATE,                           -- Ngày sinh
    Address VARCHAR(100),               -- Địa chỉ
    Gender CHAR(1),                     -- Giới tính (M/F)
    Salary DECIMAL(15, 2),              -- Lương
    SupervisorID INT,                   -- Mã người giám sát (Self-reference)
    DeptID INT,                         -- Mã phòng ban
    FOREIGN KEY (SupervisorID) REFERENCES Employee(EmpID)
);

-- 2. Bảng Works_on (Lưu phân công công việc)
CREATE TABLE IF NOT EXISTS Works_on (
    EmpID INT,                          -- Mã nhân viên
    ProjID INT,                         -- Mã dự án
    TaskNo INT,                         -- Mã công việc
    Hours DECIMAL(5, 2),                -- Số giờ làm
    PRIMARY KEY (EmpID, ProjID, TaskNo), -- Khóa chính phức hợp để tránh trùng việc
    FOREIGN KEY (EmpID) REFERENCES Employee(EmpID)
);

-- Dữ liệu mẫu giả lập (Để test không bị lỗi khóa ngoại)
-- Bạn có thể xóa phần này nếu muốn database sạch
INSERT INTO Employee (EmpID, FName, LName, Salary, SupervisorID, DeptID) VALUES 
(1, 'Big', 'Boss', 10000, NULL, 1); -- Sếp tổng (để nhân viên khác tham chiếu)