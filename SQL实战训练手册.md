# SQL 实战训练手册 · T-SQL 版

**配套课件**：《数据库系统原理》Ch1 Introduction / Ch2 Relational Model / Ch3 Introduction to SQL
**示例库**：university 数据库（与课件 Ch3 完全一致的 10 张表）
**环境**：VSCode + SQL Server (mssql) 扩展
**体量**：10 个阶段 · 65 道题 · 从建库到查询优化全覆盖

> **关于答案**：本手册所有预期结果（行数、具体值）均在真实数据库上执行验证过，不是估算。你跑出来的结果应与之逐字一致；若不一致，先检查建表脚本与种子数据是否完整执行。

---

## 使用说明

1. **顺序执行**：阶段 1、2 是后面所有题目的地基，必须先跑完。
2. **先自己写，再看答案**：每题的答案都折叠在 `<details>` 里，点开前先动手。
3. **SQL 里的 `--` 注释可以直接跑**，不影响执行。
4. **执行方式**：在 VSCode 中打开 `.sql` 文件或本手册内的代码块，选中语句后按 `Ctrl + Shift + E`（mssql 扩展默认执行快捷键）；连接建立后会弹出结果网格。
5. **难度标记**：★ 基础　★★ 进阶　★★★ 课件难点 / 易错题

---

## 第 0 章 · 环境准备

### 0.1 确认你有可连接的 SQL Server 实例

mssql 扩展只是客户端，**必须有一个 SQL Server 服务端**才能执行。三选一：

| 方案 | 适用 | 操作 |
|---|---|---|
| **A. Docker（推荐，最快）** | 装了 Docker Desktop | 见下方命令 |
| **B. SQL Server Express / Developer 本地安装** | 愿意装 ~1.5GB | 官网下载，安装时选"基本"实例 |
| **C. LocalDB** | 装过 Visual Studio | 服务器名填 `(localdb)\MSSQLLocalDB` |

**方案 A 一键起库**（在终端执行，密码需含大小写+数字+符号，长度 ≥ 8）：

```bash
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Db@12345678" \
  -p 1433:1433 --name sql2022 -d \
  mcr.microsoft.com/mssql/server:2022-latest
```

验证容器起来了：`docker ps`，看到 `sql2022` 状态 `Up` 即成功。

### 0.2 在 VSCode 里建立连接

1. `Ctrl + Shift + P` → 输入 `MS SQL: Connect` → 回车
2. 选 `Create Connection Profile`
3. 依次填写：
   - **Server name**：`localhost,1433`（Docker/Express）；LocalDB 填 `(localdb)\MSSQLLocalDB`
   - **Database name**：先留空（回车跳过）
   - **Authentication**：`SQL Login`
   - **User name**：`sa`
   - **Password**：`Db@12345678`（你上一步设的）
   - **Save Password**：`Yes`
   - **Profile Name**：`university`
4. 左下角状态栏出现 `localhost,1433 : master` 即连接成功

> 连不上先排查：① `docker ps` 容器是否在跑；② 端口 1433 是否被占用；③ 密码是否含特殊字符被 shell 吞掉（Windows 下用双引号包裹）。

### 0.3 建议的工作方式

新建一个 `lab.sql` 文件，每做完一题把语句粘进去并加注释，最后它就是你的作品集。本手册的 SQL 都可以整段复制。

---

## 阶段 1 · 建库建表（DDL）

> **对应课件**：P25 3.2 域类型　|　P26 3.3 建表与完整性约束　|　P27 3.4 drop / alter
> **通关标准**：10 张表全部创建成功，且能查到 `sys.foreign_keys` 里有 11 条外键

### 1.1 创建数据库 ★

创建名为 `UniversityDB` 的数据库。

> T-SQL 中 `GO` 是批处理分隔符，不是 SQL 语句，VSCode 里执行整段时它是必需的——`CREATE DATABASE` 与后续的 `USE` 必须在不同的批处理里。

<details><summary>参考答案</summary>

```sql
CREATE DATABASE UniversityDB;
GO

USE UniversityDB;
GO

-- 确认当前库
SELECT DB_NAME() AS current_db;
```

**预期**：`current_db = UniversityDB`

**解析**：课件 P24 的 SQL Parts 里 DDL 包含 create / drop / alter，`CREATE DATABASE` 属于 DDL 的库级操作，`USE` 用于切换当前数据库上下文。
</details>

### 1.2 建两张"根表"：classroom / department ★

| 表名 | 属性 | 主键 |
|---|---|---|
| classroom | building VARCHAR(15), room_number VARCHAR(7), capacity NUMERIC(4,0) | (building, room_number) |
| department | dept_name VARCHAR(20), building VARCHAR(15), budget NUMERIC(12,2) | dept_name |

要求：两张表都不依赖任何表，先建它们。

<details><summary>参考答案</summary>

```sql
CREATE TABLE classroom (
    building     VARCHAR(15),
    room_number  VARCHAR(7),
    capacity     NUMERIC(4,0),
    PRIMARY KEY (building, room_number)
);

CREATE TABLE department (
    dept_name  VARCHAR(20),
    building   VARCHAR(15),
    budget     NUMERIC(12,2),
    PRIMARY KEY (dept_name)
);
GO
```

**解析**：课件 P26 指出 DDL 能定义"关系模式 / 属性值类型 / 完整性约束 / 索引 / 授权 / 物理存储"。这里用到了前三项。复合主键的写法是 `PRIMARY KEY (A, B)`——对应课件 P26 里 `takes` 的多属性主键。
</details>

### 1.3 建 course —— 外键 + NOT NULL ★

course(course_id VARCHAR(8), title VARCHAR(50), dept_name VARCHAR(20), credits NUMERIC(2,0))，主键 course_id，dept_name 外键引用 department，title 不可为空。

<details><summary>参考答案</summary>

```sql
CREATE TABLE course (
    course_id  VARCHAR(8),
    title      VARCHAR(50) NOT NULL,
    dept_name  VARCHAR(20),
    credits    NUMERIC(2,0),
    PRIMARY KEY (course_id),
    FOREIGN KEY (dept_name) REFERENCES department ON DELETE SET NULL
);
GO
```

**解析**：课件 P26 的三类完整性约束——`primary key` / `foreign key ... references` / `not null`，这一题全用上了。`ON DELETE SET NULL` 是**参照动作**：系被删掉时，课程的 dept_name 置为 NULL 而不是拒绝删除（课件 P16 讲参照完整性，未展开动作，这里补一句工程实践）。
</details>

### 1.4 建 instructor —— 复刻课件 P26 原例 ★★

要求与课件示例一致：`ID CHAR(5)`、`name VARCHAR(20) NOT NULL`、`dept_name VARCHAR(20)`、`salary NUMERIC(8,2)`，主键 ID，dept_name 外键引用 department。

<details><summary>参考答案</summary>

```sql
CREATE TABLE instructor (
    ID         CHAR(5),
    name       VARCHAR(20) NOT NULL,
    dept_name  VARCHAR(20),
    salary     NUMERIC(8,2),
    PRIMARY KEY (ID),
    FOREIGN KEY (dept_name) REFERENCES department ON DELETE SET NULL
);
GO
```

**解析**：课件 P26 的原句就是这个。注意两点：① `CHAR(5)` 是定长，存 `'10101'` 正好 5 位；② `salary NUMERIC(8,2)` 是定点数，共 8 位含 2 位小数——课件 P25 强调金额必须用定点数而非浮点，避免精度丢失。
</details>

### 1.5 建 section —— 复合主键 + 复合外键 ★★

section(course_id, sec_id, semester, year, building, room_number, time_slot_id)，主键为 (course_id, sec_id, semester, year)，course_id 外键引用 course，(building, room_number) 外键引用 classroom。

<details><summary>参考答案</summary>

```sql
CREATE TABLE section (
    course_id     VARCHAR(8),
    sec_id        VARCHAR(8),
    semester      VARCHAR(6),
    year          NUMERIC(4,0),
    building      VARCHAR(15),
    room_number   VARCHAR(7),
    time_slot_id  VARCHAR(4),
    PRIMARY KEY (course_id, sec_id, semester, year),
    FOREIGN KEY (course_id) REFERENCES course ON DELETE CASCADE,
    FOREIGN KEY (building, room_number) REFERENCES classroom ON DELETE SET NULL
);
GO
```

**解析**：外键也可以由**多个属性**组成——课件 P26 的 `takes` 例子里 `foreign key (course_id, year) references section` 就是这种。被引用方必须有对应的主键或唯一约束，classroom 的主键恰好是 (building, room_number)，所以能对上。
</details>

### 1.6 建 teaches —— 四属性复合外键 ★★★

teaches(ID, course_id, sec_id, semester, year)，主键全属性组合，两个外键：ID → instructor，(course_id, sec_id, semester, year) → section。

<details><summary>参考答案</summary>

```sql
CREATE TABLE teaches (
    ID         CHAR(5),
    course_id  VARCHAR(8),
    sec_id     VARCHAR(8),
    semester   VARCHAR(6),
    year       NUMERIC(4,0),
    PRIMARY KEY (ID, course_id, sec_id, semester, year),
    FOREIGN KEY (ID) REFERENCES instructor ON DELETE CASCADE,
    FOREIGN KEY (course_id, sec_id, semester, year)
        REFERENCES section ON DELETE CASCADE
);
GO
```

**解析**：这是全库最"重"的约束。它表达的是"某位教师讲授某个具体的课程班"，所以外键必须完整指向 section 的四属性主键，不能只写 course_id——否则无法区分同一门课的不同学期班次。
</details>

### 1.7 建 student 与 takes —— 课件 P26 的复合主键原例 ★★

student(ID VARCHAR(5), name VARCHAR(20) NOT NULL, dept_name VARCHAR(20), tot_cred NUMERIC(3,0))，主键 ID。
takes(ID, course_id, sec_id, semester, year, grade)，主键 **(ID, course_id, year)**（与课件一致），ID 外键引用 student。

<details><summary>参考答案</summary>

```sql
CREATE TABLE student (
    ID         VARCHAR(5),
    name       VARCHAR(20) NOT NULL,
    dept_name  VARCHAR(20),
    tot_cred   NUMERIC(3,0),
    PRIMARY KEY (ID),
    FOREIGN KEY (dept_name) REFERENCES department ON DELETE SET NULL
);

CREATE TABLE takes (
    ID         VARCHAR(5),
    course_id  VARCHAR(8),
    sec_id     VARCHAR(8),
    semester   VARCHAR(6),
    year       NUMERIC(4,0),
    grade      VARCHAR(2),
    PRIMARY KEY (ID, course_id, year),
    FOREIGN KEY (ID) REFERENCES student ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES course ON DELETE CASCADE
);
GO
```

**解析**：课件 P26 明确写了 `primary key (ID, course_id, year)`——主键只取三个属性，意味着**同一学生在同一年只能选同一门课一次**（不同年份可重修）。这不是笔误，是有意的设计约束，期末考试常考"为什么主键不包含 sec_id/semester"。
</details>

### 1.8 建 advisor 与 prereq —— 同一表内外的联系 ★★

advisor(s_ID, i_ID)：s_ID 主键兼外键引用 student，i_ID 外键引用 instructor（允许为 NULL，表示"尚未分配导师"）。
prereq(course_id, prereq_id)：复合主键，两列都是外键引用 course。

<details><summary>参考答案</summary>

```sql
CREATE TABLE advisor (
    s_ID  VARCHAR(5),
    i_ID  CHAR(5),
    PRIMARY KEY (s_ID),
    FOREIGN KEY (s_ID) REFERENCES student ON DELETE CASCADE,
    FOREIGN KEY (i_ID) REFERENCES instructor ON DELETE SET NULL
);

CREATE TABLE prereq (
    course_id  VARCHAR(8),
    prereq_id  VARCHAR(8),
    PRIMARY KEY (course_id, prereq_id),
    FOREIGN KEY (course_id) REFERENCES course ON DELETE CASCADE,
    FOREIGN KEY (prereq_id) REFERENCES course ON DELETE CASCADE
);
GO
```

