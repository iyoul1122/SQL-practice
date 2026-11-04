USE UniversityDB;

# 阶段八：NULL 与三值逻辑

# 8.1 IS NULL 与 = NULL 的差别
# 统计成绩为空的行数
SELECT COUNT(*)
FROM takes
WHERE grade IS NULL;

# 8.2 三值逻辑的短路规则
SELECT COUNT(*) 
FROM instructor 
WHERE salary > 50000 AND dept_name IS NULL;
SELECT name, salary 
FROM instructor 
WHERE salary > 90000 OR dept_name IS NULL;

# 8.3 NOT IN 遇到 NULL
# 找出没有导师的学生
SELECT *
FROM student s 
WHERE NOT EXISTS (
    SELECT 1 
    FROM advisor a 
    WHERE a.s_ID = s.ID);
SELECT * 
FROM student 
WHERE ID NOT IN (
    SELECT `s_ID` 
    FROM advisor);
# 找出没有带任何学生的教师。
SELECT *
FROM instructor
WHERE `ID` NOT IN(
    SELECT `i_ID`
    FROM advisor
);

# 8.4 NULL 与手写 IN 列表
SELECT * FROM takes;
SELECT * FROM takes WHERE grade NOT IN ('A','B','C', NULL);
SELECT * FROM takes WHERE grade NOT IN ('A','B','C');

# 8.5 聚集函数忽略 NULL
# 先看全表，再分别用 COUNT(*) 与 COUNT(grade) 按成绩分组统计。
SELECT * FROM takes;
SELECT grade, COUNT(*) as n
FROM takes
GROUP BY grade
ORDER BY grade;
SELECT grade, COUNT(grade) as n
FROM takes
GROUP BY grade
ORDER BY grade;
