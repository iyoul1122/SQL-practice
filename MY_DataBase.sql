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


# 阶段三：基础查询


# 阶段四：连接与集合运算


# 阶段五：聚集函数与分组


#阶段六：嵌套子查询


# 阶段七：数据库修改


# 阶段八：NULL与三值逻辑


# 阶段九：索引与查询优化

