-- Active: 1790786545269@@127.0.0.1@3306@universitydb
-- Active: 1790786545269@@127.0.0.1@3306

# 阶段一：建库建表
CREATE DATABASE UniversityDB;

USE UniversityDB;

CREATE TABLE classroom(
    building    VARCHAR(15),
    room_number VARCHAR(7),
    capacity    NUMERIC(4,0),
    PRIMARY KEY(building, room_number)
);

CREATE TABLE department(
    dept_name   VARCHAR(20),
    building    VARCHAR(15),
    budget      NUMERIC(12,2),
    PRIMARY KEY(dept_name)
);

CREATE TABLE course(
    course_id   VARCHAR(8),
    title       VARCHAR(50),
    dept_name   VARCHAR(20),
    credits     NUMERIC(2,0),
    PRIMARY KEY(course_id),
    FOREIGN KEY(dept_name) REFERENCES department(dept_name) ON DELETE SET NULL
);

CREATE TABLE instructor(
    ID          CHAR(5),
    name        VARCHAR(20) NOT NULL,
    dept_name   VARCHAR(20),
    salary      NUMERIC(8,2),
    PRIMARY KEY(ID),
    FOREIGN KEY(dept_name) REFERENCES department(dept_name) ON DELETE SET NULL
);

CREATE TABLE section(
    course_id       VARCHAR(8),
    sec_id          VARCHAR(8),
    semester        VARCHAR(6),
    year            NUMERIC(4,0),
    building        VARCHAR(15),
    room_number     VARCHAR(7),
    time_slot_id    VARCHAR(4),
    PRIMARY KEY(course_id, sec_id, semester, year),
    FOREIGN KEY(course_id) REFERENCES course(course_id) ON DELETE CASCADE,
    FOREIGN KEY(building, room_number) REFERENCES classroom(building, room_number) ON DELETE SET NULL
);

CREATE TABLE teaches(
    ID          CHAR(5),
    course_id   VARCHAR(8),
    sec_id      VARCHAR(8),
    semester    VARCHAR(6),
    year        NUMERIC(4,0),
    PRIMARY KEY(ID, course_id, sec_id, semester, year),
    FOREIGN KEY(ID) REFERENCES instructor(ID) ON DELETE CASCADE,
    FOREIGN KEY(course_id, sec_id, semester, year)
        REFERENCES section(course_id, sec_id, semester, year) ON DELETE CASCADE
);

CREATE TABLE student(
    ID          VARCHAR(5),
    name        VARCHAR(20) NOT NULL,
    dept_name   VARCHAR(20),
    tot_cred    NUMERIC(3,0),
    PRIMARY KEY(ID),
    FOREIGN KEY(dept_name) REFERENCES department(dept_name) ON DELETE SET NULL
);

CREATE TABLE takes(
    ID          VARCHAR(5),
    course_id   VARCHAR(8),
    sec_id      VARCHAR(8),
    semester    VARCHAR(6),
    year        NUMERIC(4,0),
    grade       VARCHAR(2),
    PRIMARY KEY(ID, course_id, year),
    FOREIGN KEY(ID) REFERENCES student(ID) ON DELETE CASCADE,
    FOREIGN KEY(course_id) REFERENCES course(course_id) ON DELETE CASCADE
);

CREATE TABLE advisor(
    s_ID    VARCHAR(5),
    i_ID    CHAR(5),
    PRIMARY KEY(s_ID),
    FOREIGN KEY(s_ID) REFERENCES student(ID) ON DELETE CASCADE,
    FOREIGN KEY(i_ID) REFERENCES instructor(ID) ON DELETE SET NULL
);

CREATE TABLE prereq(
    course_id   VARCHAR(8),
    prereq_id   VARCHAR(8),
    PRIMARY KEY(course_id, prereq_id),
    FOREIGN KEY(course_id) REFERENCES course(course_id) ON DELETE CASCADE,
    FOREIGN KEY(prereq_id) REFERENCES course(course_id) ON DELETE CASCADE
);

SELECT 
    TABLE_NAME AS referencing_relation,
    COLUMN_NAME AS fk_column,
    REFERENCED_TABLE_NAME AS referenced_relation,
    REFERENCED_COLUMN_NAME AS pk_column
FROM 
    information_schema.KEY_COLUMN_USAGE
WHERE 
    TABLE_SCHEMA = 'universitydb' 
    AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY 
    referencing_relation;

ALTER TABLE student ADD COLUMN age INT;
SELECT ID, name, age FROM student;
ALTER TABLE student DROP COLUMN age;
ALTER TABLE instructor ADD CONSTRAINT ck_salary CHECK (salary > 0);
ALTER TABLE student MODIFY COLUMN tot_cred DECIMAL(3,0) DEFAULT 0;
DESC student;
SHOW CREATE TABLE student;

