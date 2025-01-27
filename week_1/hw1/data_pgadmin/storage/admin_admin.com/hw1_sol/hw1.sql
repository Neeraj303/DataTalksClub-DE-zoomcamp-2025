--------------------------------- Question 3 ------------------------------------
-- Upto 1 mile
SELECT COUNT(1)
FROM (
	SELECT * FROM green_taxi_trips 
	WHERE DATE("lpep_pickup_datetime") >= '2019-10-01'
		AND DATE("lpep_dropoff_datetime") <= '2019-10-31'
		AND "trip_distance" <= 1
) AS foo

-- In between 1 (exclusive) and 3 mile (inclusive)
SELECT COUNT(1)
FROM (
	SELECT * FROM green_taxi_trips 
	WHERE DATE("lpep_pickup_datetime") >= '2019-10-01'
		AND DATE("lpep_dropoff_datetime") <= '2019-10-31'
		AND "trip_distance" > 1 AND "trip_distance" <= 3
) AS foo

-- In between 3 (exclusive) and 7 miles (inclusive)
SELECT COUNT(1)
FROM (
	SELECT * FROM green_taxi_trips 
	WHERE DATE("lpep_pickup_datetime") >= '2019-10-01'
		AND DATE("lpep_dropoff_datetime") <= '2019-10-31'
		AND "trip_distance" > 3 AND "trip_distance" <= 7
) AS foo


-- In between 7 (exclusive) and 10 miles (inclusive)
SELECT COUNT(1)
FROM (
	SELECT * FROM green_taxi_trips 
	WHERE DATE("lpep_pickup_datetime") >= '2019-10-01'
		AND DATE("lpep_dropoff_datetime") <= '2019-10-31'
		AND "trip_distance" > 7 AND "trip_distance" <= 10
) AS foo

-- Over 10 miles
SELECT COUNT(1)
FROM (
	SELECT * FROM green_taxi_trips 
	WHERE DATE("lpep_pickup_datetime") >= '2019-10-01'
		AND DATE("lpep_dropoff_datetime") <= '2019-10-31'
		AND "trip_distance" > 10
) AS foo

--------------------------------- Question 4 ------------------------------------
SELECT * FROM green_taxi_trips
SELECT * FROM taxi_zone

-- cte to find max trip distance for each day
WITH cte AS (
	SELECT 
		DATE(lpep_pickup_datetime) AS date,
		MAX(trip_distance) AS max_distance
	FROM 
		green_taxi_trips
	GROUP BY DATE(lpep_pickup_datetime)
)

-- to find the max trip distance amoung the all the dates
SELECT date
FROM cte
WHERE max_distance = (SELECT MAX(max_distance) FROM cte)

---------------------------------- Question 5 -----------------------------------
SELECT * FROM green_taxi_trips

WITH cte AS (
	SELECT 
		SUM("total_amount"),
		"PULocationID"
	FROM green_taxi_trips
	WHERE DATE("lpep_pickup_datetime") = '2019-10-18' 
		-- AND DATE("lpep_dropoff_datetime") = '2019-10-18'
	GROUP BY 2
	
)

-- to check pickup locationid with more than 13000 total amount
-- SELECT *
-- FROM cte
-- WHERE sum > 13000
-- ORDER BY sum DESC

-- to get the name of the zones
SELECT "Zone"
FROM taxi_zone
WHERE "LocationID" IN (
	SELECT "PULocationID"
	FROM cte
	WHERE sum > 13000
	ORDER BY sum DESC	
)

-------------------------------- Question 6 ------------------------------------
SELECT "LocationID" FROM taxi_zone WHERE "Zone" = 'East Harlem North'

WITH cte AS (
	SELECT DATE("lpep_pickup_datetime") AS date, "DOLocationID", "tip_amount"
	FROM green_taxi_trips
	WHERE DATE("lpep_pickup_datetime") >= '2019-10-01' 
		AND DATE("lpep_pickup_datetime") <= '2019-10-31'
		AND "PULocationID" = (SELECT "LocationID" FROM taxi_zone WHERE "Zone" = 'East Harlem North')
)

SELECT "Zone" FROM taxi_zone
WHERE "LocationID" = (
SELECT "DOLocationID" FROM cte 
ORDER BY "tip_amount" DESC 
LIMIT 1)

