USE UniversityDB;

# 阶段五：聚集函数与分组
# 5.1 单值聚集
# 查询计算机系教师的平均工资。
SELECT AVG(salary) as avg_salary
FROM instructor
WHERE dept_name = 'Comp. Sci.';

# 5.2 COUNT(*) 与 COUNT(列) 的差别
# 对 takes 表统计总行数、grade 非空的行数、不同学生人数，观察三者差异。
SELECT COUNT(*)             as all_rows,
       COUNT(grade)         as not_null_grade,
       COUNT(DISTINCT `ID`) as distinct_students
FROM takes;

# 5.4 HAVING 对组筛选
# 按系分组统计教师人数与平均工资，只保留平均工资高于 80000 的系，按系名升序。
SELECT dept_name,
       AVG(salary)  as avg_salary,
       COUNT(*)     as teachers_num
FROM instructor
GROUP BY dept_name
HAVING AVG(salary) > 80000
ORDER BY dept_name;

# 5.5 分组 + 外连接：统计含零的组
# 统计每门课程的选课人数（无人选修的课程也要显示 0），按人数降序、课程号升序。
SELECT  c.course_id, c.title,
        COUNT(t.ID) as stud_num
FROM course as c LEFT JOIN takes as t ON c.course_id = t.course_id
GROUP BY c.course_id, c.title
ORDER BY COUNT(t.ID) DESC, c.course_id;

# 5.6 多表分组：学生已获学分
# 统计每位学生已获得的总学分（排除成绩为空或为 F 的记录），按学分降序。
SELECT s.`ID`, s.name, SUM(c.credits) as earned_credits
FROM student as s
JOIN takes as t ON s.`ID` = t.`ID`
JOIN course as c ON t.course_id = c.course_id
WHERE t.grade IS NOT NULL AND t.grade <> 'F'
GROUP BY s.`ID`, s.name
ORDER BY earned_credits DESC;
