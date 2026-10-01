-- Active: 1790786545269@@127.0.0.1@3306@universitydb
-- Active: 1790786545269@@127.0.0.1@3306
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
    TABLE_NAME AS referencing_relation, --r1 参照关系
    COLUMN_NAME AS fk_column,
    REFERENCED_TABLE_NAME AS referenced_relation, --r2 被参照关系
    REFERENCED_COLUMN_NAME AS pk_column
FROM 
    information_schema.KEY_COLUMN_USAGE
WHERE 
    TABLE_SCHEMA = 'universitydb' 
    AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY 
    referencing_relation;