# Solution to [Week 1 Homework](../homework.md)

## Question 1. Understanding docker first run 

Run docker with the `python:3.12.8` image in an interactive mode, use the entrypoint `bash`.

What's the version of `pip` in the image?

- 24.3.1
- 24.2.1
- 23.3.1
- 23.2.1

## Answer 1

```bash
# first create a container
docker run -it python:3.12.8 bash

# then check the version of pip
pip --version
```
**Answer**
a) 24.3.1

## Question 2. Understanding Docker networking and docker-compose

Given the following `docker-compose.yaml`, what is the `hostname` and `port` that **pgadmin** should use to connect to the postgres database?

```yaml
services:
  db: # service name
    container_name: postgres
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: 'postgres'
      POSTGRES_PASSWORD: 'postgres'
      POSTGRES_DB: 'ny_taxi'
    ports: # port mapping host machine:container
      - '5433:5432'
    volumes:
      - vol-pgdata:/var/lib/postgresql/data

  pgadmin:
    container_name: pgadmin
    image: dpage/pgadmin4:latest
    environment:
      PGADMIN_DEFAULT_EMAIL: "pgadmin@pgadmin.com"
      PGADMIN_DEFAULT_PASSWORD: "pgadmin"
    ports:
      - "8080:80"
    volumes:
      - vol-pgadmin_data:/var/lib/pgadmin  

volumes: # define the shared volumes accessible to services, and this retains the data even after the container is removed
  vol-pgdata:
    name: vol-pgdata
  vol-pgadmin_data:
    name: vol-pgadmin_data
```

- postgres:5433
- localhost:5432
- db:5433
- postgres:5432
- db:5432

If there are more than one answers, select only one of them

## Answer 2
You can either use service name (db) or container name (postgres) to connect to the database.
- Port Mapping: The 5433:5432 (host machine port:container port) port mapping in the db service's definition is for external access to the database, forwards external requests to port 5433 on the host machine to port 5432 inside the database container.
- Internal Communication: Within the Docker network, services communicate directly using container names and their internal ports (5432).  

__Host Name: postgres or db__  
__Port:5432__

**Answer**  
c) postgres:5432



##  Prepare Postgres

Run Postgres and load data as shown in the videos
We'll use the green taxi trips from October 2019:

```bash
wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_2019-10.csv.gz
```

You will also need the dataset with zones:

```bash
wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv
```

Download this data and put it into Postgres.

You can use the code from the course. It's up to you whether
you want to use Jupyter or a python script.

The files required: [Dockerfile](Dockerfile), [docker-compose.yaml](docker-compose.yaml), [ingest_data_hw1.py](ingest_data_hw1.py) tp create a container and upload data and access using docker compose. First create a postgres container and then run the ingest_data_hw1.py script to upload the data. Then use docker-compose to access postgres container via pgadmin.

```bash 
# to create a network
docker network create hw1

# run to create postgres container
docker run -it \
  -e POSTGRES_DB="ny_taxi" \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -v $(pwd)/hw1_postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  --network=hw1 \
  --name hw1-database \
  postgres:13

# to create a docker image from the Dockerfile
docker build -t data_ingest:v3_hw1 .

## but what if i want to give both URLs in the same command
URL="https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_2019-10.csv.gz,https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv"

docker run -it \
  --network=hw1 \
  data_ingest:v3_hw1 \
  --user=root \
  --password=root \
  --host=hw1-database \
  --port=5432 \
  --db=ny_taxi \
  --url=${URL} \
  --table_name="green_taxi_trips,taxi_zone" 

# to check if the data was uploaded or not
pgcli -h localhost -p 5432 -u root -d ny_taxi

# then close the previous postgres container
docker kill <container_id>

# then docker-compose up -d
docker compose up -d

docker compose down
```


## Question 3. Trip Segmentation Count

During the period of October 1st 2019 (inclusive) and November 1st 2019 (exclusive), how many trips, **respectively**, happened:
1. Up to 1 mile
2. In between 1 (exclusive) and 3 miles (inclusive),
3. In between 3 (exclusive) and 7 miles (inclusive),
4. In between 7 (exclusive) and 10 miles (inclusive),
5. Over 10 miles 

