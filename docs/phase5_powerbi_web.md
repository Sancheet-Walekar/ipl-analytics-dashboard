# Phase 5 (Browser Version) – Power BI in the Web with a College Account

Use this guide if you **don't have Windows**. Everything happens at **app.powerbi.com** in Chrome, Edge or Firefox, on Linux, Mac or Windows.

The **DAX measures, chart choices and page layouts are the same** as in the main guide, [phase5_powerbi.md](phase5_powerbi.md). This file covers only the steps that **differ** in the browser, and it links back to the main guide for the rest.

> Microsoft updates the web interface often, so a button may have a slightly different name or position from this guide. Look for the closest match. Hovering over a greyed-out button usually shows the reason it's disabled.

---

## How the data gets to Power BI in the browser
The browser version **cannot connect to MySQL on your laptop**. That would need a "gateway" program, which only runs on Windows. Instead, we **export the tables from MySQL into one Excel workbook** and give Power BI that file:

```
Raw CSV → Python (clean) → MySQL (store + SQL) → Excel export (Python) → Power BI web (dashboard)
```
In the viva, say: *"My final tables live in MySQL. I export them with a Python script into an Excel workbook, which Power BI Service imports. Power BI Desktop could connect to MySQL directly, but the web service needs a gateway for local databases."*

---

## Step 1 – Check that your college account has Power BI
1. Go to **https://app.powerbi.com** and sign in with your **college email**.
2. If you reach the Power BI **Home** page, it works. A **Free** licence is enough: you can build reports in **My workspace**, and you only need Pro to *share* them with others.
3. If you see *"Your organization doesn't allow you to sign up"* or similar, ask your college IT department to enable Power BI for your account. Until then, use a college lab Windows PC with the main guide.

---

## Step 2 – Create the Excel workbook (on your laptop)
In the VS Code terminal, from the project folder:
```bash
source venv/bin/activate
pip install -r requirements.txt                      # installs xlsxwriter and sqlalchemy
MYSQL_USER=ipl_user python scripts/export_for_powerbi.py
```
Enter your `ipl_user` MySQL password when asked. **Expected output (2–3 minutes):**
```
Reading teams from MySQL ...
Reading matches from MySQL ...
Reading deliveries from MySQL ...
Writing .../data/powerbi/ipl_powerbi.xlsx (2-3 minutes, please wait) ...
  sheet 'teams': 15 rows x 3 columns
  sheet 'matches': 1,095 rows x 23 columns
  sheet 'deliveries': 260,920 rows x 29 columns
Done! .../data/powerbi/ipl_powerbi.xlsx (21.3 MB)
```
If MySQL isn't running, use `python scripts/export_for_powerbi.py --from-csv`. It builds the same workbook from the cleaned CSVs.

**Why one Excel file with "Tables"?** Power BI's Excel import loads data only if it is formatted as an Excel **Table** (Insert → Table in Excel). Putting all 3 tables in one workbook gives you **one semantic model containing all 3 tables**, which you need for relationships. Uploading 3 separate CSVs would create 3 separate models.

You don't need to open the file. If you do (in LibreOffice Calc), you'll see 3 sheets: `teams`, `matches` and `deliveries`.

---

## Step 3 – Put the workbook on your college OneDrive
1. Go to **https://www.office.com** (same college login) → **OneDrive**.
2. Create a folder `IPL Project` → **Upload → Files** → choose `data/powerbi/ipl_powerbi.xlsx`.

**Why OneDrive and not "upload from computer"?** Power BI keeps a live link to a OneDrive file. If you re-export and replace the file, Power BI picks up the change. Microsoft has also been reducing support for uploading local Excel files.

---

## Step 4 – Create the semantic model
A **semantic model** (once called a *dataset*) is Power BI's name for the tables, relationships and measures behind a report.

