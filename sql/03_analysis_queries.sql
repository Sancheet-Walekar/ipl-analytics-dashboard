-- =====================================================================
-- 03_analysis_queries.sql: 25 IPL analytics queries
-- Run in MySQL Workbench: put the cursor inside ONE query and press
-- Ctrl + Enter (runs only the query under the cursor).
-- Explanations and expected results: docs/phase4_mysql.md
-- =====================================================================
USE ipl_db;

-- =========================== A. BASICS ===============================

-- Q1. Number of matches in each season              [COUNT, GROUP BY, ORDER BY]
SELECT season, COUNT(*) AS total_matches
FROM matches
GROUP BY season
ORDER BY season;

-- Q2. Overall KPIs: runs, wickets, fours and sixes   [SUM, WHERE]
SELECT SUM(total_runs) AS total_runs,
       SUM(is_wicket)  AS total_wickets,
       SUM(is_four)    AS total_fours,
       SUM(is_six)     AS total_sixes
FROM deliveries
WHERE is_super_over = 0;

-- Q3. All finals and their winners                   [WHERE, ORDER BY]
SELECT season, match_date, team1, team2, winner, result, result_margin, venue
FROM matches
WHERE match_type = 'Final'
ORDER BY season;

-- Q4. Ways batters got out                           [COUNT, WHERE, GROUP BY]
SELECT dismissal_kind, COUNT(*) AS dismissals
FROM deliveries
WHERE is_wicket = 1
GROUP BY dismissal_kind
ORDER BY dismissals DESC;

-- =========================== B. TEAMS ================================

-- Q5. Matches played, won and win % for every team   [LEFT JOIN, CASE, COUNT, SUM]
SELECT t.team_name,
       COUNT(m.match_id)                                         AS played,
       SUM(CASE WHEN m.winner = t.team_name THEN 1 ELSE 0 END)   AS won,
       ROUND(100 * SUM(CASE WHEN m.winner = t.team_name THEN 1 ELSE 0 END)
                 / COUNT(m.match_id), 1)                         AS win_pct
FROM teams t
LEFT JOIN matches m
       ON t.team_name IN (m.team1, m.team2)
GROUP BY t.team_name
ORDER BY won DESC;

-- Q6. IPL titles per team, including teams with 0 titles   [LEFT JOIN, subquery in FROM]
SELECT t.team_name, t.is_active, COUNT(f.match_id) AS titles
FROM teams t
LEFT JOIN (SELECT match_id, winner FROM matches WHERE match_type = 'Final') AS f
       ON f.winner = t.team_name
GROUP BY t.team_name, t.is_active
ORDER BY titles DESC, t.team_name;

-- Q7. Wins per team per season (for a season-trend chart)   [GROUP BY 2 columns]
SELECT season, winner AS team, COUNT(*) AS wins
FROM matches
WHERE winner IS NOT NULL
GROUP BY season, winner
ORDER BY season, wins DESC;

-- Q8. Head-to-head: Mumbai Indians vs Chennai Super Kings   [WHERE with AND/OR]
SELECT winner, COUNT(*) AS wins
FROM matches
WHERE (team1 = 'Mumbai Indians' AND team2 = 'Chennai Super Kings')
   OR (team1 = 'Chennai Super Kings' AND team2 = 'Mumbai Indians')
GROUP BY winner;

-- Q9. Highest team totals in an innings              [INNER JOIN, GROUP BY, LIMIT]
SELECT d.match_id, m.season, d.batting_team, d.bowling_team,
       SUM(d.total_runs) AS innings_total
FROM deliveries d
INNER JOIN matches m ON m.match_id = d.match_id
WHERE d.is_super_over = 0
GROUP BY d.match_id, m.season, d.inning, d.batting_team, d.bowling_team
ORDER BY innings_total DESC
LIMIT 10;

-- ======================= C. TOSS & MATCH RESULTS ======================

-- Q10. Does winning the toss mean winning the match?   [AVG of a 0/1 column]
SELECT ROUND(AVG(toss_winner_won) * 100, 1) AS toss_winner_won_pct
FROM matches
WHERE winner IS NOT NULL;

