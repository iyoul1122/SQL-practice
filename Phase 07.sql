USE UniversityDB;

# 阶段七：数据库修改（用事务语句包裹）
# 7.1 DELETE 基础
# 删除 Music 系 ID 为 15151 的教师，前后各查一次教师总数对比，最后回滚。
START TRANSACTION;
SELECT COUNT(*) FROM instructor;
DELETE FROM instructor WHERE `ID` = '15151' AND dept_name = 'Music';
SELECT COUNT(*) FROM instructor;
ROLLBACK;

# 7.2 删除低于平均工资的教师 —— 「先算完再改」
# 删除工资低于全体平均工资的教师，用派生表先把平均值算完再删，最后回滚。
START TRANSACTION;
DELETE FROM instructor
WHERE salary < (
    SELECT avg_salary 
    FROM (SELECT AVG(salary) as avg_salary FROM instructor) as avg
);
ROLLBACK;

# 7.3 DELETE + 子查询
# 删除教学楼位于 Watson 的系所辖教师，最后回滚。
START TRANSACTION;
DELETE FROM instructor
WHERE dept_name IN (
    SELECT dept_name
    FROM department
    WHERE building = 'Watson'
);
ROLLBACK;

# 7.4 INSERT + SELECT 批量装载
# 把物理系且已获学分超过 50 的学生批量插入 instructor 表（工资置 18000），最后回滚。
START TRANSACTION;
INSERT INTO instructor
    SELECT ID, name, dept_name, 18000
    FROM student
    WHERE dept_name = 'Physics' AND tot_cred > 50;
ROLLBACK;

# 7.5 UPDATE + CASE 分档更新
# 用 CASE 分档涨薪：工资高于 80000 涨 3%，其余涨 5%，最后回滚。
START TRANSACTION;
UPDATE instructor
SET salary = CASE
    WHEN salary > 80000 THEN salary*1.03
    ELSE salary*1.05
    END
;
ROLLBACK;

# 7.6 多表 UPDATE
# 依据选课记录重算每位学生的 tot_cred 总学分（成绩为空或为 F 不计入，无记录记 0），最后回滚。
START TRANSACTION;
UPDATE student SET tot_cred = COALESCE((
    SELECT SUM(c.credits)
    FROM course as c JOIN takes as t on c.course_id = t.course_id
    WHERE student.`ID` = t.`ID` AND t.grade IS NOT NULL AND t.grade <> 'F'
), 0);
ROLLBACK;
