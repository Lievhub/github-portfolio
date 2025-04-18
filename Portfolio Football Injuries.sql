/*
Football injuries Data Exploration 

Aim: To find out whether football injuries increase overtime and whether it's casuality is as a result of increase of football games.

Goal: To recommend to FIFA and other football bodies that there should be less games being played by players

Skills used: CTE's, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- Tracking the count of the injuries per season overtime 

SELECT Season, COUNT(*) AS injury
FROM portfolio
GROUP BY Season
ORDER BY Season;

-- Keeps notes on the most common injury types and the average days the players were unavailable for

SELECT Injury, 
       COUNT(*) AS count, 
       AVG(
         CASE 
           WHEN Days ~ '^\d+' THEN CAST(SPLIT_PART(Days, ' ', 1) AS INTEGER)
           ELSE NULL 
         END
       ) AS avg_days_out
FROM portfolio
WHERE season NOT IN ('1909/10', '1910/11')
GROUP BY Injury
ORDER BY count DESC
LIMIT 15;

-- Games missed per season 

SELECT Season, player_name, 
       SUM(
         CASE 
           WHEN games_missed ~ '^\d+$' THEN CAST(games_missed AS INTEGER)
           ELSE 0 
         END
       ) AS total_games_missed
FROM portfolio
GROUP BY Season, player_name
ORDER BY 
  CASE 
    WHEN Season = '94/95' THEN 0 /* This was necessary because the the larger numbers were placed at the top although they
	                               were older in time */
	WHEN Season = '96/97' THEN 1
    WHEN Season = '98/99' THEN 2
    WHEN Season = '99/00' THEN 3
    ELSE 9999 -- All other seasons will be ordered after the specific ones
  END ASC,
  Season ASC;  -- Secondary sort by Season in ascending order for the rest

-- Most Injury-Prone Seasons 

SELECT Season,
       COUNT(*) AS total_injuries,
       AVG(
         CASE 
           WHEN Days ~ '^\d+' THEN CAST(SPLIT_PART(Days, ' ', 1) AS INTEGER)
           ELSE NULL 
         END
       ) AS avg_duration,
       SUM(
         CASE 
           WHEN Days ~ '^\d+' THEN CAST(SPLIT_PART(Days, ' ', 1) AS INTEGER)
           ELSE 0 
         END
       ) AS total_days_lost
FROM portfolio
GROUP BY Season
ORDER BY avg_duration DESC
LIMIT 10;

-- Severity index of the different injuries 

SELECT player_name,
       COUNT(*) AS injury_count,
       AVG(
         CASE 
           WHEN Days ~ '^\d+' THEN CAST(SPLIT_PART(Days, ' ', 1) AS INTEGER)
           ELSE NULL 
         END
       ) AS avg_days_out,
       ROUND(
         COUNT(*) * AVG(
           CASE 
             WHEN Days ~ '^\d+' THEN CAST(SPLIT_PART(Days, ' ', 1) AS INTEGER)
             ELSE NULL 
           END
         ), 2
       ) AS severity_index
FROM portfolio
GROUP BY player_name
HAVING COUNT(*) > 5
ORDER BY severity_index DESC
LIMIT 20;

-- Creating View to store data for later visualisations

CREATE VIEW games_missed_per_season AS
SELECT 
    season,
    SUM(games_missed::INTEGER) AS total_games_missed
FROM portfolio
GROUP BY season
ORDER BY season;

-- Creating View to store data for later visualisations

CREATE VIEW avg_injury_duration_per_season AS
SELECT 
    season,
    AVG(REPLACE(days, ' days', '')::INTEGER) AS avg_duration
FROM portfolio
WHERE days ~ '^\d+ days$'
GROUP BY season
ORDER BY season;

-- Creating View to store data for later visualisations

CREATE VIEW unique_players_per_season AS
SELECT 
    season,
    COUNT(DISTINCT player_id) AS unique_players
FROM portfolio
GROUP BY season
ORDER BY season;

-- Using CTE to perform calculations and make code more readeable 

WITH cleaned_data AS (
    SELECT
        season,
        REPLACE(days, ' days', '')::INTEGER AS injury_days,
        games_missed::INTEGER AS games_missed
    FROM portfolio
    WHERE 
        days ~ '^\d+ days$'
        AND games_missed ~ '^\d+$'
),

season_stats AS (
    SELECT
        season,
        COUNT(*) AS total_injuries,
        AVG(injury_days) AS avg_injury_days,
        SUM(games_missed) AS total_games_missed
    FROM cleaned_data
    GROUP BY season
),

avg_injuries_overall AS (
    SELECT AVG(total_injuries) AS avg_injuries
    FROM season_stats
)

SELECT 
    s.season,
    s.total_injuries,
    s.avg_injury_days,
    s.total_games_missed
FROM season_stats s
JOIN avg_injuries_overall a ON TRUE
WHERE s.total_injuries > a.avg_injuries
ORDER BY s.season;

-- Ranking the total injuries per season 

WITH player_injury_counts AS (
    SELECT 
        player_name,
        season,
        COUNT(*) AS total_injuries
    FROM portfolio
    GROUP BY player_name, season
)
SELECT 
    player_name,
    season,
    total_injuries,
    RANK() OVER (PARTITION BY season ORDER BY total_injuries DESC) AS rank_in_season
FROM player_injury_counts;