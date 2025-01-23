## [Week 1 Official Github](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/01-docker-terraform): Docker-Terraform | [Homework 1](homework.md) | [HW1 Solution]()

### [Video 1: Intro to Docker](https://youtu.be/EYNwNlOrpr0&list=PL3MmuxUbc_hJed7dXYoJw8DoCuVHhGEQb&index=4)

Docker: Delivers software in **containers** and container are **isolated** from one another and bundle their own software, libraries and configuration files.

**Docker** image is like an snapshot of the container. It is a read-only template with instructions for creating a Docker container. You can run this docker image in different environment (AWS, GCP) and it will behave the same way.

Benefites of Docker:
- Reproducibility
- Local Experimentation
- Integration tests (CI/CD) (we use github action, jenkins)
- Running pipelines on the cloud
- Spark
- Serverless: Concept for processing data, one record at a time. (AWS Lambda, Google Cloud Functions)

```bash
# To check the setup of Docker
docker run hello-world

# Then run ubuntu conatiner 
# -it mean in interactive mode, ubuntu is the image name and bash is the command to run, anything after image name is parameter of this container
docker run -it ubuntu bash

# To exit the container (Ctrl + D) or type exit
exit

# Run python in docker (image:tag), this would open python shell, but cant install using pip
docker run -it python:3.9

# Add entrypoint to run python script, now you can use pip to install on docker container
docker run -it --entrypoint=bash python:3.9

# But when you exit the container, all the changes will be lost, to save the changes you need to make a Dockerfile

# To build an image from docker file, image name is test:pandas
docker build -t test:pandas .

# To run this image
docker run -it test:pandas
```

### [Video 2: Ingesting NY Taxi Data to Postgres](https://youtu.be/2JM-ziJt0WI&list=PL3MmuxUbc_hJed7dXYoJw8DoCuVHhGEQb&index=5)

Docker compose: Running multiple docker containers at once. It is a tool for defining and running multi-container Docker applications. Check this [file](https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/02-workflow-orchestration/docker-compose.yml) for docker image.

```bash
# To check all the current containers running
docker ps

# To stop any container 
docker stop <container_id>

# run the below command to create the docker 
docker run -it \
  -e POSTGRES_DB="ny_taxi" \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -v $(pwd)/ny_taxi_postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:13

# In new terminal install pgcli
pip install pgcli

# connect by this, then enter the password which is "root"
pgcli -h localhost -p 5432 -u root -d ny_taxi
\dt # to see the tables
\d yellow_taxi_data # to check the created table/schema
SELECT COUNT(1) FROM yellow_taxi_data # to check the added data rows
# use Ctrl + D to exit pgcli

# to download data 
wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2021-01.csv.gz 

gzip -d yellow_tripdata_2021-01.csv.gz # unzip
wc -l yellow_tripdata_2021-01.csv # to check number of rows
```

You can check this [Data Dictionary](https://www.nyc.gov/assets/tlc/downloads/pdf/data_dictionary_trip_records_yellow.pdf)


### [Video 3: Connecting pgAdmin Postgres](https://youtu.be/hCAIVe9N0ow?list=PL3MmuxUbc_hJed7dXYoJw8DoCuVHhGEQb)

```bash
# to connect to pgadmin run below in terminal
docker run -it \
  -e PGADMIN_DEFAULT_EMAIL="admin@admin.com" \
  -e PGADMIN_DEFAULT_PASSWORD="root" \
  -p 8080:80 \
  dpage/pgadmin4
```

open the web-browser and use this http://localhost:8080/login?next=/browser/ then enter the email and password as defined above. But we have created 2 container which are not connected so we need to connect them first via networks. Close both the containers (Ctrl+D for pgcli and Ctrl+c for postgres container).

```bash
docker network create pg-network

docker run -it \
  -e POSTGRES_DB="ny_taxi" \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -v $(pwd)/ny_taxi_postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  --network=pg-network \
  --name pg-database \
  postgres:13

  # list all the containers, even the stopped ones
  docker ps -a

  # check existing network 
  docker network ls

  # remove the current existing network
  docker network rm pg-network
```

### [Video 4: Dockerizing the Ingestion Script](https://youtu.be/B1WwATwf-vY?list=PL3MmuxUbc_hJed7dXYoJw8DoCuVHhGEQb)

We would learn how to convert the ipynb notebook to python script and then run it in docker container.

We will first convert the jupyter notebook to python script using below command

```bash
jupyter nbconvert --to=script upload-data.ipynb
```

check the final file [ingest_data.py](week_1/2_docker_sql/ingest_data.py) for the file python file. And run the below command in terminal to run this python script.

```bash
URL="https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2021-01.csv.gz"

python ingest_data.py \
  --user=root \
  --password=root \
  --host=localhost \
  --port=5432 \
  --db=ny_taxi \
  --table_name=yellow_taxi_trips \
  --url=${URL}
```

Then modify to add all the parameters in the [Dockerfile](week_1/2_docker_sql/Dockerfile) and then build the image by following the below commands

```bash
docker build -t taxi_ingest:v001 .
```

Then run the below command to run the docker image

```bash
URL="https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2021-01.csv.gz"

docker run -it \
  --network=pg-network \
  taxi_ingest:v001 \
    --user=root \
    --password=root \
    --host=pg-database \
    --port=5432 \
    --db=ny_taxi \
    --table_name=yellow_taxi_trips \
    --url=${URL}
```


### [Video 5: Running Postgres and pgAdmin with Docker-Compose](https://youtu.be/hKI6PkPhpa0?list=PL3MmuxUbc_hJed7dXYoJw8DoCuVHhGEQb)

We will make a yaml file to run the postgres and pgadmin in one go. We will use Docker Compose to run multiple containers at once. 

```bash
# To run the docker compose file
docker compose up

# To Close use Ctrl+C and then run the below command to remove the containers
docker compose down

# To run in detached mode, you would have access to the terminal, run the below command
docker compose up -d
docker compose down # to close the containers
```

You always need to register server to avoid this

```bash
mkdir data_pgadmin
sudo chmod -R 777 ./data_pgadmin/

# And modify the docker-compose file to add the volume
  pgadmin:
    image: dpage/pgadmin4
    volumes:
      - "./data_pgadmin:/var/lib/pgadmin:rw"
```

### [Video 6: SQL Refresher](https://youtu.be/QEcps_iskgg?list=PL3MmuxUbc_hJed7dXYoJw8DoCuVHhGEQb)

Install the taxi_zone_lookup.csv file

```bash
wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv
```

Check the upload-data.ipynb for uploading the data to postgres. 

```SQL
-- To count the nnmber of rows in the table
SELECT COUNT(1) FROM zones

-- To check the first 5 rows
SELECT * FROM zones LIMIT 5


```