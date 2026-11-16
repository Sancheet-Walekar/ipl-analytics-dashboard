# Phase 4 – MySQL Database & SQL Analysis

**Files used in this phase**
| File | Purpose |
|---|---|
| [sql/01_create_database.sql](../sql/01_create_database.sql) | Creates the database, 3 tables, primary and foreign keys, and indexes |
| [scripts/load_to_mysql.py](../scripts/load_to_mysql.py) | **Recommended:** loads the cleaned CSVs using Python |
| [sql/02_load_data.sql](../sql/02_load_data.sql) | Alternative: loads them with MySQL's `LOAD DATA` |
| [sql/03_analysis_queries.sql](../sql/03_analysis_queries.sql) | 26 analysis queries |

---

## Step 1 – Install MySQL (Windows)

1. Go to https://dev.mysql.com/downloads/installer/ and download **MySQL Installer for Windows**. Choose the larger file (≈ 300 MB), so nothing else needs downloading during setup.
2. On the download page, click **"No thanks, just start my download"**.
3. Run the installer and choose the setup type **"Server only"** + **MySQL Workbench**. (On newer installers, choose **Custom** and add *MySQL Server 8.x* and *MySQL Workbench 8.x*.)
4. Click **Execute** to install, then **Next** through the configuration screens:
   - **Type and Networking:** Development Computer, port **3306** (keep the default)
   - **Authentication:** *Use Strong Password Encryption* (recommended)
   - **Accounts and Roles:** set a **root password**. ⚠️ Write it down; you need it every time.
   - **Windows Service:** tick *Start the MySQL Server at System Startup*
5. Click **Execute → Finish**.
6. Open **MySQL Workbench** and click the **"Local instance MySQL80"** tile. Enter your root password and tick *Save password in vault*.

You now have a **query tab**: a white editor where you type SQL. The ⚡ (lightning) icon runs everything in the tab, and **Ctrl + Enter** runs only the statement under the cursor.

**Mac:** download the macOS DMG from https://dev.mysql.com/downloads/mysql/ and Workbench from https://dev.mysql.com/downloads/workbench/.
**Linux (Ubuntu):** `sudo apt install mysql-server`; install Workbench separately or use the `mysql` command line.

---

## Step 2 – Database concepts (learn these before running the scripts)

| Term | Simple meaning | In our project |
|---|---|---|
| **Database** | A container for related tables | `ipl_db` |
| **Table** | Rows and columns, like a sheet in Excel | `teams`, `matches`, `deliveries` |
| **Data type** | What kind of value a column holds | `INT`, `VARCHAR(50)`, `DATE`, `DECIMAL(4,1)`, `TINYINT` |
| **NULL** | "No value" (not zero, not an empty string) | `winner` of a washed-out match |
| **Primary key (PK)** | Column that uniquely identifies each row. It can never be NULL or repeated | `matches.match_id`, `teams.team_name` |
| **Foreign key (FK)** | Column that must match a PK in another table | `deliveries.match_id → matches.match_id` |
| **Constraint** | A rule MySQL enforces automatically | `CHECK (toss_decision IN ('bat','field'))` |
| **Index** | Like a book's index: makes searching on a column faster | `idx_deliveries_batter` |
| **AUTO_INCREMENT** | MySQL numbers new rows 1, 2, 3 … automatically | `deliveries.delivery_id` |

**Why add a separate `teams` table?** It is a *master table*. The foreign keys stop anyone from inserting a misspelt team such as "Mumbai Indian". This is how we **enforce** the team-name cleaning we did in Phase 3. It also stores extra team details (short name, active or defunct) in one place.

**Why `over_index` instead of `over`?** `OVER` is a **reserved word** in MySQL 8 (it is used by window functions), so a column called `over` causes syntax errors.

### ER diagram (Entity–Relationship)

```
                ┌───────────────────────┐
                │        teams          │
                │───────────────────────│
                │ PK team_name          │
                │    short_name (UQ)    │
                │    is_active          │
                └───────────┬───────────┘
          1 team appears    │    1 team appears in
          in many matches   │    many deliveries
              ┌─────────────┴───────────────┐
              │ N                           │ N
┌─────────────▼───────────────┐   ┌─────────▼───────────────────┐
│          matches            │   │         deliveries          │
│─────────────────────────────│   │─────────────────────────────│
│ PK match_id                 │1 N│ PK delivery_id              │
│    season, match_date, venue├──▶│ FK match_id                 │
│ FK team1, team2             │   │ FK batting_team             │
│ FK toss_winner, winner      │   │ FK bowling_team             │
│ FK batting_first_team       │   │    inning, over_index, ball │
│    result, result_margin... │   │    batter, bowler, runs ... │
└─────────────────────────────┘   └─────────────────────────────┘
```
- teams **1 : N** matches (a team plays many matches)
- matches **1 : N** deliveries (a match has about 240 balls)

