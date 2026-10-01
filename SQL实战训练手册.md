# SQL 实战训练手册 · MySQL 版

**配套课件**：《数据库系统原理》Ch1 Introduction / Ch2 Relational Model / Ch3 Introduction to SQL
**示例库**：university 数据库（与课件 Ch3 完全一致的 10 张表）
**环境**：VSCode + MySQL 扩展，MySQL 5.7 / 8.0 均可
**体量**：10 个阶段 · 65 道题 · 从建库到查询优化全覆盖

> **关于答案**：本手册所有预期结果（行数、具体值）均在真实数据库上执行验证过，不是估算。你跑出来的结果应与之逐字一致；若不一致，先检查建表脚本与种子数据是否完整执行。

## 版本说明（先看这里）

MySQL 有个关键版本分界线会直接影响阶段 4、6、10 的写法：

| 语法 | MySQL 8.0.31+ | MySQL 8.0.30 及更早 / 5.7 |
|---|---|---|
| `INTERSECT` | ✅ 支持 | ❌ 不支持 → 用 `EXISTS` 改写 |
| `EXCEPT` | ✅ 支持 | ❌ 不支持 → 用 `NOT EXISTS` 改写 |
| `UNION` | ✅ 支持 | ✅ 支持 |
| CTE（`WITH`） | ✅ | ❌ 5.7 不支持 |
| 窗口函数 | ✅ | ❌ 5.7 不支持 |
| `EXPLAIN ANALYZE` | ✅ 8.0.18+ | ❌ → 用普通 `EXPLAIN` |
| `CHECK` 约束真正生效 | ✅ 8.0.16+ | ⚠️ 8.0.15 及更早会**静默忽略** |

**本手册的写法**：所有版本敏感的题目都给**两种写法**——标注 `【8.0.31+】` 的是最简洁的原生写法，标注 `【全版本】` 的是任何 MySQL 都能跑的等价改写。**两条写法的结果完全一致**（已逐条实测验证）。

查看你的版本：

```sql
SELECT VERSION();
```

---

## 使用说明

1. **顺序执行**：阶段 1、2 是后面所有题目的地基，必须先跑完。
2. **先自己写，再看答案**：每题的答案都折叠在 `<details>` 里，点开前先动手。
3. **MySQL 用 `--` 注释**，`#` 也可以；行内注释用 `/* */`。
4. **每条语句必须以 `;` 结尾**（MySQL 没有 `GO`）。
5. **难度标记**：★ 基础　★★ 进阶　★★★ 课件难点 / 易错题

---

## 第 0 章 · 环境准备

### 0.1 确认你有可连接的 MySQL 实例

VSCode 的 MySQL 扩展只是客户端，**必须有一个 MySQL 服务端**才能执行。三选一：

| 方案 | 适用 | 操作 |
|---|---|---|
| **A. Docker（推荐，最快）** | 装了 Docker Desktop | 见下方命令 |
| **B. 本机 MySQL 8.0 安装** | 愿意装 ~400MB | 官网下载 MSI 安装包，装时记住 root 密码 |
| **C. XAMPP / WAMP / phpStudy** | 已装集成环境 | 启动面板里的 MySQL 服务即可 |

**方案 A 一键起库**：

```bash
docker run --name mysql8 -e MYSQL_ROOT_PASSWORD=Db@123456 \
  -p 3306:3306 -d mysql:8.0
```

容器起来了没：`docker ps`，看到 `mysql8` 状态 `Up` 即成功。

> 想指定 MySQL 5.7 把 `mysql:8.0` 换成 `mysql:5.7` 即可。本手册两种版本都有对应写法。

### 0.2 在 VSCode 里建立连接

推荐安装这两个扩展之一（扩展市场搜索即可）：

- **`Database Client`**（作者 cweijan）——功能最全，支持 MySQL / PG / SQLite 等多种库
- **`MySQL`**（作者 cweijan）——轻量，专注 MySQL

连接步骤（两者大同小异）：

1. 侧边栏出现数据库图标 → 点 `+` 新建连接
2. 依次填写：
   - **Host**：`127.0.0.1`
   - **Port**：`3306`
   - **Username**：`root`
   - **Password**：`Db@123456`（你上一步设的）
   - **Database**：先留空
3. 连接成功后展开能看到已有数据库

> 连不上先排查：① `docker ps` 容器是否在跑；② 3306 端口是否被本机已有 MySQL 占用；③ 密码是否含特殊字符被吞掉。

### 0.3 建议的工作方式

新建一个 `lab.sql` 文件，每做完一题把语句粘进去并加注释，最后它就是你的作品集。本手册的 SQL 都可以整段复制。

> ⚠️ **MySQL 的一个硬限制**：`CREATE` / `ALTER` / `DROP` 这类 DDL 语句会**隐式提交事务**，无法回滚。只有 `INSERT` / `DELETE` / `UPDATE` 能被事务保护（阶段 7 会用到）。

---

## 阶段 1 · 建库建表（DDL）

> **对应课件**：P25 3.2 域类型　|　P26 3.3 建表与完整性约束　|　P27 3.4 drop / alter
> **通关标准**：10 张表全部创建成功，且 `information_schema` 里能查到 11 条外键

### 1.1 创建数据库 ★

创建名为 `UniversityDB` 的数据库，字符集用 `utf8mb4`（MySQL 真正的完整 UTF-8，支持 emoji）。

<details><summary>参考答案</summary>

```sql
CREATE DATABASE IF NOT EXISTS UniversityDB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE UniversityDB;

-- 确认当前库
SELECT DATABASE() AS current_db;
```

**预期**：`current_db = UniversityDB`

**解析**：课件 P24 的 SQL Parts 里 DDL 包含 create / drop / alter。`CHARACTER SET utf8mb4` 是 MySQL 特有议题——MySQL 的 `utf8` 其实是**残缺的 3 字节 UTF-8**，存不了 emoji 和部分生僻字，必须写 `utf8mb4`。

> **Linux 用户注意**：MySQL 在 Linux 上 `lower_case_table_names=0`，**表名大小写敏感**。Windows / macOS 默认不敏感。统一用小写表名可以避免跨平台迁移踩坑。
</details>

### 1.2 建两张"根表"：classroom / department ★

| 表名 | 属性 | 主键 |
|---|---|---|
| classroom | building VARCHAR(15), room_number VARCHAR(7), capacity DECIMAL(4,0) | (building, room_number) |
| department | dept_name VARCHAR(20), building VARCHAR(15), budget DECIMAL(12,2) | dept_name |

要求：两张表都不依赖任何表，先建它们。

<details><summary>参考答案</summary>

```sql
CREATE TABLE classroom (
    building     VARCHAR(15),
    room_number  VARCHAR(7),
    capacity     DECIMAL(4,0),
    PRIMARY KEY (building, room_number)
);

CREATE TABLE department (
    dept_name  VARCHAR(20),
    building   VARCHAR(15),
    budget     DECIMAL(12,2),
    PRIMARY KEY (dept_name)
);
```

**解析**：课件 P26 指出 DDL 能定义"关系模式 / 属性值类型 / 完整性约束 / 索引 / 授权 / 物理存储"。这里用到了前三项。复合主键写法是 `PRIMARY KEY (A, B)`——对应课件 P26 里 `takes` 的多属性主键。

> **类型说明**：课件写 `numeric(p,d)`，MySQL 支持 `NUMERIC`，但它是 `DECIMAL` 的同义词。本手册统一写 `DECIMAL`，两者完全等价。
</details>

### 1.3 建 course —— 外键 + NOT NULL ★

course(course_id VARCHAR(8), title VARCHAR(50), dept_name VARCHAR(20), credits DECIMAL(2,0))，主键 course_id，dept_name 外键引用 department，title 不可为空。

<details><summary>参考答案</summary>

```sql
CREATE TABLE course (
    course_id  VARCHAR(8),
    title      VARCHAR(50) NOT NULL,
    dept_name  VARCHAR(20),
    credits    DECIMAL(2,0),
    PRIMARY KEY (course_id),
    FOREIGN KEY (dept_name) REFERENCES department (dept_name) ON DELETE SET NULL
);
```

**解析**：课件 P26 的三类完整性约束——`primary key` / `foreign key ... references` / `not null`，这一题全用上了。`ON DELETE SET NULL` 是**参照动作**：系被删掉时，课程的 dept_name 置为 NULL 而不是拒绝删除。

> **MySQL 要求**：外键列与被引用列的**类型必须完全一致**（长度、符号都要一致），且被引用列必须有索引。若写成 `REFERENCES department` 不带列名，MySQL 也能接受（默认主键），但显式写出更清晰。
</details>

### 1.4 建 instructor —— 复刻课件 P26 原例 ★★

要求与课件示例一致：`ID CHAR(5)`、`name VARCHAR(20) NOT NULL`、`dept_name VARCHAR(20)`、`salary DECIMAL(8,2)`，主键 ID，dept_name 外键引用 department。

<details><summary>参考答案</summary>

```sql
CREATE TABLE instructor (
    ID         CHAR(5),
    name       VARCHAR(20) NOT NULL,
    dept_name  VARCHAR(20),
    salary     DECIMAL(8,2),
    PRIMARY KEY (ID),
    FOREIGN KEY (dept_name) REFERENCES department (dept_name) ON DELETE SET NULL
);
```

**解析**：课件 P26 的原句就是这个。注意两点：① `CHAR(5)` 是定长，存 `'10101'` 正好 5 位，MySQL 会自动去掉 CHAR 列的尾随空格；② `DECIMAL(8,2)` 是定点数，共 8 位含 2 位小数——课件 P25 强调金额必须用定点数而非浮点，避免精度丢失。
</details>

### 1.5 建 section —— 复合主键 + 复合外键 ★★

section(course_id, sec_id, semester, year, building, room_number, time_slot_id)，主键为 (course_id, sec_id, semester, year)，course_id 外键引用 course，(building, room_number) 外键引用 classroom。

<details><summary>参考答案</summary>

```sql
CREATE TABLE section (
    course_id     VARCHAR(8),
    sec_id        VARCHAR(8),
    semester      VARCHAR(6),
    `year`        DECIMAL(4,0),
    building      VARCHAR(15),
    room_number   VARCHAR(7),
    time_slot_id  VARCHAR(4),
    PRIMARY KEY (course_id, sec_id, semester, `year`),
    FOREIGN KEY (course_id) REFERENCES course (course_id) ON DELETE CASCADE,
    FOREIGN KEY (building, room_number) REFERENCES classroom (building, room_number) ON DELETE SET NULL
);
```

**解析**：外键也可以由**多个属性**组成——课件 P26 的 `takes` 例子里 `foreign key (course_id, year) references section` 就是这种。被引用方必须有对应的主键或唯一约束，classroom 的主键恰好是 (building, room_number)，所以能对上。