**解析**：prereq 的两个属性引用**同一张表** course，是"关系内部的联系"；advisor 是"两张实体表之间的联系"。课件 P16 说"外键是关系模型表达联系的主要手段"，这两张表就是两个典型例子。注意 `i_ID` 没有 NOT NULL——这正是阶段 8 的陷阱素材。
</details>

### 1.9 校验：查看模式图信息 ★

用系统视图查出所有外键的"参照关系 → 被参照关系"，对照课件 P17 的模式图读图要点（箭头由参照方指向被参照方）。

<details><summary>参考答案</summary>

```sql
SELECT
    OBJECT_NAME(f.parent_object_id)  AS referencing_relation,  -- r1 参照关系
    COL_NAME(fc.parent_object_id, fc.parent_column_id) AS fk_column,
    OBJECT_NAME(f.referenced_object_id) AS referenced_relation, -- r2 被参照关系
    COL_NAME(fc.referenced_object_id, fc.referenced_column_id) AS pk_column
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON f.object_id = fc.constraint_object_id
ORDER BY referencing_relation;

-- 全部表清单
SELECT name FROM sys.tables ORDER BY name;
```

**预期**：外键 11 条；表 10 张——advisor、classroom、course、department、instructor、prereq、section、student、takes、teaches。

**解析**：课件 P17 的模式图三要点——① 主键加下划线；② 箭头由外键所在关系指向主键所在关系；③ 建表与导数据必须遵循箭头依赖顺序。`sys.foreign_keys` 就是这张图的机器可读版本。
</details>

### 1.10 ALTER TABLE 实战 ★★

(1) 给 student 增加 `age INT` 列；(2) 观察已有行的该列值；(3) 再把它删掉；(4) 给 instructor.salary 加 CHECK 约束 `salary > 0`；(5) 给 student.tot_cred 加 DEFAULT 0。

<details><summary>参考答案</summary>

```sql
-- (1) 加列
ALTER TABLE student ADD age INT;

-- (2) 已有元组在新列上取 NULL（课件 P27 原话）
SELECT ID, name, age FROM student;

-- (3) 删列（SQL Server 支持 DROP COLUMN；课件 P27 提醒"许多数据库不支持"）
ALTER TABLE student DROP COLUMN age;

-- (4) CHECK 约束：域约束
ALTER TABLE instructor ADD CONSTRAINT ck_salary CHECK (salary > 0);

-- (5) 默认值：工程实践要求"用默认值替代 NULL"
ALTER TABLE student ADD CONSTRAINT df_totcred DEFAULT 0 FOR tot_cred;
GO
```

**解析**：课件 P27 三个考点：① `add` 之后已有元组在新属性上取 NULL，**所以新增列不能带 NOT NULL**（除非给默认值）；② `drop attribute` 在很多数据库中不支持（SQL Server 支持，Oracle/MySQL 老版本不支持）；③ `drop` 删整表，`delete` 只删元组。另外课件 P34 的工程实践——"避免属性取 NULL，用默认值替代，防止索引失效"——就是 (5) 的动机。
</details>

---

## 阶段 2 · 数据装载（DML 插入）

> **对应课件**：P16 2.4 导入顺序　|　P38 3.12 插入
> **通关标准**：10 张表行数 = classroom 5 / department 7 / course 14 / instructor 12 / section 17 / teaches 17 / student 13 / takes 23 / advisor 6 / prereq 6

### 2.1 按依赖顺序装载 ★★

**先想后做**：写出插入顺序，再执行。顺序错了会被外键拒绝。

<details><summary>参考答案</summary>

**顺序**：classroom、department（无依赖）→ course、instructor、student（依赖 department）→ section（依赖 course、classroom）→ teaches（依赖 section、instructor）→ takes（依赖 student、course）→ advisor（依赖 student、instructor）→ prereq（依赖 course）

```sql
-- ① 无依赖
INSERT INTO classroom VALUES
 ('Packard','101',500),('Painter','514',100),('Taylor','312',100),
 ('Watson','100',100),('Watson','120',100);

INSERT INTO department VALUES
 ('Biology','Watson',90000),('Comp. Sci.','Taylor',100000),
 ('Elec. Eng.','Taylor',85000),('Finance','Painter',120000),
 ('History','Painter',50000),('Music','Packard',80000),
 ('Physics','Watson',70000);

-- ② 依赖 department
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

-- ③ 依赖 course / classroom
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

-- ④ 依赖 section / instructor
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

-- ⑤ 依赖 student / course
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

-- ⑥ 依赖 student / instructor
INSERT INTO advisor VALUES
 ('00128','45565'),('12345','10101'),('44553','22222'),
 ('78901','83821'),('98988','76766'),('55739',NULL);

INSERT INTO prereq VALUES
 ('BIO-301','BIO-101'),('BIO-399','BIO-301'),('CS-190','CS-101'),
 ('CS-315','CS-101'),('CS-347','CS-101'),('PHY-201','PHY-101');
GO
```

**解析**：课件 P16"导入顺序"——**先导入被参照关系 r2，再导入参照关系 r1**。先定义各系，再导入隶属各系的教师。你把 instructor 放在 department 前面插入，会立刻收到 `The INSERT statement conflicted with the FOREIGN KEY constraint` 错误。
</details>

### 2.2 故意违反外键 —— 体会约束的作用 ★★

执行下面这条，记录报错信息，然后说明为什么被拒绝。

```sql
INSERT INTO instructor VALUES ('99999','Turing','Astronomy',100000);
```

<details><summary>参考答案</summary>

**预期报错**：
```
Msg 547, Level 16, State 0
The INSERT statement conflicted with the FOREIGN KEY constraint "FK__instructo__dept___xxxx".
The conflict occurred in database "UniversityDB", table "dbo.department", column 'dept_name'.
```

**解析**：`Astronomy` 在 department 中不存在，违反**参照完整性**（课件 P16）。课件 P26 原话："约束一旦声明，任何违反完整性约束的更新都会被阻止。"这正是文件系统做不到的（课件 P4 完整性问题：约束埋在程序代码里）。

**修复**：先 `INSERT INTO department VALUES ('Astronomy','Taylor',60000);` 再插教师。
</details>

### 2.3 违反主键约束 ★

```sql
INSERT INTO instructor VALUES ('10101','Fake','Physics',50000);
```

<details><summary>参考答案</summary>

**预期报错**：`Msg 2627 ... Violation of PRIMARY KEY constraint 'PK__instruct__...'. Cannot insert duplicate key in object 'dbo.instructor'. The duplicate key value is (10101).`

**解析**：主键唯一且非空（课件 P15）。注意这里 `name` 也重复了，但**报错只会先命中主键**——约束检查有先后顺序，主键/唯一约束通常先于外键被检查。
</details>

### 2.4 违反 NOT NULL 与 CHECK ★

```sql
INSERT INTO instructor (ID, dept_name, salary) VALUES ('88888','Physics',50000);
INSERT INTO instructor VALUES ('77777','Nobody','Physics',-1);
```

<details><summary>参考答案</summary>

- 第一条：`Msg 515 Cannot insert the value NULL into column 'name' ... column does not allow nulls.`
- 第二条：`Msg 547 The INSERT statement conflicted with the CHECK constraint 'ck_salary'.`（前提是你做了 1.10 的第 4 小问）

**解析**：`name VARCHAR(20) NOT NULL` 是域约束层面的非空；`CHECK (salary > 0)` 是**属性值依赖**（课件 P16 提到的完整性四类之一）。两者都由 DBMS 执行，不需要写进应用程序。
</details>

### 2.5 INSERT + SELECT 批量装载 ★★

把 Music 系学分超过 30 的学生转为教师，工资统一 18000（课件 P38 原例，阈值改为 30 以便有结果）。**先用 SELECT 预演，再插入。**

<details><summary>参考答案</summary>

```sql
-- 预演：确认要插什么
SELECT ID, name, dept_name, 18000 AS salary
FROM student
WHERE dept_name = 'Music' AND tot_cred > 30;
-- 预期 1 行：('55739','Sanchez','Music',18000)

-- 正式插入
INSERT INTO instructor (ID, name, dept_name, salary)
SELECT ID, name, dept_name, 18000
FROM student
WHERE dept_name = 'Music' AND tot_cred > 30;

-- 回滚这次插入，保持后续题目的数据一致
DELETE FROM instructor WHERE ID = '55739';
GO
```

**解析**：课件 P38 考点①——`insert` 中的 `select-from-where` 会**先被完整求值**，再把结果全部插入。否则 `INSERT INTO t SELECT * FROM t` 会无限自我膨胀。
</details>

### 2.6 数据核对 ★

一条 SQL 查全库各表行数，确认与阶段 2 通关标准一致。

<details><summary>参考答案</summary>

```sql
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
```

**预期**：`5  7  14  12  17  17  13  23  6  6`

**解析**：这是**标量子查询**的典型用法（课件 P37），把 10 个单值查询横向拼成一行，比 `UNION ALL` 十行结果更适合做数据核对。
</details>

---

## 阶段 3 · 基础查询（select / where / order by）

> **对应课件**：P28 3.5 基本查询结构　|　P29 3.6-① select　|　P30 3.6-② where　|　P32 3.7 like　|　P33 3.8 order by
> **通关标准**：能不看答案写出 8 类条件筛选

### 3.1 投影 + 算术表达式 + as ★

查询全体教师的姓名与**月薪**（salary/12），结果按姓名升序。

<details><summary>参考答案</summary>

```sql
SELECT name, salary/12 AS monthly_salary
FROM instructor
ORDER BY name;
```

**预期 12 行**，前几行：Brandt 7666.666666、Califieri 5166.666666、Crick 6000……

> T-SQL 中 `NUMERIC / INT` 的结果会保留较多小数位，如需两位：
> `CAST(salary/12 AS NUMERIC(8,2)) AS monthly_salary`

**解析**：课件 P29——select 子句可含 `+ − * /` 算术表达式，结果列用 `as` 重命名（`as` 可省略）。这条查询等价于关系代数 `π name, salary/12 (instructor)`。
</details>

### 3.2 DISTINCT 去重 ★

查询教师所属的系名，**去掉重复**。再写一个不带 DISTINCT 的版本，比较行数。

<details><summary>参考答案</summary>

```sql
SELECT DISTINCT dept_name FROM instructor ORDER BY dept_name;   -- 7 行
SELECT ALL dept_name FROM instructor ORDER BY dept_name;        -- 12 行
SELECT dept_name FROM instructor ORDER BY dept_name;            -- 12 行（默认 ALL）
```

**预期**：DISTINCT 返回 7 行：Biology / Comp. Sci. / Elec. Eng. / Finance / History / Music / Physics

**解析**：课件 P29 强调——**关系代数的投影 π 会自动去重，SQL 默认不去重**。这是 SQL 与关系代数最常考的差异点。
</details>

### 3.3 where 单条件 ★

找出计算机系（`'Comp. Sci.'`）全体教师的姓名。

<details><summary>参考答案</summary>

```sql
SELECT name FROM instructor WHERE dept_name = 'Comp. Sci.' ORDER BY name;
```

**预期 3 行**：Brandt、Katz、Srinivasan

**解析**：课件 P30——字符串条件必须加**单引号**；SQL 中字符串用单引号，双引号在 T-SQL 里默认被当标识符（`SET QUOTED_IDENTIFIER`）。
</details>

### 3.4 AND 组合条件 ★

找出计算机系中工资高于 70000 的教师姓名与工资。

<details><summary>参考答案</summary>

```sql
SELECT name, salary FROM instructor
WHERE dept_name = 'Comp. Sci.' AND salary > 70000
ORDER BY name;
```

**预期 2 行**：Brandt 92000、Katz 75000

**解析**：对应关系代数 `σ dept_name='Comp. Sci.' ∧ salary>70000 (instructor)`（课件 P19）。
</details>

### 3.5 BETWEEN 闭区间 ★★

找出工资在 90000 与 100000 **之间（含端点）**的教师姓名与工资。

<details><summary>参考答案</summary>

