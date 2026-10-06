#This is a log of all cleaning/processing of data for this project

###--Loading all csv files into separate tables.
CREATE OR REPLACE TABLE Aug_2025 AS
FROM
  "/Users/enzomendoza/Documents/divvy_trip_data_Aug2025_to_Aug2026/copy data/202508-divvy-tripdata.csv";

CREATE OR REPLACE TABLE Sep_2025 AS
FROM
  "/Users/enzomendoza/Documents/divvy_trip_data_Aug2025_to_Aug2026/copy data/202509-divvy-tripdata.csv";

CREATE OR REPLACE TABLE Oct_2025 AS
FROM
  "/Users/enzomendoza/Documents/divvy_trip_data_Aug2025_to_Aug2026/copy data/202510-divvy-tripdata.csv";

CREATE OR REPLACE TABLE Nov_2025 AS
FROM
  "/Users/enzomendoza/Documents/divvy_trip_data_Aug2025_to_Aug2026/copy data/202511-divvy-tripdata.csv";

CREATE OR REPLACE TABLE Dec_2025 AS
FROM
  "/Users/enzomendoza/Documents/divvy_trip_data_Aug2025_to_Aug2026/copy data/202512-divvy-tripdata.csv";

CREATE OR REPLACE TABLE Feb_2026 AS
FROM
  "/Users/enzomendoza/Documents/divvy_trip_data_Aug2025_to_Aug2026/copy data/202602-divvy-tripdata.csv";

CREATE OR REPLACE TABLE March_2026 AS
FROM
  "/Users/enzomendoza/Documents/divvy_trip_data_Aug2025_to_Aug2026/copy data/202603-divvy-tripdata.csv";

CREATE OR REPLACE TABLE April_2026 AS
FROM
  "/Users/enzomendoza/Documents/divvy_trip_data_Aug2025_to_Aug2026/copy data/202604-divvy-tripdata.csv";

CREATE OR REPLACE TABLE May_2026 AS
FROM
  "/Users/enzomendoza/Documents/divvy_trip_data_Aug2025_to_Aug2026/copy data/202605-divvy-tripdata.csv";

CREATE OR REPLACE TABLE June_2026 AS
FROM
  "/Users/enzomendoza/Documents/divvy_trip_data_Aug2025_to_Aug2026/copy data/202606-divvy-tripdata.csv";

CREATE OR REPLACE TABLE July_2026 AS
FROM
  "/Users/enzomendoza/Documents/divvy_trip_data_Aug2025_to_Aug2026/copy data/202607-divvy-tripdata.csv";

CREATE OR REPLACE TABLE Aug_2026 AS
FROM
  "/Users/enzomendoza/Documents/divvy_trip_data_Aug2025_to_Aug2026/copy data/202508-divvy-tripdata.csv";

###-- Appends all rows of each table into one table all_trips
CREATE TABLE all_trips AS
SELECT * FROM Aug_2025
UNION ALL
SELECT * FROM Sep_2025
UNION ALL
SELECT * FROM Oct_2025
UNION ALL
SELECT * FROM Nov_2025
UNION ALL
SELECT * FROM Dec_2025
UNION ALL
SELECT * FROM Feb_2026
UNION ALL
SELECT * FROM March_2026
UNION ALL
SELECT * FROM April_2026
UNION ALL
SELECT * FROM May_2026
UNION ALL
SELECT * FROM June_2026
UNION ALL
SELECT * FROM July_2026
UNION ALL
SELECT * FROM Aug_2026;

###-- Cleaned up tables no longer needed
DROP TABLE IF EXISTS Aug2025;
DROP TABLE IF EXISTS Aug_2025;
DROP TABLE IF EXISTS Sep_2025;
DROP TABLE IF EXISTS Oct_2025;
DROP TABLE IF EXISTS Nov_2025;
DROP TABLE IF EXISTS Dec_2025;
DROP TABLE IF EXISTS Feb_2026;
DROP TABLE IF EXISTS March_2026;
DROP TABLE IF EXISTS April_2026;
DROP TABLE IF EXISTS May_2026;
DROP TABLE IF EXISTS June_2026;
DROP TABLE IF EXISTS July_2026;
DROP TABLE IF EXISTS Aug_2026;

