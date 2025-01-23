FROM python:3.9

RUN apt-get install wget
RUN pip install pandas sqlalchemy psycopg2

# copy the python file in the specified directory in the container
WORKDIR /app
COPY ingest_data.py ingest_data.py

# ENTRYPOINT ["bash"]
ENTRYPOINT ["python", "ingest_data.py"]