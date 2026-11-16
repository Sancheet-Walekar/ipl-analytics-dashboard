# Phase 5 – Power BI Dashboard

**Goal:** a 3-page interactive dashboard: **IPL Overview**, **Player Performance** and **Match Analysis**.
**Save your file as:** `powerbi/IPL_Dashboard.pbix`

> Power BI Desktop runs **only on Windows** (10/11). Use your own Windows PC or one in the college lab.

---

## Step 1 – Install Power BI Desktop
1. Open the **Microsoft Store** → search **"Power BI Desktop"** → **Get / Install**. It's free, and the Store version updates itself.
   (Or download it from https://www.microsoft.com/power-bi/desktop.)
2. Open it. If it asks you to sign in, you can close that box; signing in is **not** needed to build a dashboard.

**Power BI Desktop: the 3 views** (icons on the left edge)
| Icon | View | Used for |
|---|---|---|
| 📊 | **Report** | Building charts and pages |
| ▦ | **Table** (Data) | Looking at the rows and adding calculated columns |
| ⛓ | **Model** | Creating relationships between tables |

---

## Step 2 – Get the data in (choose ONE option)

### Option A: Connect to MySQL (recommended: shows the full Python → SQL → Power BI pipeline)
**Before you start:** MySQL must be installed on the **same Windows PC**, with `ipl_db` loaded (Phase 4).

1. Install **MySQL Connector/NET**. Power BI needs it to talk to MySQL.
   https://dev.mysql.com/downloads/connector/net/ → download the `.msi` → install → **restart Power BI**.
2. **Home → Get data → More… → Database → MySQL database → Connect.**
3. Server: `localhost:3306`  Database: `ipl_db` → **OK**.
4. Choose the **Database** tab on the left (not Windows). User name: `root` (or `ipl_user`), password: your MySQL password → **Connect**.
   If it says *"The connection is not encrypted"*, click **OK**. That is normal for a local database.
5. The **Navigator** opens. Tick `ipl_db.deliveries`, `ipl_db.matches` and `ipl_db.teams`. Click **Transform Data** (not Load) so you can check the data types first (Step 3).

**Import or DirectQuery?** Choose **Import**. Power BI copies the data into the `.pbix` file. Import makes charts fast, works offline, and allows every DAX function. *DirectQuery* sends a SQL query to MySQL every time you click, which is only needed for very large or live data.

### Option B: Load the cleaned CSVs (if MySQL isn't available on the Windows PC)
1. **Home → Get data → Text/CSV** → `data/cleaned/matches_cleaned.csv` → **Transform Data**.
2. Repeat for `data/cleaned/deliveries_cleaned.csv` and `data/reference/teams.csv`.
3. In Power Query, rename the queries to `matches`, `deliveries` and `teams` (double-click the name on the left).
4. In `matches`, rename `id` → `match_id` and `date` → `match_date`. In `deliveries`, rename `over` → `over_index`. This keeps every formula below the same for both options.

---

## Step 3 – Check data types in Power Query
Power Query is the window that opened when you clicked *Transform Data*. Click each query on the left and check the icon at the top of each column (**123** = whole number, **ABC** = text, 📅 = date, **1.2** = decimal).

| Table | Column | Correct type |
|---|---|---|
| matches | match_id, season, result_margin, target_runs, toss_winner_won, is_playoff | Whole Number |
| matches | match_date | **Date** |
| matches | target_overs | Decimal Number |
| deliveries | every 0/1 flag column, runs columns, season, over_number | Whole Number |
| deliveries | phase, batter, bowler, team columns | Text |

To change a type, click the icon in the column header and pick the right type.
**If you used MySQL:** you may see extra columns at the far right named like `ipl_db.deliveries` or `ipl_db.teams`, whose cells just say *Table* or *Value*. Power BI adds these automatically from the foreign keys. Right-click each one → **Remove**.

Click **Home → Close & Apply**. The data loads (≈ 10–30 seconds).

---

## Step 4 – Relationships (Model view)
Click the **Model view** icon ⛓. Then **Home → Manage relationships**.

**Keep exactly ONE relationship:**
| From | To | Cardinality | Cross-filter direction |
|---|---|---|---|
| `matches[match_id]` | `deliveries[match_id]` | **One to many (1:*)** | Single |

If it isn't there, create it: drag `match_id` from `matches` onto `match_id` in `deliveries`.

**Delete every relationship that involves `teams`.** Power BI creates these automatically from the MySQL foreign keys, but they cause wrong results here:
- `teams` links to `matches` through 5 columns (team1, team2, toss_winner, winner, batting_first_team). Power BI allows only **one** to be active, so selecting "Mumbai Indians" would silently filter to *matches MI won* instead of *matches MI played*.
- `teams` → `deliveries` and `teams` → `matches` → `deliveries` would create **two paths** to the same table (an *ambiguous relationship*).

Instead, `teams` is used as a **disconnected table** for the team slicer and the team axis. The DAX measures in Step 6 read the selected team with `SELECTEDVALUE()`. This is a standard Power BI technique, and a good viva answer.

**Why does a season slicer still filter player stats?** The filter flows from the **1 side (matches)** to the **many side (deliveries)**. Always use `matches[season]` in slicers. Right-click `deliveries[season]` → **Hide in report view** so you don't pick it by mistake.

**Why "Single" direction?** Filters flow matches → deliveries only. "Both" directions can cause ambiguity and slow reports, and we don't need it.

The finished model (a simple star schema):
```
 teams (disconnected)          matches  1 ────── *  deliveries
 team_name, short_name         match_id            match_id
 is_active                     season, venue...    batter, bowler, runs...
```

---

## Step 5 – Calculated columns
A **calculated column** is worked out once **for every row** and stored in the table. Use one when you need to *slice, filter or group* by the value.
A **measure** is calculated **when a visual needs it**, for whatever filters are applied. Use measures for totals, averages and percentages.

How to add one: **Table view** → click the table → **Table tools → New column** → type the formula → Enter.

**In `matches`:**
```DAX
Win Type =
SWITCH (
    matches[result],
    "runs",    "Won batting first",
    "wickets", "Won chasing",
    "tie",     "Tie (Super Over)",
    "No result"
)
```
```DAX
Toss Result =
IF (
    ISBLANK ( matches[toss_winner_won] ),
    "No result",
    IF ( matches[toss_winner_won] = 1, "Toss winner won", "Toss winner lost" )
)
```
```DAX
Chasing Won =
IF (
    ISBLANK ( matches[winner] ) || matches[result] = "tie",
    BLANK (),
    IF ( matches[winner] <> matches[batting_first_team], 1, 0 )
)
```
```DAX
Season Label = "IPL " & matches[season]
```

**In `deliveries`:**
```DAX
Phase Order =
SWITCH ( deliveries[phase], "Powerplay", 1, "Middle", 2, "Death", 3 )
```
Then select the `phase` column → **Column tools → Sort by column → Phase Order**. Without this, charts sort the phases alphabetically (Death, Middle, Powerplay).

**Stop Power BI from adding up `season`:** select `matches[season]` → **Column tools → Summarization → Don't summarize**. Do the same for `match_id`, `over_number` and `inning`. Otherwise Power BI shows "Sum of season = 2,197,104"!

---

## Step 6 – DAX measures
**Create a home for the measures:** **Home → Enter data** → name the table `_Measures` → **Load**. Then right-click `_Measures` → **New measure** for each formula below. (When you've added the first measure, you can delete the dummy `Column1`.)

**Formatting:** select a measure → **Measure tools** → set the format (Whole number, Decimal with 2 places, or Percentage).

**DAX basics:**
- `SUM`, `AVERAGE`, `COUNTROWS`, `DISTINCTCOUNT` are aggregations, like SQL.
- `CALCULATE ( expression, filter1, filter2 … )` calculates the expression **with extra filters**, like adding a WHERE clause. It is the most important DAX function.
- `DIVIDE ( a, b )` is a safe division: it returns blank instead of an error when b = 0.
- `VAR … RETURN` stores a value in a variable so it's easier to read and calculated only once.

### 6.1 Overview KPIs
```DAX
Total Matches = COUNTROWS ( matches )
```
```DAX
Total Seasons = DISTINCTCOUNT ( matches[season] )
```
```DAX
Teams Played = DISTINCTCOUNT ( deliveries[batting_team] )
```
```DAX
Total Runs = CALCULATE ( SUM ( deliveries[total_runs] ), deliveries[is_super_over] = 0 )
```
```DAX
Total Wickets = CALCULATE ( SUM ( deliveries[is_wicket] ), deliveries[is_super_over] = 0 )
```
```DAX
Total Fours = CALCULATE ( SUM ( deliveries[is_four] ), deliveries[is_super_over] = 0 )
```
```DAX
Total Sixes = CALCULATE ( SUM ( deliveries[is_six] ), deliveries[is_super_over] = 0 )
```
```DAX
Legal Balls = CALCULATE ( SUM ( deliveries[is_legal_ball] ), deliveries[is_super_over] = 0 )
```
```DAX
Run Rate = DIVIDE ( [Total Runs], [Legal Balls] / 6 )
```
```DAX
Highest Team Total =
MAXX (
    SUMMARIZE ( deliveries, deliveries[match_id], deliveries[inning] ),
    [Total Runs]
)
```
`SUMMARIZE` makes a temporary table with one row per innings. `MAXX` goes through it row by row, calculates `[Total Runs]` for each innings, and keeps the highest.

### 6.2 Batting
```DAX
Batter Runs = CALCULATE ( SUM ( deliveries[batsman_runs] ), deliveries[is_super_over] = 0 )
```
```DAX
Balls Faced = CALCULATE ( SUM ( deliveries[ball_faced] ), deliveries[is_super_over] = 0 )
```
```DAX
Strike Rate = DIVIDE ( [Batter Runs], [Balls Faced] ) * 100
```
```DAX
Innings Batted = DISTINCTCOUNT ( deliveries[match_id] )
```
```DAX
Highest Score =
MAXX (
    SUMMARIZE ( deliveries, deliveries[match_id], deliveries[batter] ),
    [Batter Runs]
)
```
```DAX
Centuries =
COUNTROWS (
    FILTER (
        SUMMARIZE ( deliveries, deliveries[match_id], deliveries[batter] ),
        [Batter Runs] >= 100
    )
)
```
```DAX
Fifties =
COUNTROWS (
    FILTER (
        SUMMARIZE ( deliveries, deliveries[match_id], deliveries[batter] ),
        [Batter Runs] >= 50 && [Batter Runs] < 100
    )
)
```
```DAX
Batter Dismissals =
CALCULATE (
    COUNTROWS ( deliveries ),
    REMOVEFILTERS ( deliveries[batter] ),
    TREATAS ( VALUES ( deliveries[batter] ), deliveries[player_dismissed] ),
    deliveries[is_super_over] = 0
)
```
```DAX
Batting Average = DIVIDE ( [Batter Runs], [Batter Dismissals] )
```
`Batter Dismissals` is the most advanced measure here. A batter can be run out while he is the **non-striker**, so we can't just count wickets on the balls he faced. `TREATAS` takes the selected batter's name and applies it as a filter on `player_dismissed` instead.

### 6.3 Bowling
```DAX
Bowler Wickets = CALCULATE ( SUM ( deliveries[is_bowler_wicket] ), deliveries[is_super_over] = 0 )
```
```DAX
Bowler Runs = CALCULATE ( SUM ( deliveries[bowler_runs] ), deliveries[is_super_over] = 0 )
```
```DAX
Overs Bowled = [Legal Balls] / 6
```
```DAX
Economy = DIVIDE ( [Bowler Runs], [Legal Balls] / 6 )
```
```DAX
Bowling Average = DIVIDE ( [Bowler Runs], [Bowler Wickets] )
```
```DAX
Dot Ball % =
DIVIDE (
    CALCULATE ( SUM ( deliveries[is_dot_ball] ), deliveries[is_super_over] = 0 ),
    [Legal Balls]
)
```

### 6.4 Teams and match results
```DAX
Team Played =
VAR _team = SELECTEDVALUE ( teams[team_name] )
RETURN
    CALCULATE (
        COUNTROWS ( matches ),
        FILTER ( matches, matches[team1] = _team || matches[team2] = _team )
    )
```
```DAX
Team Wins =
VAR _team = SELECTEDVALUE ( teams[team_name] )
RETURN
    CALCULATE ( COUNTROWS ( matches ), matches[winner] = _team )
```
```DAX
Team Win % = DIVIDE ( [Team Wins], [Team Played] )
```
```DAX
Team Titles =
VAR _team = SELECTEDVALUE ( teams[team_name] )
RETURN
    CALCULATE ( COUNTROWS ( matches ), matches[winner] = _team, matches[match_type] = "Final" )
```
```DAX
Toss Win % = AVERAGE ( matches[toss_winner_won] )
```
```DAX
Chasing Win % = AVERAGE ( matches[Chasing Won] )
```
```DAX
Field First % =
DIVIDE ( CALCULATE ( COUNTROWS ( matches ), matches[toss_decision] = "field" ), [Total Matches] )
```
`SELECTEDVALUE ( teams[team_name] )` returns the team for the current row of a table or chart, or the one picked in a slicer. It returns blank if more than one team is selected.
`AVERAGE` of a 1/0 column gives the **share of 1s**: the same trick we used in Python and SQL. `AVERAGE` skips blanks, so no-result matches are left out automatically.

**Format as Percentage:** Team Win %, Toss Win %, Chasing Win %, Field First %, Dot Ball %.
**Format as Decimal (2 places):** Strike Rate, Economy, Run Rate, Batting Average, Bowling Average.

### 6.5 Check your measures (all seasons selected)
Put each measure on a **Card** visual and compare it with these values:
| Measure | Expected |
|---|---|
| Total Matches | 1,095 |
| Total Seasons | 17 |
| Total Runs | 347,470 |
| Total Sixes | 13,036 |
| Total Wickets | 12,923 |
| Run Rate | 8.30 |
| Highest Team Total | 287 |
| Toss Win % | 50.8% |
| Chasing Win % | 54.3% |
| Field First % | 64.3% |
| Dot Ball % | 36.0% |
| Centuries (all batters) | 101 |

With a slicer set to **V Kohli**: Batter Runs 8,004 · Strike Rate 131.97 · Innings 244 · Highest Score 113 · Centuries 8 · Fifties 55 · Batting Average 38.67.
With **YS Chahal**: Bowler Wickets 205 · Economy 7.84 · Bowling Average 22.45.

If a number doesn't match, check: (1) the relationship from Step 4, (2) the data types from Step 3, (3) that no slicer is filtering the page.

---

## Step 7 – Which chart for which metric (and why)

| Metric | Visual | Why this visual |
|---|---|---|
| Single headline numbers (matches, runs, sixes) | **Card** / **Multi-row card** | One number is best shown big and bold; no axis is needed |
| Runs or matches per season | **Line chart** | Season is ordered time, and a line shows the trend best |
| Wins / titles by team | **Clustered bar chart** (horizontal) | Comparing categories; long team names fit on the vertical axis |
| Team win %, played, wins | **Table** or **Matrix** with data bars | Exact values side by side; data bars add a quick visual |
| Toss decision (bat vs field) | **Donut chart** | Part-of-whole with only 2–4 slices |
| Toss decision trend by season | **100% stacked column chart** | Shows how the bat/field split changes each year |
| Top 10 run scorers / wicket takers | **Bar chart** + Top N filter | A ranking is easiest to read as sorted bars |
| Strike rate vs runs | **Scatter chart** | Shows the relationship between two measures; finds "fast and prolific" players |
| Phase-wise run rate | **Clustered column chart** | Compares 3 ordered groups |
| Win type split (batting first / chasing / tie) | **Donut** or **Pie** | Part-of-whole |
| Venue matches and chasing win % | **Bar chart** + **Line and clustered column chart** | Two different measures (count and %) on one visual, on two axes |
| Toss win %, chasing win % | **Gauge** (0–100%, target 50%) | Shows how far a % is from "no effect" (50%) |
| Season / team / player choice | **Slicer** (Dropdown, or Between for season) | Lets the user filter the whole page |

**Avoid:** 3D charts, pie charts with more than 5 slices, and too many colours. The aim is to make insight quick to read, not decoration.

---

## Step 8 – Build the 3 pages

**Page setup (each page):** click an empty part of the canvas → **Format page → Canvas settings** → 16:9 (1280 × 720). Rename the page tab at the bottom (double-click it).
**Theme:** **View → Themes** → choose a clean theme (e.g. *Executive* or *Innovate*) so all pages share the same colours.

### How to add a visual (example: a bar chart of titles)
1. Click an empty area of the canvas.
2. In **Visualizations**, click the **Clustered bar chart** icon. An empty box appears.
3. From the **Data** pane, drag `teams[short_name]` onto the **Y-axis** well, and the `[Team Titles]` measure onto the **X-axis** well.
4. Sort: click **⋯** on the visual → **Sort axis → Team Titles → Sort descending**.
5. **Format visual** (paintbrush icon) → **Title** → type "IPL Titles by Team". Turn **Data labels** on.

### Page 1: IPL Overview
```
┌──────────────────────────────────────────────────────────────────────────┐
│  🏏 IPL ANALYTICS DASHBOARD 2008–2024                [Season slicer ▼]   │
├──────────┬──────────┬──────────┬──────────┬──────────┬───────────────────┤
│ Matches  │ Seasons  │  Teams   │  Runs    │  Sixes   │ Highest Total     │
│  1,095   │   17     │   15     │ 347,470  │ 13,036   │      287          │
├──────────┴──────────┴──────────┼──────────┴──────────┴───────────────────┤
│  Runs per Season (line)        │  IPL Titles by Team (bar)               │
│  X: matches[season]            │  Y: teams[short_name]  X: [Team Titles] │
│  Y: [Total Runs]               │                                         │
├────────────────────────────────┼──────────────────────┬──────────────────┤
│  Team Performance (table)      │ Toss Decision (donut)│ Matches per      │
│  teams[team_name], [Team       │ Legend: toss_decision│ Season (column)  │
│  Played], [Team Wins],         │ Values: Total Matches│ X: season        │
│  [Team Win %]                  │                      │ Y: Total Matches │
└────────────────────────────────┴──────────────────────┴──────────────────┘
```
- **KPI cards:** 6 Card visuals in a row. Total Matches, Total Seasons, Teams Played, Total Runs, Total Sixes, Highest Team Total.
- **Team Performance table:** on the Team Win % column, **Cell elements → Data bars → On**. Sort by Team Wins.
- **Season slicer:** Slicer visual → field `matches[season]` → **Format → Slicer settings → Style: Dropdown**, tick **Multi-select with Ctrl**, and turn on **"Select all"**.

### Page 2: Player Performance
```
┌──────────────────────────────────────────────────────────────────────────┐
│  PLAYER PERFORMANCE          [Season ▼]  [Batter 🔍 ▼]  [Bowler 🔍 ▼]    │
├──────────┬──────────┬──────────┬──────────┬──────────┬───────────────────┤
│  Runs    │ Strike   │ Average  │ Highest  │ 100s/50s │  Sixes            │
│          │  Rate    │          │  Score   │          │                   │
├──────────┴──────────┴──────────┼──────────┴──────────┴───────────────────┤
│  Top 10 Run Scorers (bar)      │  Top 10 Wicket Takers (bar)             │
│  Y: deliveries[batter]         │  Y: deliveries[bowler]                  │
│  X: [Batter Runs]   Top N = 10 │  X: [Bowler Wickets]   Top N = 10       │
├────────────────────────────────┼─────────────────────────────────────────┤
│  Strike Rate vs Runs (scatter) │  Best Economy (table)                   │
│  Values: batter                │  bowler, [Bowler Wickets], [Overs       │
│  X: [Batter Runs]              │  Bowled], [Economy], [Dot Ball %]       │
│  Y: [Strike Rate]              │  filter: Legal Balls >= 1000            │
│  filter: Balls Faced >= 500    │  sort: Economy ascending                │
└────────────────────────────────┴─────────────────────────────────────────┘
```
- **Top N filter:** select the bar chart → **Filters pane → batter → Filter type: Top N → Show items: Top 10 → By value: drag [Batter Runs] → Apply filter**.
- **Minimum-balls filter (scatter):** Filters pane → *Filters on this visual* → drag `[Balls Faced]` in → **is greater than or equal to 500 → Apply**. This is the Power BI version of SQL's `HAVING`.
- **Batter and Bowler slicers:** Slicer → `deliveries[batter]` → Style **Dropdown**, then turn **Search** on (⋯ → Search). The KPI cards then show the selected player's numbers.
- **Player comparison:** in the batter slicer, hold **Ctrl** and choose 2–3 players. The bar charts and scatter show only those players.
- **Edit interactions:** with the batter slicer selected, **Format → Edit interactions**, and set the **Bowling** visuals to *None* 🚫, so choosing a batter doesn't empty the bowling visuals.

### Page 3: Match Analysis
```
┌──────────────────────────────────────────────────────────────────────────┐
│  MATCH ANALYSIS                       [Season ▼]   [Team ▼]  [Venue ▼]   │
├───────────────────┬───────────────────┬──────────────────────────────────┤
│ Toss Win %        │ Chasing Win %     │ Bat vs Field by Season           │
│ (gauge 0-100%,    │ (gauge, target    │ (100% stacked column)            │
│  target 50%)      │  50%)             │ X: season, Legend: toss_decision │
├───────────────────┴───────────────────┤ Y: Total Matches                 │
│ Win Type (donut)                      │                                  │
│ Legend: matches[Win Type]             ├──────────────────────────────────┤
│ Values: Total Matches                 │ Run Rate by Phase (column)       │
├───────────────────────────────────────┤ X: deliveries[phase]             │
│ Top Venues (line & clustered column)  │ Y: [Run Rate]                    │
│ X: venue  Column: Total Matches       │ (sorted by Phase Order)          │
│ Line: Chasing Win %   Top N = 10      │                                  │
└───────────────────────────────────────┴──────────────────────────────────┘
```
- **Gauge:** Visualizations → Gauge → Value: `[Toss Win %]`. In **Format → Gauge axis**, set Min 0, Max 1, **Target 0.5**. The target line shows "no advantage", so the needle sitting close to it tells the story.
- **Team slicer:** uses `teams[team_name]`. Add a **Card** with `[Team Win %]` and another with `[Team Titles]`. They show the selected team's numbers. (The other visuals on this page don't react to this slicer, because `teams` is disconnected. That is expected.)
- **Venue chart:** add a **Top N = 10 by Total Matches** filter on `venue`.

---

## Step 9 – Make it interactive and polished
1. **Cross-filtering:** clicking a bar (e.g. a season) filters every other visual on the page. Try it, then press **Ctrl + click** to select more than one.
2. **Sync slicers:** select the season slicer → **View → Sync slicers** → tick all 3 pages under both **Sync** 🔄 and **Visible** 👁. One season choice then applies to the whole report.
3. **Tooltips:** drag extra measures (e.g. `[Strike Rate]`) into a visual's **Tooltips** well. They appear when you hover.
4. **Page navigation buttons:** **Insert → Buttons → Navigator → Page navigator** adds tabs to move between pages.
5. **Reset filters button (optional):** **View → Bookmarks → Add** while no filters are set. Then **Insert → Buttons → Reset**, and set **Action → Bookmark** to that bookmark.
6. **Consistency:** same font sizes, aligned visuals (**Format → Align**), titles on every visual, and no more than 6–8 visuals per page.
7. **Save:** **File → Save as** → `powerbi/IPL_Dashboard.pbix`.
8. **Screenshots for the report (Phase 7):** **File → Export → Export to PDF**, or press **Win + Shift + S** to capture each page.

---

## Step 10 – Common errors and fixes

| Problem | Cause | Fix |
|---|---|---|
| *"This connector requires one or more additional components"* | MySQL Connector/NET is missing | Install it from dev.mysql.com/downloads/connector/net, then restart Power BI |
| *"Unable to connect … Authentication failed"* | Wrong user or password, or you used the Windows tab | Use the **Database** tab. To re-enter credentials: **File → Options and settings → Data source settings → Clear Permissions** |
| *"Unable to connect to any of the specified MySQL hosts"* | MySQL service stopped, or wrong server name | `services.msc` → start **MySQL80**; server = `localhost:3306` |
| "Sum of season" or "Sum of match_id" appears | Number columns are summarised by default | Column tools → Summarization → **Don't summarize** |
| Phases sorted Death, Middle, Powerplay | Alphabetical sort | Sort `phase` by `Phase Order` (Step 5) |
| Team measures show blank on a card | No team or several teams selected; `SELECTEDVALUE` needs exactly one | Select one team in the slicer, or use the measure in a table that has `teams[team_name]` on its rows |
| Team measures show wrong or identical values per team | The automatic `teams` relationships are still there, or the axis uses `matches[winner]` instead of `teams[team_name]` | Delete the `teams` relationships (Step 4); put `teams[team_name]` or `teams[short_name]` on the axis |
| Player stats don't change with the season slicer | Slicer uses `deliveries[season]` and is not synced, or the relationship is missing | Use `matches[season]`; check the relationship in Model view |
| Numbers are too high (e.g. runs ×2) | A second relationship or a "Both" direction filter | Keep only matches → deliveries, Single direction |
| DAX error *"The syntax for ',' is incorrect"* | Some countries' settings use `;` as the separator | **File → Options → Regional settings → DAX separators: Recommended** |
| DAX error *"A single value for column … cannot be determined"* | A column was used in a measure without an aggregation | Wrap it: `SUM()`, `MAX()`, or `SELECTEDVALUE()` |
| Refresh is slow | 260k rows reloaded from MySQL | Normal (≈ 30 s). Use **Home → Refresh** only when the data changes |

---

## Viva questions for this phase (quick answers)
- **Calculated column vs measure?** A column is calculated row by row and **stored** in the table; a measure is calculated **when a visual needs it**, using the current filters. Use a column to slice or group, and a measure to aggregate.
- **Why one relationship only?** Several active paths between tables cause ambiguity. The `teams` table is disconnected and read with `SELECTEDVALUE`.
- **What does CALCULATE do?** It changes the filter context: it evaluates an expression with extra or modified filters.
- **Import vs DirectQuery?** Import copies the data into Power BI (fast, all DAX features). DirectQuery queries the source live (always current, but slower).
- **What is a star schema?** Fact tables (deliveries) surrounded by dimension or lookup tables (matches, teams), linked by one-to-many relationships.
