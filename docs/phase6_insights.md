# Phase 6 – Data Analysis & Business Insights

**Queries used:** [sql/03_analysis_queries.sql](../sql/03_analysis_queries.sql) (Q1–Q26) and [sql/04_insight_queries.sql](../sql/04_insight_queries.sql) (Q27–Q33)
**Data:** IPL 2008–2024, 1,095 matches, 260,920 deliveries. Super Over balls are excluded from player stats.

---

## How to write an insight (the "What → So what → Now what" method)
A number on its own is **not** an insight. "Kohli scored 8,004 runs" is a *fact*. An insight explains **why it matters** and **what someone should do about it**.

| Part | Question it answers | Example |
|---|---|---|
| **What** | What does the data show? | Teams that chose to field after winning the toss won 53.9% of matches; teams that chose to bat won 45.4% |
| **So what** | Why does it matter? | The toss itself barely matters, but the *decision* does |
| **Now what** | What should a team, broadcaster or analyst do? | Captains should field first by default, unless the venue data says otherwise |

Each insight below uses this structure. In interviews, use the same 3 parts. That's how analysts present findings to managers.

---

## A. Team insights

### Insight 1 – Mumbai Indians win the most, but CSK win most consistently
- **What:** MI have the most wins (**144** in 261 matches). Chennai Super Kings have the best win % among long-running teams (**58.0%**) and the best playoff record (**17 wins in 26 playoff matches**). Gujarat Titans show 62.2%, but from only 45 matches, which is too small a sample to call them the best.
- **So what:** Total wins favour teams that have played the longest. Win % is the fairer comparison.
- **Now what:** Rank teams by win % with a minimum-matches rule, not by raw wins.
- **Derive it:** SQL **Q5** (LEFT JOIN + CASE) and **Q33** (playoffs, HAVING). Power BI: Page 1 *Team Performance* table with `[Team Played]`, `[Team Wins]` and `[Team Win %]`.

### Insight 2 – Two teams dominate the titles
- **What:** CSK (5) and MI (5) have won **10 of the 17 titles (59%)**. Delhi Capitals, Punjab Kings and RCB have **never** won, despite 245+ matches each.
- **So what:** Long-term success comes from a stable core and leadership (Dhoni at CSK, Rohit at MI), not just from playing a lot of matches.
- **Now what:** Franchises without titles should study what CSK and MI do in playoffs (see Insight 1), not only in league matches.
- **Derive it:** SQL **Q6** (subquery + LEFT JOIN, which keeps the 0-title teams). Power BI: Page 1 *IPL Titles by Team* bar with `[Team Titles]`.