1. In Power BI, click **My workspace** on the left.
2. Click **+ New item** → under *Store data*, choose **Semantic model** → **Excel**.
3. Choose **OneDrive for Business** (or *Browse OneDrive*) → open `IPL Project` → select `ipl_powerbi.xlsx` → **Select / Next**.
4. If asked **Import** or **Upload**, choose **Import**. *Upload* only stores the file and does not create a model.
5. If asked which tables to load, tick **teams**, **matches** and **deliveries**.
6. Choose **Create a semantic model only** (if offered) → name it `IPL Analytics` → **Create**.

Wait until `IPL Analytics` appears in My workspace. Loading 260k rows takes 1–2 minutes.

---

## Step 5 – Open the model editor
1. In My workspace, hover over the **IPL Analytics** semantic model → click **⋯ (More options)** → **Open semantic model**.
2. At the top right, switch from **Viewing** to **Editing**.

⚠️ **Changes save automatically and can't be undone with Ctrl + Z.** Work carefully. If you make a mistake, delete the measure or column and create it again.

You'll see a **diagram** of the 3 tables (the Model view), a **Data** pane on the right, and a **ribbon** at the top with *New measure*, *New column* and *Manage relationships*.

---

## Step 6 – Data types
Click a column in the **Data** pane. The **Properties** pane shows its **Data type**. Check these:

| Table | Column | Should be |
|---|---|---|
| matches | match_date | Date |
| matches | season, match_id, result_margin, target_runs, toss_winner_won | Whole number |
| deliveries | match_id, season, all runs and 0/1 flag columns | Whole number |

Excel kept the types from MySQL, so these should already be right. Only change a column if it shows the wrong type. Tip: **Ctrl + click** several columns to change them all at once.

**Hide `deliveries[season]` and `deliveries[delivery_id]`:** right-click → **Hide** (or turn on *Is hidden* in Properties). Slicers must always use `matches[season]`. The reason is explained in Step 4 of the main guide.

---

## Step 7 – Relationships
Click **Manage relationships** in the ribbon.

- **Keep or create ONE relationship:** `matches[match_id]` (1) → `deliveries[match_id]` (*), *Single* direction.
  To create it: **New relationship** → From table `matches`, column `match_id` → To table `deliveries`, column `match_id` → Cardinality **One to many** → Cross-filter **Single** → **Save**.
  Or drag `match_id` from the matches box onto `match_id` in the deliveries box in the diagram.
- **If Power BI created any relationship involving `teams`, delete it.** `teams` stays **disconnected**; the reason is explained in Step 4 of the main guide.

Unlike Power BI Desktop with MySQL, the web service does **not** read the foreign keys, so you'll probably create the relationship yourself. That's good practice to show in the viva.

---

## Step 8 – Calculated columns
Select the **matches** table in the Data pane → **New column** → type the formula in the formula bar → press Enter.
Create the 4 columns for `matches` from **Step 5 of the main guide**: `Win Type`, `Toss Result`, `Chasing Won` and `Season Label`.

For **deliveries**, use this column instead of *Sort by column*, which may not be available in the web editor:
```DAX
Phase Label =
SWITCH ( deliveries[phase], "Powerplay", "1. Powerplay", "Middle", "2. Middle", "Death", "3. Death" )
```
The numbers in front make the phases sort in the right order (Powerplay → Middle → Death) on any chart axis. Use `Phase Label` instead of `phase` in the charts.

---

## Step 9 – DAX measures
1. Select the **matches** table in the Data pane → **New measure**.
2. Paste a formula from **Step 6 of the main guide** (all 30 measures in sections 6.1–6.4) → press Enter.
3. In the **Properties** pane, set the **Format**: *Percentage* for the % measures, and *Decimal number, 2 decimal places* for Strike Rate, Economy, Run Rate and the averages.
4. Optional: in the Properties pane, set a **Display folder** such as `Batting`, `Bowling`, `Teams` or `Overview` to keep the measures organised.

