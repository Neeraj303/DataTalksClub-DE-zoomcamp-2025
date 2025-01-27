# FROM python:3.9

FROM python:3.9

RUN apt-get install wget
RUN pip install pandas sqlalchemy psycopg2

WORKDIR /app
COPY ingest_data_hw1.py ingest_data_hw1.py 

ENTRYPOINT ["python", "ingest_data_hw1.py"] 
