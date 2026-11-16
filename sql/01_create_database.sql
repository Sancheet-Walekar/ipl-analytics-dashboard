-- =====================================================================
-- 01_create_database.sql
-- Creates the ipl_db database, its 3 tables, keys and indexes.
-- Run in: MySQL Workbench (open the file, click the lightning bolt ⚡)
--      or: mysql -u root -p < sql/01_create_database.sql
--
-- WARNING: running this again DELETES the existing tables and their data.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS ipl_db
    CHARACTER SET utf8mb4            -- supports every language and symbol
    COLLATE utf8mb4_unicode_ci;      -- case-insensitive text comparison

USE ipl_db;

-- Drop the child table first: deliveries depends on matches, and matches depends on teams
DROP TABLE IF EXISTS deliveries;
DROP TABLE IF EXISTS matches;
DROP TABLE IF EXISTS teams;

-- ---------------------------------------------------------------------
-- 1. teams: one row per IPL franchise (a lookup / master table)
-- ---------------------------------------------------------------------
CREATE TABLE teams (
    team_name   VARCHAR(50)  NOT NULL,
    short_name  VARCHAR(5)   NOT NULL,
    is_active   TINYINT      NOT NULL DEFAULT 1,     -- 1 = still plays in the IPL, 0 = defunct
    PRIMARY KEY (team_name),
    UNIQUE KEY uq_short_name (short_name)
);

INSERT INTO teams (team_name, short_name, is_active) VALUES
    ('Chennai Super Kings',         'CSK',  1),
    ('Delhi Capitals',              'DC',   1),
    ('Gujarat Titans',              'GT',   1),
    ('Kolkata Knight Riders',       'KKR',  1),
    ('Lucknow Super Giants',        'LSG',  1),
    ('Mumbai Indians',              'MI',   1),
    ('Punjab Kings',                'PBKS', 1),
    ('Rajasthan Royals',            'RR',   1),
    ('Royal Challengers Bengaluru', 'RCB',  1),
    ('Sunrisers Hyderabad',         'SRH',  1),
    ('Deccan Chargers',             'DEC',  0),
    ('Gujarat Lions',               'GL',   0),
    ('Kochi Tuskers Kerala',        'KTK',  0),
    ('Pune Warriors',               'PWI',  0),
    ('Rising Pune Supergiant',      'RPS',  0);

-- ---------------------------------------------------------------------
-- 2. matches: one row per match  (from matches_cleaned.csv)
-- ---------------------------------------------------------------------
CREATE TABLE matches (
    match_id            INT           NOT NULL,      -- 'id' in the CSV
    season              SMALLINT      NOT NULL,
    city                VARCHAR(50),
    match_date          DATE          NOT NULL,      -- 'date' in the CSV
    match_type          VARCHAR(30)   NOT NULL,
    player_of_match     VARCHAR(60),                 -- NULL for no-result matches
    venue               VARCHAR(100)  NOT NULL,
    team1               VARCHAR(50)   NOT NULL,
    team2               VARCHAR(50)   NOT NULL,
    toss_winner         VARCHAR(50)   NOT NULL,
    toss_decision       VARCHAR(5)    NOT NULL,
    winner              VARCHAR(50),                 -- NULL for no-result matches
    result              VARCHAR(15)   NOT NULL,      -- runs / wickets / tie / no result
    result_margin       SMALLINT,                    -- NULL for tie / no result
    target_runs         SMALLINT,
    target_overs        DECIMAL(4,1),                -- e.g. 9.2 in rain-shortened games
    super_over          CHAR(1)       NOT NULL,      -- Y / N
    method              VARCHAR(10)   NOT NULL,      -- Normal / D/L
    umpire1             VARCHAR(60),
    umpire2             VARCHAR(60),
    toss_winner_won     TINYINT,                     -- 1 / 0, NULL for no result
    batting_first_team  VARCHAR(50)   NOT NULL,
    is_playoff          TINYINT       NOT NULL,      -- 1 = playoff match

    PRIMARY KEY (match_id),

    -- Every team column must contain a team that exists in the teams table
    CONSTRAINT fk_matches_team1        FOREIGN KEY (team1)              REFERENCES teams(team_name),
    CONSTRAINT fk_matches_team2        FOREIGN KEY (team2)              REFERENCES teams(team_name),
    CONSTRAINT fk_matches_toss_winner  FOREIGN KEY (toss_winner)        REFERENCES teams(team_name),
    CONSTRAINT fk_matches_winner       FOREIGN KEY (winner)             REFERENCES teams(team_name),
    CONSTRAINT fk_matches_bat_first    FOREIGN KEY (batting_first_team) REFERENCES teams(team_name),

    -- CHECK constraints: MySQL rejects rows that break these rules
    CONSTRAINT chk_toss_decision CHECK (toss_decision IN ('bat', 'field')),
    CONSTRAINT chk_teams_differ  CHECK (team1 <> team2),

    INDEX idx_matches_season (season),
    INDEX idx_matches_venue  (venue)
);

