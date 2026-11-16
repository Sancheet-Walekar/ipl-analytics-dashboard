# Phase 2 – Dataset Collection

## 1. Where to Download the Dataset

**Recommended:** Kaggle – *IPL Complete Dataset (2008–2024)*
https://www.kaggle.com/datasets/patrickb1912/ipl-complete-dataset-20082020

Steps:
1. Open the link and **sign in** to Kaggle. A free account works; you can sign in with Google.
2. Click the **Download** button (top right). A file like `archive.zip` downloads.
3. Right-click the zip → **Extract All**.
4. Copy `matches.csv` and `deliveries.csv` into the project's `data/raw/` folder.

**Google Colab users:** in Colab, click the folder icon on the left → upload both CSVs, or upload them to Google Drive and mount the Drive.

**Other sources (for your report's references section):**
- Cricsheet.org: free ball-by-ball data in YAML/JSON/CSV. It is the original source of most IPL datasets.
- iplt20.com: official stats, useful for cross-checking your answers.

> **What is a CSV?** "Comma-Separated Values": a plain text file where each line is one row and commas separate the columns. Excel, Python, MySQL and Power BI can all read it.

---

## 2. matches.csv: one row per match

About **1,095 rows** (one for every IPL match from 2008 to 2024) and about **20 columns**.

| Column | Meaning | Example |
|---|---|---|
| `id` | **Unique match ID** (primary key) | 335982 |
| `season` | IPL season. *Some rows look like "2007/08" or "2020/21"; we fix this in Phase 3* | 2008 |
| `city` | City where the match was played (has some missing values) | Bangalore |
| `date` | Match date | 2008-04-18 |
| `match_type` | League, Qualifier 1, Eliminator, Final, etc. | League |
| `player_of_match` | Player of the Match award winner | BB McCullum |
| `venue` | Stadium name | M Chinnaswamy Stadium |
| `team1` | First team | Royal Challengers Bangalore |
| `team2` | Second team | Kolkata Knight Riders |
| `toss_winner` | Team that won the toss | Royal Challengers Bangalore |
| `toss_decision` | `bat` or `field` | field |
| `winner` | Team that won (empty if no result) | Kolkata Knight Riders |
| `result` | `runs`, `wickets`, `tie` or `no result` | runs |
| `result_margin` | How much they won by (number of runs or wickets) | 140 |
| `target_runs` | Target set for the chasing team | 223 |
| `target_overs` | Overs available for the chase (less than 20 if rain shortened the match) | 20 |
| `super_over` | `Y` if the match was decided by a Super Over | N |
| `method` | `D/L` if the Duckworth-Lewis rain rule was used | NA |
| `umpire1`, `umpire2` | On-field umpires | Asad Rauf |

**How to read `result` + `result_margin`:**
- `runs` and `140`: the team batting first won by 140 runs.
- `wickets` and `5`: the chasing team won with 5 wickets still in hand.

---

## 3. deliveries.csv: one row per ball bowled

About **260,000 rows** (every ball of every match) and about **17 columns**.

| Column | Meaning | Example |
|---|---|---|
| `match_id` | Which match this ball belongs to (**foreign key** → `matches.id`) | 335982 |
| `inning` | 1 = first batting innings, 2 = chase (3/4 = Super Over) | 1 |
| `batting_team` | Team batting | Kolkata Knight Riders |
| `bowling_team` | Team bowling | Royal Challengers Bangalore |
| `over` | Over number. **In this dataset it starts at 0**, so over 0 = the 1st over | 0 |
| `ball` | Ball number within the over (can be more than 6 when there are wides or no-balls) | 1 |
| `batter` | Batter facing the ball | SC Ganguly |
| `bowler` | Bowler | P Kumar |
| `non_striker` | Batter at the other end | BB McCullum |
| `batsman_runs` | Runs scored off the bat (0, 1, 2, 3, 4, 6) | 0 |
| `extra_runs` | Extra runs (wides, no-balls, byes, leg-byes) | 1 |
| `total_runs` | `batsman_runs + extra_runs` | 1 |
| `extras_type` | `wides`, `noballs`, `byes`, `legbyes`, `penalty`, or empty | legbyes |
| `is_wicket` | 1 if a wicket fell on this ball, else 0 | 0 |
| `player_dismissed` | Who got out (empty if no wicket) | — |
| `dismissal_kind` | caught, bowled, lbw, run out, stumped… | caught |
| `fielder` | Fielder involved in the dismissal | — |

**Cricket rules you need for the calculations later:**
- **Strike rate** = (runs ÷ balls faced) × 100. Wides do **not** count as balls faced.
- **Economy** = runs conceded ÷ overs bowled. Byes and leg-byes are **not** charged to the bowler.
- **Bowler's wickets** do **not** include run outs, retired hurt or "obstructing the field".

---

## 4. How the Two Datasets Are Related

```
 matches                         deliveries
┌──────────────┐               ┌──────────────────┐
│ id  (PK)     │──1 ───── N ──▶│ match_id (FK)    │
│ season       │               │ inning, over,ball│
│ venue        │               │ batter, bowler   │
│ winner ...   │               │ runs, wickets ...│
└──────────────┘               └──────────────────┘
```

- **One match has many deliveries** (about 240 balls). This is a **one-to-many (1:N)** relationship.
- `matches.id` is the **primary key**: it is unique and never empty.
- `deliveries.match_id` is the **foreign key**: it points back to a match.
- To answer "Top run scorers **in 2016**", you need *runs* from deliveries and *season* from matches. You **join** the two tables on `matches.id = deliveries.match_id`.

---

## 5. How to Inspect the Datasets
Open `notebooks/01_data_inspection.ipynb`. It runs these checks one at a time:

| Command | What it tells you |
|---|---|
| `df.shape` | (rows, columns) |
| `df.head()` / `df.tail()` | First or last 5 rows |
| `df.columns` | Column names |
| `df.info()` | Data type and non-null count for each column |
| `df.describe()` | Min, max, mean and other statistics for number columns |
| `df.isnull().sum()` | Missing values in each column |
| `df.duplicated().sum()` | Number of exactly duplicated rows |
| `df['col'].unique()` / `.value_counts()` | The different values in a column and how often each appears |

### Where to run it
- **Jupyter (on your laptop):** open a terminal in the project folder → `jupyter notebook` → a browser tab opens → click `notebooks/01_data_inspection.ipynb` → press **Shift + Enter** to run each cell.
- **Google Colab:** File → Upload notebook → upload both CSVs → change the path variable in the 2nd code cell to `"/content/"`.

---

## 6. Common Errors and Fixes

| Error | Cause | Fix |
|---|---|---|
| `FileNotFoundError: matches.csv` | Wrong folder or path | Check the file is in `data/raw/`. Open the notebook from the `notebooks/` folder. On Windows, write paths with `/` or `r"C:\path"` |
| `ModuleNotFoundError: No module named 'pandas'` | Library not installed in this environment | Activate venv → `pip install -r requirements.txt`, then restart the kernel |
| `'pip' is not recognized` | Python was not added to PATH | Reinstall Python and tick "Add to PATH", or use `python -m pip install ...` |
| `'jupyter' is not recognized` | Jupyter not installed or venv not activated | `pip install notebook`, or `python -m notebook` |
| `UnicodeDecodeError` | File encoding | `pd.read_csv(path, encoding="latin-1")` |
| `DtypeWarning: mixed types` | A column has both numbers and text | Harmless for now; add `low_memory=False` |
| Kaggle download asks for login | Kaggle requires an account | Create a free account |