-- Q11. Toss decision trend per season (bat vs field %)   [CASE inside SUM]
SELECT season,
       SUM(CASE WHEN toss_decision = 'bat'   THEN 1 ELSE 0 END) AS chose_bat,
       SUM(CASE WHEN toss_decision = 'field' THEN 1 ELSE 0 END) AS chose_field,
       ROUND(100 * AVG(toss_decision = 'field'), 0)             AS field_pct
FROM matches
GROUP BY season
ORDER BY season;

-- Q12. Batting first vs chasing: who wins more?       [CASE, GROUP BY]
SELECT CASE WHEN winner = batting_first_team THEN 'Batting first' ELSE 'Chasing' END AS winning_side,
       COUNT(*) AS wins,
       ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM matches
                               WHERE winner IS NOT NULL AND result <> 'tie'), 1) AS pct
FROM matches
WHERE winner IS NOT NULL AND result <> 'tie'
GROUP BY winning_side;

-- Q13. Venues: matches hosted and chasing win % (venues with 30+ matches)   [HAVING]
SELECT venue, city,
       COUNT(*) AS matches,
       ROUND(100 * AVG(winner <> batting_first_team), 1) AS chasing_win_pct
FROM matches
WHERE winner IS NOT NULL AND result <> 'tie'
GROUP BY venue, city
HAVING COUNT(*) >= 30
ORDER BY matches DESC;

-- Q14. Biggest wins by runs                          [WHERE, ORDER BY, LIMIT]
SELECT season, winner, result_margin AS won_by_runs,
       CASE WHEN winner = team1 THEN team2 ELSE team1 END AS loser,
       venue
FROM matches
WHERE result = 'runs'
ORDER BY result_margin DESC
LIMIT 5;

-- ============================ D. BATTING ==============================

-- Q15. Top 10 run scorers                            [SUM, GROUP BY, ORDER BY]
SELECT batter,
       SUM(batsman_runs) AS runs,
       SUM(ball_faced)   AS balls,
       ROUND(100 * SUM(batsman_runs) / SUM(ball_faced), 2) AS strike_rate,
       SUM(is_four) AS fours,
       SUM(is_six)  AS sixes
FROM deliveries
WHERE is_super_over = 0
GROUP BY batter
ORDER BY runs DESC
LIMIT 10;

-- Q16. Best strike rate (minimum 500 balls faced)    [HAVING]
SELECT batter,
       SUM(batsman_runs) AS runs,
       SUM(ball_faced)   AS balls,
       ROUND(100 * SUM(batsman_runs) / SUM(ball_faced), 2) AS strike_rate
FROM deliveries
WHERE is_super_over = 0
GROUP BY batter
HAVING SUM(ball_faced) >= 500
ORDER BY strike_rate DESC
LIMIT 10;

-- Q17. Highest individual scores and centuries        [subquery in FROM, CASE]
SELECT batter, season, match_id, runs, balls,
       CASE WHEN runs >= 100 THEN 'Century'
            WHEN runs >= 50  THEN 'Fifty'
            ELSE 'Below 50' END AS milestone
FROM (SELECT match_id, season, batter,
             SUM(batsman_runs) AS runs, SUM(ball_faced) AS balls
      FROM deliveries
      WHERE is_super_over = 0
      GROUP BY match_id, season, batter) AS innings
ORDER BY runs DESC
LIMIT 10;

-- Q18. Orange Cap: top run scorer of EVERY season     [subquery + INNER JOIN]
SELECT s.season, s.batter, s.runs
FROM (SELECT season, batter, SUM(batsman_runs) AS runs
      FROM deliveries WHERE is_super_over = 0
      GROUP BY season, batter) AS s
INNER JOIN (SELECT season, MAX(runs) AS max_runs
            FROM (SELECT season, batter, SUM(batsman_runs) AS runs
                  FROM deliveries WHERE is_super_over = 0
                  GROUP BY season, batter) AS t
            GROUP BY season) AS best
        ON best.season = s.season AND best.max_runs = s.runs
ORDER BY s.season;