-- ---------------------------------------------------------------------
-- 3. deliveries: one row per ball  (from deliveries_cleaned.csv)
-- ---------------------------------------------------------------------
CREATE TABLE deliveries (
    delivery_id       INT          NOT NULL AUTO_INCREMENT,  -- MySQL numbers each ball 1, 2, 3 ...
    match_id          INT          NOT NULL,
    inning            TINYINT      NOT NULL,     -- 1, 2 (3+ = Super Over)
    batting_team      VARCHAR(50)  NOT NULL,
    bowling_team      VARCHAR(50)  NOT NULL,
    over_index        TINYINT      NOT NULL,     -- 'over' in the CSV (0-19). OVER is a reserved word in MySQL
    ball              TINYINT      NOT NULL,
    batter            VARCHAR(60)  NOT NULL,
    bowler            VARCHAR(60)  NOT NULL,
    non_striker       VARCHAR(60)  NOT NULL,
    batsman_runs      TINYINT      NOT NULL,
    extra_runs        TINYINT      NOT NULL,
    total_runs        TINYINT      NOT NULL,
    extras_type       VARCHAR(10),               -- NULL = not an extra
    is_wicket         TINYINT      NOT NULL,
    player_dismissed  VARCHAR(60),
    dismissal_kind    VARCHAR(30),
    fielder           VARCHAR(100),
    season            SMALLINT     NOT NULL,
    over_number       TINYINT      NOT NULL,     -- 1-20
    phase             VARCHAR(10)  NOT NULL,     -- Powerplay / Middle / Death
    is_super_over     TINYINT      NOT NULL,
    is_four           TINYINT      NOT NULL,
    is_six            TINYINT      NOT NULL,
    is_dot_ball       TINYINT      NOT NULL,
    ball_faced        TINYINT      NOT NULL,
    is_legal_ball     TINYINT      NOT NULL,
    bowler_runs       TINYINT      NOT NULL,
    is_bowler_wicket  TINYINT      NOT NULL,

    PRIMARY KEY (delivery_id),

    -- One match -> many deliveries
    CONSTRAINT fk_deliveries_match   FOREIGN KEY (match_id)     REFERENCES matches(match_id),
    CONSTRAINT fk_deliveries_batting FOREIGN KEY (batting_team) REFERENCES teams(team_name),
    CONSTRAINT fk_deliveries_bowling FOREIGN KEY (bowling_team) REFERENCES teams(team_name),

    CONSTRAINT chk_batsman_runs CHECK (batsman_runs BETWEEN 0 AND 6),

    -- Indexes make WHERE / GROUP BY on these columns much faster
    INDEX idx_deliveries_batter (batter),
    INDEX idx_deliveries_bowler (bowler),
    INDEX idx_deliveries_season (season)
);

-- Check: should list deliveries, matches, teams
SHOW TABLES;
SELECT COUNT(*) AS teams_loaded FROM teams;   -- expected: 15