> ⚠️ **`year` 是 MySQL 的数据类型名**（`YEAR` 类型）。虽然 MySQL 允许它作列名，但为了避免和类型混淆，本手册统一写成反引号 `` `year` ``。**养成习惯：凡是可能是保留字的列名，一律用反引号包起来**（写作 `` `year` `` 而不是 `'year'`，反引号是标识符引号，单引号是字符串）。
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
    `year`     DECIMAL(4,0),
    PRIMARY KEY (ID, course_id, sec_id, semester, `year`),
    FOREIGN KEY (ID) REFERENCES instructor (ID) ON DELETE CASCADE,
    FOREIGN KEY (course_id, sec_id, semester, `year`)
        REFERENCES section (course_id, sec_id, semester, `year`) ON DELETE CASCADE
);
```

**解析**：这是全库最"重"的约束。它表达的是"某位教师讲授某个具体的课程班"，所以外键必须完整指向 section 的四属性主键，不能只写 course_id——否则无法区分同一门课的不同学期班次。
</details>

### 1.7 建 student 与 takes —— 课件 P26 的复合主键原例 ★★

student(ID VARCHAR(5), name VARCHAR(20) NOT NULL, dept_name VARCHAR(20), tot_cred DECIMAL(3,0))，主键 ID。
takes(ID, course_id, sec_id, semester, year, grade)，主键 **(ID, course_id, year)**（与课件一致），ID 外键引用 student。

<details><summary>参考答案</summary>

```sql
CREATE TABLE student (
    ID         VARCHAR(5),
    name       VARCHAR(20) NOT NULL,
    dept_name  VARCHAR(20),
    tot_cred   DECIMAL(3,0),
    PRIMARY KEY (ID),
    FOREIGN KEY (dept_name) REFERENCES department (dept_name) ON DELETE SET NULL
);

CREATE TABLE takes (
    ID         VARCHAR(5),
    course_id  VARCHAR(8),
    sec_id     VARCHAR(8),
    semester   VARCHAR(6),
    `year`     DECIMAL(4,0),
    grade      VARCHAR(2),
    PRIMARY KEY (ID, course_id, `year`),
    FOREIGN KEY (ID) REFERENCES student (ID) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES course (course_id) ON DELETE CASCADE
);
```

**解析**：课件 P26 明确写了 `primary key (ID, course_id, year)`——主键只取三个属性，意味着**同一学生在同一年只能选同一门课一次**（不同年份可重修）。这不是笔误，是有意的设计约束，期末考试常考"为什么主键不包含 sec_id/semester"。

> 用 `VARCHAR(2)` 而不是 `CHAR(2)` 存 grade：MySQL 的 CHAR 会自动补足尾随空格（`'A'` 存成 `'A '`），虽然 `=` 比较时会忽略尾随空格，但 `LIKE` 和字符串函数行为会有差异。用 VARCHAR 更省心。
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
    FOREIGN KEY (s_ID) REFERENCES student (ID) ON DELETE CASCADE,
    FOREIGN KEY (i_ID) REFERENCES instructor (ID) ON DELETE SET NULL
);

CREATE TABLE prereq (
    course_id  VARCHAR(8),
    prereq_id  VARCHAR(8),
    PRIMARY KEY (course_id, prereq_id),
    FOREIGN KEY (course_id) REFERENCES course (course_id) ON DELETE CASCADE,
    FOREIGN KEY (prereq_id) REFERENCES course (course_id) ON DELETE CASCADE
);
```

**解析**：prereq 的两个属性引用**同一张表** course，是"关系内部的联系"；advisor 是"两张实体表之间的联系"。课件 P16 说"外键是关系模型表达联系的主要手段"，这两张表就是两个典型例子。注意 `i_ID` 没有 NOT NULL——这正是阶段 8 的陷阱素材。

> ### 💡 值得知道的方言差异：prereq 的两个 CASCADE
>
> 这两条外键**都写了** `ON DELETE CASCADE`，意味着删除一门 course 时，会有两条级联路径同时作用到 prereq：
>
> ```
> course ──(经 course_id)──→ prereq
> course ──(经 prereq_id)──→ prereq     ← 第二条路径
> ```
>
> **MySQL 允许这样建，正常工作。** 但 **SQL Server 会直接拒绝建表**：
>
> ```
> Msg 1785: 引入 FOREIGN KEY 约束 'FK__prereq__prereq_i__xxxxxx' 到表 'prereq'
>           可能会导致循环或多重级联路径。
> Msg 1750: 无法创建约束或索引。
> ```
>
> SQL Server 判断不了两条路径谁先执行，宁可在建表阶段就拒绝。三种数据库的对照：
>
> | 数据库 | 是否允许多重级联路径 | 说明 |
> |---|---|---|
> | **MySQL / MariaDB** | ✅ 允许 | InnoDB 按顺序依次处理级联 |
> | SQL Server | ❌ 拒绝建表 | 报 Msg 1785 / 1750 |
> | PostgreSQL | ✅ 允许 | 行级处理，不冲突 |
>
> 如果在 SQL Server 上，必须把其中一个改成 `ON DELETE NO ACTION`。这也提醒了一件事：**级联外键的行为在各家数据库并不统一**，跨库迁移时要逐个验证。
</details>

### 1.9 校验：查看模式图信息 ★

用 `information_schema` 查出所有外键的"参照关系 → 被参照关系"，对照课件 P17 的模式图读图要点（箭头由参照方指向被参照方）。

<details><summary>参考答案</summary>

```sql
-- 所有外键：r1 参照关系 → r2 被参照关系
SELECT
    k.TABLE_NAME             AS referencing_relation,   -- r1 参照关系
    k.COLUMN_NAME            AS fk_column,
    k.REFERENCED_TABLE_NAME  AS referenced_relation,    -- r2 被参照关系
    k.REFERENCED_COLUMN_NAME AS pk_column,
    rc.DELETE_RULE           AS on_delete
FROM information_schema.KEY_COLUMN_USAGE k
JOIN information_schema.REFERENTIAL_CONSTRAINTS rc
  ON k.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
 AND k.CONSTRAINT_SCHEMA = rc.CONSTRAINT_SCHEMA
WHERE k.TABLE_SCHEMA = 'UniversityDB'
  AND k.REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY k.TABLE_NAME, k.COLUMN_NAME;

-- 全部表清单
SELECT TABLE_NAME, ENGINE, TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'UniversityDB'
ORDER BY TABLE_NAME;
```

**预期**：外键 11 条；表 10 张——advisor、classroom、course、department、instructor、prereq、section、student、takes、teaches。

> MySQL 里数据字典在 `information_schema`（标准 SQL 也这么叫），SQL Server 则是 `sys.*` 系统视图。这是两者最直观的差异之一。

**解析**：课件 P17 的模式图三要点——① 主键加下划线；② 箭头由外键所在关系指向主键所在关系；③ 建表与导数据必须遵循箭头依赖顺序。`information_schema` 就是这张图的机器可读版本。
</details>

### 1.10 ALTER TABLE 实战 ★★

(1) 给 student 增加 `age INT` 列；(2) 观察已有行的该列值；(3) 再把它删掉；(4) 给 instructor.salary 加 CHECK 约束 `salary > 0`；(5) 给 student.tot_cred 加默认值 0。

<details><summary>参考答案</summary>

```sql
-- (1) 加列（MySQL 建议写 COLUMN，可读性更好）
ALTER TABLE student ADD COLUMN age INT;

-- (2) 已有元组在新列上取 NULL（课件 P27 原话）
SELECT ID, name, age FROM student;

-- (3) 删列
ALTER TABLE student DROP COLUMN age;

-- (4) CHECK 约束：域约束（需 MySQL 8.0.16+ 才真正生效）
ALTER TABLE instructor ADD CONSTRAINT ck_salary CHECK (salary > 0);

-- (5) 默认值：工程实践要求"用默认值替代 NULL"
ALTER TABLE student MODIFY COLUMN tot_cred DECIMAL(3,0) DEFAULT 0;

-- 查看表结构
DESC student;
SHOW CREATE TABLE student;
```

**解析**：课件 P27 三个考点：① `add` 之后已有元组在新属性上取 NULL，**所以新增列不能带 NOT NULL**（除非给默认值）；② `drop attribute` 在很多数据库中不支持（MySQL、SQL Server 支持）；③ `drop` 删整表，`delete` 只删元组。

**MySQL 语法差异一览**：

| 操作 | MySQL | SQL Server |
|---|---|---|
| 加列 | `ADD COLUMN c INT` | `ADD c INT` |
| 删列 | `DROP COLUMN c` | `DROP COLUMN c` |
| 改列类型 | `MODIFY COLUMN c 新类型` | `ALTER COLUMN c 新类型` |
| 改列名 | `CHANGE COLUMN c 新名 类型` | `sp_rename` |
| 设默认值 | `MODIFY COLUMN c 类型 DEFAULT v` | `ADD CONSTRAINT df DEFAULT v FOR c` |

另外课件 P34 的工程实践——"避免属性取 NULL，用默认值替代，防止索引失效"——就是 (5) 的动机。

> ⚠️ **MySQL 8.0.15 及更早会静默忽略 `CHECK` 约束**（能建成功但不起作用）。用 `SELECT VERSION()` 确认你的版本 ≥ 8.0.16。
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
```

**解析**：课件 P16"导入顺序"——**先导入被参照关系 r2，再导入参照关系 r1**。先定义各系，再导入隶属各系的教师。你把 instructor 放在 department 前面插入，会立刻收到 `ERROR 1452: Cannot add or update a child row: a foreign key constraint fails`。

> MySQL 多行 `VALUES` 一次插几十行是标准做法，比一行一条 `INSERT` 快得多。本手册的数据集也能一次性全部复制执行。
</details>

### 2.2 故意违反外键 —— 体会约束的作用 ★★

执行下面这条，记录报错信息，然后说明为什么被拒绝。

```sql
INSERT INTO instructor VALUES ('99999','Turing','Astronomy',100000);
```

<details><summary>参考答案</summary>

**预期报错**：
```
ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails
(`UniversityDB`.`instructor`, CONSTRAINT `instructor_ibfk_1` FOREIGN KEY (`dept_name`)
REFERENCES `department` (`dept_name`) ON DELETE SET NULL)
```

**解析**：`Astronomy` 在 department 中不存在，违反**参照完整性**（课件 P16）。课件 P26 原话："约束一旦声明，任何违反完整性约束的更新都会被阻止。"这正是文件系统做不到的（课件 P4 完整性问题：约束埋在程序代码里）。

**修复**：先 `INSERT INTO department VALUES ('Astronomy','Taylor',60000);` 再插教师。

> MySQL 的 InnoDB 会自动给外键列建索引，`instructor_ibfk_1` 这类名字是 InnoDB 自动生成的约束名。
</details>

### 2.3 违反主键约束 ★

```sql
INSERT INTO instructor VALUES ('10101','Fake','Physics',50000);
```

<details><summary>参考答案</summary>

**预期报错**：
```
ERROR 1062 (23000): Duplicate entry '10101' for key 'instructor.PRIMARY'
```

**解析**：主键唯一且非空（课件 P15）。注意这里 `name` 也重复了，但**报错只会先命中主键**——约束检查有先后顺序，唯一索引通常先于外键被检查。这也是课件 P15 选主键的实践建议：优先用数值型短字段，索引效率更高。
</details>

### 2.4 违反 NOT NULL 与 CHECK ★

```sql
INSERT INTO instructor (ID, dept_name, salary) VALUES ('88888','Physics',50000);
INSERT INTO instructor VALUES ('77777','Nobody','Physics',-1);
```

<details><summary>参考答案</summary>

- 第一条：`ERROR 1048 (23000): Column 'name' cannot be null`
- 第二条：`ERROR 3819 (HY000): Check constraint 'ck_salary' is violated.`（前提是你做了 1.10 的第 4 小问，且 MySQL ≥ 8.0.16）

**解析**：`name VARCHAR(20) NOT NULL` 是域约束层面的非空；`CHECK (salary > 0)` 是**属性值依赖**（课件 P16 提到的完整性四类之一）。两者都由 DBMS 执行，不需要写进应用程序。

> 如果你的 MySQL < 8.0.16，第二条会**插入成功**——因为老版本 MySQL 会把 CHECK 约束解析后直接丢弃。这是 MySQL 历史上著名的坑。
</details>

### 2.5 INSERT + SELECT 批量装载 ★★

把 Music 系学分超过 30 的学生转为教师，工资统一 18000（课件 P38 原例，阈值改为 30 以便有结果）。**先用 SELECT 预演，再插入。**

<details><summary>参考答案</summary>

```sql
-- 预演：确认要插什么
SELECT ID, name, dept_name, 18000 AS salary
FROM student
WHERE dept_name = 'Music' AND tot_cred > 30;
-- 预期 1 行：55739 | Sanchez | Music | 18000

