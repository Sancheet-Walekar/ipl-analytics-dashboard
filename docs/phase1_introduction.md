# Phase 1 – Project Introduction

## 1. Project Introduction
The Indian Premier League (IPL) is a professional T20 cricket league that started in 2008. Each season produces thousands of data points: who won the toss, who scored runs on every ball, who took wickets, where the match was played, and so on.

This project, **"IPL Data Analytics and Performance Dashboard Using Python, SQL and Power BI"**, turns that raw data into useful information. It follows the same pipeline a working data analyst uses:

```
Raw CSV files  →  Python (clean + explore)  →  MySQL (store + query)  →  Power BI (visualise)
```

The final output is an interactive dashboard where a user can choose a season, team or player and see their performance at once.

## 2. Problem Statement
IPL data is freely available, but in its raw form it is hard to use:
- It is spread across two large CSV files (one has 260,000+ rows), which are too big to read by hand.
- It has **data quality problems**: missing values, the same team under different names (e.g. "Delhi Daredevils" and "Delhi Capitals", "Rising Pune Supergiant" and "Rising Pune Supergiants"), and inconsistent season and date formats.
- Simple questions such as *"Does winning the toss help win the match?"* or *"Who has the best death-over economy?"* need calculations across both files.
- Fans, analysts and team management have no single visual place to compare teams, players and venues.

**Problem:** build a system that cleans, stores, analyses and visualises IPL data so that anyone can get answers quickly and accurately.

## 3. Project Objectives
1. Collect authentic IPL match and ball-by-ball data for 2008–2024.
2. Clean and standardise the data using Python (Pandas and NumPy).
3. Do exploratory data analysis (EDA) to understand trends.
4. Design a relational MySQL database with primary and foreign keys.
5. Write 20+ analytical SQL queries (aggregations, joins, subqueries, CASE).
6. Build a 3-page interactive Power BI dashboard (Overview, Player Performance, Match Analysis).
7. Find 15+ meaningful insights, such as the most successful team, top run scorer and impact of the toss.
8. Document the project for college submission and interviews.

## 4. Scope of the Project
**In scope**
- IPL seasons 2008–2024 (whatever the downloaded dataset covers).
- Team-level analysis: wins, win %, toss impact, season trends, home and venue performance.
- Player-level analysis: runs, wickets, strike rate, economy, boundaries, Player of the Match awards.
- Match-level analysis: win by runs vs wickets, venue statistics, results by phase of play (powerplay, middle overs, death overs).
- Static (historical) data loaded from CSV files.

**Out of scope**
- Live or real-time match data.
- Predicting future match results with machine learning (listed as future scope).
- Player auction prices, salaries, injuries or fitness data.
- A web or mobile app (the output is a Power BI dashboard).

## 5. Existing System vs Proposed System

| Aspect | Existing System | Proposed System |
|---|---|---|
| Data access | Raw CSVs or scattered cricket websites | One cleaned, structured MySQL database |
| Data quality | Duplicate team names, missing values | Cleaned and standardised using Python |
| Analysis | Manual; Excel struggles with 260k rows | Automated using Pandas and SQL queries |
| Custom questions | Websites show only fixed stats | Any question can be answered with SQL |
| Visualisation | Static tables | Interactive charts, slicers and drill-down in Power BI |
| Time taken | Hours per question | Seconds, by clicking a filter |
| Reusability | Must be redone every season | Add the new season's CSV and refresh |

**Limitations of the existing system:** it takes a lot of time, mistakes are easy to make, it is not interactive, and data from different sources cannot be combined.

## 6. Hardware and Software Requirements

### Hardware (minimum)
| Component | Minimum | Recommended |
|---|---|---|
| Processor | Intel i3 / AMD Ryzen 3 | Intel i5 / Ryzen 5 or better |
| RAM | 4 GB | 8 GB |
| Storage | 5 GB free | 10 GB free (SSD) |
| OS | Windows 10 (64-bit) | Windows 10/11 (64-bit) |
| Internet | Needed for downloads | — |

> Power BI Desktop runs **only on Windows**. Mac or Linux users can use a Windows PC in the college lab, or a Windows virtual machine.

### Software
| Software | Version | Use |
|---|---|---|
| Python | 3.10 or newer | Programming language |
| Pandas | 2.x | Data cleaning and analysis |
| NumPy | 1.24+ | Numeric operations |
| Jupyter Notebook / Google Colab | Latest | Writing and running Python step by step |
| MySQL Community Server | 8.x | Database |
| MySQL Workbench | 8.x | GUI for writing SQL |
| Power BI Desktop | Latest (free) | Dashboard |
| MySQL Connector/NET (or ODBC) | 8.x | Lets Power BI connect to MySQL |
| Git and a GitHub account | Latest | Version control and sharing |
| VS Code (optional) | Latest | Editor |

## 7. Expected Outcomes
1. Two cleaned CSV files (`matches_cleaned.csv`, `deliveries_cleaned.csv`) with consistent team names and dates.
2. A MySQL database `ipl_db` with related tables and 20+ tested SQL queries.
3. A 3-page Power BI dashboard:
   - **IPL Overview**: total matches, seasons, teams, titles, season-wise trends.
   - **Player Performance**: top batters and bowlers, strike rate, economy, player comparison.
   - **Match Analysis**: toss impact, venues, win margins, results by phase of play.
4. At least 15 data-backed insights written in business language.
5. A complete BCA project report and a public GitHub repository.
6. Confidence to explain each step in a viva or a data analyst interview.

## Viva tip: explain the project in one line
> "I built an end-to-end analytics pipeline. I cleaned 17 seasons of IPL ball-by-ball data in Python, stored it in a relational MySQL database, analysed it with SQL, and presented the insights in an interactive Power BI dashboard."
