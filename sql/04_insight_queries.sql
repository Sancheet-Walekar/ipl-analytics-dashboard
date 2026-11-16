-- =====================================================================
-- 04_insight_queries.sql: extra queries used for the Phase 6 insights
-- (the other insights use queries Q1-Q26 in 03_analysis_queries.sql)
-- Run one query at a time.
-- =====================================================================
USE ipl_db;

-- Q27. Scoring trend: average first-innings total and run rate per season
SELECT i.season,
       ROUND(AVG(i.runs), 1) AS avg_first_innings_total,
       ROUND(SUM(i.runs) / (SUM(i.legal_balls) / 6), 2) AS run_rate
FROM (SELECT match_id, season,
             SUM(total_runs) AS runs, SUM(is_legal_ball) AS legal_balls
      FROM deliveries
      WHERE inning = 1
      GROUP BY match_id, season) AS i
GROUP BY i.season
ORDER BY i.season;

-- Q28. Boundary share: % of runs that came from 4s and 6s, and sixes per match, per season
SELECT season,
       ROUND(100 * SUM(CASE WHEN batsman_runs IN (4, 6) THEN batsman_runs ELSE 0 END)
                 / SUM(total_runs), 1)                            AS boundary_run_pct,
       ROUND(SUM(is_six) / COUNT(DISTINCT match_id), 1)           AS sixes_per_match
FROM deliveries
WHERE is_super_over = 0
GROUP BY season
ORDER BY season;

-- Q29. After winning the toss, which choice wins more often: bat or field?
SELECT toss_decision,
       COUNT(*)                                   AS matches,
       ROUND(100 * AVG(toss_winner_won), 1)       AS toss_winner_win_pct
FROM matches
WHERE winner IS NOT NULL
GROUP BY toss_decision;

-- Q30. Home advantage for the 4 oldest franchises at their home grounds
SELECT team,
       SUM(is_home)                                                        AS home_matches,
       ROUND(100 * SUM(is_home * won) / SUM(is_home), 1)                   AS home_win_pct,
       SUM(1 - is_home)                                                    AS away_matches,
       ROUND(100 * SUM((1 - is_home) * won) / SUM(1 - is_home), 1)         AS away_win_pct
FROM (SELECT t.team,
             CASE WHEN (t.team = 'Mumbai Indians'              AND m.venue = 'Wankhede Stadium')
                    OR (t.team = 'Chennai Super Kings'         AND m.venue = 'MA Chidambaram Stadium')
                    OR (t.team = 'Kolkata Knight Riders'       AND m.venue = 'Eden Gardens')
                    OR (t.team = 'Royal Challengers Bengaluru' AND m.venue = 'M Chinnaswamy Stadium')
                  THEN 1 ELSE 0 END                         AS is_home,
             CASE WHEN m.winner = t.team THEN 1 ELSE 0 END  AS won
      FROM matches m
      INNER JOIN (SELECT 'Mumbai Indians' AS team UNION ALL SELECT 'Chennai Super Kings'
                  UNION ALL SELECT 'Kolkata Knight Riders' UNION ALL SELECT 'Royal Challengers Bengaluru') AS t
              ON t.team IN (m.team1, m.team2)
      WHERE m.winner IS NOT NULL) AS x
GROUP BY team
ORDER BY home_win_pct DESC;

-- Q31. How many matches are close finishes?
--      Close = won by 10 runs or fewer, won by 2 wickets or fewer, or a tie
SELECT CASE WHEN result = 'tie' THEN 'Tie'
            WHEN result = 'runs'    AND result_margin <= 10 THEN 'Close (<= 10 runs)'
            WHEN result = 'wickets' AND result_margin <= 2  THEN 'Close (<= 2 wickets)'
            ELSE 'Comfortable' END AS finish_type,
       COUNT(*) AS matches,
       ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM matches WHERE result <> 'no result'), 1) AS pct
FROM matches
WHERE result <> 'no result'
GROUP BY finish_type
ORDER BY matches DESC;

-- Q32. Finals: did the team batting first or chasing win?
SELECT CASE WHEN winner = batting_first_team THEN 'Batting first' ELSE 'Chasing' END AS final_won_by,
       COUNT(*) AS finals
FROM matches
WHERE match_type = 'Final'
GROUP BY final_won_by;

-- Q33. Playoff record: teams that win the big matches (Qualifiers, Eliminators, Finals)
SELECT t.team_name,
       COUNT(m.match_id)                                       AS playoff_matches,
       SUM(CASE WHEN m.winner = t.team_name THEN 1 ELSE 0 END) AS playoff_wins
FROM teams t
INNER JOIN matches m
        ON t.team_name IN (m.team1, m.team2)
WHERE m.is_playoff = 1
GROUP BY t.team_name
HAVING COUNT(m.match_id) >= 5
ORDER BY playoff_wins DESC;
