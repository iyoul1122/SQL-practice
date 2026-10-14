USE UniversityDB;

#阶段六：嵌套子查询
# 6.1 IN 子查询
# 查询开设在 Taylor 楼所在系的全部课程号与课程名，按课程号升序。
SELECT course_id, title
FROM course
WHERE dept_name IN (
    SELECT dept_name
    FROM department
    WHERE building = 'Taylor'
)
ORDER BY course_id;

# 6.2 NOT IN 与枚举集合
# 查询既不属于计算机系也不属于物理系的教师姓名，按姓名升序。
SELECT name
FROM instructor
WHERE dept_name NOT IN ('Comp. Sci.', 'Physics')
ORDER BY name;

# 6.4 ALL（全称量词）
# 查询工资高于计算机系所有教师的教师姓名与工资，按工资升序。
SELECT name, salary
FROM instructor
WHERE salary > ALL(
    SELECT salary 
    FROM instructor
    WHERE dept_name = 'Comp. Sci.'
)
ORDER BY salary;

# 6.5 EXISTS
# 查询 2017 年秋季开课、且该课程在 2018 年春季也开过的课程号（去重），按课程号升序。
SELECT DISTINCT course_id
FROM section as s
WHERE year = 2017 AND semester = 'Fall' AND EXISTS(
    SELECT course_id
    FROM section as s_
    WHERE year = 2018 AND semester = "Spring" AND s.course_id = s_.course_id
)
ORDER BY course_id;

# 6.6 双层否定实现「全部」
# 查询选修了生物系开设的全部课程的学生 ID 与姓名，按 ID 升序。
SELECT s.`ID`, s.name
FROM student as s
WHERE NOT EXISTS((
        SELECT course_id
        FROM course
        WHERE dept_name = 'Biology'
    ) EXCEPT (
        SELECT t.course_id
        FROM takes as t
        WHERE t.`ID` = s.`ID`
    )
)
ORDER BY s.ID;

# 6.7 FROM 子句中的子查询（临时关系）
# 把「各系平均工资」作为临时关系，从中筛出平均工资高于 80000 的系，按系名升序。
SELECT dept_name, avg_salary
FROM (
    SELECT dept_name, AVG(salary) as avg_salary
    FROM instructor
    GROUP BY dept_name
) AS dept_avg_salary
WHERE avg_salary > 80000
ORDER BY dept_name;

# 6.8 WITH 子句
# 用 WITH 取出最高预算值，再查出预算等于该值的系名与预算。
WITH max_budget(value) as (
    SELECT MAX(budget)
    FROM department
)
SELECT d.dept_name, d.budget
FROM department as d, max_budget as m
WHERE d.budget = m.value;

# 6.9 标量子查询
# 列出每个系的系名及其教师人数，按系名升序。
SELECT d.dept_name,
       (
        SELECT COUNT(*)
        FROM instructor as i
        WHERE i.dept_name = d.dept_name
       ) as num_instructors
FROM department as d
ORDER BY d.dept_name;

# 6.10 UNIQUE 的替代实现（验证查询：找出 2017 年开设多个班的课程）
# 找出 2017 年开设了 1 个以上班级的课程号，按课程号升序，用于验证 UNIQUE 的替代实现。
SELECT c.course_id
FROM course as c
WHERE (
    SELECT COUNT(*)
    FROM section as s
    WHERE s.year = 2017 AND s.course_id = c.course_id
) > 1
ORDER BY c.course_id;
