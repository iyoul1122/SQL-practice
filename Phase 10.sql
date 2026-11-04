USE UniversityDB;

# 10.1 教务驾驶舱：各系全景视图
# 输出每个系：系名、预算、教师人数、学生人数、课程门数。按预算降序
CREATE VIEW view_department AS
SELECT  d.dept_name as department,
        d.budget as budget,
        i.i_num as teacher_num,
        s.s_num as student_num,
        co.c_num as course_num
FROM department d
LEFT JOIN (
    SELECT dept_name, COUNT(*) as i_num
    FROM instructor
    GROUP BY dept_name) as i ON d.dept_name = i.dept_name 
LEFT JOIN (
    SELECT dept_name, COUNT(*) as s_num
    FROM student
    GROUP BY dept_name) as s ON d.dept_name = s.dept_name 
LEFT JOIN (
    SELECT dept_name, COUNT(*) as c_num
    FROM course
    GROUP BY dept_name) as co ON d.dept_name = co.dept_name
ORDER BY budget DESC;
SELECT * FROM view_department;

# 10.2 教师授课负荷排行
# 列出每位教师：ID、姓名、系、讲授的不同课程数、授课班次总数。未授课者显示 0。按课程数降序
SELECT i.ID, i.name, i.dept_name, 
       COUNT(DISTINCT course_id) as course_num,
       COUNT(course_id) as section_num
FROM instructor i LEFT JOIN teaches t on t.`ID` = i.`ID` 
GROUP BY i.`ID`, i.name, i.dept_name
ORDER BY course_num DESC, course_num, section_num;

# 10.3 学生成绩单（含未选课学生）
# 输出每个学生的 ID、姓名、系、课程号、课程名、成绩。未选课的学生也要出现（课程与成绩为 NULL）
SELECT s.`ID`, s.name, s.dept_name, t.course_id, c.title, t.grade
FROM student s 
LEFT JOIN takes t ON t.`ID` = s.`ID` 
LEFT JOIN course c ON c.course_id = t.course_id
ORDER BY s.`ID`, t.course_id;

# 10.4 课程先修链
# 列出每门课及其直接先修课（无先修课的显示 NULL），并按"是否为基础课"标注
SELECT c.course_id, c.title, p.prereq_id,
       CASE 
        WHEN p.prereq_id IS NULL THEN '基础课'  
        ELSE  '非基础课'
       END as level_tag
FROM course c LEFT JOIN prereq p ON p.course_id = c.course_id
ORDER BY c.course_id;

# 10.5 数据质量审计
# 找出"数据可疑"的记录：
# 1.从未被任何学生选修的课程；
SELECT c.*
FROM course c
WHERE NOT EXISTS (SELECT 1 FROM takes t WHERE t.course_id = c.course_id)
ORDER BY c.course_id;
# 2.选了课的学生的 tot_cred 为 0；
SELECT s.*, t.course_id
FROM student s LEFT JOIN takes t ON s.`ID` = t.`ID`
WHERE s.tot_cred = 0 AND t.course_id IS NOT NULL
ORDER BY s.`ID`;
# 3.成绩为 NULL 的选课记录对应的学生与课程。
SELECT `ID`, course_id
FROM takes
WHERE grade IS NULL;

# 10.6 期末模拟：用关系代数思考，用 SQL 落地
# 题目：找出"选修了计算机系开设的全部课程"的学生
SELECT s.`ID`, s.name
FROM student s
WHERE NOT EXISTS(
    SELECT course_id FROM course WHERE dept_name = 'Comp. Sci.'
    EXCEPT
    SELECT t.course_id FROM takes t WHERE t.`ID` = s.`ID`
    )
ORDER BY s.`ID`;
SELECT s.`ID`, s.name
FROM student s
WHERE NOT EXISTS(
    SELECT c.course_id
    FROM course c
    WHERE c.dept_name = 'Comp. Sci.'
        AND NOT EXISTS(
            SELECT 1
            FROM takes t
            WHERE t.`ID` = s.`ID` AND c.course_id = t.course_id
        )
    )
ORDER BY s.`ID`;