```sql
SELECT name, salary FROM instructor
WHERE salary BETWEEN 90000 AND 100000
ORDER BY salary;
```

**预期 3 行**：Wu 90000、Brandt 92000、Einstein 95000

**解析**：课件 P30——`between ... and ...` 是**闭区间**，等价于 `salary >= 90000 AND salary <= 100000`。注意 Wu 的 90000 被包含进来了，这正是"含端点"的证据。`NOT BETWEEN` 取反。
</details>

### 3.6 LIKE 通配：包含子串 ★

找出姓名中包含子串 `a` 的教师（不区分顺序位置）。

<details><summary>参考答案</summary>

```sql
SELECT name FROM instructor WHERE name LIKE '%a%' ORDER BY name;
```

**预期 6 行**：Brandt、Califieri、El Said、Katz、Mozart、Srinivasan

**解析**：课件 P32——`%` 匹配任意长度子串（含空串），`_` 匹配**恰好一个**字符。另注：SQL Server 默认排序规则 `Chinese_PRC_CI_AS` 是**不区分大小写**的，所以 `'%a%'` 与 `'%A%'` 结果相同；课件说"模式匹配区分大小写"是按标准 SQL 说的。
</details>

### 3.7 LIKE 通配：定长匹配 ★★

找出姓名恰好是 4 个字符的教师。

<details><summary>参考答案</summary>

```sql
SELECT name FROM instructor WHERE name LIKE '____' ORDER BY name;
```

**预期 2 行**：Gold、Katz

**解析**：4 个下划线 = 恰好 4 个字符。课件 P32 的速查：`'_ _ _'` 恰好三个字符，`'_ _ _ %'` 至少三个字符（原文空格是为了看清，实际写作 `'___'` / `'___%'`）。
</details>

### 3.8 ORDER BY 多列 + 分别指定升降序 ★

按系名升序排列，同系内按工资降序排列，输出系名、姓名、工资。

<details><summary>参考答案</summary>

```sql
SELECT dept_name, name, salary
FROM instructor
ORDER BY dept_name ASC, salary DESC;
```

**预期 12 行**，开头几行：

| dept_name | name | salary |
|---|---|---|
| Biology | Crick | 72000 |
| Comp. Sci. | Brandt | 92000 |
| Comp. Sci. | Katz | 75000 |
| Comp. Sci. | Srinivasan | 65000 |
| Elec. Eng. | Kim | 80000 |
| Finance | Wu | 90000 |
| Finance | Singh | 80000 |
| History | Califieri | 62000 |
| History | El Said | 60000 |
| Music | Mozart | 40000 |
| Physics | Einstein | 95000 |
| Physics | Gold | 87000 |

**解析**：课件 P33——`desc` 降序、`asc` 升序（默认升序）；排序是查询的**最后一步**（在分组与聚集之后执行）。课件还特别提醒：别把大数据拉到程序里排序，排序是数据库的基本能力。
</details>

---

## 阶段 4 · 连接与集合运算

> **对应课件**：P20 2.8 笛卡尔积与连接　|　P31 3.6-③ from 子句　|　P32 3.7 自连接　|　P33 3.8 集合运算
> **通关标准**：能解释"笛卡尔积 204 行"是怎么算出来的

### 4.1 笛卡尔积的规模 ★★

`SELECT * FROM instructor, teaches` 会返回多少行？先口算，再用 `COUNT(*)` 验证。

<details><summary>参考答案</summary>

```sql
SELECT COUNT(*) AS cartesian_rows FROM instructor, teaches;  -- 204
SELECT COUNT(*) FROM instructor;  -- 12
SELECT COUNT(*) FROM teaches;     -- 17
```

**预期**：204 = 12 × 17

**解析**：课件 P20——若 r 有 m 个元组、s 有 n 个元组，则 `r × s` 有 m × n 个元组。这 204 行里绝大多数是"这位教师并没教这门课"的无意义配对。**这就是连接必须写连接条件的原因。**
</details>

### 4.2 用 INNER JOIN 写连接（T-SQL 无 NATURAL JOIN）★★★

找出所有教过课的教师 ID 与姓名（去重）。课件写的是 `instructor natural join teaches`。

<details><summary>参考答案</summary>

```sql
-- 写法 A：显式连接条件（课件 P31 等价写法）
SELECT DISTINCT i.ID, i.name
FROM instructor i, teaches t
WHERE i.ID = t.ID
ORDER BY i.name;

-- 写法 B：INNER JOIN（推荐，T-SQL 标准写法）
SELECT DISTINCT i.ID, i.name
FROM instructor i INNER JOIN teaches t ON i.ID = t.ID
ORDER BY i.name;
```

**预期 11 行**：Brandt、Crick、Einstein、El Said、Gold、Katz、Kim、Mozart、Singh、Srinivasan、Wu

> **方言差异**：**SQL Server 不支持 `NATURAL JOIN`**。课件 P31 的 `FROM instructor NATURAL JOIN teaches` 在 T-SQL 里会报语法错。必须改写成上面的显式形式。这是本手册最重要的方言差异，期末若考机试请务必记住。

**解析**：`JOIN = 笛卡尔积 + 选择`（课件 P20）。12 位教师中只有 Califieri 没有授课记录，所以结果是 11 人。
</details>

### 4.3 外连接：找出"没有教过课"的教师 ★★

找出从未出现在 teaches 中的教师。用两种写法：NOT IN 子查询、LEFT JOIN + IS NULL。

<details><summary>参考答案</summary>

```sql
-- 写法 A：NOT IN 子查询
SELECT ID, name FROM instructor
WHERE ID NOT IN (SELECT ID FROM teaches)
ORDER BY name;

-- 写法 B：LEFT JOIN + IS NULL（性能通常更好）
SELECT i.ID, i.name
FROM instructor i LEFT JOIN teaches t ON i.ID = t.ID
WHERE t.ID IS NULL
ORDER BY i.name;
```

**预期 1 行**：`58583  Califieri`

**解析**：课件未展开外连接（属于 Ch4 高级 SQL），但这是工程中最常用的"找缺失"手法。写法 A 有个隐藏陷阱：如果 `teaches.ID` 里有 NULL，`NOT IN` 会返回空集——见阶段 8.3。
</details>

### 4.4 三表连接：教师 → 授课 → 课程班 ★★

找出 2018 年春季上课的教师姓名、课程号、教学楼与教室号。

<details><summary>参考答案</summary>

```sql
SELECT i.name, s.course_id, s.building, s.room_number
FROM instructor i
JOIN teaches t ON i.ID = t.ID
JOIN section  s ON t.course_id = s.course_id
                AND t.sec_id    = s.sec_id
                AND t.semester  = s.semester
                AND t.year      = s.year
WHERE s.semester = 'Spring' AND s.year = 2018
ORDER BY i.name;
```

**预期 9 行**：

| name | course_id | building | room_number |
|---|---|---|---|
| Brandt | CS-190 | Taylor | 312 |
| Brandt | CS-347 | Taylor | 312 |
| Crick | BIO-101 | Painter | 514 |
| Einstein | PHY-201 | Watson | 120 |
| Gold | BIO-399 | Watson | 100 |
| Katz | CS-101 | Packard | 101 |
| Kim | EE-181 | Taylor | 312 |
| Mozart | MU-199 | Packard | 101 |
| Singh | FIN-301 | Packard | 101 |

**解析**：课件 P31 的工程实践——**from 子句中的表数不要超过 4 张**。这里是 3 张，安全。注意 `teaches` 到 `section` 的连接条件是**四属性全部相等**，因为 section 的主键是四属性复合的。
</details>

### 4.5 自连接与元组变量 ★★★

找出工资**高于计算机系某位教师**的教师姓名（去重）。课件 P32 原例。

<details><summary>参考答案</summary>

```sql
SELECT DISTINCT T.name
FROM instructor AS T, instructor AS S
WHERE T.salary > S.salary AND S.dept_name = 'Comp. Sci.'
ORDER BY T.name;
```

**预期 8 行**：Brandt、Crick、Einstein、Gold、Katz、Kim、Singh、Wu

**解析**：课件 P32——元组变量 T、S 把同一个 instructor 关系"拆成两份"，实现对同一属性不同取值的比较。CS 系最低工资是 65000，所以只要工资 > 65000 就满足"高于某位 CS 教师"，共 8 人（Srinivasan 自己的 65000 不满足严格大于）。若题目改成"高于计算机系**所有**教师"，那就要用阶段 6 的 `> ALL`。
</details>

### 4.6 UNION —— 并集 ★★

找出 2017 年秋季**或** 2018 年春季开设过的课程号（去重）。

<details><summary>参考答案</summary>

```sql
(SELECT course_id FROM section WHERE semester = 'Fall'   AND year = 2017)
UNION
(SELECT course_id FROM section WHERE semester = 'Spring' AND year = 2018)
ORDER BY course_id;
```

**预期 14 行**：BIO-101、BIO-301、BIO-399、CS-101、CS-190、CS-315、CS-347、EE-181、FIN-201、FIN-301、HIS-351、MU-199、PHY-101、PHY-201

> T-SQL 中子查询的括号**可以省略**，但 `ORDER BY` 只能出现在最后一个 SELECT 之后并作用于整体结果。

**解析**：课件 P33——`union` 对应 ∪，默认自动去重；写成 `UNION ALL` 则保留重复。两个子查询必须**属性数目与类型一一对应**。
</details>

### 4.7 INTERSECT —— 交集 ★★

找出 2017 年秋季和 2018 年春季**都开设过**的课程号。

<details><summary>参考答案</summary>

```sql
SELECT course_id FROM section WHERE semester = 'Fall'   AND year = 2017
INTERSECT
SELECT course_id FROM section WHERE semester = 'Spring' AND year = 2018
ORDER BY course_id;
```

**预期 2 行**：CS-101、CS-347

**解析**：对应 ∩。课件 P21 指出交可由差导出：`r ∩ s = r − (r − s)`，所以交不属于六个基本运算。
</details>

### 4.8 EXCEPT —— 差集 ★★

找出 2017 年秋季开设、但 2018 年春季**没有**开设的课程号。

<details><summary>参考答案</summary>

```sql
SELECT course_id FROM section WHERE semester = 'Fall'   AND year = 2017
EXCEPT
SELECT course_id FROM section WHERE semester = 'Spring' AND year = 2018
ORDER BY course_id;
```

**预期 5 行**：BIO-301、CS-315、FIN-201、HIS-351、PHY-101

**解析**：对应 −（`r − s` = 在 r 中但不在 s 中）。课件 P21 强调并交差的前提是**同元且域相容**。T-SQL 的 `EXCEPT` 名字与标准 SQL 一致（Oracle 里叫 `MINUS`，这是常考的方言差异）。
</details>

---

## 阶段 5 · 聚集函数与分组

> **对应课件**：P35 3.10 聚集 · group by · having　|　P34 3.9 null 与聚集
> **通关标准**：能说清 where 与 having 的分工、group by 的硬性规则

### 5.1 单值聚集 ★

求计算机系教师的平均工资。

<details><summary>参考答案</summary>

```sql
SELECT AVG(salary) AS avg_salary FROM instructor WHERE dept_name = 'Comp. Sci.';
```

**预期**：`77333.333333`

**解析**：课件 P35——聚集函数作用于一列的值并返回一个值。`AVG` 会自动忽略 NULL（课件 P34 考点②：除 `COUNT(*)` 外所有聚集都忽略 NULL）。
</details>

### 5.2 COUNT(*) 与 COUNT(列) 的差别 ★★★

对 takes 表分别统计：总行数、grade 非 NULL 的行数、不同学生数。

<details><summary>参考答案</summary>

```sql
SELECT COUNT(*)            AS all_rows,
       COUNT(grade)        AS non_null_grade,
       COUNT(DISTINCT ID)  AS distinct_students
FROM takes;
```

**预期**：`23   20   12`