# 阶段二：数据装载
INSERT INTO classroom VALUES
 ('Packard','101',500),('Painter','514',100),('Taylor','312',100),
 ('Watson','100',100),('Watson','120',100);

INSERT INTO department VALUES
 ('Biology','Watson',90000),('Comp. Sci.','Taylor',100000),
 ('Elec. Eng.','Taylor',85000),('Finance','Painter',120000),
 ('History','Painter',50000),('Music','Packard',80000),
 ('Physics','Watson',70000);

INSERT INTO course VALUES
 ('BIO-101','Intro. to Biology','Biology',4),
 ('BIO-301','Genetics','Biology',4),
 ('BIO-399','Computational Biology','Biology',3),
 ('CS-101','Intro. to Computer Science','Comp. Sci.',4),
 ('CS-190','Game Design','Comp. Sci.',4),
 ('CS-315','Robotics','Comp. Sci.',3),
 ('CS-347','Database System Concepts','Comp. Sci.',3),
 ('EE-181','Intro. to Digital Systems','Elec. Eng.',3),
 ('FIN-201','Investment Banking','Finance',3),
 ('FIN-301','Risk Management','Finance',3),
 ('HIS-351','World History','History',3),
 ('MU-199','Music Video Production','Music',3),
 ('PHY-101','Physical Principles','Physics',4),
 ('PHY-201','Quantum Physics','Physics',3);

INSERT INTO instructor VALUES
 ('10101','Srinivasan','Comp. Sci.',65000),
 ('12121','Wu','Finance',90000),
 ('15151','Mozart','Music',40000),
 ('22222','Einstein','Physics',95000),
 ('32343','El Said','History',60000),
 ('33456','Gold','Physics',87000),
 ('45565','Katz','Comp. Sci.',75000),
 ('58583','Califieri','History',62000),
 ('76543','Singh','Finance',80000),
 ('76766','Crick','Biology',72000),
 ('83821','Brandt','Comp. Sci.',92000),
 ('98345','Kim','Elec. Eng.',80000);

INSERT INTO student VALUES
 ('00128','Zhang','Comp. Sci.',102),
 ('11223','Lee','Comp. Sci.',0),
 ('12345','Shankar','Comp. Sci.',32),
 ('19991','Brandt','History',80),
 ('23121','Chavez','Finance',110),
 ('44553','Peltier','Physics',56),
 ('45678','Levy','Physics',46),
 ('54321','Williams','Comp. Sci.',54),
 ('55739','Sanchez','Music',38),
 ('70557','Snow','Physics',0),
 ('78901','Brown','Comp. Sci.',58),
 ('98765','Bourikas','Elec. Eng.',98),
 ('98988','Tanaka','Biology',120);

INSERT INTO section VALUES
 ('BIO-101','1','Spring',2018,'Painter','514','B'),
 ('BIO-301','1','Fall',2017,'Painter','514','A'),
 ('BIO-399','1','Spring',2018,'Watson','100','E'),
 ('CS-101','1','Fall',2017,'Packard','101','A'),
 ('CS-101','1','Spring',2018,'Packard','101','A'),
 ('CS-101','2','Fall',2017,'Taylor','312','B'),
 ('CS-190','1','Spring',2018,'Taylor','312','E'),
 ('CS-315','1','Fall',2017,'Watson','120','D'),
 ('CS-347','1','Fall',2017,'Taylor','312','A'),
 ('CS-347','1','Spring',2018,'Taylor','312','A'),
 ('EE-181','1','Spring',2018,'Taylor','312','C'),
 ('FIN-201','1','Fall',2017,'Painter','514','B'),
 ('FIN-301','1','Spring',2018,'Packard','101','C'),
 ('HIS-351','1','Fall',2017,'Painter','514','C'),
 ('MU-199','1','Spring',2018,'Packard','101','D'),
 ('PHY-101','1','Fall',2017,'Watson','100','A'),
 ('PHY-201','1','Spring',2018,'Watson','120','D');

INSERT INTO teaches VALUES
 ('10101','CS-101','1','Fall',2017),
 ('10101','CS-315','1','Fall',2017),
 ('10101','CS-347','1','Fall',2017),
 ('12121','FIN-201','1','Fall',2017),
 ('15151','MU-199','1','Spring',2018),
 ('22222','PHY-101','1','Fall',2017),
 ('22222','PHY-201','1','Spring',2018),
 ('32343','HIS-351','1','Fall',2017),
 ('33456','BIO-399','1','Spring',2018),
 ('45565','CS-101','1','Spring',2018),
 ('45565','CS-101','2','Fall',2017),
 ('76543','FIN-301','1','Spring',2018),
 ('76766','BIO-101','1','Spring',2018),
 ('76766','BIO-301','1','Fall',2017),
 ('83821','CS-190','1','Spring',2018),
 ('83821','CS-347','1','Spring',2018),
 ('98345','EE-181','1','Spring',2018);

