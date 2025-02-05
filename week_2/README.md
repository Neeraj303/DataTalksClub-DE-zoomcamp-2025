## [Week 2 Official Github](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/02-workflow-orchestration): Workflow Orchestration | [Homework 2](homework.md) | [HW2 Solution]()

### Extra Video: [Intro to Workflow Orchestration](https://www.youtube.com/watch?v=0yK7LXwYeD0)
It is from 2022 DE zoomcamp. This explains the concept of workflow orchestration and how it is used in data engineering in better and simple way. We can have Data Workflow / Data Pipeline or DAG (Directed Acylic Graph) then we use workflow orchesteration tool such as kestra.

### [Video 1: Introduction to Workflow Orchestration](https://www.youtube.com/watch?v=Np6QmmcgLCs)

We would use Kestra for workflow orchestration. Kestra is a workflow orchestration tool that allows you to define, schedule, and monitor workflows. It is similar to Apache Airflow, Prefect, and Dagster.

**What is Orchestration?**  
Orchestration is the automated configuration, coordination, and management of computer systems and software. It is the process of integrating two or more applications and/or services together to automate a process, or synchronize data in real-time.  

**What is Kestra?**
- Kestra is a workflow orchestration tool that allows you to define, schedule, and monitor workflows.
- It is similar to Apache Airflow, Prefect, and Dagster.
- It gives option of nocode, low code and full code for flexibility.
- It allow languages such as rust, python, c, etc
- It allow you to monitor the workflow in real time.