Refer to this [link](https://datatalks-club.slack.com/archives/C01FABYF2RG/p1737047207950159) for some clarification on the question. Focus on the trips that ended before November 1st, 2019.
Answers:

- 104,802;  197,670;  110,612;  27,831;  35,281
- 104,802;  198,924;  109,603;  27,678;  35,189
- 104,793;  201,407;  110,612;  27,831;  35,281
- 104,793;  202,661;  109,603;  27,678;  35,189
- 104,838;  199,013;  109,645;  27,688;  35,202

## Answer 3

```sql
-- Upto 1 mile: 104802
SELECT COUNT(1)
FROM (
	SELECT * FROM green_taxi_trips 
	WHERE DATE("lpep_pickup_datetime") >= '2019-10-01'
		AND DATE("lpep_dropoff_datetime") <= '2019-10-31'
		AND "trip_distance" <= 1
) AS foo

-- In between 1 (exclusive) and 3 mile (inclusive): 198924 Trips
SELECT COUNT(1)
FROM (
	SELECT * FROM green_taxi_trips 
	WHERE DATE("lpep_pickup_datetime") >= '2019-10-01'
		AND DATE("lpep_dropoff_datetime") <= '2019-10-31'
		AND "trip_distance" > 1 AND "trip_distance" <= 3
) AS foo

-- In between 3 (exclusive) and 7 miles (inclusive): 109603 Trips
SELECT COUNT(1)
FROM (
	SELECT * FROM green_taxi_trips 
	WHERE DATE("lpep_pickup_datetime") >= '2019-10-01'
		AND DATE("lpep_dropoff_datetime") <= '2019-10-31'
		AND "trip_distance" > 3 AND "trip_distance" <= 7
) AS foo


-- In between 7 (exclusive) and 10 miles (inclusive): 27678 Trips
SELECT COUNT(1)
FROM (
	SELECT * FROM green_taxi_trips 
	WHERE DATE("lpep_pickup_datetime") >= '2019-10-01'
		AND DATE("lpep_dropoff_datetime") <= '2019-10-31'
		AND "trip_distance" > 7 AND "trip_distance" <= 10
) AS foo

-- Over 10 miles: 35189 Trips
SELECT COUNT(1)
FROM (
	SELECT * FROM green_taxi_trips 
	WHERE DATE("lpep_pickup_datetime") >= '2019-10-01'
		AND DATE("lpep_dropoff_datetime") <= '2019-10-31'
		AND "trip_distance" > 10
) AS foo

```
**Answer**  
b) 104,802;  198,924;  109,603;  27,678;  35,189

## Question 4. Longest trip for each day

Which was the pick up day with the longest trip distance?
Use the pick up time for your calculations.

Tip: For every day, we only care about one single trip with the longest distance. 

- 2019-10-11
- 2019-10-24
- 2019-10-26
- 2019-10-31

```sql
WITH cte AS (
	SELECT 
		DATE(lpep_pickup_datetime) AS date,
		MAX(trip_distance) AS max_distance
	FROM 
		green_taxi_trips
	GROUP BY DATE(lpep_pickup_datetime)
)

SELECT date
FROM cte
WHERE max_distance = (SELECT MAX(max_distance) FROM cte)
```

**Answer**
d) 2019-10-31

## Question 5. Three biggest pickup zones

Which were the top pickup locations with over 13,000 in
`total_amount` (across all trips) for 2019-10-18?

Consider only `lpep_pickup_datetime` when filtering by date.
 
- East Harlem North, East Harlem South, Morningside Heights
- East Harlem North, Morningside Heights
- Morningside Heights, Astoria Park, East Harlem South
- Bedford, East Harlem North, Astoria Park

```sql
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
```

**Answer**  
a) East Harlem North, East Harlem South, Morningside Heights

## Question 6. Largest tip

For the passengers picked up in October 2019 in the zone
named "East Harlem North" which was the drop off zone that had
the largest tip?

Note: it's `tip` , not `trip`

We need the name of the zone, not the ID.

- Yorkville West
- JFK Airport
- East Harlem North
- East Harlem South

```sql
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
```
**Answer**  
b) JFK Airport

## Terraform

In this section homework we'll prepare the environment by creating resources in GCP with Terraform.

In your VM on GCP/Laptop/GitHub Codespace install Terraform. 
Copy the files from the course repo
[here](../../../01-docker-terraform/1_terraform_gcp/terraform) to your VM/Laptop/GitHub Codespace.

Modify the files as necessary to create a GCP Bucket and Big Query Dataset.


## Question 7. Terraform Workflow

Which of the following sequences, **respectively**, describes the workflow for: 
1. Downloading the provider plugins and setting up backend,
2. Generating proposed changes and auto-executing the plan
3. Remove all resources managed by terraform`

Answers:
- terraform import, terraform apply -y, terraform destroy
- teraform init, terraform plan -auto-apply, terraform rm
- terraform init, terraform run -auto-approve, terraform destroy
- terraform init, terraform apply -auto-approve, terraform destroy
- terraform import, terraform apply -y, terraform rm

**Answer**  
d) terraform init, terraform apply -auto-approve, terraform destroy

## Submitting the solutions

* Form for submitting: https://courses.datatalks.club/de-zoomcamp-2025/homework/hw1