---

## Step 3 – Create the database and tables
1. In Workbench: **File → Open SQL Script →** `sql/01_create_database.sql`
2. Click ⚡ (Execute all).
3. In the left panel (**Navigator → Schemas**), click 🔄 refresh. `ipl_db` appears with 3 tables.

**Expected output:** the last two results show `deliveries, matches, teams` and `teams_loaded = 15`.

The order matters: `teams` is created first, then `matches` (which refers to teams), then `deliveries` (which refers to matches). A foreign key can only point to a table that already exists.

---

## Step 4 – Load the cleaned CSVs

### Option A (recommended): Python script
In the terminal, from the project folder, with the venv active:
```bash
pip install -r requirements.txt          # installs mysql-connector-python
python scripts/load_to_mysql.py
```
Type your MySQL root password when asked; the characters won't appear as you type, which is normal.

**Expected output (about 1–2 minutes):**
```
Connected to MySQL 8.x / database 'ipl_db'
Loading matches ...
  matches: 1,095 / 1,095 rows
Loading deliveries ... (about 1 minute)
  deliveries: 260,920 / 260,920 rows
teams      :      15 rows
matches    :   1,095 rows
deliveries : 260,920 rows
Done! Expected: teams 15, matches 1,095, deliveries 260,920
```

**How the script works:**
1. `mysql.connector.connect(...)` opens a connection, the same as logging in through Workbench.
2. `pd.read_csv()` reads each cleaned CSV, and `.rename()` changes `id → match_id`, `date → match_date` and `over → over_index` to match the table columns.
3. `df.where(df.notna(), None)`: MySQL does not understand pandas' `NaN`. Python's `None` becomes SQL `NULL`.
4. `INSERT INTO ... VALUES (%s, %s, ...)`: each `%s` is a placeholder that the connector fills in safely. This is called a *parameterised query*, and it protects against SQL injection.
5. `executemany()` + batches of 5000 rows: much faster than inserting one row at a time.
6. **matches is loaded before deliveries**, because a delivery's `match_id` must already exist (foreign key).
7. The password comes from `getpass`, so it is **never written in the code** or uploaded to GitHub.

### Option B: `LOAD DATA` (pure SQL)
Follow the 4 setup steps at the top of `sql/02_load_data.sql`, change the file paths, and run it.

### Option C: Workbench Table Data Import Wizard (not recommended)
Right-click a table → *Table Data Import Wizard*. It is fine for `matches`, but it takes **30+ minutes** for 260,000 deliveries, and it treats empty cells as `''` instead of NULL.

### Verify the load
```sql
USE ipl_db;
SELECT COUNT(*) FROM matches;      -- 1095
SELECT COUNT(*) FROM deliveries;   -- 260920
SELECT * FROM matches LIMIT 5;
```

---

## Step 5 – SQL clauses you need to know

A SELECT query is **written** in this order. MySQL **runs** it in the order shown in the second column:

| Written order | Execution order | What it does |
|---|---|---|
| `SELECT` | 5 | Chooses which columns to show |
| `FROM` / `JOIN` | 1 | Chooses the table(s) |
| `WHERE` | 2 | Filters **rows** *before* grouping |
| `GROUP BY` | 3 | Makes groups (one per team, season …) |
| `HAVING` | 4 | Filters **groups** *after* grouping |
| `ORDER BY` | 6 | Sorts the result |
| `LIMIT` | 7 | Keeps the first N rows |

**WHERE vs HAVING** (a very common interview question): `WHERE` cannot use `SUM()` or `COUNT()`, because the groups don't exist yet at that stage. `HAVING` can.

**INNER JOIN vs LEFT JOIN:**
- `INNER JOIN` keeps only rows that have a match in **both** tables.
- `LEFT JOIN` keeps **every** row of the left table; columns from the right table are NULL where nothing matches. Q6 uses this to show teams with **0 titles**, which an INNER JOIN would drop.

---

## Step 6 – The 26 queries explained
Open `sql/03_analysis_queries.sql`, put the cursor inside a query and press **Ctrl + Enter**.

