USE EmployeeDB;

DROP PROCEDURE IF EXISTS sp_AddEmployee;
DROP PROCEDURE IF EXISTS sp_UpdateSalary;
DROP PROCEDURE IF EXISTS sp_AssignTask;
DROP PROCEDURE IF EXISTS sp_GetEmployeesByDepartment;

DELIMITER $$

-- =============================================
-- 1. sp_AddEmployee
-- Yêu cầu: Thêm nhân viên, check trùng ID, check lương <= Sếp
-- =============================================
CREATE PROCEDURE sp_AddEmployee(
    IN p_LName VARCHAR(50),
    IN p_MName VARCHAR(50),
    IN p_FName VARCHAR(50),
    IN p_EmpID INT,
    IN p_DOB DATE,
    IN p_Address VARCHAR(100),
    IN p_Gender CHAR(1),
    IN p_Salary DECIMAL(15, 2),
    IN p_SupervisorID INT,
    IN p_DeptID INT
)
BEGIN
    DECLARE v_SuperSalary DECIMAL(15, 2);

    -- [Check 1] Kiểm tra ID nhân viên đã tồn tại chưa [cite: 11]
    IF EXISTS (SELECT 1 FROM Employee WHERE EmpID = p_EmpID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Employee ID already exists.';
    END IF;

    -- [Check 2] Kiểm tra lương không được vượt quá lương Supervisor [cite: 12]
    IF p_SupervisorID IS NOT NULL THEN
        SELECT Salary INTO v_SuperSalary 
        FROM Employee 
        WHERE EmpID = p_SupervisorID;
        
        -- Nếu tìm thấy sếp và lương nhân viên mới cao hơn lương sếp
        IF v_SuperSalary IS NOT NULL AND p_Salary > v_SuperSalary THEN
            SIGNAL SQLSTATE '45000' -- Trả về mã lỗi [cite: 13]
            SET MESSAGE_TEXT = 'Error: Employee salary cannot exceed Supervisor salary.';
        END IF;
    END IF;

    -- Thực hiện thêm mới [cite: 9]
    INSERT INTO Employee (EmpID, FName, MName, LName, DOB, Address, Gender, Salary, SupervisorID, DeptID)
    VALUES (p_EmpID, p_FName, p_MName, p_LName, p_DOB, p_Address, p_Gender, p_Salary, p_SupervisorID, p_DeptID);
END$$

-- =============================================
-- 2. sp_UpdateSalary
-- Yêu cầu: Update lương, check nhân viên tồn tại, check lương <= Sếp
-- =============================================
CREATE PROCEDURE sp_UpdateSalary(
    IN p_EmpID INT,
    IN p_NewSalary DECIMAL(15, 2)
)
BEGIN
    DECLARE v_SupervisorID INT;
    DECLARE v_SuperSalary DECIMAL(15, 2);

    -- [Check 1] Kiểm tra nhân viên có tồn tại không [cite: 16]
    IF NOT EXISTS (SELECT 1 FROM Employee WHERE EmpID = p_EmpID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Employee does not exist.';
    END IF;

    -- Lấy ID sếp của nhân viên này
    SELECT SupervisorID INTO v_SupervisorID FROM Employee WHERE EmpID = p_EmpID;

    -- [Check 2] Kiểm tra lương mới so với lương sếp [cite: 17]
    IF v_SupervisorID IS NOT NULL THEN
        SELECT Salary INTO v_SuperSalary FROM Employee WHERE EmpID = v_SupervisorID;
        
        IF v_SuperSalary IS NOT NULL AND p_NewSalary > v_SuperSalary THEN
            SIGNAL SQLSTATE '45000' -- Trả về mã lỗi [cite: 18]
            SET MESSAGE_TEXT = 'Error: New salary cannot exceed Supervisor salary.';
        END IF;
    END IF;

    -- Thực hiện update [cite: 14]
    UPDATE Employee SET Salary = p_NewSalary WHERE EmpID = p_EmpID;
END$$

-- =============================================
-- 3. sp_AssignTask
-- Yêu cầu: Gán task, check trùng task, max 3 tasks/người/dự án, max 4 người/dự án
-- =============================================
CREATE PROCEDURE sp_AssignTask(
    IN p_EmpID INT,
    IN p_ProjID INT,
    IN p_TaskNo INT,
    IN p_Hours DECIMAL(5, 2)
)
BEGIN
    DECLARE v_EmployeeTaskCount INT;
    DECLARE v_ProjectEmpCount INT;

    -- [Check 1] Kiểm tra nhân viên đã được gán task này chưa (Tránh trùng lặp) [cite: 21]
    IF EXISTS (SELECT 1 FROM Works_on WHERE EmpID = p_EmpID AND ProjID = p_ProjID AND TaskNo = p_TaskNo) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Employee is already assigned to this specific task.';
    END IF;

    -- [Check 2] Một nhân viên không được làm quá 3 task trong cùng 1 dự án [cite: 23]
    SELECT COUNT(*) INTO v_EmployeeTaskCount
    FROM Works_on
    WHERE EmpID = p_EmpID AND ProjID = p_ProjID;

    IF v_EmployeeTaskCount >= 3 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Employee cannot be assigned more than 3 tasks in the same project.';
    END IF;

    -- [Check 3] Một dự án tối đa 4 nhân viên làm việc [cite: 23]
    -- Đếm số nhân viên ĐANG làm việc trong dự án này (DISTINCT để đếm số người, không đếm số task)
    SELECT COUNT(DISTINCT EmpID) INTO v_ProjectEmpCount
    FROM Works_on
    WHERE ProjID = p_ProjID;

    -- Nếu dự án đã đủ 4 người, VÀ người đang được thêm vào KHÔNG nằm trong danh sách 4 người đó (người mới) -> Chặn
    IF v_ProjectEmpCount >= 4 AND NOT EXISTS (SELECT 1 FROM Works_on WHERE EmpID = p_EmpID AND ProjID = p_ProjID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Project can have a maximum of 4 employees.';
    END IF;

    -- Thực hiện thêm mới vào bảng Works_on [cite: 20]
    INSERT INTO Works_on (EmpID, ProjID, TaskNo, Hours)
    VALUES (p_EmpID, p_ProjID, p_TaskNo, p_Hours);
END$$

-- =============================================
-- 4. sp_GetEmployeesByDepartment
-- Yêu cầu: Lấy danh sách nhân viên theo phòng ban
-- =============================================
CREATE PROCEDURE sp_GetEmployeesByDepartment(
    IN p_DeptID INT
)
BEGIN
    -- Trả về result set [cite: 25]
    SELECT EmpID, FName, MName, LName, DOB, Address, Gender, Salary, SupervisorID
    FROM Employee
    WHERE DeptID = p_DeptID;
END$$

DELIMITER ;