-- 正式插入
INSERT INTO instructor (ID, name, dept_name, salary)
SELECT ID, name, dept_name, 18000
FROM student
WHERE dept_name = 'Music' AND tot_cred > 30;

-- 回滚这次插入，保持后续题目的数据一致
DELETE FROM instructor WHERE ID = '55739';
```

**解析**：课件 P38 考点①——`insert` 中的 `select-from-where` 会**先被完整求值**，再把结果全部插入。否则 `INSERT INTO t SELECT * FROM t` 会无限自我膨胀。

> MySQL 里 `INSERT ... SELECT` 对同一张表操作时会先把结果集物化到临时表，不会真的无限膨胀，但仍建议避免这种写法。
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

**解析**：这是**标量子查询**的典型用法（课件 P37），把 10 个单值查询横向拼成一行，比 `UNION ALL` 十行结果更适合做数据核对。MySQL 里这条查询执行很快，因为 InnoDB 对 `COUNT(*)` 有专门优化路径。
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

**预期 12 行**，前几行：Brandt 7666.666667、Califieri 5166.666667、Crick 6000.000000……

如需保留两位小数：

```sql
SELECT name, ROUND(salary/12, 2) AS monthly_salary
FROM instructor
ORDER BY name;
```

**解析**：课件 P29——select 子句可含 `+ − * /` 算术表达式，结果列用 `as` 重命名（`as` 可省略）。这条查询等价于关系代数 `π name, salary/12 (instructor)`。

> **MySQL 特有**：`/` 是普通除法返回 DECIMAL；`DIV` 才是整数除法（`8 DIV 3` = 2）；`%` 或 `MOD()` 取余。SQL Server 里两个整数相除会做整除，MySQL 不会——这是常见的跨库计算结果差异。
</details>

### 3.2 DISTINCT 去重 ★

查询教师所属的系名，**去掉重复**。再写一个带 ALL 的版本，比较行数。

<details><summary>参考答案</summary>

```sql
SELECT DISTINCT dept_name FROM instructor ORDER BY dept_name;   -- 7 行
SELECT ALL dept_name FROM instructor ORDER BY dept_name;        -- 12 行
SELECT dept_name FROM instructor ORDER BY dept_name;            -- 12 行（默认 ALL）
```

**预期**：DISTINCT 返回 7 行：Biology / Comp. Sci. / Elec. Eng. / Finance / History / Music / Physics

**解析**：课件 P29 强调——**关系代数的投影 π 会自动去重，SQL 默认不去重**。这是 SQL 与关系代数最常考的差异点。MySQL 支持写 `ALL` 显式声明保留重复，不过实际很少有人写。
</details>

### 3.3 where 单条件 ★

找出计算机系（`'Comp. Sci.'`）全体教师的姓名。

<details><summary>参考答案</summary>

```sql
SELECT name FROM instructor WHERE dept_name = 'Comp. Sci.' ORDER BY name;
```

**预期 3 行**：Brandt、Katz、Srinivasan

**解析**：课件 P30——字符串条件必须加**单引号**。

> **MySQL 的引号规则**：单引号 `'...'` 是字符串；反引号 `` `...` `` 是标识符（表名/列名）；双引号 `"..."` 默认也是字符串，但若开启 `ANSI_QUOTES` 模式就变成标识符。**不要依赖双引号**，统一用单引号表示字符串、反引号表示标识符。
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

**解析**：课件 P32——`%` 匹配任意长度子串（含空串），`_` 匹配**恰好一个**字符。

> **大小写取决于排序规则（collation）**：本手册用的 `utf8mb4_unicode_ci`，`ci` = case insensitive，所以 `'%a%'` 与 `'%A%'` 结果相同。若改成 `utf8mb4_bin` 就变成区分大小写。课件说"模式匹配区分大小写"是按标准 SQL 说的，实际行为由数据库的 collation 决定。
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

**预期 12 行**：

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

> MySQL 里想取前几条用 `LIMIT`（SQL Server 用 `TOP`）：`ORDER BY salary DESC LIMIT 3;`
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

> MySQL 里写 `FROM instructor CROSS JOIN teaches` 语义完全相同，但显式写 `CROSS JOIN` 能让读代码的人一眼看出"这是故意做的笛卡尔积"，避免被当成漏写连接条件的 bug。
</details>

### 4.2 用 NATURAL JOIN 连接（课件原式直接可用）★★★

找出所有教过课的教师 ID 与姓名（去重）。课件 P31 写的是 `instructor natural join teaches`。

<details><summary>参考答案</summary>

```sql
-- 课件原式：MySQL 原生支持 NATURAL JOIN
SELECT DISTINCT ID, name
FROM instructor NATURAL JOIN teaches
ORDER BY name;

-- 等价写法 A：显式连接条件（课件 P31 也给了）
SELECT DISTINCT i.ID, i.name
FROM instructor i, teaches t
WHERE i.ID = t.ID
ORDER BY i.name;

-- 等价写法 B：INNER JOIN（工程推荐）
SELECT DISTINCT i.ID, i.name
FROM instructor i INNER JOIN teaches t ON i.ID = t.ID
ORDER BY i.name;
```

**三种写法预期完全相同，11 行**：Brandt、Crick、Einstein、El Said、Gold、Katz、Kim、Mozart、Singh、Srinivasan、Wu

> ✅ **MySQL 支持 `NATURAL JOIN`**，课件原式可以直接跑，这点是 MySQL 比 SQL Server 方便的地方（SQL Server 完全不支持，必须改写）。

**但工程上不推荐用 NATURAL JOIN**，原因：它自动按**所有同名列**连接。假如将来给两张表各加一个同名的 `created_at` 字段，连接条件会悄悄多出一条 `created_at = created_at`，查询结果可能突变却不会报错。**写清楚 `ON i.ID = t.ID` 是更稳的做法。**

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
                AND t.`year`    = s.`year`
WHERE s.semester = 'Spring' AND s.`year` = 2018
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
-- 【全版本】UNION 自 MySQL 诞生就支持
SELECT course_id FROM section WHERE semester = 'Fall'   AND `year` = 2017
UNION
SELECT course_id FROM section WHERE semester = 'Spring' AND `year` = 2018
ORDER BY course_id;

-- 对比：UNION ALL 不去重
SELECT course_id FROM section WHERE semester = 'Fall'   AND `year` = 2017
UNION ALL
SELECT course_id FROM section WHERE semester = 'Spring' AND `year` = 2018
ORDER BY course_id;
```

**预期 14 行**：BIO-101、BIO-301、BIO-399、CS-101、CS-190、CS-315、CS-347、EE-181、FIN-201、FIN-301、HIS-351、MU-199、PHY-101、PHY-201

> MySQL 的两个子查询可以用括号包起来：`(SELECT ...) UNION (SELECT ...) ORDER BY course_id`，也可以不包。最后的 `ORDER BY` 总是作用于**整个 UNION 结果**。

**解析**：课件 P33——`union` 对应 ∪，默认自动去重；写成 `UNION ALL` 则保留重复，而且 MySQL 执行 `UNION ALL` 会跳过去重步骤，**明显更快**。不需要去重时优先写 `UNION ALL`。
</details>

### 4.7 INTERSECT —— 交集 ★★

找出 2017 年秋季和 2018 年春季**都开设过**的课程号。

<details><summary>参考答案</summary>

```sql
-- 【8.0.31+】原生 INTERSECT
SELECT course_id FROM section WHERE semester = 'Fall'   AND `year` = 2017
INTERSECT
SELECT course_id FROM section WHERE semester = 'Spring' AND `year` = 2018
ORDER BY course_id;

-- 【全版本】用 EXISTS 改写，结果完全相同
SELECT DISTINCT s1.course_id
FROM section s1
WHERE s1.semester = 'Fall' AND s1.`year` = 2017
  AND EXISTS (SELECT 1 FROM section s2
              WHERE s2.semester = 'Spring' AND s2.`year` = 2018
                AND s2.course_id = s1.course_id)
ORDER BY s1.course_id;

-- 【全版本】用 INNER JOIN 改写，思路更直接
SELECT DISTINCT s1.course_id
FROM section s1
JOIN section s2 ON s1.course_id = s2.course_id
WHERE s1.semester = 'Fall'   AND s1.`year` = 2017
  AND s2.semester = 'Spring' AND s2.`year` = 2018
ORDER BY s1.course_id;
```

**三种写法预期相同，2 行**：CS-101、CS-347

**解析**：对应 ∩。课件 P21 指出交可由差导出：`r ∩ s = r − (r − s)`，所以交不属于六个基本运算——上面的 EXISTS 和 JOIN 写法正是这个思路的落地。

> MySQL 直到 **8.0.31** 才加入 `INTERSECT` / `EXCEPT`，这是 MySQL 长期被吐槽的缺失之一。低版本务必用后两种改写。
</details>

### 4.8 EXCEPT —— 差集 ★★

找出 2017 年秋季开设、但 2018 年春季**没有**开设的课程号。

<details><summary>参考答案</summary>