**解析**：23 条选课记录中，3 条 grade 为 NULL（Snow 的 CS-101、Tanaka 的 BIO-301 与 BIO-399），所以 `COUNT(grade) = 20`；13 名学生中 Lee 从未选课，所以 `COUNT(DISTINCT ID) = 12`。**这是本数据集里最经典的 NULL 考点**（课件 P34、P35 交叉点）。
</details>

### 5.3 GROUP BY 分组聚集 ★★

按系统计：系名、平均工资、教师人数。

<details><summary>参考答案</summary>

```sql
SELECT dept_name,
       AVG(salary) AS avg_salary,
       COUNT(*)    AS num_instructors
FROM instructor
GROUP BY dept_name
ORDER BY dept_name;
```

**预期 7 行**：

| dept_name | avg_salary | num_instructors |
|---|---|---|
| Biology | 72000 | 1 |
| Comp. Sci. | 77333.333333 | 3 |
| Elec. Eng. | 80000 | 1 |
| Finance | 85000 | 2 |
| History | 61000 | 2 |
| Music | 40000 | 1 |
| Physics | 91000 | 2 |

**解析**：课件 P35 硬性规则——**select 子句中出现在聚集函数之外的属性，必须出现在 group by 列表中**。`dept_name` 在 group by 里，合法。
</details>

### 5.4 HAVING 对组筛选 ★★

找出平均工资**高于 80000** 的系及其平均工资。

<details><summary>参考答案</summary>

```sql
SELECT dept_name, AVG(salary) AS avg_salary
FROM instructor
GROUP BY dept_name
HAVING AVG(salary) > 80000
ORDER BY dept_name;
```

**预期 2 行**：Finance 85000、Physics 91000

> 注：Elec. Eng. 恰好是 80000，不满足严格大于，被排除——边界条件要看清。

**解析**：课件 P35——`where` 作用于**分组前的元组**，`having` 作用于**分组后的组**。因此聚集函数（`AVG`、`COUNT`…）**不能出现在 where 中**，写了会报 `Msg 8121 / Msg 147`。
</details>

### 5.5 分组 + 外连接：统计含零的组 ★★

统计每门课的选课人数，**包括无人选修的课程**（显示 0）。

<details><summary>参考答案</summary>

```sql
SELECT c.course_id, c.title, COUNT(t.ID) AS num_students
FROM course c LEFT JOIN takes t ON c.course_id = t.course_id
GROUP BY c.course_id, c.title
ORDER BY num_students DESC, c.course_id;
```

**预期 14 行**，两端分别是：CS-101 7 人、CS-347 5 人 …… FIN-301 0 人、PHY-201 0 人

**解析**：这里必须用 `COUNT(t.ID)` 而不是 `COUNT(*)`——若用 `COUNT(*)`，无人选的课程会因左连接产生的 NULL 行被计成 1。这是外连接 + 聚集最常踩的坑。
</details>

### 5.6 多表分组：学生已获学分 ★★★

统计每位学生**已修得**的总学分（只统计 grade 非空且不为 'F' 的课程），按学分降序。

<details><summary>参考答案</summary>

```sql
SELECT s.ID, s.name, SUM(c.credits) AS earned_credits
FROM student s
JOIN takes  t ON s.ID = t.ID
JOIN course c ON t.course_id = c.course_id
WHERE t.grade IS NOT NULL AND t.grade <> 'F'
GROUP BY s.ID, s.name
ORDER BY earned_credits DESC;
```

**预期 11 行**：Shankar 14、Peltier 8、Zhang 7、Levy 7、Williams 7、Brown 7、Tanaka 4、Brandt 3、Chavez 3、Sanchez 3、Bourikas 3

**解析**：三张表连接 + 分组，仍未超过课件 P31 的"4 张表"上限。注意 `grade <> 'F'` 与 `grade IS NOT NULL` 要同时写——因为 `NULL <> 'F'` 的结果是 unknown，不会通过过滤。
</details>

### 5.7 group by 的非法写法（改错题）★★★

下面这条语句会报错，指出原因并改正。

```sql
SELECT dept_name, ID, AVG(salary) FROM instructor GROUP BY dept_name;
```

<details><summary>参考答案</summary>

**预期报错**：`Msg 8120 Column 'instructor.ID' is invalid in the select list because it is not contained in either an aggregate function or the GROUP BY clause.`

**改正**（二选一）：

```sql
-- 方案 A：ID 也分组（每个 ID 自成一组，AVG 失去意义）
SELECT dept_name, ID, AVG(salary) FROM instructor GROUP BY dept_name, ID;

-- 方案 B：用聚集处理 ID（更符合"按系统计"的意图）
SELECT dept_name, COUNT(ID) AS num, AVG(salary) AS avg_salary
FROM instructor GROUP BY dept_name;
```

**解析**：课件 P35 明确列为错误示例。原因：分组后一组只输出一行，而同一组内 ID 有多个不同取值，DBMS 不知道该输出哪个——**语义不允许**。
</details>

---

## 阶段 6 · 嵌套子查询

> **对应课件**：P36 3.11-① in / some / all　|　P37 3.11-② exists / with / 标量子查询
> **通关标准**：能用双层否定写出"全部"类题目

### 6.1 IN 子查询 ★★

找出位于 Taylor 楼的**各系**所开设的全部课程（course_id + title）。

<details><summary>参考答案</summary>

```sql
SELECT course_id, title FROM course
WHERE dept_name IN (SELECT dept_name FROM department WHERE building = 'Taylor')
ORDER BY course_id;
```

**预期 5 行**：CS-101、CS-190、CS-315、CS-347、EE-181

**解析**：课件 P36——子查询可出现在 where 子句，形式为 `B <运算> (子查询)`。in 表示"属于该集合"。
</details>

### 6.2 NOT IN 与枚举集合 ★

找出既不在计算机系也不在物理系的教师姓名。

<details><summary>参考答案</summary>

```sql
SELECT name FROM instructor
WHERE dept_name NOT IN ('Comp. Sci.', 'Physics')
ORDER BY name;
```

**预期 7 行**：Califieri、Crick、El Said、Kim、Mozart、Singh、Wu

**解析**：课件 P36——`in` 后面也可以直接给**枚举集合**，不一定是子查询。
</details>

### 6.3 SOME（存在量词）★★★

找出工资**高于计算机系某位教师**（即高于 CS 系最低工资）的教师姓名与工资。用 `> SOME` 写。

<details><summary>参考答案</summary>

```sql
SELECT name, salary FROM instructor
WHERE salary > SOME (SELECT salary FROM instructor WHERE dept_name = 'Comp. Sci.')
ORDER BY salary;
```

**预期 8 行**：Crick 72000、Katz 75000、Singh 80000、Kim 80000、Gold 87000、Wu 90000、Brandt 92000、Einstein 95000

**解析**：课件 P36——`F <comp> SOME r` 等价于"存在 t ∈ r 使 F <comp> t 成立"，也就是 `> MIN(r)`。CS 系工资集合是 {65000, 75000, 92000}，最小值 65000，所以结果是所有工资 > 65000 的教师。`= SOME` 等价于 `IN`。
</details>

### 6.4 ALL（全称量词）★★★

找出工资**高于计算机系所有教师**（即高于 CS 系最高工资）的教师。

<details><summary>参考答案</summary>

```sql
SELECT name, salary FROM instructor
WHERE salary > ALL (SELECT salary FROM instructor WHERE dept_name = 'Comp. Sci.')
ORDER BY salary;
```

**预期 1 行**：Einstein 95000

**解析**：`F <comp> ALL r` 等价于"对 r 中每个 t 都成立"，也就是 `> MAX(r)`。CS 系最高 92000，只有 Einstein 超过。

**对比记忆**（课件 P36 考点）：
- `= SOME` ≡ `IN`，但 `<> SOME` **不等于** `NOT IN`
- `<> ALL` ≡ `NOT IN`

用 6.3 与 6.4 的对比最能体会差别：同一个子查询，SOME 得 8 行，ALL 得 1 行。

> **补充实验**：把上面两题的 `Comp. Sci.` 换成 `Biology`，会发现 SOME 与 ALL 结果**完全相同**（都是 7 行）。原因是 Biology 只有 Crick 一位教师，集合只有一个元素时 MIN = MAX。这是很好的验证性实验。
</details>

### 6.5 EXISTS ★★★

用 `EXISTS` 重写 4.7 的交集查询：找出 2017 秋和 2018 春都开设过的课程。

<details><summary>参考答案</summary>

```sql
SELECT DISTINCT S.course_id
FROM section AS S
WHERE S.semester = 'Fall' AND S.year = 2017
  AND EXISTS (SELECT 1 FROM section AS T
              WHERE T.semester = 'Spring' AND T.year = 2018
                AND S.course_id = T.course_id)
ORDER BY S.course_id;
```

**预期 2 行**：CS-101、CS-347（与 4.7 完全一致）

**解析**：课件 P37——`exists` 在子查询非空时返回 true。这里的子查询引用了外层 `S.course_id`，叫**相关子查询**（相关名 correlation name，课件 P32）。`SELECT 1` 是惯用写法，因为 EXISTS 只关心"有没有行"，不关心列内容。
</details>

### 6.6 双层否定实现"全部" ★★★（本阶段最难）

找出**选修了 Biology 系全部课程**的学生 ID 与姓名。

<details><summary>参考答案</summary>

```sql
SELECT S.ID, S.name
FROM student AS S
WHERE NOT EXISTS (
        (SELECT course_id FROM course WHERE dept_name = 'Biology')
        EXCEPT
        (SELECT T.course_id FROM takes AS T WHERE T.ID = S.ID)
      )
ORDER BY S.ID;
```

> **T-SQL 注意**：外层 `NOT EXISTS (...)` 内部的两个子查询**不能各加一对括号**（T-SQL 不支持 `(SELECT ...) EXCEPT (SELECT ...)` 这种写法）。正确写法如下：

```sql
SELECT S.ID, S.name
FROM student AS S
WHERE NOT EXISTS (
        SELECT course_id FROM course WHERE dept_name = 'Biology'
        EXCEPT
        SELECT T.course_id FROM takes AS T WHERE T.ID = S.ID
      )
ORDER BY S.ID;
```

**预期 1 行**：`98988  Tanaka`

**解析**：课件 P37 的典型题型。X = 生物系全部课程 {BIO-101, BIO-301, BIO-399}，Y = 该学生选修的课程。"Y 包含 X" 写成 `X − Y 为空`，即 `NOT EXISTS (X EXCEPT Y)`——**双层否定实现全称量词**。数据里 Peltier 只选了 BIO-101，被正确排除。

**等价写法 2（用 COUNT 比较数量，通常更好优化）**：

```sql
SELECT S.ID, S.name
FROM student AS S
WHERE (SELECT COUNT(*) FROM course C WHERE C.dept_name = 'Biology')
      =
      (SELECT COUNT(*) FROM takes T
       WHERE T.ID = S.ID
         AND T.course_id IN (SELECT course_id FROM course WHERE dept_name = 'Biology'))
ORDER BY S.ID;
```

同样返回 Tanaka。课件 P40 考点⑦：这类题也可以用 count 比较数量。
</details>

### 6.7 FROM 子句中的子查询（临时关系）★★

先按系统计平均工资，再从中筛出平均工资 > 80000 的系。要求用 **FROM 子查询**写，不用 HAVING。

<details><summary>参考答案</summary>

```sql
SELECT dept_name, avg_salary
FROM (SELECT dept_name, AVG(salary) AS avg_salary
      FROM instructor
      GROUP BY dept_name) AS dept_avg
WHERE avg_salary > 80000
ORDER BY dept_name;
```

**预期 2 行**：Finance 85000、Physics 91000

**解析**：课件 P37——from 子句中的 ri 可以替换为任意合法子查询，相当于定义一个临时关系。注意**必须给派生表起别名**（`AS dept_avg`），T-SQL 里少了别名会报 `Msg 102 Incorrect syntax near ')'`。
</details>

### 6.8 WITH 子句 ★★

用 `WITH` 定义临时视图 `max_budget`，找出预算最高的系。

<details><summary>参考答案</summary>

