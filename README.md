# cyclist-bike-share-analysis
My first case study in my data journey! This is the capstone project for Coursera's Google Data Analytics Course.
This is the process I went through while completing this case study.

--ASK

1. Business task:
  "The problem we're trying to solve is understanding the similarities and differences between casual riders and annual members, so we can use that information to help convert casual riders into annual members."
2. Key stakeholders:
  "The key stakeholders are Lily Moreno (the marketing director), the Cyclistic executive team, and the marketing analytics team."
3. How insights drive the decision:
  "It unlocks the decision of how to target casual riders with a marketing strategy, based on how their riding behavior compares to that of current annual members."

--PREPARE
1. Data location & organization:
  "The data consists of 12 CSV files representing the past 12 months of Cyclistic trip data, each containing fields including ride_id, rideable_type, started_at, ended_at, start/end station names and IDs, start/end latitude and longitude, and member_casual."
2. ROCCC:
  Reliable — The data comes directly from Cyclistic's own ride-tracking system, capturing every trip taken, not a sample or estimate.
  Original — First-party data, collected directly by Cyclistic through its own bike-share system (not secondhand or scraped from a third party).
  Comprehensive — It includes the key fields needed to answer the business question — ride times, station locations, bike type, and rider type (member vs. casual) — though it's limited to trip-level behavior and doesn't include demographic or payment information.
  Current — Covers the most recent 12 months of ride data, so it reflects up-to-date usage patterns rather than outdated behavior.
  Cited — The data is publicly provided by Motivate International Inc. under their specific license, which is referenced in the case study.
3. Privacy considerations:
  We cannot connect a customers credit card 9nfo to a ride as that is breach of privacy, so we won't know how many times a particular rider has used the service.
4. Data integrity:
  Missing values in start_station_name/start_station_id and end_station_name/end_station_id — likely from dockless or valet-style returns where a bike wasn't returned to an official station.
  Possible inconsistent column structure across the 12 monthly files, if any months used a different schema.
  Potential invalid time values — cases where ended_at is earlier than started_at, which would produce a negative or nonsensical ride_length once calculated in the Process phase.
  Possible duplicate ride_id entries across files, which would inflate ride counts if not caught before merging.

-- PROCESS
  1. I am using DuckDB and SQL to filter and clean the data. I chose these tools as there were millions of rows to process and it would make it faster.
  2. I merged all the files rides from the past year together into one table first. Then proceeded to clean with the following steps:
  --Check to see column types are correct
  SELECT COUNT(*) FROM all_trips;
  DESCRIBE all_trips;

  -- check correct ride_id len, all ride_id are 16 char, 0 rows affected
  SELECT LENGTH(ride_id) AS id_length, COUNT(*) 
  FROM all_trips GROUP BY 1;
  
  -- check for duplicate ride_ids, 395,106 rows affected, will filter them out
  SELECT ride_id, COUNT(*) as DUPS 
  FROM all_trips 
  GROUP BY ride_id 
  HAVING DUPS > 1;
  
  -- check for unexpected values, all values correct, 0 rows affected
  SELECT member_casual, COUNT(*) FROM all_trips GROUP BY 1;
  SELECT rideable_type, COUNT(*) FROM all_trips GROUP BY 1;
  
  -- checks for nulls in columns, 0 rows affected
  SELECT
    COUNT(*) FILTER (WHERE ride_id IS NULL) AS null_id,
    COUNT(*) FILTER (WHERE started_at IS NULL OR ended_at IS NULL) AS null_times,
    COUNT(*) FILTER (WHERE member_casual IS NULL) AS null_rider
  FROM all_trips;
  
  -- checks for inconsistent ride times, 29 rows affected, will filter them out
  SELECT COUNT(*) FROM all_trips WHERE ended_at <= started_at;
  
  -- checks for null values in start or end stations 2,259,222 rows affected,
  -- will keep in the analysis
  SELECT ride_id
  FROM all_trips
  WHERE start_station_id IS NULL OR end_station_id IS NULL
3. Then I made a new table with the cleaned data: 
  -- Creates new table with cleaned data and added columns of ride_length where
  -- ride_length is greater than 1 minute, and no bounds on upper ranges, and 
  -- day_of_week. 946,725 rows were eliminated from table. 5,743,633 remain
  CREATE TABLE trips_clean AS
  SELECT DISTINCT
    TRIM(ride_id) AS ride_id,
    TRIM(rideable_type) AS rideable_type,
    started_at,
    ended_at,
    TRIM(member_casual) AS member_casual,
    printf('%02d:%02d:%02d',
         date_diff('second', started_at, ended_at) // 3600,
         (date_diff('second', started_at, ended_at) % 3600) // 60,
         date_diff('second', started_at, ended_at) % 60) AS ride_length,
    dayname(started_at) AS day_of_week,
  FROM all_trips
  WHERE ride_id IS NOT NULL
    AND started_at IS NOT NULL
    AND date_diff('second', started_at, ended_at) >= 60;