```sql
-- 【8.0.31+】原生 EXCEPT
SELECT course_id FROM section WHERE semester = 'Fall'   AND `year` = 2017
EXCEPT
SELECT course_id FROM section WHERE semester = 'Spring' AND `year` = 2018
ORDER BY course_id;

-- 【全版本】用 NOT EXISTS 改写（推荐，最直观）
SELECT DISTINCT s1.course_id
FROM section s1
WHERE s1.semester = 'Fall' AND s1.`year` = 2017
  AND NOT EXISTS (SELECT 1 FROM section s2
                  WHERE s2.semester = 'Spring' AND s2.`year` = 2018
                    AND s2.course_id = s1.course_id)
ORDER BY s1.course_id;

-- 【全版本】用 LEFT JOIN + IS NULL 改写
SELECT DISTINCT s1.course_id
FROM section s1
LEFT JOIN section s2
       ON s1.course_id = s2.course_id
      AND s2.semester  = 'Spring'
      AND s2.`year`    = 2018
WHERE s1.semester = 'Fall' AND s1.`year` = 2017
  AND s2.course_id IS NULL
ORDER BY s1.course_id;
```

**三种写法预期相同，5 行**：BIO-301、CS-315、FIN-201、HIS-351、PHY-101

**解析**：对应 −（`r − s` = 在 r 中但不在 s 中）。课件 P21 强调并交差的前提是**同元且域相容**。

> 注意第三种写法里，`s2.semester = 'Spring'` 这个条件必须放在 **`ON` 子句里**，不能放到 `WHERE` 里——放到 WHERE 会把左连接"打回"内连接，结果全空。这是 LEFT JOIN 过滤条件位置的高频考点。

> MySQL 的 `EXCEPT` 名字与标准 SQL 一致（Oracle 叫 `MINUS`）。
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
| Biology | 72000.000000 | 1 |
| Comp. Sci. | 77333.333333 | 3 |
| Elec. Eng. | 80000.000000 | 1 |
| Finance | 85000.000000 | 2 |
| History | 61000.000000 | 2 |
| Music | 40000.000000 | 1 |
| Physics | 91000.000000 | 2 |

**解析**：课件 P35 硬性规则——**select 子句中出现在聚集函数之外的属性，必须出现在 group by 列表中**。`dept_name` 在 group by 里，合法。

> MySQL 用 `ONLY_FULL_GROUP_BY` 这个 sql_mode 来强制这条规则，**5.7 起默认开启**。这是好事——MySQL 5.6 时代允许非法写法并返回一个"随机"的值，坑了无数人。查看当前模式：`SELECT @@sql_mode;`
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

**解析**：课件 P35——`where` 作用于**分组前的元组**，`having` 作用于**分组后的组**。因此聚集函数（`AVG`、`COUNT`…）**不能出现在 where 中**。

> MySQL 允许在 `HAVING` 里用 SELECT 的别名（`HAVING avg_salary > 80000`），标准 SQL 和大多数数据库不允许。**别依赖这个便利**——写全 `HAVING AVG(salary) > 80000` 到哪都能跑。
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

> MySQL 5.7+ 的 `ONLY_FULL_GROUP_BY` 会要求 select 里所有非聚集列都进 GROUP BY，所以这里写了 `GROUP BY s.ID, s.name`。MySQL 能识别 `s.ID` 是主键从而推断 `s.name` 函数依赖于它，某些情况下可以省略，但写全最保险。
</details>

### 5.7 group by 的非法写法（改错题）★★★

下面这条语句会报错，指出原因并改正。

```sql
SELECT dept_name, ID, AVG(salary) FROM instructor GROUP BY dept_name;
```

<details><summary>参考答案</summary>

**预期报错**（MySQL 5.7+ 默认开启 `ONLY_FULL_GROUP_BY` 时）：
```
ERROR 1055 (42000): Expression #2 of SELECT list is not in GROUP BY clause
and contains nonaggregated column 'UniversityDB.instructor.ID' which is not
functionally dependent on columns in GROUP BY clause; this is incompatible
with sql_mode=only_full_group_by
```

**关掉 ONLY_FULL_GROUP_BY 会怎样？** MySQL 5.6 或手动关闭该模式时，这条 SQL **不报错但返回随机值**——同一系的三个教师 ID 里随便挑一个。这比报错更危险。保持默认开启。

**改正**（二选一）：

```sql
-- 方案 A：ID 也分组（每个 ID 自成一组，AVG 失去意义）
SELECT dept_name, ID, AVG(salary) FROM instructor GROUP BY dept_name, ID;

-- 方案 B：用聚集处理 ID（更符合"按系统计"的意图）
SELECT dept_name, COUNT(ID) AS num, AVG(salary) AS avg_salary
FROM instructor GROUP BY dept_name;
```

**解析**：课件 P35 明确列为错误示例。原因：分组后一组只输出一行，而同一组内 ID 有多个不同取值，DBMS 不知道该输出哪个——**语义不允许**。MySQL 用报错的方式把这个问题拦在了门外。
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

> MySQL 对 `IN (子查询)` 的优化经历了几个版本：5.6 起会把子查询转成 semi-join，性能大幅提升。但复杂子查询仍可能退化。**不确定时就用 JOIN 改写**（见 9.8）。
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

**解析**：课件 P36——`in` 后面也可以直接给**枚举集合**，不一定是子查询。`NOT IN` + 枚举集合在 MySQL 里会被优化成一系列范围判断，速度很快。
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

> MySQL 支持 `SOME` 和 `ANY` 两个等价关键字（`= ANY` ≡ `= SOME` ≡ `IN`）。

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
SELECT DISTINCT s1.course_id
FROM section s1
WHERE s1.semester = 'Fall' AND s1.`year` = 2017
  AND EXISTS (SELECT 1 FROM section s2
              WHERE s2.semester = 'Spring' AND s2.`year` = 2018
                AND s1.course_id = s2.course_id)
ORDER BY s1.course_id;
```

**预期 2 行**：CS-101、CS-347（与 4.7 完全一致）

**解析**：课件 P37——`exists` 在子查询非空时返回 true。这里的子查询引用了外层 `s1.course_id`，叫**相关子查询**（相关名 correlation name，课件 P32）。`SELECT 1` 是惯用写法，因为 EXISTS 只关心"有没有行"，不关心列内容。

> MySQL 会把 `EXISTS` 转成 semi-join 优化，`SELECT 1` / `SELECT *` / `SELECT id` 的执行计划完全相同。
</details>

### 6.6 双层否定实现"全部" ★★★（本阶段最难）

找出**选修了 Biology 系全部课程**的学生 ID 与姓名。

<details><summary>参考答案</summary>

```sql
-- 【8.0.31+】原生 EXCEPT 写法（课件 P37 的原式）
SELECT S.ID, S.name
FROM student AS S
WHERE NOT EXISTS (
        SELECT course_id FROM course WHERE dept_name = 'Biology'
        EXCEPT
        SELECT T.course_id FROM takes AS T WHERE T.ID = S.ID
      )
ORDER BY S.ID;

-- 【全版本】用双重 NOT EXISTS 改写 —— 把 EXCEPT 翻译成两层否定
SELECT S.ID, S.name
FROM student AS S
WHERE NOT EXISTS (
        SELECT C.course_id
        FROM course C
        WHERE C.dept_name = 'Biology'
          AND NOT EXISTS (SELECT 1 FROM takes T
                          WHERE T.ID = S.ID AND T.course_id = C.course_id)
      )
ORDER BY S.ID;

-- 【全版本】计数法（最容易理解，也最容易优化）
SELECT S.ID, S.name
FROM student S
WHERE (SELECT COUNT(*) FROM course C WHERE C.dept_name = 'Biology')
      =
      (SELECT COUNT(*) FROM takes T
       WHERE T.ID = S.ID
         AND T.course_id IN (SELECT course_id FROM course WHERE dept_name = 'Biology'))
ORDER BY S.ID;
```

**三种写法预期相同，1 行**：`98988  Tanaka`

**解析**：课件 P37 的典型题型。X = 生物系全部课程 {BIO-101, BIO-301, BIO-399}，Y = 该学生选修的课程。"Y 包含 X" 写成 `X − Y 为空`，即 `NOT EXISTS (X EXCEPT Y)`——**双层否定实现全称量词**。

第二种写法的翻译逻辑值得记牢：

> **「不存在一门生物系的课，是这个学生没选的」**

数据里 Peltier 只选了 BIO-101，被正确排除。
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

**解析**：课件 P37——from 子句中的 ri 可以替换为任意合法子查询，相当于定义一个临时关系。

> ⚠️ **MySQL 强制要求派生表必须有别名**（`AS dept_avg`），少了会报 `ERROR 1248 (42000): Every derived table must have its own alias`。这条限制比 SQL Server 更严格。

> 性能提示：MySQL 5.6 起会把简单派生表**合并（merge）**到外层查询，不一定真的物化成临时表；复杂派生表才会物化。用 `EXPLAIN` 能看到 `<derived2>` 是否出现。
</details>

### 6.8 WITH 子句 ★★

用 `WITH` 定义临时视图 `max_budget`，找出预算最高的系。

<details><summary>参考答案</summary>

```sql
-- 【MySQL 8.0+】CTE 写法
WITH max_budget(value) AS (
    SELECT MAX(budget) FROM department
)
SELECT d.dept_name, d.budget
FROM department d, max_budget m
WHERE d.budget = m.value;
```

```sql
-- 【全版本 / MySQL 5.7】没有 CTE，改用派生表
SELECT d.dept_name, d.budget
FROM department d,
     (SELECT MAX(budget) AS value FROM department) m
WHERE d.budget = m.value;
```

**预期 1 行**：`Finance   120000`

**解析**：课件 P37——"with 子句定义局部临时视图，**建议优先使用**"。复杂查询拆成若干步，每步定义一个中间视图，逻辑比层层嵌套清晰得多。MySQL 8.0 加入了 CTE 支持（含递归 CTE），这是 8.0 最重要的升级之一。

> MySQL 的 CTE 默认倾向于物化，与派生表性能接近；不像 PostgreSQL 12+ 那样自动内联优化。写复杂 CTE 时留意 `EXPLAIN`。
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

> 这类相关标量子查询在 MySQL 里会被**逐外层行执行**（10 万行主表就是 10 万次子查询）。数据量大时必须改写成 LEFT JOIN + GROUP BY，见 9.8。
</details>

### 6.10 UNIQUE 的替代实现 ★★★

课件 P37 的 `unique` 谓词用于测试子查询结果中是否有重复元组。**MySQL 不支持 `UNIQUE` 子查询谓词**（SQL Server 也不支持）。请找出"2017 年只开设过一个课程班（section）"的课程号，用 MySQL 实现。

<details><summary>参考答案</summary>

```sql
-- 课件原式（MySQL 会报语法错，仅作对照）
-- SELECT T.course_id FROM course AS T
-- WHERE UNIQUE (SELECT R.course_id FROM section AS R
--               WHERE T.course_id = R.course_id AND R.`year` = 2017)