```sql
WITH max_budget(value) AS (
    SELECT MAX(budget) FROM department
)
SELECT d.dept_name, d.budget
FROM department d, max_budget m
WHERE d.budget = m.value;
```

**预期 1 行**：`Finance   120000`

**解析**：课件 P37——"with 子句定义局部临时视图，**建议优先使用**"。复杂查询拆成若干步，每步定义一个中间视图，逻辑比层层嵌套清晰得多。T-SQL 里 WITH 后面如果要跟其他语句，需要用 `;` 结束前一条语句。
</details>

### 6.9 标量子查询 ★★

列出每个系及其教师人数（人数为 0 也要显示）。

<details><summary>参考答案</summary>

```sql
SELECT d.dept_name,
       (SELECT COUNT(*) FROM instructor i WHERE i.dept_name = d.dept_name)
           AS num_instructors
FROM department d
ORDER BY d.dept_name;
```

**预期 7 行**：Biology 1、Comp. Sci. 3、Elec. Eng. 1、Finance 2、History 2、Music 1、Physics 2

**解析**：课件 P37——出现在 select 子句中、只产生单个值的子查询叫标量子查询。这里它引用了外层 `d.dept_name`，是相关子查询。用 `LEFT JOIN + GROUP BY` 也能做到，但标量子查询在"主表行数不多"时可读性最好。
</details>

### 6.10 UNIQUE 的替代实现 ★★★

课件 P37 的 `unique` 谓词用于测试子查询结果中是否有重复元组。**SQL Server 不支持 `UNIQUE` 子查询谓词**。请找出"2017 年只开设过一个课程班（section）"的课程号，用 T-SQL 实现。

<details><summary>参考答案</summary>

```sql
-- 课件原式（T-SQL 会报语法错，仅作对照）
-- SELECT T.course_id FROM course AS T
-- WHERE UNIQUE (SELECT R.course_id FROM section AS R
--               WHERE T.course_id = R.course_id AND R.year = 2017)

-- T-SQL 等价实现 A：相关子查询计数
SELECT c.course_id
FROM course c
WHERE (SELECT COUNT(*) FROM section s
       WHERE s.course_id = c.course_id AND s.year = 2017) = 1
ORDER BY c.course_id;

-- T-SQL 等价实现 B：分组 + HAVING
SELECT course_id
FROM section
WHERE year = 2017
GROUP BY course_id
HAVING COUNT(*) = 1
ORDER BY course_id;
```

**预期**：A 返回 6 行（BIO-301、CS-315、CS-347、FIN-201、HIS-351、PHY-101）

> 注意 A 与 B 的**语义差异**：B 只统计"在 2017 有开课记录的课程"，A 还要求"只开一次"——本数据下两者结果一致，但若某门课在 2017 一次都没开，A 会返回 0 次 ≠ 1 而排除它，B 根本不会出现它。结果相同是因为所有 2017 有记录的课程都恰好只开 1 次或 2 次。

**验证**：`SELECT course_id, COUNT(*) FROM section WHERE year = 2017 GROUP BY course_id HAVING COUNT(*) > 1;` → CS-101 开了 2 个班，所以被排除。

**解析**：这是课件与 T-SQL 的第二个方言差异（`NATURAL JOIN` 是第一个）。`UNIQUE` 是标准 SQL 的谓词，SQL Server / MySQL 均未实现。
</details>

---

## 阶段 7 · 数据库修改（insert / delete / update）

> **对应课件**：P38 3.12-① 删除与插入　|　P39 3.12-② 更新与 case
> **通关标准**：理解"先算完再改"和两条 update 的顺序陷阱
>
> **⚠️ 本章会真的改数据**——阶段 8、9、10 的所有预期结果都基于**未修改**的初始数据。两条建议二选一：
>
> 1. **每道题用事务包裹**（推荐）：`BEGIN TRANSACTION;` → 执行修改 → 查看结果 → `ROLLBACK;`
> 2. **每道题后执行附录 C 重置脚本**，重新建表装载数据

### 7.1 DELETE 基础 ★

删除 Music 系的教师 Mozart（ID 15151），并验证删除前后行数。

<details><summary>参考答案</summary>

```sql
BEGIN TRANSACTION;
SELECT COUNT(*) FROM instructor;                          -- 12
DELETE FROM instructor WHERE ID = '15151';
SELECT COUNT(*) FROM instructor;                          -- 11
ROLLBACK;
SELECT COUNT(*) FROM instructor;                          -- 12，已还原
```

**解析**：课件 P38——`delete` 只删除元组（数据），表结构仍在；删结构用 `drop table`。
</details>

### 7.2 删除低于平均工资的教师 —— "先算完再改" ★★★

课件 P38 的经典陷阱题：删除工资低于全体平均工资的教师。

**先回答**：如果边删边重算平均工资，会发生什么？

<details><summary>参考答案</summary>

```sql
-- 预演：看看会删掉谁
SELECT ID, name, salary FROM instructor
WHERE salary < (SELECT AVG(salary) FROM instructor)
ORDER BY salary;

-- 一次性删除（正确做法）
DELETE FROM instructor
WHERE salary < (SELECT AVG(salary) FROM instructor);
```

**预演结果 5 行**：Mozart 40000、El Said 60000、Califieri 62000、Srinivasan 65000、Crick 72000
（全体平均工资 = 74833.333333）

**解析**：课件 P38 的陷阱——**一边删除，平均工资一边变化，边删边算会出错**。SQL 的语义保证了正确性：`WHERE` 子句中的子查询会先被完整求值（得到 74833.33），再据此一次性标记待删元组，**不会重算、不会重复测试**。这正是声明式语言的好处——你不用自己写循环，DBMS 保证语义。

> 若你真的执行了 DELETE，用附录 C 重置数据。
</details>

### 7.3 DELETE + 子查询 ★★

删除所在系位于 Watson 楼的全体教师（课件 P38 原例）。

<details><summary>参考答案</summary>

```sql
-- 预演：Watson 楼有 Biology 和 Physics 两个系
SELECT ID, name, dept_name FROM instructor
WHERE dept_name IN (SELECT dept_name FROM department WHERE building = 'Watson')
ORDER BY ID;
-- 预期 3 行：22222 Einstein Physics / 33456 Gold Physics / 76766 Crick Biology

DELETE FROM instructor
WHERE dept_name IN (SELECT dept_name FROM department WHERE building = 'Watson');
```

**解析**：`IN` 子查询在 DELETE 中同样适用。若担心误删，可以先用 `BEGIN TRANSACTION` + `ROLLBACK` 试跑：

```sql
BEGIN TRANSACTION;
DELETE FROM instructor WHERE dept_name IN (SELECT dept_name FROM department WHERE building='Watson');
SELECT COUNT(*) FROM instructor;   -- 查看影响
ROLLBACK;                           -- 撤销
SELECT COUNT(*) FROM instructor;   -- 恢复 12
```

**这是数据库事务最实用的一个用法**（课件 P24 的 Transaction Control），强烈建议养成修改数据前开事务的习惯。
</details>

### 7.4 INSERT + SELECT 批量装载 ★★

把 Physics 系学分超过 50 的学生转为教师，工资 18000。

<details><summary>参考答案</summary>

```sql
INSERT INTO instructor (ID, name, dept_name, salary)
SELECT ID, name, dept_name, 18000
FROM student
WHERE dept_name = 'Physics' AND tot_cred > 50;

SELECT * FROM instructor WHERE salary = 18000;   -- 验证：44553 Peltier

-- 还原（否则后续题目的教师人数预期会错）
DELETE FROM instructor WHERE ID = '44553';
```

**解析**：课件 P38 原例（课件用 Music 系 144 学分）。`INSERT ... SELECT` 的 select 会先完整求值再插入。
</details>

### 7.5 UPDATE + CASE 分档更新 ★★★

给全体教师涨薪：工资 > 80000 的涨 3%，其余涨 5%。**要求用一条 CASE 语句完成**，避免两条 update 的顺序陷阱。

<details><summary>参考答案</summary>

```sql
-- 预演
SELECT ID, name, salary,
       CAST(ROUND(CASE WHEN salary > 80000 THEN salary * 1.03
                       ELSE salary * 1.05 END, 2) AS NUMERIC(8,2)) AS new_salary
FROM instructor ORDER BY ID;

-- 执行
UPDATE instructor
SET salary = ROUND(CASE WHEN salary > 80000 THEN salary * 1.03
                        ELSE salary * 1.05 END, 2);
```

**预演结果（部分）**：Srinivasan 65000 → 68250、Wu 90000 → 92700、Singh 80000 → 84000、Kim 80000 → 84000

> 执行后 salary 已被改写，继续做阶段 8、10 之前请用附录 C 重置。

**解析**：课件 P39 的顺序陷阱——若写成两条 update：
```sql
UPDATE instructor SET salary = salary * 1.05 WHERE salary <= 80000;  -- (II)
UPDATE instructor SET salary = salary * 1.03 WHERE salary >  80000;  -- (I)
```
先执行 (II) 时，原本 78000 的教师涨到 81900，随后会被 (I) **再涨一次**。用 `CASE` 一条语句、一次扫描完成分档，每个元组只被更新一次，**不存在顺序问题**。

> 注意本题边界：`Singh` 和 `Kim` 恰好是 80000，走 `ELSE` 分支涨 5%。
</details>

### 7.6 UPDATE + FROM（T-SQL 特有的多表更新）★★

根据 takes 与 course 重算每位学生的 `tot_cred`（只统计 grade 非空且不为 'F' 的学分，未选课的学生置 0）。

<details><summary>参考答案</summary>

```sql
-- 预演
SELECT s.ID, s.name,
       COALESCE((SELECT SUM(c.credits) FROM takes t JOIN course c ON t.course_id = c.course_id
                 WHERE t.ID = s.ID AND t.grade IS NOT NULL AND t.grade <> 'F'), 0) AS new_cred,
       s.tot_cred AS old_cred
FROM student s ORDER BY s.ID;

-- 写法 A：标量子查询（标准 SQL，通用）
UPDATE student
SET tot_cred = COALESCE(
    (SELECT SUM(c.credits)
     FROM takes t JOIN course c ON t.course_id = c.course_id
     WHERE t.ID = student.ID AND t.grade IS NOT NULL AND t.grade <> 'F'), 0);

-- 写法 B：UPDATE ... FROM（T-SQL 方言，性能通常更好）
UPDATE s
SET tot_cred = COALESCE(x.cred, 0)
FROM student s
LEFT JOIN (SELECT t.ID, SUM(c.credits) AS cred
           FROM takes t JOIN course c ON t.course_id = c.course_id
           WHERE t.grade IS NOT NULL AND t.grade <> 'F'
           GROUP BY t.ID) x ON s.ID = x.ID;

-- 还原（tot_cred 已被改写，还原成本较高，建议直接重置）
-- 推荐做法：执行前先 BEGIN TRANSACTION，确认无误后 COMMIT
```

**预演结果**：Zhang 7（原 102）、Lee 0（0）、Shankar 14（32）、Brandt 3（80）、Chavez 3（110）、Peltier 8（56）、Levy 7（46）、Williams 7（54）、Sanchez 3（38）、Snow 0（0）、Brown 7（58）、Bourikas 3（98）、Tanaka 4（120）

**解析**：课件 P39——未选课的学生 SUM 为 NULL，必须处理（`COALESCE` 或 `CASE WHEN ... IS NOT NULL`）。课件原式就是这个 update，只是用了 case。T-SQL 的 `UPDATE ... FROM` 是课件 P39 末尾"多表更新"例子的方言实现。
</details>

### 7.7 修改操作违反约束 ★★

执行下面三条，各会怎样？

```sql
UPDATE instructor SET salary = NULL WHERE ID = '10101';
DELETE FROM department WHERE dept_name = 'Comp. Sci.';
INSERT INTO takes VALUES ('00128','CS-101','1','Spring',2017,'A');
```

<details><summary>参考答案</summary>

