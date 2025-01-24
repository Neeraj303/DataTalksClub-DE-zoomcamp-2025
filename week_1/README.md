
## [Week 1 Official Github                        ](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/01-docker-terraform): Docker-Terraform | [Homework 1](homework.md) | [HW1 Solution]()

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

---------------------------------- SQL Refresher ----------------------------------
-- To count the nnmber of rows in the table
SELECT COUNT(1) FROM zones

-- To check the first 5 rows
SELECT * FROM zones LIMIT 5
SELECT * FROM yellow_taxi_rides LIMIT 5;

-- See data without joining
SELECT
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    total_amount,
    CONCAT(zpu."Borough", ' | ', zpu."Zone") AS "pickup_loc",
    CONCAT(zdo."Borough", ' | ', zdo."Zone") AS "dropff_loc"
FROM 
    yellow_taxi_trips t,
    zones zpu,
    zones zdo
WHERE
    t."PULocationID" = zpu."LocationID"
    AND t."DOLocationID" = zdo."LocationID"
LIMIT 100;

-- Use JOIN to check multiple tables
SELECT
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    total_amount,
    CONCAT(zpu."Borough", ' | ', zpu."Zone") AS "pickup_loc",
    CONCAT(zdo."Borough", ' | ', zdo."Zone") AS "dropff_loc"
FROM yellow_taxi_trips t
JOIN zones zpu -- when writing JOIN by default states that we want to use an INNER JOIN
	ON t."PULocationID" = zpu."LocationID"
JOIN zones zdo
	ON t."DOLocationID" = zdo."LocationID"
LIMIT 100;

-- check for NULL entries
SELECT
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    total_amount,
    "PULocationID",
    "DOLocationID"
FROM 
    yellow_taxi_trips 
WHERE
    "PULocationID" IS NULL
    OR "DOLocationID" IS NULL
LIMIT 100;

-- Subquery to check LocationIDs in the Zones table not in yellow_taxi_trips
SELECT
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    total_amount,
    "PULocationID",
    "DOLocationID"
FROM 
    yellow_taxi_trips 
WHERE
    "DOLocationID" NOT IN (SELECT "LocationID" from zones)
    OR "PULocationID" NOT IN (SELECT "LocationID" from zones)
LIMIT 100;

-- Using Left JOIN
DELETE FROM zones WHERE "LocationID" = 142;

SELECT
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    total_amount,
    CONCAT(zpu."Borough", ' | ', zpu."Zone") AS "pickup_loc",
    CONCAT(zdo."Borough", ' | ', zdo."Zone") AS "dropff_loc"
FROM 
    yellow_taxi_trips t
LEFT JOIN 
    zones zpu ON t."PULocationID" = zpu."LocationID"
JOIN
    zones zdo ON t."DOLocationID" = zdo."LocationID"
LIMIT 100;

-- Number of Trips per day and ordering by day
SELECT
    CAST(tpep_dropoff_datetime AS DATE) AS "day",
    COUNT(1)
FROM 
    yellow_taxi_trips 
GROUP BY
    CAST(tpep_dropoff_datetime AS DATE)
ORDER BY 1 ASC

-- To check day with largest number of records/rides
SELECT
    CAST(tpep_dropoff_datetime AS DATE) AS "day",
    COUNT(1)
FROM 
    yellow_taxi_trips 
GROUP BY
    CAST(tpep_dropoff_datetime AS DATE)
ORDER BY 2 DESC
LIMIT 1;

-- Max amount of money a driver made for different day
SELECT
    CAST(tpep_dropoff_datetime AS DATE) AS "day",
    COUNT(1),
	MAX(total_amount) AS max_total_amount,
	MAX(passenger_count) AS max_total_passenger
FROM 
    yellow_taxi_trips 
GROUP BY
    CAST(tpep_dropoff_datetime AS DATE)
ORDER BY 2 DESC

-- Grouping by multiple columns
SELECT
    CAST(tpep_dropoff_datetime AS DATE) AS "day",
    "DOLocationID",
    COUNT(1) AS "count",
    MAX(total_amount) AS "max_total_amount",
    MAX(passenger_count) AS "max_passenger_count"
FROM 
    yellow_taxi_trips 
GROUP BY
    1, 2
ORDER BY 1 ASC, 2 ASC
LIMIT 100;


