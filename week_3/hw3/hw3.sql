-- Creating external table referring to gcs path
CREATE OR REPLACE EXTERNAL TABLE `hybrid-matrix-448616-b9.module3_hw3.external_yellow_tripdata`
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://dezoomcamp_hw3_2025_texnh/yellow_tripdata_2024-*.parquet']
);

-- Check yello trip data
SELECT COUNT(1) as row_count FROM hybrid-matrix-448616-b9.module3_hw3.external_yellow_tripdata;

-- For the below query the data is copied from GCS to BigQuery.
-- Create a non partitioned table from external table
CREATE OR REPLACE TABLE hybrid-matrix-448616-b9.module3_hw3.yellow_tripdata_non_partitoned AS
SELECT * FROM hybrid-matrix-448616-b9.module3_hw3.external_yellow_tripdata;

-- Question 2
SELECT DISTINCT PULocationID FROM hybrid-matrix-448616-b9.module3_hw3.external_yellow_tripdata; 
SELECT DISTINCT PULocationID FROM hybrid-matrix-448616-b9.module3_hw3.yellow_tripdata_non_partitoned;



--Question 3
SELECT PULocationID FROM hybrid-matrix-448616-b9.module3_hw3.yellow_tripdata_non_partitoned;
SELECT PULocationID, DOLocationID FROM hybrid-matrix-448616-b9.module3_hw3.yellow_tripdata_non_partitoned;

--Question 4
SELECT COUNT(1) FROM hybrid-matrix-448616-b9.module3_hw3.yellow_tripdata_non_partitoned 
WHERE fare_amount=0;

-- Question 5
-- make a partitioned data
CREATE OR REPLACE TABLE hybrid-matrix-448616-b9.module3_hw3.yellow_tripdata_partitoned 
PARTITION BY DATE(tpep_pickup_datetime) AS
SELECT * FROM hybrid-matrix-448616-b9.module3_hw3.external_yellow_tripdata;

-- make a partitioned, clustered data
CREATE OR REPLACE TABLE hybrid-matrix-448616-b9.module3_hw3.yellow_tripdata_partitoned_clustered
PARTITION BY DATE(tpep_pickup_datetime)
CLUSTER BY VendorID AS
SELECT * FROM hybrid-matrix-448616-b9.module3_hw3.external_yellow_tripdata;

-- Question 6
SELECT DISTINCT VendorID FROM hybrid-matrix-448616-b9.module3_hw3.yellow_tripdata_non_partitoned
WHERE DATE(tpep_dropoff_datetime) >= '2024-03-01' AND DATE(tpep_dropoff_datetime) <= '2024-03-15';


SELECT DISTINCT VendorID FROM hybrid-matrix-448616-b9.module3_hw3.yellow_tripdata_partitoned
WHERE DATE(tpep_dropoff_datetime) >= '2024-03-01' AND DATE(tpep_dropoff_datetime) <= '2024-03-15';

SELECT DISTINCT VendorID FROM hybrid-matrix-448616-b9.module3_hw3.yellow_tripdata_partitoned_clustered
WHERE DATE(tpep_dropoff_datetime) >= '2024-03-01' AND DATE(tpep_dropoff_datetime) <= '2024-03-15';