1. `UPDATE instructor SET salary = NULL` —— **成功**（salary 未声明 NOT NULL）。但立刻暴露课件 P34 的工程实践问题：NULL 会让索引失效、让比较产生 unknown。**正确做法**是给 salary 加 `NOT NULL DEFAULT 0`。
2. `DELETE FROM department WHERE dept_name='Comp. Sci.'` —— **成功但会级联**：instructor/course/student 的 dept_name 被置 NULL（`ON DELETE SET NULL`）。若用的是默认 `NO ACTION`，则会被拒绝。
3. `INSERT INTO takes ... ('00128','CS-101',2017)` —— **失败**，违反主键 `(ID, course_id, year)`：学生 00128 在 2017 年已选过 CS-101（`Msg 2627 ... duplicate key value is (00128, CS-101, 2017)`）。注意这里 semester 写的 'Spring' 与已存在的 'Fall' 不同，**但主键不包含 semester**，所以照样冲突——这正是 1.7 题强调的设计后果。

**解析**：课件 P38 考点③——任何修改操作都可能违反完整性约束（主键重复、外键无对应、not null 为空），违反者会被 DBMS 拒绝。
</details>

---

## 阶段 8 · NULL 与三值逻辑

> **对应课件**：P34 3.9 Null 与三值逻辑
> **通关标准**：能预判任意含 NULL 表达式的结果是 true / false / unknown

### 8.1 `IS NULL` vs `= NULL` ★★

takes 表中有 3 条 grade 为 NULL 的记录。分别用两种写法统计，比较结果。

<details><summary>参考答案</summary>

```sql
SELECT COUNT(*) FROM takes WHERE grade IS NULL;      -- 3
SELECT COUNT(*) FROM takes WHERE grade = NULL;       -- 0
SELECT COUNT(*) FROM takes WHERE grade IS NOT NULL;  -- 20
```

**解析**：课件 P34——**不能用 `= NULL` 判断空值**，因为 `NULL = NULL` 的结果是 **unknown**，而 where 谓词为 unknown 时按 false 处理，该元组不会输出。必须写 `IS NULL`。

> T-SQL 里如果 `SET ANSI_NULLS OFF`（已废弃），`= NULL` 会生效。永远不要依赖这个设置。
</details>

### 8.2 三值逻辑的短路规则 ★★★

课件 P34 给出两条短路结论。用数据验证它们：

```sql
SELECT COUNT(*) FROM instructor WHERE salary > 50000 AND dept_name = NULL;
SELECT name, salary FROM instructor WHERE salary > 90000 OR dept_name = NULL;
```

<details><summary>参考答案</summary>

- 第一条：**0 行**。`dept_name = NULL` 恒为 unknown，`true ∧ unknown = unknown`；但只要有 false 就必为 false。所有教师的 `dept_name` 都非空，`unknown ∧ unknown = unknown` → 按 false 处理 → 0 行。
- 第二条：**2 行**（Einstein 95000、Brandt 92000）。`salary > 90000` 为 true 时，`true ∨ unknown = true`，直接短路为真。

**解析**：课件 P34 考点①——记住两条短路：`false ∧ unknown = false`、`unknown ∨ true = true`；其余组合都是 unknown，而 where 中的 unknown 按 false 处理。
</details>

### 8.3 NOT IN 遇到 NULL —— 最隐蔽的坑 ★★★（必做）

advisor 表中有一条 `i_ID` 为 NULL 的记录（Sanchez 尚未分配导师）。执行下面两条，观察结果差异。

```sql
SELECT COUNT(*) FROM student WHERE ID NOT IN (SELECT i_ID FROM advisor);
SELECT COUNT(*) FROM student s WHERE NOT EXISTS (SELECT 1 FROM advisor a WHERE a.i_ID = s.ID);
```

<details><summary>参考答案</summary>

- `NOT IN` 版本：**0 行**
- `NOT EXISTS` 版本：**13 行**

**解析**：这是三值逻辑最具破坏力的后果。`x NOT IN (集合)` 等价于 `x <> 每个元素` 的 AND 串联；一旦集合中含 NULL，就有一项 `x <> NULL` = unknown，整个 AND 链变成 unknown（除非已有 false），于是**没有任何行能通过**，结果恒为空集。

**结论（课件 P36 考点 + 工程实践）**：只要子查询的列可能为 NULL，**一律用 `NOT EXISTS` 代替 `NOT IN`**。`NOT EXISTS` 不受 NULL 影响，因为它只判断"是否存在行"。

**验证正确语义**：真正"没有导师"的学生是 8 人（Lee、Brandt、Chavez、Levy、Williams、Sanchez、Snow、Bourikas）：

```sql
SELECT s.ID, s.name FROM student s
LEFT JOIN advisor a ON s.ID = a.s_ID
WHERE a.i_ID IS NULL
ORDER BY s.ID;
```
</details>

### 8.4 NULL 与 IN 列表 ★★

```sql
SELECT COUNT(*) FROM takes WHERE grade NOT IN ('A','B','C', NULL);
SELECT COUNT(*) FROM takes WHERE grade NOT IN ('A','B','C');
```

<details><summary>参考答案</summary>

- 第一条：**0 行**（列表含 NULL，NOT IN 恒为空集）
- 第二条：**7 行**

**解析**：与 8.3 同理，只是 NULL 来自手写列表而非子查询。grade 分布为：A 9 条、A- 2、B 3、B+ 2、B- 1、C 1、C+ 1、F 1、NULL 3，共 23。第二条排除 A/B/C 共 13 条与 3 条 NULL（NULL 参与比较得 unknown，被丢弃），剩 7 条（A- 2 + B+ 2 + B- 1 + C+ 1 + F 1 = 7）。
</details>

### 8.5 聚集函数忽略 NULL ★★

对 takes 表分别求：`COUNT(*)`、`COUNT(grade)`、`AVG` 需要数值……改用：统计每条 grade 值的分布，并说明为什么 `COUNT(*)` ≠ `COUNT(grade)`。

<details><summary>参考答案</summary>

```sql
SELECT grade, COUNT(*) AS n FROM takes GROUP BY grade ORDER BY grade;
SELECT COUNT(*) AS all_rows, COUNT(grade) AS non_null FROM takes;  -- 23, 20
```

**grade 分布**：

| grade | n |
|---|---|
| NULL | 3 |
| A | 9 |
| A- | 2 |
| B | 3 |
| B+ | 2 |
| B- | 1 |
| C | 1 |
| C+ | 1 |
| F | 1 |

**解析**：课件 P34 考点② + P35——**除 `COUNT(*)` 外所有聚集运算都忽略 NULL**。所以 `COUNT(grade) = 20` 而 `COUNT(*) = 23`；同理 `AVG(列)` 的分母是 20 而不是 23。

> **`GROUP BY` 会把 NULL 归为一组**（最上面那行的 NULL 组），这在数据质量审计时很有用。
</details>

---

## 阶段 9 · 索引与查询优化

> **对应课件**：P9 1.7 查询处理器（DML 编译器生成执行计划并做查询优化，选代价最低的方案）
> **P22 2.10 等价查询与查询优化**
> **P40 工程实践三条**：① 避免 `SELECT *`；② 避免属性取 NULL；③ from 表数 ≤ 4，嵌套改连接
> ⚠️ **重要前提**：本阶段前面的表都只有十几行，SQL Server 对这种小表**永远选择全表扫描**（走索引反而更贵）。所以必须先造一张大表，优化效果才看得见。

### 9.1 造一张 10 万行的大表 ★★

创建 `big_enroll`，插入 100,000 行模拟选课记录。

<details><summary>参考答案</summary>

```sql
CREATE TABLE big_enroll (
    enroll_id   INT IDENTITY(1,1) PRIMARY KEY,
    student_id  INT          NOT NULL,
    course_id   INT          NOT NULL,
    score       NUMERIC(5,2) NOT NULL,
    enroll_date DATE         NOT NULL
);
GO

-- 用系统表交叉连接生成序列（无需循环）
WITH N AS (
    SELECT TOP (100000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO big_enroll (student_id, course_id, score, enroll_date)
SELECT (n % 5000) + 1,                                  -- 5000 个学生
       (n % 300) + 1,                                   -- 300 门课
       CAST((n % 101) AS NUMERIC(5,2)),                 -- 0~100 分
       DATEADD(DAY, n % 365, '2024-01-01')              -- 一年内随机日期
FROM N;
GO

SELECT COUNT(*) FROM big_enroll;   -- 100000
```

**解析**：`ROW_NUMBER() OVER (ORDER BY (SELECT NULL))` 是 T-SQL 造序列的标准技巧；`sys.all_objects` 自交叉连接能提供上百万行基数。这一步对应课件 P9 的"物理设计"——你正在为优化实验准备数据分布。
</details>

### 9.2 打开性能测量开关 ★

学会读取 SQL Server 的 IO 与耗时统计。

<details><summary>参考答案</summary>

```sql
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- 之后执行的每条查询，都会在"消息"面板输出：
--   Table 'big_enroll'. Scan count 1, logical reads 437, physical reads 0, ...
--   SQL Server Execution Times: CPU time = 16 ms, elapsed time = 143 ms.
```

> **VSCode 提示**：mssql 扩展把这类消息输出到**"消息"**（Messages）面板，与结果网格分开。如果看不到，检查查询结果区域下方是否有 Messages 标签页。

**关键指标**：
- **logical reads（逻辑读）**：从内存缓冲池读取的 8KB 页数。**这是最重要的指标**，越低越好
- **physical reads**：真正从磁盘读的页数（首次查询后才会有值）
- **elapsed time**：总耗时，受缓存影响大，看趋势即可

关闭：`SET STATISTICS IO OFF; SET STATISTICS TIME OFF;`
</details>

### 9.3 无索引基线：全表扫描 ★★

统计 student_id = 4242 的记录数，记录 logical reads。

<details><summary>参考答案</summary>

```sql
SELECT COUNT(*) FROM big_enroll WHERE student_id = 4242;
```

**预期**：结果 20 行；消息面板显示

```
Table 'big_enroll'. Scan count 1, logical reads ~437
```

**解析**：没有索引时，SQL Server 只能做 **Table Scan（全表扫描）**——把 437 个数据页全部读一遍才能确定哪些行满足条件。这对应课件 P20 说的"实际数据库中不会真的先生成完整笛卡尔积再做筛选，而是由查询优化器选择更高效的等价执行方式"——而这里优化器**没有更高效的路可选**。
</details>

### 9.4 建索引后对比 ★★★

在 `student_id` 上建非聚集索引，重跑同一查询，比较 logical reads。

<details><summary>参考答案</summary>

```sql
CREATE NONCLUSTERED INDEX ix_big_enroll_student ON big_enroll(student_id);
GO

-- 强制刷新统计信息（课件 P9 存储管理器职责的一部分）
UPDATE STATISTICS big_enroll;
GO

SELECT COUNT(*) FROM big_enroll WHERE student_id = 4242;
```

**预期**：logical reads 从 ~437 降到 **个位数（通常 2~5）**；执行计划从 `Table Scan` 变成 `Index Seek`

**解析**：索引把"扫描 10 万行"变成"沿 B+ 树直接定位 20 行"。这是课件 P9 说的"存储结构与存取方法定义"（DBA 五大职责之二），也是物理设计（P9）的核心内容。

**代价（必须知道的取舍）**：索引不是免费的——
- 占磁盘空间；
- 每次 INSERT / UPDATE / DELETE 都要同步维护索引，**降低写性能**；
- 索引太多会让优化器选错计划。

经验法则：在**高频查询的筛选列、连接列、外键列**上建索引。
</details>

### 9.5 覆盖索引与 INCLUDE ★★★

查询 `SELECT student_id, score FROM big_enroll WHERE student_id = 4242`。普通索引需要"回表"取 score。用 INCLUDE 建覆盖索引消除回表。

<details><summary>参考答案</summary>

```sql
-- 覆盖索引：把 score 放进索引的叶子层
CREATE NONCLUSTERED INDEX ix_big_enroll_cover
    ON big_enroll(student_id) INCLUDE (score);
GO

SELECT student_id, score FROM big_enroll WHERE student_id = 4242;
```

**预期**：logical reads 进一步下降；执行计划只剩 `Index Seek`，不再有 `Key Lookup`（回表）

