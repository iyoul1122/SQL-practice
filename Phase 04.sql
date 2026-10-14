USE UniversityDB;

# 阶段四：连接与集合运算
# 4.2 用 NATURAL JOIN 连接
# 用自然连接找出所有授课教师的 ID 与姓名（去重），按姓名升序。
SELECT DISTINCT ID, name
FROM instructor NATURAL JOIN teaches
ORDER BY name;

# 4.3 外连接：找出「没有教过课」的教师（NOT IN 写法）
# 列出所有从未出现在 teaches 表中的教师全部信息，按姓名升序。
SELECT *
FROM instructor
WHERE ID NOT IN(
    SELECT ID
    FROM teaches
)
ORDER BY name;

# 4.4 三表连接：教师 → 授课 → 课程班
# 查询 2018 年春季学期每位授课教师的姓名及其开课的课程号、教学楼、教室号，按姓名升序。
SELECT i.name, s.course_id, s.building, s.room_number
FROM instructor as i
JOIN teaches as t ON i.`ID` = t.`ID`
JOIN section as s ON t.course_id = s.course_id
                  AND t.sec_id   = s.sec_id
                  AND t.semester = s.semester
                  AND t.year     = s.year
WHERE s.year = 2018 AND s.semester = 'Spring'
ORDER BY i.name;

# 4.5 自连接与元组变量
# 找出工资高于计算机系任意某位教师工资的教师姓名（去重），按姓名升序。
SELECT DISTINCT i.name
FROM instructor as i, instructor as i_
WHERE i.salary > i_.salary AND i_.dept_name = 'Comp. Sci.'
ORDER BY i.name;

# 4.8 EXCEPT —— 差集
# 找出 2017 年秋季开课、但 2018 年春季未开课的课程号，按课程号升序。
(
    SELECT course_id
    FROM section
    WHERE year = 2017 AND semester = 'Fall'
) EXCEPT 
(
    SELECT course_id
    FROM section
    WHERE year = 2018 AND semester = 'Spring'
)
ORDER BY course_id;