```

### [Video 7: Introduction to GCP](https://youtu.be/18jIzE41fJ4?list=PL3MmuxUbc_hJed7dXYoJw8DoCuVHhGEQb)

- GCP offers cloud servies.
- Include range of hosted serviees for computem, storage, and application development that run on Google hardware.
- Same infrastructure that Google uses internally for its end-user products, such as Google Search, Gmail, file storage, and YouTube.

We will talk majorly about BigData and Storage & Database services.


### [Video 8: Introduction Terraform: Concepts and Overview, a primer](https://youtu.be/s2bOYDCKl_M?list=PL3MmuxUbc_hJed7dXYoJw8DoCuVHhGEQb)

- **What is Terraform?**  
Terraform is an open-source tool that allows you to define and provision *infrastructure as code*. This means that you can define your infrastructure in a human-readable configuration file, and then use Terraform to create and manage that infrastructure.

- **Why use Terraform?**
  - **Reproducibility**: You can define your infrastructure in a configuration file, which makes it easy to reproduce your infrastructure in different environments.
  - **Automation**: Terraform allows you to automate the creation and management of your infrastructure, which can save you time and reduce the risk of human error.
  - **Collaboration**: Terraform configuration files can be version-controlled and shared, which makes it easy to collaborate with others on your infrastructure.

- **How does Terraform work?**   
Terraform uses a declarative language to define your infrastructure. This means that you tell Terraform what you want your infrastructure to look like, and Terraform figures out how to create it. Terraform then uses providers to interact with different cloud platforms and services.

**Provider** allow you to communicate with the cloud provider, like AWS, GCP, Azure, etc. Code that allow terraform to interact with the cloud provider.

- **Key Terraform commands**:

```bash
## defined the provider. Initializes a working directory containing Terraform configuration.
terraform init

## Generates an execution plan that shows the changes that will be made to your infrastructure if you apply the current configuration.
terraform plan

## Do what is in the tf file Creates or updates the infrastructure defined in your configuration.
terraform apply

## Remove everything defined in tf file. Destroys all of the infrastructure that was created by Terraform.
terraform destroy
```

### [Video 9: Terraform Basics: Simple one file Terraform Deployment](https://www.youtube.com/watch?v=s2bOYDCKl_M&list=PL3MmuxUbc_hJed7dXYoJw8DoCuVHhGEQb&index=12)

To install terraform for Ubuntu, refer to this [link](https://developer.hashicorp.com/terraform/install) and run the below commands

```bash
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

## To check if installed correctly
terraform --version
```

We create Service account on GCP, which is never meant to be logged into. It is used to give permissions to the resources. We will create a bucket in GCP using terraform.
Check this [website](https://registry.terraform.io/providers/hashicorp/google/latest/docs) for terraform google provider to create [main.tf](week_1/terrademo/main.tf) file.
Check this [link](http://registry.terraform.io/providers/wiardvanrij/ipv4google/latest/docs/resources/storage_bucket) to create google cloud storage bucket.
Before pushing to the remote repo always remember to include .gitignote file, for terraform refer to this [file](https://github.com/github/gitignore/blob/main/Terraform.gitignore). For specific region check this [link](https://cloud.google.com/compute/docs/regions-zones)

main.tf file to create a bucket in GCP
```
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.17.0"
    }
  }
}

provider "google" {
  credentials = "./keys/my-creds.json"
  project     = "hybrid-matrix-448616-b9"
  region      = "ap-south-1"
}

resource "google_storage_bucket" "demo-bucket" {
  name          = "hybrid-matrix-448616-b9"
  location      = "US"
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}
```

```bash
terraform fmt # to format the file

terraform init # to initialize the terraform

terraform plan # to check the plan

terraform apply # to apply the plan

terraform destroy # to destroy the resources
```

### [Video 10: Terraform Deployment with a Variables File](https://youtu.be/PBi0hHjLftk&list=PL3MmuxUbc_hJed7dXYoJw8DoCuVHhGEQb&index=13)

```bash
terraform apply # the bucket would be added to gcp, this would also create terraform.tfstate file 

terraform destroy # the terraform.tfstate file would be deleted, the corresponding bucket would be deleted from gcp and would create terraform.tfstate.backup file
```

Check this for [terraform Bigquery dataset](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset). This would add the dataset to the bigquery.

main.tf file to add dataset to bigquery
```
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.17.0"
    }
  }
}

provider "google" {
  credentials = "./keys/my-creds.json"
  project     = "hybrid-matrix-448616-b9"
  region      = "ap-south-1"
}

resource "google_storage_bucket" "demo-bucket" {
  name          = "hybrid-matrix-448616-b9"
  location      = "US"
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}

resource "google_bigquery_dataset" "demo_dataset" {
  dataset_id = "demo_dataset"
}
```

Creating a variables.tf file to add variables to the terraform file and using these vairables in corresponding modified main.tf file.
```
variable "credentials" {
  description = "credentials"
  default     = "./keys/my-creds.json"
}

variable "region_india" {
  description = "Region"
  default     = "asia-south1-c"
}

variable "region_us" {
  description = "Region"
  default     = "us-central1"
}

variable "project" {
  description = "Project"
  default     = "hybrid-matrix-448616-b9"
}