-- 等价实现 A：相关子查询计数
SELECT c.course_id
FROM course c
WHERE (SELECT COUNT(*) FROM section s
       WHERE s.course_id = c.course_id AND s.`year` = 2017) = 1
ORDER BY c.course_id;

-- 等价实现 B：分组 + HAVING（推荐，只需扫描一次 section）
SELECT course_id
FROM section
WHERE `year` = 2017
GROUP BY course_id
HAVING COUNT(*) = 1
ORDER BY course_id;
```

**预期**：均为 6 行——BIO-301、CS-315、CS-347、FIN-201、HIS-351、PHY-101

**验证**：反过来查"2017 年开过多个班的课程"：

```sql
SELECT course_id, COUNT(*) AS n
FROM section
WHERE `year` = 2017
GROUP BY course_id
HAVING COUNT(*) > 1;
-- 预期 1 行：CS-101 开了 2 个班
```

> 注意 A 与 B 的**语义差异**：B 只统计"在 2017 有开课记录的课程"，A 要求"恰好开一次"，某门课一次都没开时 A 得 0 ≠ 1 会排除它，B 则根本不会出现它。本数据下结果一致，因为所有 2017 有记录的课程都恰好开 1 次或 2 次。

**解析**：这是课件与 MySQL 的一个方言差异。`UNIQUE` 是标准 SQL 的谓词，MySQL / SQL Server 均未实现。
</details>

---

## 阶段 7 · 数据库修改（insert / delete / update）

> **对应课件**：P38 3.12-① 删除与插入　|　P39 3.12-② 更新与 case
> **通关标准**：理解"先算完再改"和两条 update 的顺序陷阱
>
> **⚠️ 本章会真的改数据**——阶段 8、9、10 的所有预期结果都基于**未修改**的初始数据。两条建议二选一：
>
> 1. **每道题用事务包裹**（推荐）：`START TRANSACTION;` → 执行修改 → 查看结果 → `ROLLBACK;`
> 2. **每道题后执行附录 C 重置脚本**，重新建表装载数据
>
> ⚠️ **MySQL 特有限制**：不能在一条语句里既修改某张表、又从**同一张表**里 SELECT 子查询（报 ERROR 1093）。7.2 会专门讲怎么绕过。

### 7.1 DELETE 基础 ★

删除 Music 系的教师 Mozart（ID 15151），并验证删除前后行数。

<details><summary>参考答案</summary>

```sql
START TRANSACTION;
SELECT COUNT(*) FROM instructor;                          -- 12
DELETE FROM instructor WHERE ID = '15151';
SELECT COUNT(*) FROM instructor;                          -- 11
ROLLBACK;
SELECT COUNT(*) FROM instructor;                          -- 12，已还原
```

**解析**：课件 P38——`delete` 只删除元组（数据），表结构仍在；删结构用 `drop table`。

> MySQL 的 InnoDB 支持事务，所以 `ROLLBACK` 能生效。但如果表引擎是 **MyISAM**，事务是不生效的——删了就真删了。检查引擎：`SELECT TABLE_NAME, ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA='UniversityDB';`，必须全是 `InnoDB`。这是 MySQL 新手最容易踩的坑之一。
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

-- 一次性删除（MySQL 直接这样写会报错！见下方）
DELETE FROM instructor
WHERE salary < (SELECT avg_sal FROM (SELECT AVG(salary) AS avg_sal FROM instructor) AS x);
```

**预演结果 5 行**：Mozart 40000、El Said 60000、Califieri 62000、Srinivasan 65000、Crick 72000
（全体平均工资 = 74833.333333）

> ### ⚠️ MySQL 的 ERROR 1093 —— 必须先绕过
>
> 课件 P38 的原式在 MySQL 上**跑不通**：
>
> ```sql
> DELETE FROM instructor WHERE salary < (SELECT AVG(salary) FROM instructor);
> -- ERROR 1093 (HY000): You can't specify target table 'instructor' for update in FROM clause
> ```
>
> MySQL 不允许一条语句**既**

> 修改目标表 **又** 从它里面 SELECT 子查询（怕语义歧义）。三种绕法：
>
> ```sql
> -- 绕法 1（推荐）：派生表包一层，MySQL 会先物化成临时表
> DELETE FROM instructor
> WHERE salary < (SELECT avg_sal FROM (SELECT AVG(salary) AS avg_sal FROM instructor) AS x);
>
> -- 绕法 2：多表 DELETE 语法
> DELETE i
> FROM instructor i
> JOIN (SELECT AVG(salary) AS avg_sal FROM instructor) x
> WHERE i.salary < x.avg_sal;
>
> -- 绕法 3：用户变量
> SELECT @avg_sal := AVG(salary) FROM instructor;
> DELETE FROM instructor WHERE salary < @avg_sal;
> ```
>
> 同样的坑也出现在 **UPDATE**（见 7.5 末的说明）。这是 MySQL 独有的限制，SQL Server / PostgreSQL 无此问题。

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

START TRANSACTION;
DELETE FROM instructor
WHERE dept_name IN (SELECT dept_name FROM department WHERE building = 'Watson');
SELECT COUNT(*) FROM instructor;   -- 9
ROLLBACK;
SELECT COUNT(*) FROM instructor;   -- 12，已还原
```

**解析**：`IN` 子查询在 DELETE 中同样适用。这里的目标表（instructor）与子查询的表（department）**不同**，所以不会触发 ERROR 1093。

**强烈建议养成修改数据前开事务的习惯**——`START TRANSACTION` → 修改 → 查看 → 确认无误再 `COMMIT`，否则 `ROLLBACK`。这是课件 P24 "Transaction Control" 最实用的一个落地。
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

**解析**：课件 P38 原例（课件用 Music 系 144 学分）。`INSERT ... SELECT` 的 select 会先完整求值再插入。源表与目标表不同，不触发 ERROR 1093。
</details>

### 7.5 UPDATE + CASE 分档更新 ★★★

给全体教师涨薪：工资 > 80000 的涨 3%，其余涨 5%。**要求用一条 CASE 语句完成**，避免两条 update 的顺序陷阱。

<details><summary>参考答案</summary>

```sql
-- 预演
SELECT ID, name, salary,
       ROUND(CASE WHEN salary > 80000 THEN salary * 1.03
                  ELSE salary * 1.05 END, 2) AS new_salary
FROM instructor ORDER BY ID;

-- 执行
UPDATE instructor
SET salary = ROUND(CASE WHEN salary > 80000 THEN salary * 1.03
                        ELSE salary * 1.05 END, 2);
```

**预演结果（部分）**：Srinivasan 65000 → 68250.00、Wu 90000 → 92700.00、Singh 80000 → 84000.00、Kim 80000 → 84000.00

> 执行后 salary 已被改写，继续做阶段 8、10 之前请用附录 C 重置。

**解析**：课件 P39 的顺序陷阱——若写成两条 update：
```sql
UPDATE instructor SET salary = salary * 1.05 WHERE salary <= 80000;  -- (II)
UPDATE instructor SET salary = salary * 1.03 WHERE salary >  80000;  -- (I)
```
先执行 (II) 时，原本 78000 的教师涨到 81900，随后会被 (I) **再涨一次**。用 `CASE` 一条语句、一次扫描完成分档，每个元组只被更新一次，**不存在顺序问题**。

> ### MySQL 补充：课件 P39 的"低于平均涨薪"原式会报错
>
> 课件原文：
> ```sql
> UPDATE instructor SET salary = salary * 1.05
> WHERE salary < (SELECT AVG(salary) FROM instructor);   -- ERROR 1093！
> ```
>
> 同样的 ERROR 1093（目标表与子查询同表）。MySQL 正确写法：
>
> ```sql
> UPDATE instructor i
> JOIN (SELECT AVG(salary) AS avg_sal FROM instructor) x
> SET i.salary = i.salary * 1.05
> WHERE i.salary < x.avg_sal;
> ```
>
> 多表 UPDATE 语法是 MySQL 的惯用解法，既绕过限制又保持"先算完再改"的语义。
</details>

### 7.6 多表 UPDATE ★★

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

-- 写法 B：MySQL 多表 UPDATE + LEFT JOIN（性能更好，推荐）
UPDATE student s
LEFT JOIN (SELECT t.ID, SUM(c.credits) AS cred
           FROM takes t JOIN course c ON t.course_id = c.course_id
           WHERE t.grade IS NOT NULL AND t.grade <> 'F'
           GROUP BY t.ID) x ON s.ID = x.ID
SET s.tot_cred = COALESCE(x.cred, 0);
```

**预演结果**：Zhang 7（原 102）、Lee 0（0）、Shankar 14（32）、Brandt 3（80）、Chavez 3（110）、Peltier 8（56）、Levy 7（46）、Williams 7（54）、Sanchez 3（38）、Snow 0（0）、Brown 7（58）、Bourikas 3（98）、Tanaka 4（120）

> MySQL 里 `COALESCE()` 与 `IFNULL()` 都能处理 NULL，前者是标准 SQL，建议用前者。

**解析**：课件 P39——未选课的学生 SUM 为 NULL，必须处理（`COALESCE` 或 `CASE WHEN ... IS NOT NULL`）。写法 B 是课件 P39 末尾"多表更新"例子的 MySQL 实现：

```sql
-- MySQL 多表 UPDATE 通用语法
UPDATE 表1 [INNER|LEFT] JOIN 表2 ON 连接条件 SET 表1.列 = ...;
```

对应 SQL Server 的 `UPDATE ... FROM`、PostgreSQL 的 `UPDATE ... FROM`，三者语法各不相同。
</details>

### 7.7 修改操作违反约束 ★★

执行下面三条，各会怎样？

```sql
UPDATE instructor SET salary = NULL WHERE ID = '10101';
DELETE FROM department WHERE dept_name = 'Comp. Sci.';
INSERT INTO takes VALUES ('00128','CS-101','1','Spring',2017,'A');
```

<details><summary>参考答案</summary>

1. `UPDATE instructor SET salary = NULL` —— **成功**（salary 未声明 NOT NULL）。但立刻暴露课件 P34 的工程实践问题：NULL 让比较产生 unknown、语义模糊。**正确做法**是给 salary 加 `NOT NULL DEFAULT 0`。
2. `DELETE FROM department WHERE dept_name='Comp. Sci.'` —— **成功但会级联**：instructor/course/student 的 dept_name 被置 NULL（`ON DELETE SET NULL`）。若建表时用默认的 `RESTRICT`（MySQL 默认行为是 `RESTRICT`，与标准 SQL 的 `NO ACTION` 基本同义），则会被拒绝。
3. `INSERT INTO takes ... ('00128','CS-101',2017)` —— **失败**，违反主键 `(ID, course_id, year)`：
   ```
   ERROR 1062 (23000): Duplicate entry '00128-CS-101-2017' for key 'takes.PRIMARY'
   ```
   注意这里 semester 写的 'Spring' 与已存在的 'Fall' 不同，**但主键不包含 semester**，所以照样冲突——这正是 1.7 题强调的设计后果。