##-- CLEANING STARTS HERE

###-- Check to see column types are correct
SELECT COUNT(*) FROM all_trips;
DESCRIBE all_trips;

###-- check correct ride_id len, all ride_id are 16 char, 0 rows affected
SELECT LENGTH(ride_id) AS id_length, COUNT(*) 
FROM all_trips GROUP BY 1;

-- check for duplicate ride_ids, 395,106 rows affected, will filter them out
SELECT ride_id, COUNT(*) as DUPS 
FROM all_trips 
GROUP BY ride_id 
HAVING DUPS > 1;

###-- check for unexpected values, all values correct, 0 rows affected
SELECT member_casual, COUNT(*) FROM all_trips GROUP BY 1;
SELECT rideable_type, COUNT(*) FROM all_trips GROUP BY 1;

###-- checks for nulls in columns, 0 rows affected
SELECT
  COUNT(*) FILTER (WHERE ride_id IS NULL) AS null_id,
  COUNT(*) FILTER (WHERE started_at IS NULL OR ended_at IS NULL) AS null_times,
  COUNT(*) FILTER (WHERE member_casual IS NULL) AS null_rider
FROM all_trips;

###-- checks for inconsistent ride times, 29 rows affected, will filter them out
SELECT COUNT(*) FROM all_trips WHERE ended_at <= started_at;

###-- checks for null values in start or end stations 2,259,222 rows affected, will keep in the analysis
SELECT ride_id
FROM all_trips
WHERE start_station_id IS NULL OR end_station_id IS NULL

###-- Creates new table with cleaned data and added columns of ride_length where
###-- ride_length is greater than 1 minute and less than 24 hours, and no bounds on upper ranges, and 
###-- day_of_week. 946,725 rows were eliminated from table. 5,737,350 remain
CREATE OR REPLACE TABLE trips_clean AS
SELECT DISTINCT
  TRIM(ride_id) AS ride_id,
  TRIM(rideable_type) AS rideable_type,
  started_at,
  ended_at,
  TRIM(start_station_name) AS start_station_name,
  TRIM(start_station_id) AS start_station_id,
  TRIM(end_station_name) AS end_station_name,
  TRIM(end_station_id) AS end_station_id,
  start_lat,
  start_lng,
  end_lat,
  end_lng,
  TRIM(member_casual) AS member_casual,
  printf('%02d:%02d:%02d',
       date_diff('second', started_at, ended_at) // 3600,
       (date_diff('second', started_at, ended_at) % 3600) // 60,
       date_diff('second', started_at, ended_at) % 60) AS ride_length,
  dayname(started_at) AS day_of_week,
FROM all_trips
WHERE ride_id IS NOT NULL
  AND started_at IS NOT NULL
  AND date_diff('second', started_at, ended_at) BETWEEN 61 AND 86400;

##-- PROCESSING STARTS HERE

###-- Creates table for rides by weekday, groups by casual and members
CREATE OR REPLACE TABLE summary_weekday_total_rides AS
SELECT member_casual,
       dayname(started_at) AS weekday,
       COUNT(*) AS rides
FROM trips_clean
GROUP BY 1, 2
ORDER BY weekday, rides;

###-- Creates table for rides by month, groups by casual and members
CREATE OR REPLACE TABLE summary_monthly_total_rides AS
SELECT member_casual,
       monthname(started_at) AS month,
       COUNT(*) AS rides
FROM trips_clean
GROUP BY 1, 2
ORDER BY month;

###-- Creates table for rides by season (meteorological seasons, Northern Hemisphere)
CREATE OR REPLACE TABLE summary_seasons_total_rides AS 
SELECT member_casual,
       CASE WHEN month(started_at) IN (12, 1, 2) THEN 'Winter'
            WHEN month(started_at) IN (3, 4, 5)  THEN 'Spring'
            WHEN month(started_at) IN (6, 7, 8)  THEN 'Summer'
            ELSE 'Fall' END AS season,
       COUNT(*) AS rides