-- Q19. Batter category by strike rate (1000+ balls)   [CASE, HAVING, subquery]
SELECT batting_style, COUNT(*) AS batters
FROM (SELECT batter,
             CASE WHEN 100 * SUM(batsman_runs) / SUM(ball_faced) >= 140 THEN 'Aggressive (SR 140+)'
                  WHEN 100 * SUM(batsman_runs) / SUM(ball_faced) >= 125 THEN 'Balanced (SR 125-140)'
                  ELSE 'Anchor (SR < 125)' END AS batting_style
      FROM deliveries
      WHERE is_super_over = 0
      GROUP BY batter
      HAVING SUM(ball_faced) >= 1000) AS b
GROUP BY batting_style
ORDER BY batters DESC;

-- Q20. Virat Kohli: runs per season                  [WHERE, GROUP BY]
SELECT season, SUM(batsman_runs) AS runs, SUM(ball_faced) AS balls,
       ROUND(100 * SUM(batsman_runs) / SUM(ball_faced), 2) AS strike_rate
FROM deliveries
WHERE batter = 'V Kohli' AND is_super_over = 0
GROUP BY season
ORDER BY season;

-- ============================ E. BOWLING ==============================

-- Q21. Top 10 wicket takers                          [SUM, GROUP BY]
SELECT bowler,
       SUM(is_bowler_wicket) AS wickets,
       ROUND(SUM(is_legal_ball) / 6, 1) AS overs,
       ROUND(SUM(bowler_runs) / (SUM(is_legal_ball) / 6), 2) AS economy
FROM deliveries
WHERE is_super_over = 0
GROUP BY bowler
ORDER BY wickets DESC
LIMIT 10;

-- Q22. Best economy (minimum 1000 legal balls)       [HAVING]
SELECT bowler,
       SUM(is_legal_ball) AS balls,
       SUM(bowler_runs)   AS runs_conceded,
       ROUND(SUM(bowler_runs) / (SUM(is_legal_ball) / 6), 2) AS economy
FROM deliveries
WHERE is_super_over = 0
GROUP BY bowler
HAVING SUM(is_legal_ball) >= 1000
ORDER BY economy
LIMIT 10;

-- Q23. Bowlers whose economy beats the league average (500+ balls)   [subquery in HAVING]
SELECT bowler,
       ROUND(SUM(bowler_runs) / (SUM(is_legal_ball) / 6), 2) AS economy
FROM deliveries
WHERE is_super_over = 0
GROUP BY bowler
HAVING SUM(is_legal_ball) >= 500
   AND SUM(bowler_runs) / (SUM(is_legal_ball) / 6) <
       (SELECT SUM(bowler_runs) / (SUM(is_legal_ball) / 6)
        FROM deliveries WHERE is_super_over = 0)
ORDER BY economy
LIMIT 15;

-- Q24. Death-over specialists (overs 16-20, 300+ balls)   [WHERE, HAVING]
SELECT bowler,
       SUM(is_legal_ball)    AS death_balls,
       SUM(is_bowler_wicket) AS death_wickets,
       ROUND(SUM(bowler_runs) / (SUM(is_legal_ball) / 6), 2) AS death_economy
FROM deliveries
WHERE phase = 'Death' AND is_super_over = 0
GROUP BY bowler
HAVING SUM(is_legal_ball) >= 300
ORDER BY death_economy
LIMIT 10;

-- ======================== F. PHASE & AWARDS ===========================

-- Q25. Run rate and wickets by phase of play          [GROUP BY, AVG-style ratio]
SELECT phase,
       SUM(total_runs) AS runs,
       SUM(is_wicket)  AS wickets,
       ROUND(SUM(total_runs) / (SUM(is_legal_ball) / 6), 2) AS run_rate,
       ROUND(SUM(is_legal_ball) / SUM(is_wicket), 1)        AS balls_per_wicket
FROM deliveries
WHERE is_super_over = 0
GROUP BY phase
ORDER BY FIELD(phase, 'Powerplay', 'Middle', 'Death');

-- Q26. Most Player of the Match awards                [COUNT, WHERE ... IS NOT NULL]
SELECT player_of_match, COUNT(*) AS awards
FROM matches
WHERE player_of_match IS NOT NULL
GROUP BY player_of_match
ORDER BY awards DESC
LIMIT 10;
