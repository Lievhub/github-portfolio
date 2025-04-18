-- Cleaning Data in SQL Queries with Dataset renamed as portfolio for ease
-----------------------------------------------------------------------

SELECT *
FROM portfolio

-----------------------------------------------------------------------
-- Standardise type format (This table had a unsuitable data types)

UPDATE portfolio SET games_missed = '0' WHERE games_missed ='?';

-----------------------------------------------------------------------
-- Some rows in the 'days' table had unwanted fields like "?" they were updated to 0

UPDATE portfolio
SET Days = '0'
WHERE Days !~ '^\d+(\s+days)?$';

-----------------------------------------------------------------------
-- Replace blank cells (white space) with zeros in SQL

UPDATE portfolio
SET Days = '0'
WHERE TRIM(Days) = '' OR Days IS NULL;

UPDATE portfolio
SET games_missed = '0'
WHERE TRIM(games_missed) = '' OR games_missed IS NULL;

-----------------------------------------------------------------------
-- Rows where data is simply incorrect

DELETE  FROM portfolio WHERE season IN ('1909/10','1910/11')