**解析**：这是课件 P29 工程实践①"**避免在 select 中使用 `*`**"的技术原因——
- `SELECT *` 需要读取所有列，索引无法覆盖，必然回表，索引形同虚设；
- 只查需要的列，才能被覆盖索引完全命中。

**记住这条链路**：`SELECT *` → 无法覆盖索引 → 回表 → 逻辑读飙升 → 索引失效。
</details>

### 9.6 索引失效场景一：列上套函数 ★★★

下面两条查询语义相同，但第二条索引失效。用 STATISTICS IO 验证。

```sql
-- A：可走索引
SELECT COUNT(*) FROM big_enroll WHERE student_id = 4242;
-- B：列上套函数，索引失效
SELECT COUNT(*) FROM big_enroll WHERE student_id + 0 = 4242;
```

<details><summary>参考答案</summary>

**预期**：A 的 logical reads 是个位数；B 回到 ~437（全表扫描）

**解析**：优化器无法对"列参与表达式"的形式使用索引查找（除非建计算列索引）。同类失效场景：

| 失效写法 | 原因 |
|---|---|
| `WHERE YEAR(enroll_date) = 2024` | 列上套函数 |
| `WHERE student_id + 0 = 4242` | 列参与算术 |
| `WHERE name LIKE '%dar%'` | 通配符在前，无法定位起点 |
| `WHERE dept_name IS NULL` | NULL 不进索引（部分索引除外） |
| 隐式类型转换 | 如 VARCHAR 列与 INT 比较 |

**正确改写**：`WHERE enroll_date >= '2024-01-01' AND enroll_date < '2025-01-01'`——把函数从列上挪到常量上。
</details>

### 9.7 索引失效场景二：NULL ★★★

演示"属性允许 NULL 会拖累索引"：给 course_id 建索引，然后比较 `WHERE course_id = 200` 与 `WHERE course_id IS NULL` 的行为，并说明课件 P34 为什么建议用 DEFAULT 代替 NULL。

<details><summary>参考答案</summary>

```sql
CREATE NONCLUSTERED INDEX ix_big_enroll_course ON big_enroll(course_id);
GO

SELECT COUNT(*) FROM big_enroll WHERE course_id = 200;        -- Index Seek
SELECT COUNT(*) FROM big_enroll WHERE course_id IS NULL;      -- 本列 NOT NULL，结果为 0
```

改造实验：新增一个允许 NULL 的列并观察

```sql
ALTER TABLE big_enroll ADD remark VARCHAR(50) NULL;           -- 允许 NULL
UPDATE big_enroll SET remark = NULL;                          -- 全为 NULL
CREATE INDEX ix_big_enroll_remark ON big_enroll(remark);

SELECT COUNT(*) FROM big_enroll WHERE remark IS NULL;         -- 100000，但优化器倾向扫描
```

**结论**：
1. NULL 值让优化器拿不到有效的**选择度估计**（statistics 对 NULL 的基数估计偏差大），容易选错计划；
2. 业务逻辑里"未知"应该用**默认值**（`DEFAULT 0` / `DEFAULT ''` / `DEFAULT '1900-01-01'`）表达，而不是 NULL；
3. 一旦列必须可空且要高频查询，考虑**筛选索引（filtered index）**：

```sql
CREATE INDEX ix_remark_notnull ON big_enroll(remark) WHERE remark IS NOT NULL;
```

**解析**：直接对应课件 P34 的工程实践——"实际应用中应避免在属性中引入 null，防止索引失效；可用默认值（default value）替代"。也与 1.10 第 (5) 小问呼应。
</details>

### 9.8 嵌套子查询改写成连接 ★★★

课件 P36 明确指出："从 SQL 优化角度，嵌套应改为 from 子句中的多表连接，便于 DBMS 查询优化；被嵌入的 select 子句可能逐行重复执行，效率较低。"

**任务**：把下面这条相关子查询改写成连接，并用 STATISTICS IO 在大表上对比。

```sql
-- 原式：相关子查询（可能逐行执行）
SELECT b.student_id, b.course_id, b.score
FROM big_enroll b
WHERE b.score > (SELECT AVG(x.score) FROM big_enroll x WHERE x.course_id = b.course_id);
```

<details><summary>参考答案</summary>

```sql
-- 改写：先按课聚合，再连接（只聚合一次，而非每行一次）
SELECT b.student_id, b.course_id, b.score
FROM big_enroll b
JOIN (SELECT course_id, AVG(score) AS avg_score
      FROM big_enroll
      GROUP BY course_id) s
  ON b.course_id = s.course_id
WHERE b.score > s.avg_score;

-- 或用 WITH，可读性更好（课件 P37 推荐）
WITH course_avg AS (
    SELECT course_id, AVG(score) AS avg_score FROM big_enroll GROUP BY course_id
)
SELECT b.student_id, b.course_id, b.score
FROM big_enroll b JOIN course_avg s ON b.course_id = s.course_id
WHERE b.score > s.avg_score;
```

**预期**：改写后 CPU time 与 elapsed time 显著下降（数据量越大差距越明显）

**解析**：相关子查询在概念上是"对外层每一行执行一次内层查询"。现代 SQL Server 优化器常常能自动把它转成连接（同一个计划），**但并非总能成功**——一旦转换失败就是 O(n²)。手动改写成连接是课件 P40 工程实践③明确要求的做法。这也呼应课件 P22 的"等价查询"：写法不同，结果相同，**成本不同**——这正是查询优化发挥作用的地方。
</details>

### 9.9 表数 ≤ 4 与反规范化设计 ★★★

课件 P31 + P40："频繁执行的查询，from 中表的个数不要超过 4 个；若频繁执行的查询涉及 N ≥ 4 张表，应把这 N 张表的数据合并（反规范化设计）。"

**任务**：学生 + 导师 + 导师所在系 的查询需要 4 张表（student / advisor / instructor / department）。请用**视图**把这个高频查询固化下来，让应用层只查 1 张"表"。

<details><summary>参考答案</summary>

```sql
-- 原始 4 表查询
SELECT s.name AS student_name, i.name AS advisor_name, d.building
FROM student    s
LEFT JOIN advisor    a ON s.ID = a.s_ID
LEFT JOIN instructor i ON a.i_ID = i.ID
LEFT JOIN department d ON i.dept_name = d.dept_name;

-- 方案 A：视图（逻辑层合并，课件 P5 视图层）
CREATE VIEW v_student_advisor AS
SELECT s.ID AS student_id, s.name AS student_name, s.dept_name AS student_dept,
       i.ID AS advisor_id, i.name AS advisor_name, d.building AS advisor_building
FROM student    s
LEFT JOIN advisor    a ON s.ID = a.s_ID
LEFT JOIN instructor i ON a.i_ID = i.ID
LEFT JOIN department d ON i.dept_name = d.dept_name;
GO

SELECT * FROM v_student_advisor WHERE student_dept = 'Comp. Sci.';
-- 预期 5 行：Zhang/Katz/Taylor、Lee/NULL/NULL、Shankar/Srinivasan/Taylor、
--           Williams/NULL/NULL、Brown/Brandt/Taylor

-- 方案 B：反规范化（物理层合并，真实建一张宽表，课件 P31 原话）
CREATE TABLE student_advisor_flat (
    student_id       VARCHAR(5),
    student_name     VARCHAR(20),
    student_dept     VARCHAR(20),
    advisor_name     VARCHAR(20),
    advisor_building VARCHAR(15)
);
INSERT INTO student_advisor_flat
SELECT s.ID, s.name, s.dept_name, i.name, d.building
FROM student s
LEFT JOIN advisor    a ON s.ID = a.s_ID
LEFT JOIN instructor i ON a.i_ID = i.ID
LEFT JOIN department d ON i.dept_name = d.dept_name;
GO
```

**解析**：这是**规范化的代价与反规范化的取舍**：
- 视图：零冗余，查询时仍需连接，适合读少写多；
- 宽表：查询极快（单表扫描），但导师改名要同步更新（更新异常），适合读多写少的报表场景。

课件 P4 讲文件系统的问题之一就是"冗余与不一致"——反规范化正是**主动引入受控冗余**来换性能，必须有配套的同步机制（触发器或定时刷新）。
</details>

### 9.10 收尾：清理实验对象 ★

<details><summary>参考答案</summary>

```sql
DROP VIEW  IF EXISTS v_student_advisor;      -- SQL Server 2016+
DROP TABLE IF EXISTS student_advisor_flat;
DROP TABLE IF EXISTS big_enroll;
GO

-- 查看某张表上有哪些索引
SELECT name, type_desc FROM sys.indexes WHERE object_id = OBJECT_ID('instructor');
```

**解析**：课件 P27——`drop` 删整表（结构与数据一起消失），`delete` 只删元组。主键会自动创建一个**聚集索引**（`CLUSTERED`），这就是 `sys.indexes` 里能看到 PK 索引的原因。
</details>

---

## 阶段 10 · 综合实战

> **对应课件**：全部 Ch3 + Ch2 关系代数
> **要求**：不看答案独立完成，写完再对照

### 10.1 教务驾驶舱：各系全景视图 ★★

输出每个系：系名、预算、教师人数、学生人数、课程门数。按预算降序。

<details><summary>参考答案</summary>

```sql
SELECT d.dept_name,
       d.budget,
       (SELECT COUNT(*) FROM instructor i WHERE i.dept_name = d.dept_name) AS num_instructors,
       (SELECT COUNT(*) FROM student    s WHERE s.dept_name = d.dept_name) AS num_students,
       (SELECT COUNT(*) FROM course     c WHERE c.dept_name = d.dept_name) AS num_courses
FROM department d
ORDER BY d.budget DESC;
```

**预期**：

| dept_name | budget | ins | stu | course |
|---|---|---|---|---|
| Finance | 120000 | 2 | 1 | 2 |
| Comp. Sci. | 100000 | 3 | 5 | 4 |
| Biology | 90000 | 1 | 1 | 3 |
| Elec. Eng. | 85000 | 1 | 1 | 1 |
| Music | 80000 | 1 | 1 | 1 |
| Physics | 70000 | 2 | 3 | 2 |
| History | 50000 | 2 | 1 | 1 |
</details>

### 10.2 教师授课负荷排行 ★★

列出每位教师：ID、姓名、系、讲授的**不同课程数**、授课班次总数。未授课者显示 0。按课程数降序。

<details><summary>参考答案</summary>

```sql
SELECT i.ID, i.name, i.dept_name,
       COUNT(DISTINCT t.course_id) AS num_courses,
       COUNT(t.course_id)         AS num_sections
FROM instructor i LEFT JOIN teaches t ON i.ID = t.ID
GROUP BY i.ID, i.name, i.dept_name
ORDER BY num_courses DESC, num_sections DESC, i.name;
```

**预期 12 行**：Srinivasan 3/3；Brandt 2/2；Crick 2/2；Einstein 2/2；Katz 1/2；El Said 1/1；Gold 1/1；Kim 1/1；Mozart 1/1；Singh 1/1；Wu 1/1；Califieri 0/1

> **注意** `COUNT(t.course_id)` 对 Califieri 返回 0（左连接 NULL 被忽略），而 `COUNT(*)` 会返回 1——这正是 5.5 的坑。
</details>

### 10.3 学生成绩单（含未选课学生）★★

输出每个学生的 ID、姓名、系、课程号、课程名、成绩。未选课的学生也要出现（课程与成绩为 NULL）。

<details><summary>参考答案</summary>

```sql
SELECT s.ID, s.name, s.dept_name, t.course_id, c.title, t.grade
FROM student s
LEFT JOIN takes  t ON s.ID = t.ID
LEFT JOIN course c ON t.course_id = c.course_id
ORDER BY s.ID, t.course_id;
```

**预期 24 行**（13 名学生，其中 Lee 有一行全 NULL 的课程列；takes 共 23 条记录）
</details>

### 10.4 课程先修链 ★★★

列出每门课及其直接先修课（无先修课的显示 NULL），并按"是否为基础课"标注。

