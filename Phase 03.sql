USE UniversityDB;

# 阶段三：基础查询（select / where / order by）
# 3.1 投影 + 算术表达式 + as
# 查询全体教师的姓名与月薪（salary/12），结果按姓名升序。
SELECT name, salary/12 AS monthly_salary
FROM instructor
ORDER BY name;

# 3.2 DISTINCT 去重 / ALL 与默认去重对比
# 列出教师所在的不同系，并按系名升序；再对比 COUNT(DISTINCT 列) 与 COUNT(ALL 列) 的结果差异。
SELECT DISTINCT dept_name
FROM instructor
ORDER BY dept_name;
SELECT
    (SELECT COUNT(DISTINCT dept_name) 
     FROM instructor) AS distinct_dept_name,
    (SELECT COUNT(ALL dept_name)
     FROM instructor) AS all_dept_name;

# 3.4 AND 组合条件
# 查询计算机系中工资高于 70000 的教师姓名与工资，按姓名升序。
SELECT name, salary
FROM instructor
WHERE dept_name = 'Comp. Sci.' AND salary > 70000
ORDER BY name;

# 3.5 BETWEEN 闭区间
# 查询工资在 90000 到 100000 之间（含两端）的教师姓名与工资，按姓名升序。
SELECT name, salary
FROM instructor
WHERE salary BETWEEN 90000 AND 100000
ORDER BY name;

# 3.6 LIKE 通配：包含子串
# 查询姓名中含有字母 a 的教师全部信息，按姓名升序。
SELECT *
FROM instructor
WHERE name LIKE '%a%'
ORDER BY name;

# 3.7 LIKE 通配：定长匹配
# 查询姓名恰好为 4 个字符的教师全部信息，按姓名升序。
SELECT *
FROM instructor
WHERE name LIKE '____'
ORDER BY name;

# 3.8 ORDER BY 多列 + 分别指定升降序
# 按系名升序、系内工资降序，列出教师所在系、姓名与工资。
SELECT dept_name, name, salary
FROM instructor
ORDER BY dept_name, salary DESC;