variable "location" {
  description = "Project Location"
  default     = "US"
}

variable "bq_dataset_name" {
  description = "My BigQuery Dataset Name"
  default     = "demo_dataset"
}

variable "gcs_bucket_name" {
  description = "My Storage Bucket Name"
  default     = "hybrid-matrix-448616-b9"
}

variable "gcs_storage_class" {
  description = "Bucket Storage Class"
  default     = "STANDARD"
}
```

Modified main.tf file to include the variables
```
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.17.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials)
  project     = var.project
  region      = var.region_india
}

resource "google_storage_bucket" "demo-bucket" {
  name          = var.gcs_bucket_name
  location      = var.location
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}

resource "google_bigquery_dataset" "demo_dataset" {
  dataset_id = var.bq_dataset_name
  location   = var.location
}
```

```bash
# run these on terminal
terraform fmt # to format the file
terraform plan # to check the plan
terraform apply # to apply/deploy the plan
terraform destroy # to destroy the resources
```

### [Video 11: GCP Cloud VM](https://youtu.be/ae-CV2KfoN0&list=PL3MmuxUbc_hJed7dXYoJw8DoCuVHhGEQb&index=14)

How to setup an environment on GCP using instance.  
We first need ssh key to login on the instance, we would use git bash. [Create SSH keys](https://cloud.google.com/compute/docs/connect/create-ssh-keys)

```bash
# On local machine
cd ~/.ssh
ssh-keygen -t rsa -f ~/.ssh/gcp -C texnh # this would create gcp and gcp.pub file
```

Then we would create a VM instance on GCP, check this [link](https://cloud.google.com/compute/docs/instances/create-start-instance) to create an instance.  
Then we would connect to the instance by adding the above ssh gcp.pub key to the metadata of the instance in GCP. This would create an VM with specified setup the external ip: 35.200.172.97. To ssh into VM machine use this command if you had setuped the password you would be prompted with that.

Install anaconda using this [link](https://docs.anaconda.com/anaconda/install/) on the VM machine.

```bash
# -i for identity file, then name and the ip adress
ssh -i ~/.ssh/gcp texnh@35.200.172.97

htop # to check the resources

# to download anaconda on VM
wget https://repo.anaconda.com/archive/Anaconda3-2024.10-1-Linux-x86_64.sh 
bash Anaconda3-2024.10-1-Linux-x86_64.sh

# to install docker
sudo apt-get update
sudo apt-get install docker.io

# to exit
logout
```

Follow the below step for creating config file for ssh on your local machine

```bash
cd ~/.ssh
code config

# Add the below content to the file
Host de-zoomcamp
	Hostname 35.200.172.97
	User texnh
	IdentityFile ~/.ssh/gcp

# Save the file and then run the below command to ssh into the VM
ssh de-zoomcamp
```
Follow the below steps on GCP VM

Check this [link](https://github.com/sindresorhus/guides/blob/main/docker-without-sudo.md) for docker without sudo.   
To install docker compose check this [link](https://github.com/docker/compose/releases). I have installed v2.32.4 docker-compose-linux-x86_64

```bash
# the below command would lead to error of permission denied
docker run hello-world 

# follow the below commands to run docker without sudo
sudo groupadd docker
sudo gpasswd -a $USER docker
sudo service docker restart

# then logout of the VM and then login again
docker run hello-world
docker run -it ubuntu bash

# clone the repo 
git clone https://github.com/DataTalksClub/data-engineering-zoomcamp.git

# to install docker-compose
mkdir bin
cd bin
wget https://github.com/docker/compose/releases/download/v2.32.4/docker-compose-linux-x86_64 -O docker-compose
chmod +x docker-compose
./docker-compose version

# to make docker-compose available in all the terminal
vi ~/.bashrc
echo "export PATH=\"\${HOME}/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc
which docker-compose
docker-compose version

cd data-engineering-zoomcamp/01-docker-terraform/2_docker_sql
docker-compose up -d
docker ps

# now install pgcli
conda install -c conda-forge pgcli

pgcli -h localhost -p 5432 -u root -d ny_taxi
\dt # to see the tables
```

To access postgres locally go the VScode ports on which you have de-zoomcamp host connection then add 5432 to it. Then on your local machine run the below command. Similarly add 8080 port then paste localhost:8080 on your browser to access pgadmin.

```bash
pgcli -h localhost -p 5432 -u root -d ny_taxi

cd data-engineering-zoomcamp/01-docker-terraform/2_docker_sql
wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2021-01.csv.gz 
gunzip yellow_tripdata_2021-01.csv.gz
conda install anaconda::psycopg2

jupyter notebook # this would not open brave so use google chrome
# then open upload-data.ipynb and run the cells

# to install terraform
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

cd 1_terraform_gcp/
```