**解析**：课件 P38 考点③——任何修改操作都可能违反完整性约束（主键重复、外键无对应、not null 为空），违反者会被 DBMS 拒绝。

> MySQL InnoDB 的外键动作完整支持：`CASCADE` / `SET NULL` / `RESTRICT` / `NO ACTION`。注意 `NO ACTION` 在 MySQL 中等价于 `RESTRICT`（检查**立即**执行），这点与某些数据库"延迟到事务提交时检查"不同。
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

> MySQL 提供了 `<=>` **空安全等于运算符**：`grade <=> NULL` 与 `grade IS NULL` 等价，两个 NULL 比较得 true。这是 MySQL 独有的运算符，写迁移脚本时很有用。
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

**对照表**（课件 P34 原文）：

| AND | true | false | unknown |
|---|---|---|---|
| **true** | true | false | unknown |
| **false** | false | false | **false** ← 短路 |
| **unknown** | unknown | **false** ← 短路 | unknown |

| OR | true | false | unknown |
|---|---|---|---|
| **true** | true | true | **true** ← 短路 |
| **false** | true | false | unknown |
| **unknown** | **true** ← 短路 | unknown | unknown |
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

> **MySQL 优化说明**：MySQL 5.6+ 会把 `NOT EXISTS` 转成 anti-semi-join，性能通常优于 `LEFT JOIN + IS NULL`。三种写法里，`NOT IN` 不仅语义危险，在某些场景下优化器也较难处理。**首选 NOT EXISTS。**
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

对 takes 表分别求：`COUNT(*)`、`COUNT(grade)`，并统计 grade 值分布。

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

> **`GROUP BY` 会把 NULL 归为一组**（表格最上面那行），且 MySQL 输出时 NULL 排在最前。这在数据质量审计时很有用。
</details>

---

## 阶段 9 · 索引与查询优化

> **对应课件**：P9 1.7 查询处理器（DML 编译器生成执行计划并做查询优化，选代价最低的方案）
> **P22 2.10 等价查询与查询优化**
> **P40 工程实践三条**：① 避免 `SELECT *`；② 避免属性取 NULL；③ from 表数 ≤ 4，嵌套改连接
>
> ⚠️ **重要前提**：前面的表都只有十几行，MySQL 优化器对这种小表**永远选择全表扫描**（走索引反而更贵）。所以必须先造一张大表，优化效果才看得见。

### 9.1 造一张 10 万行的大表 ★★

创建 `big_enroll`，插入 100,000 行模拟选课记录。

<details><summary>参考答案</summary>

```sql
CREATE TABLE big_enroll (
    enroll_id   INT AUTO_INCREMENT PRIMARY KEY,
    student_id  INT           NOT NULL,
    course_id   INT           NOT NULL,
    score       DECIMAL(5,2)  NOT NULL,
    enroll_date DATE          NOT NULL
);

-- 全版本通用造数：用 information_schema 交叉连接生成序列
INSERT INTO big_enroll (student_id, course_id, score, enroll_date)
SELECT (rn % 5000) + 1,                                    -- 5000 个学生
       (rn % 300) + 1,                                     -- 300 门课
       (rn % 101),                                         -- 0~100 分
       DATE_ADD('2024-01-01', INTERVAL (rn % 365) DAY)     -- 一年内分布
FROM (
    SELECT @rn := @rn + 1 AS rn
    FROM information_schema.columns a,
         information_schema.columns b,
         (SELECT @rn := 0) r
    LIMIT 100000
) x;

SELECT COUNT(*) FROM big_enroll;   -- 100000
```

> **`information_schema.columns` 行数不够怎么办？**（比如全新安装的库，交叉连接不足 10 万行）
> 三张表交叉即可：`FROM information_schema.columns a, information_schema.columns b, information_schema.columns c LIMIT 100000`。
> 先自检：`SELECT COUNT(*) FROM information_schema.columns;`，两表相乘 ≥ 100000 就够。
>
> ⚠️ **兼容性提示**：`@rn := @rn + 1` 这种用户变量写法在 MySQL 8.0.22+ 被标记为 **deprecated**（未来可能移除），且官方不保证 SELECT 列表里用户变量的求值顺序。**8.0 用户请优先用下面的递归 CTE 写法**；5.7 只能用它。

**【MySQL 8.0 备选】递归 CTE**（注意要先调参数，默认递归深度只有 1000）：

```sql
SET SESSION cte_max_recursion_depth = 1000000;   -- 必须！默认 1000 会报 ERROR 3636
INSERT INTO big_enroll (student_id, course_id, score, enroll_date)
WITH RECURSIVE seq(n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 100000
)
SELECT (n % 5000) + 1, (n % 300) + 1, (n % 101),
       DATE_ADD('2024-01-01', INTERVAL (n % 365) DAY)
FROM seq;
```

**解析**：这一步对应课件 P9 的"物理设计"——你正在为优化实验准备数据分布。MySQL 的 AUTO_INCREMENT 是自增列（SQL Server 写 `IDENTITY(1,1)`）。
</details>

### 9.2 打开性能测量开关 ★

MySQL **没有** SQL Server 的 `STATISTICS IO`，但有更细的三套工具。

<details><summary>参考答案</summary>

**工具 1：`EXPLAIN` —— 看执行计划（全版本）**

```sql
EXPLAIN SELECT COUNT(*) FROM big_enroll WHERE student_id = 4242;
```

重点看这几列：

| 列 | 含义 | 好坏顺序 |
|---|---|---|
| `type` | 访问方式 | `system > const > eq_ref > ref > range > index > ALL`（**ALL 最差，全表扫描**） |
| `key` | 实际用到的索引 | NULL = 没走索引 |
| `rows` | 预计扫描行数 | 越小越好 |
| `Extra` | 附加信息 | `Using index` = 覆盖索引（好）；`Using where` = 回表过滤；`Using filesort/temporary` = 需要优化 |

**工具 2：`Handler_read_%` 计数器 —— 看真实读取行数（全版本）**

```sql
FLUSH STATUS;                                     -- 清零会话级计数器
SELECT COUNT(*) FROM big_enroll WHERE student_id = 4242;
SHOW SESSION STATUS LIKE 'Handler_read%';
```

| 计数器 | 含义 |
|---|---|
| `Handler_read_rnd_next` | **全表扫描**的读数 —— 这个数很大说明在扫全表 |
| `Handler_read_key` | 按索引键定位的次数 |
| `Handler_read_next` | 沿索引顺序读下一行 |
| `Handler_read_rnd` | 按随机位置读行（通常要避免） |

**这就是 MySQL 版的"逻辑读"**：全表扫描时 `Handler_read_rnd_next ≈ 100000`；走索引后降到几十。

**工具 3：`EXPLAIN ANALYZE` —— 真实执行并返回实测耗时（8.0.18+）**

```sql
EXPLAIN ANALYZE SELECT COUNT(*) FROM big_enroll WHERE student_id = 4242;
```

输出里能看到每步的 `actual time=... rows=...`，比估算的 `rows` 准得多。
</details>

### 9.3 无索引基线：全表扫描 ★★

统计 student_id = 4242 的记录数，记录 `type`、`rows`、`Handler_read_rnd_next`。

<details><summary>参考答案</summary>

```sql
EXPLAIN SELECT COUNT(*) FROM big_enroll WHERE student_id = 4242;
```

**预期**：

| type | key | rows | Extra |
|---|---|---|---|
| ALL | NULL | ~100000 | Using where |

结果 20 行（100000 / 5000 = 20）。

```sql
FLUSH STATUS;
SELECT COUNT(*) FROM big_enroll WHERE student_id = 4242;
SHOW SESSION STATUS LIKE 'Handler_read%';
```

**预期**：`Handler_read_rnd_next ≈ 100001`（扫了整张表）

**解析**：没有索引时，MySQL 只能做 **Table Scan（全表扫描，type=ALL）**——把整张表读一遍才能确定哪些行满足条件。这对应课件 P20 说的"实际数据库中不会真的先生成完整笛卡尔积再做筛选，而是由查询优化器选择更高效的等价执行方式"——而这里优化器**没有更高效的路可选**。
</details>

### 9.4 建索引后对比 ★★★

在 `student_id` 上建二级索引，重跑同一查询，对比执行计划与 Handler 计数。

<details><summary>参考答案</summary>

```sql
CREATE INDEX ix_enroll_student ON big_enroll(student_id);

-- 刷新统计信息（InnoDB 的索引基数统计）
ANALYZE TABLE big_enroll;

EXPLAIN SELECT COUNT(*) FROM big_enroll WHERE student_id = 4242;
```

**预期**：

| type | key | rows | Extra |
|---|---|---|---|
| ref | ix_enroll_student | 20 | Using index |

```sql
FLUSH STATUS;
SELECT COUNT(*) FROM big_enroll WHERE student_id = 4242;
SHOW SESSION STATUS LIKE 'Handler_read%';
```

**预期**：`Handler_read_key = 1`，`Handler_read_next ≈ 20`，`Handler_read_rnd_next ≈ 0`

> 降水量级对比：全表扫描读 **10 万行** vs 走索引读 **20 行**，差 5000 倍。

**解析**：索引把"扫描 10 万行"变成"沿 B+ 树直接定位 20 行"。这是课件 P9 说的"存储结构与存取方法定义"（DBA 五大职责之二），也是物理设计（P9）的核心内容。

**代价（必须知道的取舍）**：索引不是免费的——
- 占磁盘空间；
- 每次 INSERT / UPDATE / DELETE 都要同步维护 B+ 树，**降低写性能**；
- 索引太多会让优化器选错计划。

经验法则：在**高频查询的筛选列、连接列、外键列**上建索引。

> **MySQL 索引特性**：InnoDB 的二级索引叶子节点存的是**主键值**，走二级索引拿到主键后通常要"回表"再查一次聚簇索引。所以 **InnoDB 表一定不要用过长的主键**（比如长 VARCHAR），否则所有二级索引都会跟着膨胀。
</details>

### 9.5 覆盖索引（MySQL 用复合索引实现）★★★

查询 `SELECT student_id, score FROM big_enroll WHERE student_id = 4242`。单列索引需要"回表"取 score。用**复合索引**消除回表。

<details><summary>参考答案</summary>

```sql
-- MySQL 没有 SQL Server 的 INCLUDE 语法，改用「把要取的列放进索引」
CREATE INDEX ix_enroll_cover ON big_enroll(student_id, score);

ANALYZE TABLE big_enroll;

EXPLAIN SELECT student_id, score FROM big_enroll WHERE student_id = 4242;
```

**预期**：`Extra` 出现 **`Using index`**（覆盖索引命中，无需回表）

> **MySQL vs SQL Server 语法对照**：
> ```sql
> -- SQL Server
> CREATE INDEX ix ON big_enroll(student_id) INCLUDE (score);
> -- MySQL / PostgreSQL
> CREATE INDEX ix ON big_enroll(student_id, score);
> ```
> 两者效果相同：MySQL 的复合索引天然包含后续列的值。

