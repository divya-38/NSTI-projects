CREATE DATABASE IF NOT EXISTS EmployeePayroll;
USE EmployeePayroll;

-- 2) Departments table
CREATE TABLE Departments (
    DepartmentID   INT             AUTO_INCREMENT PRIMARY KEY,
    DepartmentName VARCHAR(50)     NOT NULL
) ENGINE=InnoDB;

-- 3) Employees table
CREATE TABLE Employees (
    EmployeeID     INT             AUTO_INCREMENT PRIMARY KEY,
    FirstName      VARCHAR(50)     NOT NULL,
    LastName       VARCHAR(50)     NOT NULL,
    DateOfBirth    DATE            NOT NULL,
    Gender         CHAR(1)         NOT NULL
                              CHECK (Gender IN ('M','F')),
    HireDate       DATE            NOT NULL,
    DepartmentID   INT             NOT NULL,
    CONSTRAINT FK_Employees_Departments
        FOREIGN KEY (DepartmentID)
        REFERENCES Departments(DepartmentID)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 4) Salaries table (history of salary changes)
CREATE TABLE Salaries (
    SalaryID       INT             AUTO_INCREMENT PRIMARY KEY,
    EmployeeID     INT             NOT NULL,
    Salary         DECIMAL(10,2)   NOT NULL,
    StartDate      DATE            NOT NULL,
    EndDate        DATE            NULL,
    CONSTRAINT FK_Salaries_Employees
        FOREIGN KEY (EmployeeID)
        REFERENCES Employees(EmployeeID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT CHK_SalaryDates
        CHECK (EndDate IS NULL OR EndDate >= StartDate)
) ENGINE=InnoDB;

-- 5) Seed with sample data

-- Departments
INSERT INTO Departments (DepartmentName) VALUES
  ('Human Resources'),
  ('Finance'),
  ('Technology'),
  ('Marketing');

-- Employees
INSERT INTO Employees (FirstName, LastName, DateOfBirth, Gender, HireDate, DepartmentID) VALUES
  ('John', 'Doe',   '1990-05-15', 'M', '2018-01-20', 3),
  ('Jane', 'Smith', '1985-11-30', 'F', '2019-03-10', 2),
  ('Peter','Jones', '1992-07-22', 'M', '2020-06-01', 3),
  ('Mary', 'Brown', '1988-02-10', 'F', '2017-09-15', 1);

-- Initial Salaries (all EndDate = NULL as “current”)
INSERT INTO Salaries (EmployeeID, Salary, StartDate, EndDate) VALUES
  (1, 60000.00, '2018-01-20', NULL),
  (2, 75000.00, '2019-03-10', NULL),
  (3, 65000.00, '2020-06-01', NULL),
  (4, 55000.00, '2017-09-15', NULL);

-- 6) Sample salary update (history-safe)

-- a) Close out the old salary
UPDATE Salaries
SET EndDate = '2021-01-01'
WHERE EmployeeID = 1
  AND EndDate IS NULL;

-- b) Insert the new salary record
INSERT INTO Salaries (EmployeeID, Salary, StartDate, EndDate)
VALUES (1, 65000.00, '2021-01-01', NULL);

-- 7) Sample CRUD + Queries

-- READ: all employees
SELECT * FROM Employees;

-- READ: employees with department names
SELECT
    e.EmployeeID,
    e.FirstName,
    e.LastName,
    d.DepartmentName
FROM Employees AS e
JOIN Departments AS d
  ON e.DepartmentID = d.DepartmentID;

-- READ: current salaries
SELECT
    e.FirstName,
    e.LastName,
    s.Salary,
    s.StartDate
FROM Employees AS e
JOIN Salaries AS s
  ON e.EmployeeID = s.EmployeeID
WHERE s.EndDate IS NULL;

-- UPDATE: move Mary Brown (EmployeeID=4) to Marketing (DepartmentID=4)
UPDATE Employees
SET DepartmentID = 4
WHERE EmployeeID = 4;

-- DELETE: remove employee 4 and their salary history (cascades)
DELETE FROM Employees
WHERE EmployeeID = 4;

--------------------------------------------------------------------------------
-- 8) Joins & Advanced Queries
--------------------------------------------------------------------------------

-- INNER JOIN
SELECT
    e.FirstName,
    e.LastName,
    d.DepartmentName
FROM Employees AS e
INNER JOIN Departments AS d
  ON e.DepartmentID = d.DepartmentID;

-- LEFT JOIN (all employees, even without a department)
SELECT
    e.FirstName,
    e.LastName,
    d.DepartmentName
FROM Employees AS e
LEFT JOIN Departments AS d
  ON e.DepartmentID = d.DepartmentID;

-- “RIGHT JOIN” equivalent (all departments, even if zero employees)
SELECT
    d.DepartmentName,
    e.FirstName,
    e.LastName
FROM Departments AS d
LEFT JOIN Employees AS e
  ON e.DepartmentID = d.DepartmentID;

-- AGGREGATE: count employees per department
SELECT
    d.DepartmentName,
    COUNT(e.EmployeeID) AS NumEmployees
FROM Departments AS d
LEFT JOIN Employees AS e
  ON e.DepartmentID = d.DepartmentID
GROUP BY d.DepartmentName;

-- AGGREGATE: average current salary by department
SELECT
    d.DepartmentName,
    AVG(s.Salary) AS AvgSalary
FROM Departments AS d
JOIN Employees AS e
  ON e.DepartmentID = d.DepartmentID
JOIN Salaries AS s
  ON e.EmployeeID = s.EmployeeID
WHERE s.EndDate IS NULL
GROUP BY d.DepartmentName;

-- FILTER & ORDER
SELECT
    e.FirstName,
    e.LastName,
    s.Salary
FROM Employees AS e
JOIN Salaries AS s
  ON e.EmployeeID = s.EmployeeID
WHERE s.EndDate IS NULL
  AND s.Salary > 65000
ORDER BY s.Salary DESC;

-- PATTERN MATCHING
SELECT
    FirstName, LastName
FROM Employees
WHERE LastName LIKE 'S%';  -- last names starting with “S”

-- SET MEMBERSHIP
SELECT
    FirstName, LastName, DepartmentID
FROM Employees
WHERE DepartmentID IN (2,3);  -- Finance or Technology