USE UniversityDB;

# 阶段九：索引与查询优化

# 9.1 造一张大表
CREATE TABLE big_enroll (
    enroll_id   INT AUTO_INCREMENT PRIMARY KEY,
    student_id  INT           NOT NULL,
    course_id   INT           NOT NULL,
    score       DECIMAL(5,2)  NOT NULL,
    enroll_date DATE          NOT NULL
);
INSERT INTO big_enroll (student_id, course_id, score, enroll_date)
SELECT (rn % 5000) + 1,                                    -- 5000 个学生
       (rn % 300) + 1,                                     -- 300 门课
       (rn % 101),                                         -- 0~100 分
       DATE_ADD('2024-01-01', INTERVAL (rn % 365) DAY)     -- 一年内分布
FROM (
    SELECT @rn := @rn + 1 AS rn
    FROM information_schema.columns a,
         information_schema.columns b,
         (SELECT @rn := 0) r
    LIMIT 100000
) x;
SELECT COUNT(*) FROM big_enroll;   -- 100000

# 9.2 性能测量开关 & 9.3 无索引查询测量
EXPLAIN SELECT COUNT(*)
FROM big_enroll
WHERE student_id = 4242;
FLUSH STATUS;       -- 清零会话级计数器
SELECT COUNT(*) FROM big_enroll WHERE student_id = 4242;
SHOW SESSION STATUS LIKE 'Handler_read%';
EXPLAIN ANALYZE SELECT COUNT(*) FROM big_enroll WHERE student_id = 4242;

# 9.4 建索引查询
CREATE INDEX ix_enroll_stu ON big_enroll(student_id);
ANALYZE TABLE big_enroll;       -- 刷新统计信息（InnoDB 的索引基数统计）
EXPLAIN SELECT COUNT(*) FROM big_enroll WHERE student_id = 4242;
FLUSH STATUS;
SELECT COUNT(*) FROM big_enroll WHERE student_id = 4242;
SHOW SESSION STATUS LIKE 'Handler_read%';

# 9.5 覆盖索引
CREATE INDEX ix_enroll_cover ON big_enroll(student_id, score);
ANALYZE TABLE big_enroll;       -- 刷新统计信息（InnoDB 的索引基数统计）
EXPLAIN SELECT student_id, score FROM big_enroll WHERE student_id = 4242;

# 9.6 索引失效场景：列上套函数 / 隐式转换
-- A：可走索引
EXPLAIN SELECT COUNT(*) FROM big_enroll WHERE student_id = 4242;
-- B：列上套表达式
EXPLAIN SELECT COUNT(*) FROM big_enroll WHERE student_id + 0 = 4242;

-- C：列上套函数
CREATE INDEX ix_enroll_year ON big_enroll(enroll_date);
EXPLAIN SELECT COUNT(*) FROM big_enroll WHERE YEAR(enroll_date) = 2024;
-- D：日期范围写法（推荐）
EXPLAIN SELECT COUNT(*) FROM big_enroll 
WHERE enroll_date >= '2024-01-01' AND enroll_date < '2025-01-01';

-- E：字符串列与数字比较（隐式转换）——先准备一列字符串
ALTER TABLE big_enroll ADD COLUMN course_code VARCHAR(10);
UPDATE big_enroll SET course_code = CONCAT('C', course_id);
CREATE INDEX ix_enroll_code ON big_enroll(course_code);
ANALYZE TABLE big_enroll;
-- E-1：类型一致
EXPLAIN SELECT COUNT(*) FROM big_enroll WHERE course_code = 'C42';
-- E-2：字符串列与数字比较
EXPLAIN SELECT COUNT(*) FROM big_enroll WHERE course_code = 1;

# 9.8 嵌套子查询改写成连接
# 把相关子查询改写成连接，并用 EXPLAIN 对比
--原查询：复杂度 O(n*n)
EXPLAIN SELECT b.student_id, b.course_id, b.score
FROM big_enroll b
WHERE b.score > (
    SELECT AVG(x.score)
    FROM big_enroll x
    WHERE x.course_id = b.course_id);
--现查询：复杂度 O(n+C)
EXPLAIN SELECT b.student_id, b.course_id, b.score   
FROM big_enroll as b
JOIN (
    SELECT course_id, AVG(score) as avg_score
    FROM big_enroll
    GROUP BY course_id) as s
    ON b.course_id = s.course_id
WHERE b.score > s.avg_score;

# 9.9 表数 ≤ 4 与反规范化设计 
# 学生 + 导师 + 导师所在系 的查询需要 4 张表（student / advisor / instructor / department）
# 请用视图把这个高频查询固化下来，让应用层只查 1 张"表"
--原查询
SELECT s.ID        AS student_id,
       s.name      AS student_name,
       s.dept_name AS student_dept,
       i.ID        AS advisor_id,
       i.name      AS advisor_name,
       d.building  AS advisor_building
FROM student    s
LEFT JOIN advisor    a ON s.ID = a.s_ID
LEFT JOIN instructor i ON a.i_ID = i.ID
LEFT JOIN department d ON i.dept_name = d.dept_name
ORDER BY s.ID;
-- 方案 A：视图（逻辑层合并）
CREATE VIEW v_student_advisor AS
SELECT s.ID AS student_id, s.name AS student_name, s.dept_name AS student_dept,
       i.ID AS advisor_id, i.name AS advisor_name, d.building AS advisor_building
FROM student as s
LEFT JOIN advisor as a ON s.ID = a.s_ID
LEFT JOIN instructor as i ON a.i_ID = i.ID
LEFT JOIN department as d ON i.dept_name = d.dept_name;
SELECT * FROM v_student_advisor WHERE student_dept = 'Comp. Sci.';
-- 方案 B：反规范化（物理层合并，真实建一张宽表）
CREATE TABLE student_advisor_flat (
    student_id       VARCHAR(5),
    student_name     VARCHAR(20),
    student_dept     VARCHAR(20),
    advisor_name     VARCHAR(20),
    advisor_building VARCHAR(15)
);
INSERT INTO student_advisor_flat
SELECT s.ID, s.name, s.dept_name, i.name, d.building
FROM student s
LEFT JOIN advisor    a ON s.ID = a.s_ID
LEFT JOIN instructor i ON a.i_ID = i.ID
LEFT JOIN department d ON i.dept_name = d.dept_name;

# 9.10 收尾：清理实验对象
DROP VIEW  IF EXISTS v_student_advisor;
DROP TABLE IF EXISTS student_advisor_flat;
DROP TABLE IF EXISTS big_enroll;
SHOW INDEX FROM instructor;