FROM trips_clean
GROUP BY 1, 2
ORDER BY 1, rides DESC;

-- Creates table for total rides and % split, groups by casual and members
CREATE OR REPLACE TABLE summary_total_rides_split AS 
SELECT member_casual,
       COUNT(*) AS rides,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_rides
FROM trips_clean
GROUP BY member_casual;

###-- Creates table for average, median, and max by rider type
CREATE OR REPLACE TABLE mean_max_median_trips AS
SELECT member_casual,
       ROUND(AVG(ride_length), 2)    AS avg_minutes,
       ROUND(MEDIAN(ride_length), 2) AS median_minutes,
       ROUND(MAX(ride_length), 2)    AS max_minutes
FROM trips_clean
GROUP BY member_casual;

###-- Creates table for avg ride length by weekday
CREATE OR REPLACE TABLE summary_ride_length_weekday AS
SELECT member_casual,
       dayname(started_at) AS weekday,
       ROUND(AVG(ride_length), 2) AS avg_ride_length
FROM trips_clean
GROUP BY 1, 2, dayofweek(started_at)
ORDER BY 1, dayofweek(started_at);

###-- Creates table for average ride length by month
CREATE OR REPLACE TABLE avg_ride_length_monthly AS
SELECT member_casual,
       strftime(started_at, '%Y-%m') AS year_month,
       ROUND(AVG(ride_length), 2)    AS avg_ride_minutes,
       ROUND(MEDIAN(ride_length), 2) AS median_ride_minutes
FROM trips_clean
WHERE month(started_at) <> 1
GROUP BY 1, 2
ORDER BY 2, 1;

###-- Creates table for total rides by day of week (Sunday first)
CREATE OR REPLACE TABLE total_rides_by_weekday AS
SELECT member_casual,
       dayname(started_at) AS weekday,
       COUNT(*) AS rides
FROM trips_clean
GROUP BY 1, 2, dayofweek(started_at)
ORDER BY 1, dayofweek(started_at);

###-- Creates table for total rides by hour of day
CREATE OR REPLACE TABLE total_rides_by_hour AS
SELECT member_casual,
       hour(started_at) AS hour_of_day,
       COUNT(*) AS rides
FROM trips_clean
GROUP BY 1, 2
ORDER BY 1, 2;

###-- Creates table for top 10 start stations per rider type
CREATE OR REPLACE TABLE top10_rides_per_start_station AS
SELECT member_casual, start_station_name, COUNT(*) AS rides
FROM trips_clean
WHERE start_station_name IS NOT NULL AND start_station_name <> ''
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (PARTITION BY member_casual ORDER BY COUNT(*) DESC) <= 10
ORDER BY 1, rides DESC

###-- Creates table for top 10 end stations per rider type
CREATE OR REPLACE TABLE top10_rides_per_end_station AS
SELECT member_casual, end_station_name, COUNT(*) AS rides
FROM trips_clean
WHERE end_station_name IS NOT NULL AND end_station_name <> ''
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (PARTITION BY member_casual ORDER BY COUNT(*) DESC) <= 10
ORDER BY 1, rides DESC;

###-- Creates table for total round trips (same start and end station)
CREATE OR REPLACE TABLE summary_round_trips AS
SELECT member_casual,
       COUNT(*) FILTER (WHERE start_station_name = end_station_name) AS round_trips,
       ROUND(COUNT(*) FILTER (WHERE start_station_name = end_station_name) * 100.0 / COUNT(*), 1) AS pct_round_trips
FROM trips_clean
WHERE start_station_name IS NOT NULL AND end_station_name IS NOT NULL
GROUP BY member_casual;

###-- Exports all tables file directory
EXPORT DATABASE '/Users/enzomendoza/Documents/database/' (FORMAT CSV, HEADER);