INSERT INTO takes VALUES
 ('00128','CS-101','1','Fall',2017,'A'),
 ('00128','CS-347','1','Fall',2017,'A-'),
 ('12345','CS-101','1','Fall',2017,'A'),
 ('12345','CS-190','1','Spring',2018,'A'),
 ('12345','CS-315','1','Fall',2017,'A'),
 ('12345','CS-347','1','Fall',2017,'A'),
 ('19991','HIS-351','1','Fall',2017,'B'),
 ('23121','FIN-201','1','Fall',2017,'C+'),
 ('44553','BIO-101','1','Spring',2018,'B'),
 ('44553','PHY-101','1','Fall',2017,'B-'),
 ('45678','CS-101','1','Fall',2017,'F'),
 ('45678','CS-101','1','Spring',2018,'B+'),
 ('45678','CS-347','1','Fall',2017,'B+'),
 ('54321','CS-101','1','Spring',2018,'A-'),
 ('54321','CS-347','1','Fall',2017,'A'),
 ('55739','MU-199','1','Spring',2018,'B'),
 ('70557','CS-101','1','Spring',2018,NULL),
 ('78901','CS-101','1','Fall',2017,'A'),
 ('78901','CS-347','1','Fall',2017,'A'),
 ('98765','EE-181','1','Spring',2018,'C'),
 ('98988','BIO-101','1','Spring',2018,'A'),
 ('98988','BIO-301','1','Fall',2017,NULL),
 ('98988','BIO-399','1','Spring',2018,NULL);

INSERT INTO advisor VALUES
 ('00128','45565'),('12345','10101'),('44553','22222'),
 ('78901','83821'),('98988','76766'),('55739',NULL);

INSERT INTO prereq VALUES
 ('BIO-301','BIO-101'),('BIO-399','BIO-301'),('CS-190','CS-101'),
 ('CS-315','CS-101'),('CS-347','CS-101'),('PHY-201','PHY-101');

INSERT INTO instructor
    SELECT ID, name, dept_name, 18000
    FROM student
    WHERE dept_name = 'Music' AND tot_cred > 30;
DELETE FROM instructor WHERE ID = '55739';

SELECT
    (SELECT COUNT(*) FROM classroom)  AS classroom,
    (SELECT COUNT(*) FROM department) AS department,
    (SELECT COUNT(*) FROM course)     AS course,
    (SELECT COUNT(*) FROM instructor) AS instructor,
    (SELECT COUNT(*) FROM section)    AS section,
    (SELECT COUNT(*) FROM teaches)    AS teaches,
    (SELECT COUNT(*) FROM student)    AS student,
    (SELECT COUNT(*) FROM takes)      AS takes,
    (SELECT COUNT(*) FROM advisor)    AS advisor,
    (SELECT COUNT(*) FROM prereq)     AS prereq;

# 阶段三：基础查询
SELECT name, salary/12 AS monthly_salary
FROM instructor
ORDER BY name;

SELECT DISTINCT dept_name
FROM instructor
ORDER BY dept_name;
SELECT
    (SELECT COUNT(DISTINCT dept_name) 
     FROM instructor) AS distinct_dept_name,
    (SELECT COUNT(ALL dept_name)
     FROM instructor) AS all_dept_name;

SELECT name, salary
FROM instructor
WHERE dept_name = 'Comp. Sci.' AND salary > 70000
ORDER BY name;

SELECT name, salary
FROM instructor
WHERE salary BETWEEN 90000 AND 100000
ORDER BY name;

SELECT *
FROM instructor
WHERE name LIKE '%a%'
ORDER BY name;

SELECT *
FROM instructor
WHERE name LIKE '____'
ORDER BY name;

SELECT dept_name, name, salary
FROM instructor
ORDER BY dept_name, salary DESC;

# 阶段四：连接与集合运算
SELECT DISTINCT ID, name
FROM instructor NATURAL JOIN teaches
ORDER BY name;

SELECT *
FROM instructor
WHERE ID NOT IN(
    SELECT ID
    FROM teaches
)
ORDER BY name;

SELECT i.name, s.course_id, s.building, s.room_number
FROM instructor as i
JOIN teaches as t ON i.`ID` = t.`ID`
JOIN section as s ON t.course_id = s.course_id
                  AND t.sec_id   = s.sec_id
                  AND t.semester = s.semester
                  AND t.year     = s.year
WHERE s.year = 2018 AND s.semester = 'Spring'
ORDER BY i.name;

SELECT DISTINCT i.name
FROM instructor as i, instructor as i_
WHERE i.salary > i_.salary AND i_.dept_name = 'Comp. Sci.'
ORDER BY i.name;

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

# 阶段五：聚集函数与分组


#阶段六：嵌套子查询


# 阶段七：数据库修改


# 阶段八：NULL与三值逻辑


# 阶段九：索引与查询优化