(The main guide creates a separate `_Measures` table with *Enter data*. In the web editor, just keeping the measures in `matches` with display folders is simpler and works the same way.)

**Check:** the expected values in **section 6.5 of the main guide** apply exactly, because it is the same data and the same formulas.

---

## Step 10 – Build the report
1. Go back to My workspace → **⋯** on `IPL Analytics` → **Create report** (or open the model and click **Create report / Explore → Create a blank report**).
2. The report editor in the browser looks almost the same as Power BI Desktop: a **Visualizations** pane, a **Data** pane, a **Filters** pane and the canvas.
3. Build the 3 pages exactly as in **Steps 7–9 of the main guide**:
   - Page 1 **IPL Overview**: 6 KPI cards, runs per season line, titles bar, team table, toss donut, season slicer
   - Page 2 **Player Performance**: player KPI cards, Top 10 batters and bowlers (Top N filter), strike-rate scatter, economy table, batter and bowler slicers
   - Page 3 **Match Analysis**: toss and chasing gauges, win-type donut, bat/field trend, phase run rate (use **Phase Label**), venue chart, team slicer
4. Add pages with the **+** at the bottom. Double-click a page tab to rename it.
5. **Save often:** **File → Save** → name `IPL Dashboard` → save to **My workspace**.

**Browser differences you may notice**
| In Desktop | In the browser |
|---|---|
| "Sum of season" fix in Column tools | In the visual's field well, click the **⌄** next to `season` → **Don't summarize** |
| View → Sync slicers | If the **Sync slicers** pane isn't in the View menu, copy the season slicer onto each page (Ctrl + C / Ctrl + V). Power BI asks whether to sync it; choose **Sync** |
| Sort by column (phase) | Use the `Phase Label` column from Step 8 |
| File → Save as .pbix | **File → Download this file** (if offered), or Export to PDF (below) |

---

## Step 11 – Save your work for the project and GitHub
The report lives in your Power BI account, so take copies for the repo and the project report:

1. **PDF of all pages:** open the report (in Reading view) → **Export → PDF** → save as `powerbi/IPL_Dashboard.pdf`.
2. **Screenshots:** for each page, press **Print Screen** (or `Shift + Print Screen` to select an area on Ubuntu). Save them as `powerbi/screenshots/page1_overview.png`, `page2_players.png` and `page3_matches.png`.
3. **.pbix (if available):** **File → Download this file → A copy of your report and data** → save as `powerbi/IPL_Dashboard.pbix`. If this option is greyed out for a web-created model, the PDF and screenshots are enough.
4. **Link for your guide (optional, Pro licence only):** **Share** → enter their college email.

Then commit:
```bash
git add powerbi/
git commit -m "Phase 5: Power BI dashboard (PDF and screenshots)"
git push
```

---

## Common problems in the browser

| Problem | Fix |
|---|---|
| Can't sign up / "organization doesn't allow" | Ask college IT to enable Power BI, or use a lab PC with Power BI Desktop |
| *Open semantic model* is greyed out | Hover over it to see the reason. Make sure you are the owner (you created it) and that it is in **My workspace** |
| Excel import shows no tables | The data isn't formatted as Excel Tables. Re-create the file with `scripts/export_for_powerbi.py`; don't save it again from LibreOffice, which may remove the Table formatting |
| Only `teams` (or one table) loaded | Tick all 3 tables at the import step, or delete the model and import again |
| "File too large" | The workbook is about 20 MB; the limit is 1 GB. Check you uploaded `ipl_powerbi.xlsx`, not a zip |
| Numbers don't match section 6.5 | Check the relationship (Step 7) and that no slicer or filter is active |
| Changes disappeared | You were in **Viewing** mode. Switch to **Editing** at the top right |
| Report is slow | 260k rows in a free account is fine, but avoid very wide tables and too many visuals per page (6–8 max) |
| Updated data after re-export | Replace the file in OneDrive with the same name → in Power BI, **⋯ on the semantic model → Refresh now** |