Useful resource for [getting started with Kestra](https://kestra.io/blogs/2024-04-05-getting-started-with-kestra)

__Launch Kestra in Docker:__   
Make sure docker is running and then run the following command to launch Kestra in Docker. Access the Kestra UI at http://localhost:8080 

```bash
docker run --pull=always --rm -it -p 8080:8080 --user=root \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /tmp:/tmp kestra/kestra:latest server local
```

Workflows are referenced as Flows and they’re declared using YAML making it very readable as well as works with any language! Within each flow, there are 3 required properties you’ll need:

- `id` which is the name of your flow. This can’t be changed once you’ve executed your flow for the first time.
- `namespace` which allows you to specify the environments you want your flow to execute in, e.g. production vs development
- `tasks` which is a list of the tasks that will execute when the flow is executed, in the order they’re defined in. Tasks contain an id as well as a type with each different type having their own additional properties.

After opening kestra click on create flow then save it and execute it you can find the output in the logs with the message you have given in the flow.
```yaml
id: my_first_flow # 
namespace: company.team

tasks:
  - id: hello
    type: io.kestra.plugin.core.log.Log
    message: Hello World! 🚀
```

Another example to extract tranform and query, in the gantt chart you can see the time taken by each task and which task runs when and what is the order of tasks. You can check the outputs tab to see the output of each task. 
```yaml
id: 01_getting_started_data_pipeline # name of the workflow needs to be unqiue
namespace: zoomcamp #sort of folder where the workflow is stored

inputs: # input parameters
  - id: columns_to_keep
    type: ARRAY
    itemType: STRING
    defaults: # array for 2 values
      - brand
      - price

tasks:
  - id: extract
    type: io.kestra.plugin.core.http.Download
    uri: https://dummyjson.com/products # extract data from this url

  - id: transform # this is python script to transform
    type: io.kestra.plugin.scripts.python.Script
    containerImage: python:3.11-alpine
    inputFiles:
      data.json: "{{outputs.extract.uri}}" # input file is the output of extract task
    outputFiles:
      - "*.json"
    env:
      COLUMNS_TO_KEEP: "{{inputs.columns_to_keep}}"
    script: |
      import json
      import os

      columns_to_keep_str = os.getenv("COLUMNS_TO_KEEP")
      columns_to_keep = json.loads(columns_to_keep_str)

      with open("data.json", "r") as file:
          data = json.load(file)

      filtered_data = [
          {column: product.get(column, "N/A") for column in columns_to_keep}
          for product in data["products"]
      ]

      with open("products.json", "w") as file:
          json.dump(filtered_data, file, indent=4)

  - id: query # this is the query to run on the transformed data
    type: io.kestra.plugin.jdbc.duckdb.Query
    inputFiles:
      products.json: "{{outputs.transform.outputFiles['products.json']}}" # input file is the output of transform task
    sql: |
      INSTALL json;
      LOAD json;
      SELECT brand, round(avg(price), 2) as avg_price
      FROM read_json_auto('{{workingDir}}/products.json')
      GROUP BY brand
      ORDER BY avg_price DESC;
    fetchType: STORE
```

### [Video 2: Learn the Concepts of Kestra](https://www.youtube.com/watch?v=o79n-EVpics)

This provide further resources:  
- [Getting Started with Kestra in 15 minutes](https://www.youtube.com/watch?v=a2BZ7vOihjg)
- [Kestra Beginner Tutorial](https://www.youtube.com/watch?v=HR47SY2RkPQ&list=PLEK3H8YwZn1oaSNybGnIfO03KC_jQVChL)
- [Install Kestra with Docker Compose | How-to Guide](https://www.youtube.com/watch?v=SGL8ywf3OJQ)  
After restarting the docker container all the flows will be lost. so refer to avoid this.

create application.yaml file

```yaml
datasources:
  postgres:
    url: jdbc:postgresql://postgres:5432/kestra
    driverClassName: org.postgresql.Driver
    username: kestra
    password: k3str4
kestra:
  server:
    basicAuth:
      enabled: false
      username: "admin@kestra.io" # it must be a valid email address
      password: kestra
  repository:
    type: postgres
  storage:
    type: local
    local:
      basePath: "/app/storage"
  queue:
    type: postgres
  tasks:
    tmpDir:
      path: "/tmp/kestra-wd/tmp"
  url: "http://localhost:8080/"
```
But the above file only runs kestra but we want to run kestra along with postgres so we need to use docker-compose file, by refering to this [link](https://kestra.io/docs/installation/docker-compose)

```bash
curl -o docker-compose.yml \
https://raw.githubusercontent.com/kestra-io/kestra/develop/docker-compose.yml
```

```bash
docker compose build
docker compose up
docker compose down
```
- [What is Orchestrator | Learn with Kestra](https://www.youtube.com/watch?v=ZV6CPZDiJFA)

---
All the flows can be found in this [flows](flows) folder. You can either copy paste the flows into kestra or If you prefer to add flows programmatically using Kestra's API, run the following commands:

```bash
curl -X POST http://localhost:8080/api/v1/flows/import -F fileUpload=@flows/01_getting_started_data_pipeline.yaml
curl -X POST http://localhost:8080/api/v1/flows/import -F fileUpload=@flows/02_postgres_taxi.yaml
curl -X POST http://localhost:8080/api/v1/flows/import -F fileUpload=@flows/02_postgres_taxi_scheduled.yaml
curl -X POST http://localhost:8080/api/v1/flows/import -F fileUpload=@flows/03_postgres_dbt.yaml
curl -X POST http://localhost:8080/api/v1/flows/import -F fileUpload=@flows/04_gcp_kv.yaml
curl -X POST http://localhost:8080/api/v1/flows/import -F fileUpload=@flows/05_gcp_setup.yaml
curl -X POST http://localhost:8080/api/v1/flows/import -F fileUpload=@flows/06_gcp_taxi.yaml
curl -X POST http://localhost:8080/api/v1/flows/import -F fileUpload=@flows/06_gcp_taxi_scheduled.yaml
curl -X POST http://localhost:8080/api/v1/flows/import -F fileUpload=@flows/07_gcp_dbt.yaml
```

### [Video 3: Create an ETL Pipeline with Postgres in Kestra](https://www.youtube.com/watch?v=OkfLX28Ecjg)

__Pre-setup__:  
We will create a single docker compose file. We will create 2 different postgres db, one for kestra (which would have a lot of tables created which we are not interested in), other for our data which would access through pgadmin its important to check all the port mapping and volumes.
If stuck refer to these FAQ: [Docker Setup](https://www.youtube.com/watch?v=73g6qJN0HcM), [Ports and images](https://www.youtube.com/watch?v=l2M2mW76RIU), . I have refered to this docker-compose file:

Access pgadmin: `localhost:8085`, login with the credentials provided in the docker-compose file.  
Access kestra: `localhost:8080`, login with the credentials provided in the docker-compose file.

```yaml
volumes:
  postgres-data:  # this db for kestra
    driver: local
  kestra-data: # this is for kestra data
    driver: local
  zoomcamp-data: # this db is for data we upload
    driver: local

services:
  postgres: # this container name 
    image: postgres:16.6  # shift to latest to use merge command
    volumes: # Named volumes persist even if the containers using them are removed. data remain
      - postgres-data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: kestra
      POSTGRES_USER: kestra
      POSTGRES_PASSWORD: k3str4
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -d $${POSTGRES_DB} -U $${POSTGRES_USER}"]
      interval: 30s
      timeout: 10s
      retries: 10
    # port not defined so this is only accessible from the Kestra container, continue using 5432 without any issues

  kestra:
    image: kestra/kestra:latest # using the latest image
    pull_policy: always
    # Note that this setup with a root user is intended for development purpose.
    # Our base image runs without root, but the Docker Compose implementation needs root to access the Docker socket
    # To run Kestra in a rootless mode in production, see: https://kestra.io/docs/installation/podman-compose
    user: "root"
    command: server standalone
    volumes:
      - kestra-data:/app/storage
      - /var/run/docker.sock:/var/run/docker.sock
      - /tmp/kestra-wd:/tmp/kestra-wd
    environment:
      KESTRA_CONFIGURATION: |
        datasources:
          postgres:
            url: jdbc:postgresql://postgres:5432/kestra
            driverClassName: org.postgresql.Driver
            username: kestra
            password: k3str4
        kestra:
          server:
            basicAuth:
              enabled: false
              username: "admin@kestra.io" # it must be a valid email address
              password: kestra
          repository:
            type: postgres
          storage:
            type: local
            local:
              basePath: "/app/storage"
          queue:
            type: postgres
          tasks:
            tmpDir:
              path: /tmp/kestra-wd/tmp
          url: http://localhost:8080/
    ports:
      - "8080:8080" # it uses two ports
      - "8081:8081"
    depends_on:
      postgres:
        condition: service_started
    
  postgres_zoomcamp: # this container name
    image: postgres
    environment:
      POSTGRES_USER: kestra
      POSTGRES_PASSWORD: k3str4
      POSTGRES_DB: postgres-zoomcamp # this is the db name
    ports:
      - "5432:5432"
    volumes:
      - zoomcamp-data:/var/lib/postgresql/data
    depends_on:
      kestra:  # only run when kestra starts
        condition: service_started

  pgadmin:
    image: dpage/pgadmin4
    environment:
      - PGADMIN_DEFAULT_EMAIL=admin@admin.com
      - PGADMIN_DEFAULT_PASSWORD=root
    ports:
      - "8085:80"
    depends_on:
      postgres_zoomcamp:
        condition: service_started
```
For linux in the flow file `url: jdbc:postgresql://host.docker.internal:5432/` does not seem to work in plugin defaults. So update it to `url: jdbc:postgresql://postgres_zoomcamp:5432/postgres-zoomcamp` in the flow file since we have an single docker compose file.  


Every month we get new dataset so we want to build workflow to add the new month data to the previous cummulated data.
- MDF5# create unique based on the data in that row to avoid duplicates when we rerun the pipeline.
- For sql task to run it needs a url so we use plugin_defaults to setup these details.
- The `TRUNCATE` command in SQL removes all rows from a table, but the table structure remains intact. It's different from `DROP TABLE`, which deletes the entire table, including its structure and definition.
- Every time we run the flow we download the data but we can run out of the storage so to avoid it we will purge it.

### [Video 4: Manage Scheduling and Backfills using Postgres in Kestra](https://www.youtube.com/watch?v=_-li_z97zog)

We will use schedule and backfills to run the flow at specific time and to run the flow for the previous months. We will use the same flow as above but with some changes.

`cron: "0 9 1 * *` this will run the flow at 9:00 AM on the first day of every month. Check [this](https://crontab.guru/#0_9_1_*_*)

We only have 1 stagging table, so create stagging table for each month

To allow only one instance of the flow to run at a time.
```yaml
concurrency:
  limit: 1
```
Now we will look at how we can use shcedule as the data comes in.

### [Video 5: Transform Data with dbt and Postgres in Kestra](https://www.youtube.com/watch?v=ZLp2N6p2JjE)

dbt allows us to go through data and tranform it, refer to this [03_postgres_dbt.yaml](flows/03_postgres_dbt.yaml)


### [Video 6: Create an ETL Pipeline with GCS and BigQuery in Kestra](https://www.youtube.com/watch?v=nKqjjLJ7YXs)

We will look into ETL pipeline and move it here to GCP using GCS (google cloud storage) and BigQuery. We would need service account, project_id, location id, bucket name.  I will use the same service account as used during terraform demo since it alreay have BigQuery and Storagr Admin rights.We would utilize key value store head to `NameSpaces` -> `KV Store` -> `New Key-Value`, this would be similar to environmental vairables and can use this between the flows. For more info you can refer to this [Access Values between Flows](https://www.youtube.com/watch?v=1XqujT5HeDM). Added 4 keys in the KV store:  
- `GCP_CREDS`: _Just copy paste your my-creds.json_ 
- `GCP_PROJECT_ID`: hybrid-matrix-448616-b9
- `GCP_LOCATION`: us-central1
- `GCP_BUCKET_NAME`: hybrid-matrix-448616-b9-kestra
- `GCP_DATASET`: kestra_zoomcamp   
 **Do not store your creds in the yaml file**  

 Then run `05_gcp_setup.yaml` file to setup on GCP. GCS is used for stroring unstructured data. BigQuery is used to store structured data. So we store the data into Data Lake (GCS) then pass it into Data Warehouse (BigQuery).

### [Video 7: Manage Scheduling and Backfills using BigQuery in Kestra](https://www.youtube.com/watch?v=DoaZ5JWEkH0&list=PL3MmuxUbc_hJed7dXYoJw8DoCuVHhGEQb&index=24&pp=iAQB)  

We will use a trigger to automatically fill the data for the previous months. And use backfill to fill the data for the previous months. We would use [06_gcp_taxi_scheduled.yaml](week_2/flows/06_gcp_taxi_scheduled.yaml). Delete all the tables from BigQuery then set the backfill dates to upload 2019 data.

### [Video 8: Transform Data with dbt and BigQuery in Kestra](https://www.youtube.com/watch?v=eF_EdV4A1Wk&list=PL3MmuxUbc_hJed7dXYoJw8DoCuVHhGEQb&index=25&pp=iAQB)

We will use dbt to transform the data in BigQuery. We will use [07_gcp_dbt.yaml](week_2/flows/07_gcp_dbt.yaml) to transform the data. We will use the same service account as used during terraform demo since it alreay have BigQuery and Storagr Admin rights. Upload whole dataset for green and yellow taxi data then run the yaml file to transform the data.

### [Video 9: Deploy Workflows to the Cloud with Git](https://www.youtube.com/watch?v=l-wC71tI3co&list=PL3MmuxUbc_hJed7dXYoJw8DoCuVHhGEQb&index=26&pp=iAQB)

Provide info git plugin tasks. We can use git to store the flows and then pu










---
**Useful commands:**

```bash
docker images # to check all the images in docker
docker rmi <image_id> # to remove the image from docker, you wont be able to remove an image if it is associated with a container so you need to first remove the container and then remove the image.

# to remove all containers associated with specific image 
docker container ps -a | grep 27daf7ad07a7 | awk '{print $1}' | xargs docker rm

# to check all container in docker
docker ps -a



```