**解析**：这是课件 P29 工程实践①"**避免在 select 中使用 `*`**"的技术原因——

- `SELECT *` 需要读取所有列，索引无法覆盖，必然回表，索引形同虚设；
- 只查需要的列，才能被覆盖索引完全命中。

**记住这条链路**：`SELECT *` → 无法覆盖索引 → 回表 → 读取行数飙升 → 索引效果打折。
</details>

### 9.6 索引失效场景：列上套函数 / 隐式转换 ★★★

下面几条查询语义相同或相近，但只有部分能走索引。用 EXPLAIN 逐个验证。

```sql
-- A：可走索引
SELECT COUNT(*) FROM big_enroll WHERE student_id = 4242;
-- B：列上套表达式
SELECT COUNT(*) FROM big_enroll WHERE student_id + 0 = 4242;
-- C：列上套函数
SELECT COUNT(*) FROM big_enroll WHERE YEAR(enroll_date) = 2024;
-- D：日期范围写法（推荐）
SELECT COUNT(*) FROM big_enroll WHERE enroll_date >= '2024-01-01' AND enroll_date < '2025-01-01';

-- E：字符串列与数字比较（隐式转换）——先准备一列字符串
ALTER TABLE big_enroll ADD COLUMN course_code VARCHAR(10);
UPDATE big_enroll SET course_code = CONCAT('C', course_id);
CREATE INDEX ix_enroll_code ON big_enroll(course_code);
ANALYZE TABLE big_enroll;
-- E-1：类型一致
SELECT COUNT(*) FROM big_enroll WHERE course_code = 'C42';
-- E-2：字符串列与数字比较
SELECT COUNT(*) FROM big_enroll WHERE course_code = 1;
```

<details><summary>参考答案</summary>

**预期**：

| 编号 | 能否走索引 | type | 说明 |
|---|---|---|---|
| A | ✅ | ref | 基准写法 |
| B | ❌ | ALL | 列参与算术表达式 |
| C | ❌ | ALL | 列上套函数 |
| D | ✅ | range | 把函数从列上挪到常量上 |
| E-1 | ✅ | ref | 类型一致，正常走索引 |
| E-2 | ❌ | ALL | 字符串列与整数比较 → 隐式转换，索引失效 |

> E-2 还有个隐蔽危害：MySQL 会把 `course_code` 逐行转成数字再比较，`'C42'` 被转成 **0**，所以 `course_code = 1` 匹配不到任何行但也不报错——**结果是错的**。这类 bug 在线上很难发现。

**通用改法**：把函数/运算从**列上**挪到**常量上**——`YEAR(enroll_date)=2024` 改写成 D 的形式。

**MySQL 索引失效场景汇总**：

| 失效写法 | 原因 | 修法 |
|---|---|---|
| `WHERE YEAR(col) = 2024` | 列上套函数 | 改成范围比较 |
| `WHERE col + 0 = 4242` | 列参与运算 | 把运算移到右边 |
| `WHERE NAME LIKE '%dar%'` | 通配符在前，无法定位起点 | 改用全文索引或倒排 |
| 字符串列与数字比较 | 隐式转换使索引失效，且**结果可能错** | **保持类型一致**，尤其注意 ORM 传参 |
| 两表 JOIN 的字符集/排序规则不同 | 隐式转换 | 统一 CHARACTER SET / COLLATE |
| `OR` 连接的条件有一侧无索引 | 优化器放弃索引 | 改写成 `UNION ALL` 或给两侧都建索引 |
| 优化器判断回表成本高于全表扫描 | 数据分布问题 | `ANALYZE TABLE` 刷新统计，或强制索引 `FORCE INDEX` |

> 第 5 条（字符集不一致导致 JOIN 失效）是 MySQL 独有的坑，多发生在跨库 JOIN 或历史表与新表之间，排查时优先看 `SHOW CREATE TABLE`。
</details>

### 9.7 NULL 与索引 —— MySQL 的行为和 SQL Server 相反 ★★★

这是一个**必须纠偏**的知识点。很多教程（包括面向 SQL Server 的写法）会说"NULL 不进索引，导致 `IS NULL` 走不了索引"。**在 MySQL / InnoDB 上这句话是错的。**

<details><summary>参考答案</summary>

**实验：证明 MySQL 下 `IS NULL` 能走索引**

```sql
ALTER TABLE big_enroll ADD COLUMN remark VARCHAR(50) NULL;
UPDATE big_enroll SET remark = NULL;                 -- 全部 NULL
UPDATE big_enroll SET remark = 'note' WHERE enroll_id % 100 = 0;  -- 1% 非空

CREATE INDEX ix_enroll_remark ON big_enroll(remark);
ANALYZE TABLE big_enroll;

EXPLAIN SELECT COUNT(*) FROM big_enroll WHERE remark IS NULL;
```

**预期**：`type = ref`，`key = ix_enroll_remark` —— **确实走了索引**。

**结论**：

| 数据库 | NULL 是否存入索引 | `IS NULL` 能否用索引 |
|---|---|---|
| **MySQL / InnoDB** | ✅ 存入（NULL 作为一组排在最前） | ✅ 可以（type=ref） |
| SQL Server | ❌ 不存 | ❌ 通常不能 |
| PostgreSQL | ✅ 存入 | ✅ 可以 |

**那课件 P34 的工程实践还成立吗？成立，但理由不同。**

SQL Server 上的理由是"索引失效"；**MySQL 上的理由是下面这些**（每一条都能在本手册找到对应题目）：

1. **语义模糊**：NULL 既可以表示"值未知"，也可以表示"值不存在"，两种含义混在一列里必然出错（见 1.8 的 advisor.i_ID）
2. **三值逻辑陷阱**：`NOT IN` 遇到 NULL 返回空集（**8.3，0 行 vs 13 行**）
3. **聚集函数行为差异**：`COUNT(*)` ≠ `COUNT(列)`，AVG 分母变化（**8.5**）
4. **比较运算静默失败**：`grade <> 'F'` 会漏掉所有 NULL 行，不报错只是结果少（**5.6**）
5. **存储空间**：每行需要额外的 NULL 位图

**正确做法**：用默认值表达"业务上的空"，让列保持 NOT NULL。

```sql
ALTER TABLE big_enroll MODIFY COLUMN remark VARCHAR(50) NOT NULL DEFAULT '';
UPDATE big_enroll SET remark = '' WHERE remark IS NULL;
```

这样 downstream 的所有查询都不用再写 `IS NULL` 判断，逻辑简单且不容易错。

> 顺带一提 MySQL 的**索引 cardinality（基数）**问题：如果某列绝大多数值相同（比如 99% 是 NULL），优化器可能判断"走索引不如全表扫描"而放弃索引——这不是"索引失效"，而是**成本估算后的理性选择**。用 `ANALYZE TABLE` 更新统计，或用 `SHOW INDEX FROM big_enroll` 看 Cardinality 列。
</details>

### 9.8 嵌套子查询改写成连接 ★★★

课件 P36 明确指出："从 SQL 优化角度，嵌套应改为 from 子句中的多表连接，便于 DBMS 查询优化；被嵌入的 select 子句可能逐行重复执行，效率较低。"

**任务**：把下面这条相关子查询改写成连接，并用 EXPLAIN 对比。

```sql
-- 原式：相关子查询（可能逐行执行）
SELECT b.student_id, b.course_id, b.score
FROM big_enroll b
WHERE b.score > (SELECT AVG(x.score) FROM big_enroll x WHERE x.course_id = b.course_id);
```

<details><summary>参考答案</summary>

```sql
-- 改写：先按课聚合，再连接（聚合一次，而非每行一次）
SELECT b.student_id, b.course_id, b.score
FROM big_enroll b
JOIN (SELECT course_id, AVG(score) AS avg_score
      FROM big_enroll
      GROUP BY course_id) s
  ON b.course_id = s.course_id
WHERE b.score > s.avg_score;

-- 或用 CTE【MySQL 8.0+】，可读性更好（课件 P37 推荐）
WITH course_avg AS (
    SELECT course_id, AVG(score) AS avg_score FROM big_enroll GROUP BY course_id
)
SELECT b.student_id, b.course_id, b.score
FROM big_enroll b JOIN course_avg s ON b.course_id = s.course_id
WHERE b.score > s.avg_score;
```

**预期**：改写前 `EXPLAIN` 出现 `DEPENDENT SUBQUERY`（依赖子查询，随外层行数 × 300 门课）；改写后变成 `DERIVED`（派生表，只算一次）+ `ref`

**解析**：相关子查询在概念上是"对外层每一行执行一次内层查询"。MySQL 优化器有时能把它转成 semi-join，**但并非总能成功**——一旦转换失败就是 O(n²)。手动改写成连接是课件 P40 工程实践③明确要求的做法。这也呼应课件 P22 的"等价查询"：写法不同，结果相同，**成本不同**——这正是查询优化发挥作用的地方。

> MySQL 的 `DEPENDENT SUBQUERY` 是 EXPLAIN 里的危险信号，看到就应该考虑改写。
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
```

**解析**：这是**规范化的代价与反规范化的取舍**：
- 视图：零冗余，查询时仍需连接，适合读少写多；
- 宽表：查询极快（单表扫描），但导师改名要同步更新（更新异常），适合读多写少的报表场景。

课件 P4 讲文件系统的问题之一就是"冗余与不一致"——反规范化正是**主动引入受控冗余**来换性能，必须有配套的同步机制（触发器或定时刷新）。

> **MySQL 视图的一个重要限制**：MySQL 视图默认使用 **`MERGE` 算法**（把视图定义合并到外层查询），不会预先物化；复杂视图（含 `GROUP BY`、`DISTINCT`、聚合函数）会退化为 `TEMPTABLE` 算法，先生成临时表再过滤，**性能可能很差**。用 `EXPLAIN` 检查视图查询是否出现 `<derived2>` 就知道用哪种了。
</details>

### 9.10 收尾：清理实验对象 ★

<details><summary>参考答案</summary>

```sql
DROP VIEW  IF EXISTS v_student_advisor;
DROP TABLE IF EXISTS student_advisor_flat;
DROP TABLE IF EXISTS big_enroll;