### Insight 3 – Home advantage is real, and strongest for CSK
- **What:** CSK win **70.4%** of their matches at Chepauk compared with **53.0%** elsewhere. MI (61.2% vs 52.3%) and KKR (59.1% vs 48.5%) also do much better at home. RCB gain almost nothing at Chinnaswamy (50.6% vs 47.9%).
- **So what:** Teams that build their squad for their home pitch (CSK's spinners on a slow Chennai pitch) turn home matches into near-certain points. Chinnaswamy is a small, high-scoring ground that helps the visiting batters just as much.
- **Now what:** RCB should pick a squad that suits their home ground better, especially stronger death bowling for a small ground.
- **Derive it:** SQL **Q30** (CASE to flag home matches, derived table, INNER JOIN). Power BI: Page 3 with the team slicer + venue slicer + `[Team Win %]` card.
- **Caveat:** seasons played abroad (2009 in South Africa; 2020 and parts of 2014 and 2021 in the UAE) count as "away", which slightly understates home advantage.

---

## B. Toss and match-result insights

### Insight 4 – Winning the toss barely matters…
- **What:** The toss winner won only **50.8%** of matches, almost the same as tossing a coin.
- **So what:** "We lost the toss" is not a real excuse.
- **Derive it:** SQL **Q10** (`AVG` of the 0/1 column `toss_winner_won`). Power BI: Page 3 gauge with `[Toss Win %]` and a target of 50%.

### Insight 5 – …but what you choose after the toss DOES matter
- **What:** Toss winners who chose to **field won 53.9%** of matches. Those who chose to **bat won only 45.4%**.
- **So what:** Insight 4 hides this. Choosing to field (good) and choosing to bat (bad) cancel each other out in the overall 50.8%. This is a classic example of why you should **break an average down by group**.
- **Now what:** Choose to field first by default.
- **Derive it:** SQL **Q29** (`GROUP BY toss_decision`). Power BI: clustered column chart, axis `toss_decision`, value `[Toss Win %]`.

### Insight 6 – Chasing teams win more, and captains have learned this
- **What:** Chasing teams win **54.3%** of matches. Captains chose to field after winning the toss only **35–55%** of the time in 2008–2010, but **81–83%** of the time in 2016–2019.
- **So what:** Chasing is easier because the team knows exactly how many runs it needs. Teams changed their strategy because of the data.
- **Derive it:** SQL **Q12** (CASE + subquery for %) and **Q11** (CASE pivot by season). Power BI: `[Chasing Win %]` gauge; 100% stacked column chart of `toss_decision` by `season`.

### Insight 7 – In finals, the chasing advantage disappears
- **What:** Of 17 finals, **9 were won batting first and 8 chasing**, compared with a 46/54 split in all matches.
- **So what:** Under final-day pressure, a big first-innings total is worth more, and chasing gets harder.
- **Now what:** In a final, don't automatically choose to field. Consider the venue, the conditions and your own squad.
- **Derive it:** SQL **Q32**. Power BI: filter Page 3 with `match_type = "Final"` and look at the *Win Type* donut.
- **Caveat:** 17 finals is a small sample. Present this as a *trend*, not proof.

### Insight 8 – Venues have their own personality
- **What:** Wankhede has hosted the most matches (**118**). Chasing teams win **64.9%** at Sawai Mansingh (Jaipur) but only **43.4%** at Chepauk (Chennai).
- **So what:** The general rule "field first" (Insights 5–6) is wrong in Chennai, where the pitch gets slower as the match goes on and chasing gets harder.
- **Now what:** Base the toss decision on the venue's history, not the league average.
- **Derive it:** SQL **Q13** (HAVING ≥ 30 matches). Power BI: Page 3 *Top Venues* line-and-column chart (`[Total Matches]` columns, `[Chasing Win %]` line).

### Insight 9 – Most matches are not close
- **What:** **86.3%** of decided matches were comfortable wins. Only **11.1%** were won by 10 runs or fewer, 1.3% by 2 wickets or fewer, and 1.3% were ties.
- **So what:** The "last-ball thriller" is memorable but rare. Most matches are effectively decided earlier.
- **Now what:** For broadcasters, the excitement is spread across the whole match. For teams, it's worth investing in powerplay and middle-overs performance, not only finishers.
- **Derive it:** SQL **Q31** (CASE to group margins). Power BI: calculated column `Finish Type` (the same CASE written as DAX `SWITCH(TRUE(), …)`) + donut chart.

---

## C. Scoring-trend insights

### Insight 10 – Scoring has exploded since 2023
- **What:** The average first-innings total stayed between **150 and 172** from 2008 to 2022, then jumped to **182.7 in 2023** and **189.6 in 2024**. The run rate rose from 8.24 (2008) to **9.54** (2024). **8 of the 10 highest team totals** ever were scored in 2024, including SRH's record **287**.
- **So what:** The jump matches the **Impact Player rule** (introduced in 2023), which lets teams bring in an extra batter, so batting line-ups are deeper and batters take more risks.
- **Now what:** A "par score" from older seasons (≈ 160) is out of date. Teams now need around 190+ to feel safe.
- **Derive it:** SQL **Q27** (derived table of first-innings totals → AVG per season) and **Q9** (highest totals). Power BI: Page 1 *Runs per Season* line chart; add `[Run Rate]` as a second line.

### Insight 11 – Batting is becoming boundary-driven
- **What:** Sixes per match rose from **10.7** (2008) to **17.8** (2024). Boundaries made **62.6%** of all runs in 2024, compared with ~51–55% in 2009–2013.
- **So what:** Power-hitting is now the most valued batting skill, and running between the wickets matters less.
- **Now what:** Scouting and auctions should value boundary % and strike rate above batting average.
- **Derive it:** SQL **Q28** (CASE inside SUM; COUNT DISTINCT for per-match). Power BI: measure `Sixes per Match = DIVIDE([Total Sixes], [Total Matches])` on a line chart by season.

### Insight 12 – The death overs decide matches
- **What:** Run rate in overs 16–20 is **9.96**, compared with **7.85** in the powerplay and **7.79** in the middle overs. A wicket falls every **11.8 balls** at the death, compared with every 23–25 balls earlier.
- **So what:** About 27% of all runs and 37% of all wickets come in just the last 5 overs. This is the highest-risk, highest-reward phase.
- **Now what:** A specialist death bowler (Insight 15) is one of the most valuable players in a squad.
- **Derive it:** SQL **Q25** (`GROUP BY phase`). Power BI: Page 3 *Run Rate by Phase* column chart (`Phase Label` axis).

---

## D. Player insights

### Insight 13 – Kohli is the run machine, and he adapted to the new era
- **What:** V Kohli is the highest run scorer (**8,004** runs, 8 centuries, 55 fifties). His **973 runs in 2016** is still the single-season record. In 2024 he scored 741 at a strike rate of **154.7**, his highest ever, compared with 131.97 over his career.
- **So what:** Kohli stayed at the top by increasing his scoring rate to keep up with the faster game (Insight 10).
- **Derive it:** SQL **Q15** (top scorers), **Q18** (top scorer per season, subquery + JOIN) and **Q20** (Kohli by season). Power BI: Page 2 with the batter slicer = V Kohli; KPI cards; line chart of `[Batter Runs]` and `[Strike Rate]` by season.

### Insight 14 – The fastest scorers are finishers, not openers
- **What:** Among batters with 500+ balls faced, **AD Russell** has the best strike rate (**174.93**), followed by Klaasen (168.31) and Narine (165.84). Only **17 of 77** batters with 1,000+ balls score at 140+.
- **So what:** Very fast scoring over a long career is rare, and players who can do it are worth a premium.
- **Derive it:** SQL **Q16** (HAVING ≥ 500 balls) and **Q19** (CASE categories). Power BI: Page 2 *Strike Rate vs Runs* scatter chart. Russell sits top-left (very fast, fewer runs) and Kohli bottom-right (steady, many runs).

### Insight 15 – Spinners dominate both the wicket and economy lists
- **What:** **YS Chahal** is the highest wicket-taker (**205**). Five of the top seven wicket-takers are spinners (Chahal, Chawla, Ashwin, Narine, Mishra). The **3 most economical** bowlers (1,000+ balls) are all spinners: Muralitharan **6.68**, Narine **6.73**, Rashid Khan **6.82**.
- **So what:** In a format built for batting, taking pace off the ball is the most reliable way to slow scoring down.
- **Now what:** Every squad needs at least two quality spinners, especially for slow home pitches (see CSK, Insight 3).
- **Derive it:** SQL **Q21**, **Q22** and **Q23** (subquery in HAVING vs league economy). Power BI: Page 2 *Top 10 Wicket Takers* bar + *Best Economy* table with a filter of Legal Balls ≥ 1000.

### Insight 16 – Death-over specialists: Malinga, Bumrah, and Narine
- **What:** In overs 16–20 (300+ balls), Narine has the best economy (**7.40**). **Malinga** has the most death wickets (**108**), and **Bumrah** has **91 at 8.29**, compared with the league's death run rate of 9.96.
- **So what:** Conceding 1.5–2.5 runs per over less than average across the last 5 overs saves 8–12 runs per match, about the margin of most close games (Insight 9).
- **Derive it:** SQL **Q24** (`WHERE phase = 'Death'` + HAVING). Power BI: Page 2 with a page filter `phase = Death` on the bowling table.

### Insight 17 – Sunil Narine is the most complete player in IPL history
- **What:** Narine appears in **every** list: 180 wickets (joint 5th), 6.73 economy (2nd), the best death economy (7.40), and a batting strike rate of 165.84 (3rd).
- **So what:** A player who is elite at both bowling and batting fills two places in the side, which is why KKR have kept him since 2012.
- **Derive it:** Combine **Q16**, **Q21**, **Q22** and **Q24**. Power BI: Page 2 with batter slicer *and* bowler slicer = SP Narine.

### Insight 18 – Match-winners: AB de Villiers leads the Player of the Match awards
- **What:** AB de Villiers has the most Player of the Match awards (**25**), ahead of Gayle (22) and Rohit (19), even though he ranks only 7th in runs.
- **So what:** Impact per match matters more than career totals. ABD's 151.69 strike rate won matches.
- **Derive it:** SQL **Q26**. Power BI: bar chart with `player_of_match` on the axis and `[Total Matches]` as the value, Top N = 10.

### Insight 19 – Fielding wins wickets
- **What:** **62%** of all dismissals are catches (8,063 of 12,950), plus 1,114 run outs and 358 stumpings.
- **So what:** About 7 in 10 wickets need a fielder or the wicketkeeper. A dropped catch matters as much as a bad over.
- **Now what:** Fielding drills and fielding stats (catches, run outs) should count in player selection.
- **Derive it:** SQL **Q4**. Power BI: donut chart with `dismissal_kind` as the legend and `[Total Wickets]` as the value.

---

## Summary table (for the project report and viva)

| # | Insight | Key number | Source |
|---|---|---|---|
| 1 | CSK most consistent; MI most wins | CSK 58.0% win, 17/26 playoffs; MI 144 wins | Q5, Q33 |
| 2 | Two teams dominate titles | CSK + MI = 10 of 17 | Q6 |
| 3 | Home advantage | CSK 70.4% at home vs 53.0% away | Q30 |
| 4 | Toss barely matters | 50.8% | Q10 |
| 5 | Field-first decision wins more | 53.9% vs 45.4% | Q29 |
| 6 | Chasing advantage; captains adapted | 54.3%; 81–83% field (2016–19) | Q11, Q12 |
| 7 | Finals favour neither | 9 bat-first vs 8 chasing | Q32 |
| 8 | Venues differ | Jaipur 64.9% vs Chennai 43.4% chasing | Q13 |
| 9 | Few close finishes | 86.3% comfortable | Q31 |
| 10 | Scoring explosion since 2023 | 1st-innings avg 161 → 189.6 | Q27, Q9 |
| 11 | Boundary-driven batting | 17.8 sixes/match; 62.6% runs in boundaries | Q28 |
| 12 | Death overs decide matches | RR 9.96; wicket every 11.8 balls | Q25 |
| 13 | Kohli top scorer, adapted | 8,004 runs; SR 154.7 in 2024 | Q15, Q18, Q20 |
| 14 | Finishers fastest | Russell SR 174.93 | Q16, Q19 |
| 15 | Spinners dominate | Chahal 205 wkts; top 3 economy spinners | Q21–Q23 |
| 16 | Death specialists | Malinga 108 death wkts; Narine 7.40 | Q24 |
| 17 | Narine most complete | Top in 4 lists | Q16, Q21, Q22, Q24 |
| 18 | Match-winners | ABD 25 PoM awards | Q26 |
| 19 | Fielding matters | 62% caught | Q4 |

---

## Add an insight panel to the dashboard (recommended)
On each Power BI page, add a **Text box** (Insert → Text box) titled **"Key Insights"** with 2–3 one-line insights from this list:
- **Page 1:** Insights 1, 2 and 10
- **Page 2:** Insights 13, 15 and 17
- **Page 3:** Insights 5, 7 and 12

This makes the dashboard **tell a story** rather than just show charts, which is what examiners and interviewers look for.

## Limitations to mention honestly
- **Correlation, not causation:** for example, the 2023 scoring jump *matches the timing of* the Impact Player rule, but other factors (pitches, bats, younger players) may also contribute.
- **Small samples:** 17 finals and 45 Gujarat Titans matches are too few for firm conclusions.
- **Home venue mapping is simplified:** a fixed stadium is used for each team, and seasons played abroad count as away.
- **Players' teams are not tracked:** the dataset doesn't say which team a player played for in each season, so "player value to a team" can't be measured directly.
