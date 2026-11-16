# Phase 3 – Python Data Cleaning & EDA

**Notebook:** [notebooks/02_data_cleaning_eda.ipynb](../notebooks/02_data_cleaning_eda.ipynb)
**Output:** `data/cleaned/matches_cleaned.csv` (1095 × 23), `data/cleaned/deliveries_cleaned.csv` (260920 × 28)

## 1. Where to run it
1. Open a terminal in the project folder and activate the venv (`venv\Scripts\activate` on Windows).
2. Run `jupyter notebook` and open `notebooks/02_data_cleaning_eda.ipynb`.
3. Click **Kernel → Restart & Run All**, or press **Shift + Enter** on each cell in turn.
   It takes about 10–20 seconds in total. The deliveries file is large, so wait for `[*]` to change to a number.

**Google Colab:** upload the notebook and both raw CSVs. In the first code cell, set `RAW_DIR` and `CLEAN_DIR` to `"/content/"`. When it finishes, download the two cleaned CSVs from the Files panel.

## 2. Concepts you must know (for the viva)

| Concept | Simple meaning | Pandas code |
|---|---|---|
| DataFrame | A table in Python (rows + columns) | `pd.read_csv()` |
| Series | One column of a DataFrame | `df["season"]` |
| NaN | "Not a Number": a missing value | `df.isnull().sum()` |
| Filtering | Keep only rows that match a condition (SQL `WHERE`) | `df[df["season"] == 2016]` |
| groupby | Split into groups and summarise each one (SQL `GROUP BY`) | `df.groupby("team")["runs"].sum()` |
| map / replace | Change values using a lookup dictionary | `df["team"].replace({"old": "new"})` |
| np.where | IF/ELSE for a whole column | `np.where(cond, 1, 0)` |
| Feature engineering | Making new useful columns from existing ones | `is_six`, `phase`, `bowler_runs` |

## 3. Cleaning decisions (and the reason for each)

| Problem | Decision | Reason |
|---|---|---|
| 0 duplicate rows | Checked anyway, then ran `drop_duplicates()` | Keeps the pipeline safe if new data is added |
| 19 team names → 15 franchises | Renamed 4 old names | Delhi Daredevils, Kings XI Punjab, RC Bangalore and Rising Pune Supergiants were *renamed*, not new teams |
| Deccan Chargers ≠ Sunrisers Hyderabad | **Not** merged | Different owners, so they are different franchises |
| `season` = "2007/08", "2009/10", "2020/21" | Replaced with the year of the match date | Every IPL season is played within one calendar year |
| `date` stored as text | `pd.to_datetime` | Needed for sorting, years and month analysis |
| 51 missing `city` | Filled from `venue` (Dubai/Sharjah) | The correct value can be worked out exactly |
| 5 missing `winner` and `player_of_match` | **Kept blank** | These matches were washed out, so there was no winner |
| 19 missing `result_margin` | Kept blank | Ties (14) and no-results (5) have no winning margin |
| 1074 missing `method` | Filled with "Normal" | A blank means the D/L rain rule was not used |
| Blanks in `extras_type`, `player_dismissed`, `fielder` | Kept blank | Most balls are not extras or wickets |
| 58 venue spellings | Reduced to 36 | "Eden Gardens" and "Eden Gardens, Kolkata" are the same ground |

## 4. Cricket formulas used

| Stat | Formula | Note |
|---|---|---|
| Strike rate | runs ÷ balls faced × 100 | Wides are not counted as balls faced |
| Economy | bowler runs ÷ (legal balls ÷ 6) | Byes and leg-byes are not charged to the bowler |
| Bowler wickets | wickets − run outs − retirements − obstructing the field | Official IPL rule |
| Run rate | runs ÷ (legal balls ÷ 6) | Runs per over |
| Phases | Powerplay 1–6, Middle 7–15, Death 16–20 | Standard T20 split |

## 5. Key results you should see

| Question | Answer |
|---|---|
| Most wins | Mumbai Indians: 144 wins in 261 matches |
| Best win % (older teams) | Chennai Super Kings: 58.0% |
| Most titles | CSK and MI: 5 each |
| Toss winner also won | 50.8%: the toss barely matters |
| Chasing team won | 54.3%, which is why captains prefer to field first (≈ 73–83% since 2016) |
| Highest run scorer | V Kohli: 8004 runs |
| Highest wicket taker | YS Chahal: 205 wickets |
| Best strike rate (≥ 500 balls) | AD Russell: 174.93 |
| Best economy (≥ 1000 balls) | M Muralitharan 6.68, SP Narine 6.73 |
| Most matches hosted | Wankhede Stadium: 118 |
| Most Player of the Match awards | AB de Villiers: 25 |
| Death-over run rate | 9.96, compared with ≈ 7.8 in the other phases |

## 6. Common errors and fixes

| Error | Cause | Fix |
|---|---|---|
| `FileNotFoundError` | Notebook opened from the wrong folder, or CSV not in `data/raw/` | Start Jupyter from the project folder; check `RAW_DIR` |
| `NameError: name 'matches' is not defined` | A later cell was run before an earlier one | **Kernel → Restart & Run All** |
| `KeyError: 'batter'` | Your dataset version uses `batsman` instead | Rename it: `deliveries = deliveries.rename(columns={"batsman": "batter"})` |
| `ValueError: time data ... doesn't match format` | Your dataset has dates like `18/04/2008` | Use `pd.to_datetime(matches["date"], dayfirst=True)` |
| `SettingWithCopyWarning` | Changing a filtered slice | Add `.copy()` after the filter; this is only a warning |
| `FutureWarning: observed=False` | Newer pandas, when grouping by a category column | Harmless; we already pass `observed=True` |
| Chart not showing | `%matplotlib inline` cell was not run | Run the first code cell again |
| Memory error on an old laptop | 260k rows × 28 columns | Close other apps, or use Google Colab |

## 7. Why the cleaned CSVs are not on GitHub
They are created by running the notebook. Anyone who clones the repo can recreate them in a few seconds, so they are listed in `.gitignore` to keep the repo small.