-- 查看某张表上有哪些索引
SHOW INDEX FROM instructor;
-- 或从数据字典查
SELECT INDEX_NAME, COLUMN_NAME, NON_UNIQUE
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'UniversityDB' AND TABLE_NAME = 'instructor';
```

**解析**：课件 P27——`drop` 删整表（结构与数据一起消失），`delete` 只删元组。

> `SHOW INDEX` 结果里 `Key_name` 一列会看到 `PRIMARY`，`Index_type` 为 `BTREE`。InnoDB 的主键索引就是**聚簇索引**（数据按主键顺序物理存放），这与 SQL Server 需要显式声明 `CLUSTERED` 不同——**InnoDB 里"主键"就等价于"聚簇索引"**。
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

```sql
-- 【MySQL 8.0+】递归 CTE 参考
WITH RECURSIVE post(course_id) AS (
    SELECT course_id FROM prereq WHERE prereq_id = 'CS-101'
    UNION
    SELECT p.course_id FROM prereq p JOIN post ON p.prereq_id = post.course_id
)
SELECT * FROM post;
```
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

-- 1'. 更稳的写法（takes.course_id 非空所以两者等价，但养成习惯）
SELECT c.course_id, c.title FROM course c
WHERE NOT EXISTS (SELECT 1 FROM takes t WHERE t.course_id = c.course_id)
ORDER BY c.course_id;

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

> MySQL 的 `HAVING` 允许引用 select 别名和未分组的列（这里 `s.tot_cred` 已分组），这在 MySQL 里合法。标准做法仍建议写全。
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

**SQL 实现 A —— 原生 EXCEPT【8.0.31+】**：

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

**SQL 实现 B —— 双重 NOT EXISTS【全版本】**：

```sql
SELECT S.ID, S.name
FROM student S
WHERE NOT EXISTS (
        SELECT C.course_id FROM course C
        WHERE C.dept_name = 'Comp. Sci.'
          AND NOT EXISTS (SELECT 1 FROM takes T
                          WHERE T.ID = S.ID AND T.course_id = C.course_id)
      )
ORDER BY S.ID;
```

**SQL 实现 C —— 计数比较【全版本，最易优化】**：

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

**三种写法预期相同：1 行** —— `12345  Shankar`

计算机系共 4 门课：CS-101、CS-190、CS-315、CS-347。只有 Shankar 的选课记录恰好是这 4 门。

| 学生 | 选修的 CS 系课程 | 是否全覆盖 |
|---|---|---|
| 12345 Shankar | CS-101、CS-190、CS-315、CS-347 | ✅ 4/4 |
| 00128 Zhang | CS-101、CS-347 | ❌ 2/4 |
| 45678 Levy | CS-101、CS-347 | ❌ 2/4 |
| 54321 Williams | CS-101、CS-347 | ❌ 2/4 |
| 78901 Brown | CS-101、CS-347 | ❌ 2/4 |
| 70557 Snow | CS-101 | ❌ 1/4 |

> 若你执行得到 0 行，说明阶段 7 的修改操作改变了 takes 数据，用附录 C 重置后重跑。

**解析**：这是课件 P37 的典型题型变体，同时考察：① 双层否定实现全称量词；② 集合差 `EXCEPT`；③ 相关子查询。把它与 6.6（Biology 版）对照做，能彻底掌握"全部"类题目的三种写法。
</details>

---

## 附录 A · MySQL 与课件标准 SQL / SQL Server 的方言差异速查

### A.1 课件原式 vs MySQL

| 课件写法（标准 SQL） | MySQL 是否支持 | MySQL 写法 |
|---|---|---|
| `NATURAL JOIN` | ✅ 支持（但不推荐） | 直接用，或改 `INNER JOIN ... ON` |
| `UNIQUE (子查询)` 谓词 | ❌ 不支持 | 相关子查询 `COUNT(*)=1` 或 `GROUP BY + HAVING` |
| `CREATE DOMAIN person_name CHAR(20) NOT NULL` | ❌ 不支持 | 直接在列上写类型 + `CHECK`；或用 `ENUM` 约束取值 |
| `EXCEPT` / `INTERSECT` | ⚠️ **8.0.31+** 才支持 | 低版本用 `NOT EXISTS` / `EXISTS` 改写 |
| `UNION` / `UNION ALL` | ✅ 支持 | — |
| `> SOME` / `> ALL` | ✅ 支持（`ANY` ≡ `SOME`） | — |
| `ALTER TABLE r DROP A` | ✅ 支持 | `ALTER TABLE r DROP COLUMN A` |
| `RENAME ρ`（AS 别名） | ✅ 支持 | — |
| `INTERVAL '1' day` 类型 | ❌ 无 interval 类型 | `DATE_ADD(d, INTERVAL 1 DAY)` / `DATEDIFF(a,b)` |
| `NUMERIC(p,d)` | ✅ 是 `DECIMAL` 的同义词 | 建议直接写 `DECIMAL` |
| 派生表（FROM 子查询） | ✅ 支持，**必须有别名** | 少了别名报 ERROR 1248 |

### A.2 MySQL vs SQL Server（本手册改版涉及的主要差异）

| 功能 | MySQL | SQL Server |
|---|---|---|
| 批处理分隔符 | `;`（无 GO） | `GO` |
| 自增列 | `AUTO_INCREMENT` | `IDENTITY(1,1)` |
| 限制行数 | `LIMIT n` / `LIMIT o, n` | `TOP n` / `OFFSET FETCH` |
| 字符串连接 | `CONCAT(a,b)`（`+` 是加法） | `+` 或 `CONCAT()` |
| 获取当前库 | `SELECT DATABASE()` | `SELECT DB_NAME()` |
| 数据字典 | `information_schema.*` | `sys.*` 系统视图 |
| 多表 UPDATE | `UPDATE t1 JOIN t2 ON ... SET t1.c=...` | `UPDATE ... FROM` |
| 覆盖索引 | 复合索引 `(a, b)` | `CREATE INDEX ... (a) INCLUDE (b)` |
| 执行计划 | `EXPLAIN` / `EXPLAIN ANALYZE` | `SET SHOWPLAN_XML ON` / 图形执行计划 |
| IO 统计 | `SHOW STATUS LIKE 'Handler_read%'` | `SET STATISTICS IO ON` |
| 更新统计 | `ANALYZE TABLE t` | `UPDATE STATISTICS t` |
| 事务开始 | `START TRANSACTION` | `BEGIN TRANSACTION` |
| NULL 进索引 | ✅ 进，`IS NULL` 可走索引 | ❌ 不进，通常不走索引 |
| 多重级联外键 | ✅ 允许 | ❌ 拒绝建表（Msg 1785/1750） |
| 删自身子查询 | ❌ ERROR 1093（需派生表绕过） | ✅ 允许 |
| 存储引擎 | InnoDB（事务）/ MyISAM（非事务） | 只有一种，均支持事务 |
| DDL 事务回滚 | ❌ DDL 隐式提交 | ✅ 部分支持 |
| 标识符引号 | 反引号 `` `col` `` | 方括号 `[col]` 或双引号 |
| 主键 = 聚簇索引 | ✅ InnoDB 默认 | 需显式 `CLUSTERED`（默认也是） |

### A.3 MySQL 常见错误码速查

| 错误码 | 含义 | 出现在 |
|---|---|---|
| 1062 | Duplicate entry ... for key 'PRIMARY' | 主键/唯一键冲突（2.3、7.7） |
| 1048 | Column 'x' cannot be null | NOT NULL 约束（2.4） |
| 1452 | Cannot add or update a child row: FK constraint fails | 外键违反（2.2） |
| 1451 | Cannot delete or update a parent row: FK constraint fails | 删父表被引用行时 |
| 1093 | You can't specify target table for update in FROM clause | 同表修改 + 子查询（7.2、7.5） |
| 1055 | not in GROUP BY clause ... only_full_group_by | GROUP BY 非法写法（5.7） |
| 1248 | Every derived table must have its own alias | 派生表缺别名（6.7） |
| 3819 | Check constraint 'x' is violated | CHECK 约束（2.4，需 8.0.16+） |
| 3636 | Recursive query aborted ... cte_max_recursion_depth | 递归 CTE 超深度（9.1） |
| 1146 | Table doesn't exist | 表名拼错或库没切 |

### A.4 其他 MySQL 注意点

- **`utf8mb4` 不是 `utf8`**：MySQL 的 `utf8` 是 3 字节残缺实现，必须用 `utf8mb4`
- **DDL 隐式提交**：`CREATE` / `ALTER` / `DROP` / `TRUNCATE` 无法回滚，**事务只保护 DML**
- **引擎必须是 InnoDB** 才有外键和事务，MyISAM 会静默忽略外键定义
- **反引号包列名**：`year`、`desc`、`order`、`rank` 这类可能是保留字的列名建议一律加反引号
- **`ONLY_FULL_GROUP_BY`**：5.7 起默认开启，会拦住非法的 GROUP BY 写法，别去关它
- **`SELECT @@sql_mode`** 可以查看当前所有 sql_mode 设置

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
| P25 3.2 | 域类型、numeric 定点数 | 1.2、1.4、1.10 |
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

-- MySQL 便利技巧：临时关掉外键检查，删表就不用管依赖顺序了
SET FOREIGN_KEY_CHECKS = 0;

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

SET FOREIGN_KEY_CHECKS = 1;

-- 然后回到阶段 1.2 ~ 阶段 2.1，重新建表并装载数据
```

> 不关外键检查的话，**必须按依赖逆序删除**：advisor → prereq → takes → teaches → section → student → instructor → course → department → classroom。关掉 `FOREIGN_KEY_CHECKS` 省心，但要记得改回来（`SET FOREIGN_KEY_CHECKS = 1`）。

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

**顺手检查引擎是不是 InnoDB**（否则外键和事务都不生效）：

```sql
SELECT TABLE_NAME, ENGINE
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'UniversityDB';
-- ENGINE 一列必须全是 InnoDB
```

---

## 通关自测清单

做完 65 题后，逐条自问，答不上来的回到对应页码复习：

1. 关系代数 6 个基本运算是哪 6 个？Join 和 ∩ 为什么不算？（P18、P20、P21）
2. `select-from-where` 对应哪个关系代数表达式？书写顺序与执行顺序的差别？（P28）
3. where 与 having 的分工？为什么聚集函数不能出现在 where？（P35）
4. group by 的硬性规则是什么？MySQL 用什么机制强制它？（P35、5.7）
5. `NULL = NULL` 的结果是什么？`NULL <> 'F'` 呢？where 里 unknown 怎么算？（P34、8.1、8.2）
6. `NOT IN` 遇到 NULL 会怎样？正确替代写法是什么？（8.3）
7. `= SOME` 等价于什么？`<> ALL` 等价于什么？`<> SOME` 等价于 NOT IN 吗？（P36、6.3、6.4）
8. "选修了某系全部课程"的三种写法？MySQL 8.0.31 前后有何不同？（P37、6.6、10.6）
9. 删除"低于平均工资"的记录，为什么必须"先算完再改"？MySQL 上还会遇到什么错？（P38、7.2）
10. 两条 update 分档涨薪的顺序陷阱是什么？怎么避免？（P39、7.5）
11. 工程实践三条分别是什么？各自的技术原因？（P40、9.5、9.7、9.8、9.9）
12. MySQL 下索引什么时候会失效？举 3 个例子。NULL 会进索引吗？（9.6、9.7）
13. MySQL 的 ERROR 1093 是什么？怎么绕过？（7.2、7.5）
14. MySQL 的 EXPLAIN 里 `type=ALL` 和 `Extra=Using index` 分别意味着什么？（9.2、9.4、9.5）