| # | Question | What the query does | Key result |
|---|---|---|---|
| Q1 | Matches per season | `GROUP BY season` makes one group per year, and `COUNT(*)` counts the rows in each group | 57–76 per season; 74 in 10-team years |
| Q2 | Overall KPIs | `SUM()` of the 0/1 flag columns. Summing a 1/0 column counts the 1s | 347,470 runs, 12,923 wickets, 13,036 sixes |
| Q3 | All finals | `WHERE match_type = 'Final'` keeps only finals | 17 finals, 2008–2024 |
| Q4 | Dismissal types | `WHERE is_wicket = 1`, then count by `dismissal_kind` | Caught 8,063 (62%) |
| Q5 | Team win % | `teams LEFT JOIN matches ON team IN (team1, team2)` gives each team's matches. `CASE WHEN winner = team THEN 1 ELSE 0 END` marks wins, then `SUM` and divide | MI 144 wins; CSK best win % (58.0) |
| Q6 | Titles per team | A **subquery** in `FROM` picks out the finals; `LEFT JOIN` keeps teams with 0 titles | CSK 5, MI 5, KKR 3 |
| Q7 | Wins per team per season | `GROUP BY season, winner` makes one group per (season, team) pair | Feeds the season-trend line chart |
| Q8 | MI vs CSK head-to-head | `WHERE (A AND B) OR (B AND A)`. The brackets matter | MI 20 – CSK 17 |
| Q9 | Highest team totals | `INNER JOIN` gets the season from matches; `GROUP BY match, inning` gives one total per innings | SRH 287 vs RCB (2024) |
| Q10 | Toss impact | `AVG()` of a 0/1 column = the share of 1s | 50.8%: the toss barely matters |
| Q11 | Bat or field trend | `SUM(CASE WHEN ...)` turns rows into columns (a *pivot*) | Field first 80%+ in 2016–19 |
| Q12 | Bat first vs chase | `CASE` labels each winner, and a **subquery** gives the total for the % | Chasing wins 54.3% |
| Q13 | Venue stats | `HAVING COUNT(*) >= 30` keeps only frequently used grounds | Wankhede most matches; Jaipur best for chasing (64.9%) |
| Q14 | Biggest wins by runs | `WHERE result = 'runs'`, sorted by margin | MI by 146 runs vs DC (2017) |
| Q15 | Top run scorers | `SUM(batsman_runs)` per batter. Strike rate = runs ÷ balls faced × 100 | Kohli 8,004 |
| Q16 | Best strike rate | `HAVING SUM(ball_faced) >= 500` removes players with very few balls | Russell 174.93 |
| Q17 | Highest individual scores | Inner query = runs per batter per match; outer `CASE` labels Century / Fifty | Gayle 175 off 66 balls (2013) |
| Q18 | Orange Cap per season | Subquery 1 = runs per batter per season; subquery 2 = the MAX for each season; `INNER JOIN` them to find who made the MAX | Kohli 973 (2016) is the record |
| Q19 | Batting styles | `CASE` on strike rate puts batters into Aggressive / Balanced / Anchor | 17 aggressive batters with 1000+ balls |
| Q20 | Kohli season by season | `WHERE batter = 'V Kohli'` | Peak 973 in 2016 |
| Q21 | Top wicket takers | `SUM(is_bowler_wicket)`, which leaves out run outs | Chahal 205 |
| Q22 | Best economy | Runs ÷ (legal balls ÷ 6), with `HAVING` balls ≥ 1000 | Muralitharan 6.68 |
| Q23 | Better than the league average | The **subquery inside HAVING** works out the league economy, and each bowler is compared with it | Kumble 6.58 tops the list |
| Q24 | Death-over specialists | `WHERE phase = 'Death'` before grouping | Narine 7.40, Malinga 108 death wickets |
| Q25 | Phase analysis | `GROUP BY phase`; `ORDER BY FIELD()` sets a custom sort order | Death: RR 9.96, a wicket every 11.8 balls |
| Q26 | Player of the Match | `WHERE ... IS NOT NULL` skips no-result matches | AB de Villiers 25 |

**Keywords used (checklist):** COUNT ✔ SUM ✔ AVG ✔ GROUP BY ✔ ORDER BY ✔ WHERE ✔ HAVING ✔ INNER JOIN ✔ LEFT JOIN ✔ Subqueries ✔ CASE ✔ LIMIT ✔ IN ✔ IS NULL ✔

