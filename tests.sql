USE EmployeeDB;

-- ============================================================
-- PHẦN 0: LÀM SẠCH DỮ LIỆU (RESET)
-- Chạy đoạn này đầu tiên để xóa hết dữ liệu cũ làm lại từ đầu
-- ============================================================
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE Works_on;
TRUNCATE TABLE Employee;
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- PHẦN 1: TEST sp_AddEmployee
-- ============================================================

-- 1.1. Thêm SẾP TỔNG (Happy Path - Thành công)
-- Lương 5000, không có sếp (NULL)
CALL sp_AddEmployee('Nguyen', 'Van', 'Boss', 1, '1980-01-01', 'HCM', 'M', 5000, NULL, 1);
-- -> KỲ VỌNG: Chạy thành công (OK)

-- 1.2. Thêm NHÂN VIÊN (Happy Path - Thành công)
-- Lương 3000 (< 5000 của sếp ID 1) -> Hợp lệ
CALL sp_AddEmployee('Le', 'Thi', 'Linh', 2, '1995-05-05', 'HN', 'F', 3000, 1, 1);
-- -> KỲ VỌNG: Chạy thành công (OK)

-- 1.3. Thêm NHÂN VIÊN LƯƠNG CAO HƠN SẾP (Error Case - Phải báo lỗi)
-- Lương 6000 (> 5000 của sếp ID 1) -> Vi phạm
CALL sp_AddEmployee('Tran', 'Van', 'ThamLam', 3, '1990-01-01', 'DN', 'M', 6000, 1, 1);
-- -> KỲ VỌNG: BÁO LỖI ĐỎ "Error: Employee salary cannot exceed Supervisor salary."

-- 1.4. Thêm TRÙNG ID (Error Case - Phải báo lỗi)
-- Thêm lại ID số 2 đã có
CALL sp_AddEmployee('Phan', 'Trung', 'Lap', 2, '1999-01-01', 'HCM', 'M', 1000, 1, 1);
-- -> KỲ VỌNG: BÁO LỖI ĐỎ "Error: Employee ID already exists."

-- KIỂM TRA LẠI DỮ LIỆU SAU KHI TEST PHẦN 1
SELECT * FROM Employee;
-- -> KỲ VỌNG: Chỉ có 2 dòng (ID 1 và ID 2). Không có ID 3.

-- ============================================================
-- PHẦN 2: TEST sp_UpdateSalary
-- ============================================================

-- 2.1. Tăng lương hợp lệ (Happy Path)
-- Tăng cho Linh (ID 2) từ 3000 lên 4000 (< 5000 sếp)
CALL sp_UpdateSalary(2, 4000);
-- -> KỲ VỌNG: Thành công.

-- 2.2. Tăng lương lố (Error Case)
-- Tăng cho Linh (ID 2) lên 5500 (> 5000 sếp)
CALL sp_UpdateSalary(2, 5500);
-- -> KỲ VỌNG: BÁO LỖI ĐỎ "Error: New salary cannot exceed Supervisor salary."

-- 2.3. Update người không tồn tại (Error Case)
CALL sp_UpdateSalary(999, 5000);
-- -> KỲ VỌNG: BÁO LỖI ĐỎ "Error: Employee does not exist."

-- KIỂM TRA LẠI DỮ LIỆU SAU KHI TEST PHẦN 2
SELECT * FROM Employee WHERE EmpID = 2;
-- -> KỲ VỌNG: Lương là 4000.

-- ============================================================
-- PHẦN 3: TEST sp_AssignTask
-- ============================================================

-- 3.1. Gán việc đầu tiên (Happy Path)
-- Nhân viên 2, Dự án 100, Task 1
CALL sp_AssignTask(2, 100, 1, 10);
-- -> KỲ VỌNG: Thành công.

-- 3.2. Gán trùng việc (Error Case)
-- Gán lại đúng việc trên
CALL sp_AssignTask(2, 100, 1, 5);
-- -> KỲ VỌNG: BÁO LỖI ĐỎ "Error: Employee is already assigned..."

-- 3.3. Gán quá 3 việc trong 1 dự án (Error Case)
CALL sp_AssignTask(2, 100, 2, 5); -- Việc 2 (OK)
CALL sp_AssignTask(2, 100, 3, 5); -- Việc 3 (OK)
CALL sp_AssignTask(2, 100, 4, 5); -- Việc 4 (LỖI)
-- -> KỲ VỌNG: Lệnh cuối cùng BÁO LỖI ĐỎ "Error: Employee cannot be assigned more than 3 tasks..."

-- 3.4. Test giới hạn 4 người/dự án (Error Case)
-- Chuẩn bị: Thêm nhanh 3 nhân viên nữa (ID 4, 5, 6)
INSERT INTO Employee (EmpID, FName, LName, Salary, SupervisorID, DeptID) VALUES 
(4, 'A', 'Emp4', 1000, 1, 1),
(5, 'B', 'Emp5', 1000, 1, 1),
(6, 'C', 'Emp6', 1000, 1, 1);

-- Gán 4 người vào dự án 200 (OK)
CALL sp_AssignTask(2, 200, 1, 5); -- Người 1 (ID 2)
CALL sp_AssignTask(4, 200, 1, 5); -- Người 2 (ID 4)
CALL sp_AssignTask(5, 200, 1, 5); -- Người 3 (ID 5)
CALL sp_AssignTask(6, 200, 1, 5); -- Người 4 (ID 6)

-- Cố gắng gán người thứ 5 (Sếp ID 1) vào dự án 200
CALL sp_AssignTask(1, 200, 1, 5); 
-- -> KỲ VỌNG: BÁO LỖI ĐỎ "Error: Project can have a maximum of 4 employees."

-- ============================================================
-- PHẦN 4: TEST sp_GetEmployeesByDepartment
-- ============================================================
CALL sp_GetEmployeesByDepartment(1);
-- -> KỲ VỌNG: Ra danh sách tất cả nhân viên nãy giờ thêm vào (ID 1, 2, 4, 5, 6).