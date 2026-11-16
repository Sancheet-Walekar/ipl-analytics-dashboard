-- =====================================================================
-- 02_load_data.sql  (ALTERNATIVE to scripts/load_to_mysql.py)
-- Loads the cleaned CSVs with MySQL's fast LOAD DATA command (well under a minute).
--
-- One-time setup:
--   1. In a Workbench query tab run:   SET GLOBAL local_infile = 1;
--   2. Workbench: Database > Manage Connections > your connection > Advanced tab
--      > in "Others" add the line:  OPT_LOCAL_INFILE=1   > Close, then reconnect.
--   3. Replace C:/Users/YourName/ipl-analytics-dashboard below with YOUR project path.
--      Use forward slashes / even on Windows.
--   4. Workbench: Edit > Preferences > SQL Editor > set "DBMS connection read
--      timeout" to 600 seconds (the deliveries load can take longer than 30 s).
-- =====================================================================

USE ipl_db;

-- Workbench's "safe update mode" blocks DELETE without WHERE; switch it off for this session
SET SQL_SAFE_UPDATES = 0;

-- Empty the tables first (child table first) so that re-running does not duplicate rows
DELETE FROM deliveries;
DELETE FROM matches;

-- ---------------- matches ----------------
LOAD DATA LOCAL INFILE 'C:/Users/YourName/ipl-analytics-dashboard/data/cleaned/matches_cleaned.csv'
INTO TABLE matches
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES                                   -- skip the header row
(match_id, season, @city, match_date, match_type, @player_of_match, venue, team1, team2,
 toss_winner, toss_decision, @winner, result, @result_margin, @target_runs, @target_overs,
 super_over, method, @umpire1, @umpire2, @toss_winner_won, batting_first_team, is_playoff)
SET                                              -- NULLIF('', '') turns an empty cell into NULL
    city            = NULLIF(@city, ''),
    player_of_match = NULLIF(@player_of_match, ''),
    winner          = NULLIF(@winner, ''),
    result_margin   = NULLIF(@result_margin, ''),
    target_runs     = NULLIF(@target_runs, ''),
    target_overs    = NULLIF(@target_overs, ''),
    umpire1         = NULLIF(@umpire1, ''),
    umpire2         = NULLIF(@umpire2, ''),
    toss_winner_won = NULLIF(@toss_winner_won, '');

-- ---------------- deliveries ----------------
LOAD DATA LOCAL INFILE 'C:/Users/YourName/ipl-analytics-dashboard/data/cleaned/deliveries_cleaned.csv'
INTO TABLE deliveries
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(match_id, inning, batting_team, bowling_team, over_index, ball, batter, bowler, non_striker,
 batsman_runs, extra_runs, total_runs, @extras_type, is_wicket, @player_dismissed, @dismissal_kind,
 @fielder, season, over_number, phase, is_super_over, is_four, is_six, is_dot_ball, ball_faced,
 is_legal_ball, bowler_runs, is_bowler_wicket)
SET
    extras_type      = NULLIF(@extras_type, ''),
    player_dismissed = NULLIF(@player_dismissed, ''),
    dismissal_kind   = NULLIF(@dismissal_kind, ''),
    fielder          = NULLIF(@fielder, '');

-- Verify: expected 15 / 1095 / 260920
SELECT (SELECT COUNT(*) FROM teams)      AS teams,
       (SELECT COUNT(*) FROM matches)    AS matches,
       (SELECT COUNT(*) FROM deliveries) AS deliveries;