### Why `is_super_over = 0` everywhere?
Official IPL career records do not count Super Over balls, so we leave them out to match the official statistics.

### Why does Q13 show 117 matches at Wankhede, but the Python EDA shows 118?
Q13 leaves out ties and no-results (`WHERE winner IS NOT NULL AND result <> 'tie'`), because a tied match has no batting-first or chasing winner. Always check which filters a number is based on before comparing it with another.

---

## Step 7 – Common errors and fixes

| Error | Cause | Fix |
|---|---|---|
| `Access denied for user 'root'@'localhost'` | Wrong password | Use the root password you set during install |
| `Can't connect to MySQL server on 'localhost' (10061)` | MySQL service isn't running | Windows: Win + R → `services.msc` → **MySQL80** → Start |
| `Error 1046: No database selected` | `USE ipl_db;` wasn't run | Run `USE ipl_db;` or double-click `ipl_db` in the Navigator |
| `Error 1175: You are using safe update mode` | Workbench blocks DELETE without WHERE | `SET SQL_SAFE_UPDATES = 0;` (already in 02_load_data.sql) |
| `Error 1452: Cannot add or update a child row: a foreign key constraint fails` | A team or match_id that isn't in the parent table | Load `matches` before `deliveries`; re-run the Phase 3 notebook so the team names are standardised |
| `Error 1062: Duplicate entry for key 'PRIMARY'` | Data loaded twice | Both loaders empty the tables first; or re-run `01_create_database.sql` |
| `Error 3948: Loading local data is disabled` | `local_infile` is off | `SET GLOBAL local_infile = 1;` and add `OPT_LOCAL_INFILE=1` to the connection (Option B) |
| `Error 2013: Lost connection during query` | Workbench's 30-second timeout | Edit → Preferences → SQL Editor → read timeout = 600 |
| `Error 1064: You have an error in your SQL syntax` | Typo, missing comma, or a reserved word such as `over` | Read the text just *after* "near '...'" in the error message |
| `Error 1055: ... incompatible with sql_mode=only_full_group_by` | A column in SELECT is not in GROUP BY | Add the column to `GROUP BY`, or wrap it in an aggregate |
| `ModuleNotFoundError: mysql` | Connector not installed | `pip install mysql-connector-python` |
| Python script: `File not found ... matches_cleaned.csv` | Phase 3 notebook not run | Run `notebooks/02_data_cleaning_eda.ipynb` first |
| Workbench shows only 1000 rows | Default display limit | Not an error; change *Limit to 1000 rows* in the toolbar |

---

## No MySQL Workbench? Use the command line instead
Workbench is only an editor. Everything in this phase also works from the terminal with the `mysql` command.

### Linux (Ubuntu)
On Ubuntu, MySQL's `root` user logs in through `sudo`, not a password. The Python loader needs a password, so create a project user once:
```bash
sudo mysql
```
```sql
CREATE USER 'ipl_user'@'localhost' IDENTIFIED BY 'Choose_A_Password1';
GRANT ALL PRIVILEGES ON ipl_db.* TO 'ipl_user'@'localhost';
EXIT;
```
Then, from the project folder:
```bash
mysql -u ipl_user -p < sql/01_create_database.sql          # Step 3: create the tables
MYSQL_USER=ipl_user python scripts/load_to_mysql.py         # Step 4: load the data
mysql -u ipl_user -p ipl_db --table                         # Step 6: open a SQL prompt
```
At the `mysql>` prompt, paste any query from `sql/03_analysis_queries.sql` (it must end with `;`) and press Enter. Type `exit` to leave.
To run all 26 queries at once: `mysql -u ipl_user -p --table < sql/03_analysis_queries.sql | less` (press `q` to quit).

### Windows
1. Start menu → **MySQL 8.0 Command Line Client** → enter your root password.
2. Run a file with `source` (use forward slashes):
   ```
   source C:/Users/YourName/ipl-analytics-dashboard/sql/01_create_database.sql
   ```
3. Load the data as normal: `python scripts/load_to_mysql.py`.
4. Type `USE ipl_db;` and paste queries.

### Command-line tips
| Command | Meaning |
|---|---|
| `SHOW DATABASES;` | List databases |
| `USE ipl_db;` | Switch to our database |
| `SHOW TABLES;` | List tables |
| `DESCRIBE matches;` | Show a table's columns and types |
| `\G` instead of `;` | Show a wide row vertically (easier to read) |
| `Ctrl + C` | Cancel a half-typed query |
