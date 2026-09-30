CREATE DATABASE UniversityDB;
GO

USE UniversityDB;
GO

SELECT DB_NAME() AS current_db;

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
GO

CREATE TABLE course(
    course_id   VARCHAR(8),
    title       VARCHAR(50),
    dept_name   VARCHAR(20),
    credits     NUMERIC(2,0),
    PRIMARY KEY(course_id),
    FOREIGN KEY(dept_name) REFERENCES department ON DELETE SET NULL
);
GO

CREATE TABLE instructor(
    ID          CHAR(5),
    name        VARCHAR(20) NOT NULL,
    dept_name   VARCHAR(20),
    salary      NUMERIC(8,2),
    PRIMARY KEY(ID),
    FOREIGN KEY(dept_name) REFERENCES department ON DELETE SET NULL
);
GO

CREATE TABLE section(
    course_id       VARCHAR(8),
    sec_id          VARCHAR(8),
    semester        VARCHAR(6),
    year            NUMERIC(4,0),
    building        VARCHAR(15),
    room_number     VARCHAR(7),
    time_slot_id    VARCHAR(4),
    PRIMARY KEY(course_id, sec_id, semester, year),
    FOREIGN KEY(course_id) REFERENCES course ON DELETE CASCADE,
    FOREIGN KEY(building, room_number) REFERENCES classroom ON DELETE SET NULL
);
GO

CREATE TABLE teaches(
    ID          CHAR(5),
    course_id   VARCHAR(8),
    sec_id      VARCHAR(8),
    semester    VARCHAR(6),
    year        NUMERIC(4,0),
    PRIMARY KEY(ID, course_id, sec_id, semester, year),
    FOREIGN KEY(ID) REFERENCES instructor ON DELETE CASCADE,
    FOREIGN KEY(course_id, sec_id, semester, year)
        REFERENCES section ON DELETE CASCADE
);
GO

CREATE TABLE student(
    ID          VARCHAR(5),
    name        VARCHAR(20) NOT NULL,
    dept_name   VARCHAR(20),
    tot_cred    NUMERIC(3,0),
    PRIMARY KEY(ID),
    FOREIGN KEY(dept_name) REFERENCES department ON DELETE SET NULL
);

CREATE TABLE takes(
    ID          VARCHAR(5),
    course_id   VARCHAR(8),
    sec_id      VARCHAR(8),
    semester    VARCHAR(6),
    year        NUMERIC(4,0),
    grade       CHAR(2),
    PRIMARY KEY(ID, course_id, year),
    FOREIGN KEY(ID) REFERENCES student ON DELETE CASCADE,
    FOREIGN KEY(course_id) REFERENCES course  ON DELETE CASCADE
);
GO

CREATE TABLE advisor(
    s_ID    VARCHAR(5),
    i_ID    CHAR(5),
    PRIMARY KEY(s_ID),
    FOREIGN KEY(s_ID) REFERENCES student ON DELETE CASCADE,
    FOREIGN KEY(i_ID) REFERENCES instructor ON DELETE SET NULL
);

CREATE TABLE prereq(
    course_id   VARCHAR(8),
    prereq_id   VARCHAR(8),
    PRIMARY KEY(course_id, prereq_id),
    FOREIGN KEY(course_id) REFERENCES course ON DELETE CASCADE,
    FOREIGN KEY(prereq_id) REFERENCES course ON DELETE CASCADE
);
GO