<details><summary>参考答案</summary>

```sql
SELECT c.course_id, c.title,
       p.prereq_id,
       CASE WHEN p.prereq_id IS NULL THEN '基础课' ELSE '进阶课' END AS level_tag
FROM course c LEFT JOIN prereq p ON c.course_id = p.course_id
ORDER BY c.course_id;
```

**预期 14 行**：BIO-101 基础课；BIO-301 ← BIO-101 进阶课；BIO-399 ← BIO-301；CS-101 基础课；CS-190 ← CS-101；CS-315 ← CS-101；CS-347 ← CS-101；EE-181 基础课；FIN-201 基础课；FIN-301 基础课；HIS-351 基础课；MU-199 基础课；PHY-101 基础课；PHY-201 ← PHY-101

**延伸**（自连接思考）：找出 CS-101 的**全部后继课**（含间接），需要递归 CTE——超出课件范围，留作挑战。
</details>

### 10.5 数据质量审计 ★★★

找出"数据可疑"的记录：
1. 从未被任何学生选修的课程；
2. 选了课的学生的 `tot_cred` 为 0；
3. 成绩为 NULL 的选课记录对应的学生与课程。

<details><summary>参考答案</summary>

```sql
-- 1. 无人选修的课程
SELECT c.course_id, c.title FROM course c
WHERE c.course_id NOT IN (SELECT course_id FROM takes)
ORDER BY c.course_id;
-- 预期 2 行：FIN-301、PHY-201

-- 2. 有选课记录但 tot_cred = 0 的学生
SELECT s.ID, s.name, s.tot_cred, COUNT(t.course_id) AS num_takes
FROM student s LEFT JOIN takes t ON s.ID = t.ID
GROUP BY s.ID, s.name, s.tot_cred
HAVING s.tot_cred = 0 AND COUNT(t.course_id) > 0;
-- 预期 1 行：70557 Snow 0 1

-- 3. 成绩未登记的记录
SELECT s.ID, s.name, t.course_id, c.title
FROM takes t
JOIN student s ON t.ID = s.ID
JOIN course  c ON t.course_id = c.course_id
WHERE t.grade IS NULL
ORDER BY s.ID;
-- 预期 3 行：70557 Snow CS-101 / 98988 Tanaka BIO-301 / 98988 Tanaka BIO-399
```

**解析**：这类题综合了外连接、NOT IN、HAVING、IS NULL 四个考点，是很好的自查题。注意第 1 题用了 `NOT IN`——因为 `takes.course_id` 非空，所以安全；若不确定，**永远优先用 NOT EXISTS**（见 8.3）。
</details>

### 10.6 期末模拟：用关系代数思考，用 SQL 落地 ★★★

**题目**：找出"选修了计算机系开设的**全部**课程"的学生。

先写出关系代数表达式，再写 SQL。

<details><summary>参考答案</summary>

**关系代数**（课件 P19/P21/P22）：

```
CS_courses ← π course_id ( σ dept_name = "Comp. Sci." ( course ) )
Student_taken(SID, course_id) ← π ID, course_id ( takes )
Result ← π SID ( Student_taken ÷ CS_courses )
```

（除法不是基本运算，用双层否定或计数实现）

**SQL 实现 A —— 双层否定**（课件 P37 标准答案形态）：

```sql
SELECT S.ID, S.name
FROM student S
WHERE NOT EXISTS (
        SELECT course_id FROM course WHERE dept_name = 'Comp. Sci.'
        EXCEPT
        SELECT T.course_id FROM takes T WHERE T.ID = S.ID
      )
ORDER BY S.ID;
```

**SQL 实现 B —— 计数比较**（更易优化）：

```sql
SELECT S.ID, S.name
FROM student S
WHERE (SELECT COUNT(*) FROM course C WHERE C.dept_name = 'Comp. Sci.')
      =
      (SELECT COUNT(*) FROM takes T
       WHERE T.ID = S.ID
         AND T.course_id IN (SELECT course_id FROM course WHERE dept_name = 'Comp. Sci.'))
ORDER BY S.ID;
```

**预期**：**1 行** —— `12345  Shankar`

计算机系共 4 门课：CS-101、CS-190、CS-315、CS-347。Shankar 的选课记录恰好是这 4 门，因此只有他满足条件。

| 学生 | 选修的 CS 系课程 | 是否全覆盖 |
|---|---|---|
| 12345 Shankar | CS-101、CS-190、CS-315、CS-347 | ✅ 4/4 |
| 00128 Zhang | CS-101、CS-347 | ❌ 2/4 |
| 45678 Levy | CS-101、CS-347 | ❌ 2/4 |
| 54321 Williams | CS-101、CS-347 | ❌ 2/4 |
| 78901 Brown | CS-101、CS-347 | ❌ 2/4 |
| 70557 Snow | CS-101 | ❌ 1/4 |

> 若你执行得到 0 行，说明阶段 7 的修改操作改变了 takes 数据，用附录 C 重置后重跑。

**解析**：这是课件 P37 的典型题型变体，同时考察：① 双层否定实现全称量词；② 集合差 `EXCEPT`；③ 相关子查询。把它与 6.6（Biology 版）对照做，能彻底掌握"全部"类题目的两种写法。
</details>

---

## 附录 A · T-SQL 与课件标准 SQL 的方言差异速查

| 课件写法（标准 SQL） | SQL Server 是否支持 | T-SQL 替代写法 |
|---|---|---|
| `NATURAL JOIN` | ❌ 不支持 | `INNER JOIN ... ON` 显式连接条件 |
| `UNIQUE (子查询)` 谓词 | ❌ 不支持 | 相关子查询 `COUNT(*) = 1` 或 `GROUP BY + HAVING` |
| `CREATE DOMAIN person_name CHAR(20) NOT NULL` | ❌ 不支持 | `CREATE TYPE dbo.person_name FROM VARCHAR(20) NOT NULL;`（别名类型）或直接用列定义 |
| `EXCEPT` | ✅ 支持 | （Oracle 叫 `MINUS`） |
| `INTERSECT` / `UNION` | ✅ 支持 | — |
| `> SOME` / `> ALL` | ✅ 支持 | 也可写 `> (SELECT MIN/MAX ...)` |
| `ALTER TABLE r DROP A` | ✅ 支持 | `ALTER TABLE r DROP COLUMN A` |
| `UPDATE ... FROM` | ✅ T-SQL 特有 | 标准 SQL 用相关子查询 |
| `SELECT '437'`（无 FROM） | ✅ 支持 | — |
| 字符串连接 `\|\|` | ❌ 不支持 | `+` 或 `CONCAT()` |
| `LIMIT n` | ❌ 不支持 | `TOP n` 或 `OFFSET 0 ROWS FETCH NEXT n ROWS ONLY` |
| `interval '1' day` | ❌ 无 interval 类型 | `DATEADD(DAY, 1, ...)` / `DATEDIFF(DAY, a, b)` |
| 标识符大小写 | 不敏感 | `Name` ≡ `NAME` ≡ `name`（课件 P29） |
| 字符串比较大小写 | **默认不敏感** | 排序规则 `CI_AS`；课件说"区分大小写"按标准 SQL |

**其他 T-SQL 注意点**：
- `GO` 是批处理分隔符（不是 SQL 语句），`CREATE DATABASE` / `CREATE VIEW` / `CREATE PROCEDURE` 后常需 `GO`
- 派生表（FROM 子查询）**必须**起别名
- `WITH` 前的语句必须以 `;` 结束
- `DROP TABLE IF EXISTS` 需 SQL Server 2016+

---

## 附录 B · 课件考点 → 题号索引

| 课件页码 | 考点 | 对应题号 |
|---|---|---|
| P8 1.6 | DDL / DML 区分 | 1.1–1.10、7.1–7.7 |
| P9 1.7 | 查询优化器、存储管理器 | 9.2、9.4 |
| P15 2.3 | 超键 / 候选键 / 主键 | 1.2–1.8、2.3 |
| P16 2.4 | 外键与参照完整性、导入顺序 | 1.3–1.8、2.1、2.2 |
| P17 2.5 | 模式图 | 1.9 |
| P19 2.7 | σ / π | 3.1、3.3、3.4 |
| P20 2.8 | 笛卡尔积与连接 | 4.1、4.2 |
| P21 2.9 | ∪ / ∩ / − | 4.6、4.7、4.8 |
| P22 2.10 | 等值查询与查询优化 | 9.8 |
| P25 3.2 | 域类型、numeric 定点数 | 1.4、1.10 |
| P26 3.3 | create table、三类约束、复合主键 | 1.2–1.8 |
| P27 3.4 | drop / alter、按行存储代价 | 1.10、7.1 |
| P28 3.5 | select-from-where ≡ π(σ(×))、执行顺序 | 3.1–3.8 |
| P29 3.6-① | distinct / all、算术与 as、`SELECT *` 禁用 | 3.1、3.2、9.5 |
| P30 3.6-② | where、between、元组比较 | 3.3–3.5 |
| P31 3.6-③ | from、natural join、表数 ≤ 4 | 4.1–4.4、9.9 |
| P32 3.7 | 重命名、元组变量、like、escape | 3.6、3.7、4.5 |
| P33 3.8 | order by、集合运算 | 3.8、4.6–4.8 |
| P34 3.9 | null 与三值逻辑、默认值 | 8.1–8.5、9.7 |
| P35 3.10 | 聚集、group by、having | 5.1–5.7 |
| P36 3.11-① | in / not in、some、all | 6.1–6.4 |
| P37 3.11-② | exists / not exists、unique、with、标量子查询 | 6.5–6.10 |
| P38 3.12-① | delete、insert、先算完再改 | 7.1–7.4 |
| P39 3.12-② | update、顺序陷阱、case | 7.5–7.7 |
| P40 | 工程实践三条 | 9.5、9.7、9.8、9.9 |

---

## 附录 C · 一键重置脚本

任何时候数据被改乱了，执行这段即可回到初始状态。

```sql
USE UniversityDB;
GO

-- 按依赖逆序删除
DROP TABLE IF EXISTS advisor;
DROP TABLE IF EXISTS prereq;
DROP TABLE IF EXISTS takes;
DROP TABLE IF EXISTS teaches;
DROP TABLE IF EXISTS section;
DROP TABLE IF EXISTS student;
DROP TABLE IF EXISTS instructor;
DROP TABLE IF EXISTS course;
DROP TABLE IF EXISTS department;
DROP TABLE IF EXISTS classroom;
DROP TABLE IF EXISTS big_enroll;
DROP TABLE IF EXISTS student_advisor_flat;
DROP VIEW  IF EXISTS v_student_advisor;
GO

-- 然后回到阶段 1.2 ~ 阶段 2.1，重新建表并装载数据
```

**重置后核对**：

```sql
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
-- 应为：5  7  14  12  17  17  13  23  6  6
```

---

## 通关自测清单

做完 65 题后，逐条自问，答不上来的回到对应页码复习：

1. 关系代数 6 个基本运算是哪 6 个？Join 和 ∩ 为什么不算？（P18、P20、P21）
2. `select-from-where` 对应哪个关系代数表达式？书写顺序与执行顺序的差别？（P28）
3. where 与 having 的分工？为什么聚集函数不能出现在 where？（P35）
4. group by 的硬性规则是什么？违反会怎样？（P35）
5. `NULL = NULL` 的结果是什么？`NULL <> 'F'` 呢？where 里 unknown 怎么算？（P34）
6. `NOT IN` 遇到 NULL 会怎样？正确替代写法是什么？（8.3）
7. `= SOME` 等价于什么？`<> ALL` 等价于什么？`<> SOME` 等价于 NOT IN 吗？（P36）
8. "选修了某系全部课程"的两种写法？（P37）
9. 删除"低于平均工资"的记录，为什么必须"先算完再改"？（P38）
10. 两条 update 分档涨薪的顺序陷阱是什么？怎么避免？（P39）
11. 工程实践三条分别是什么？各自的技术原因？（P40）
12. 索引什么时候会失效？举 3 个例子。（9.5、9.6、9.7）
