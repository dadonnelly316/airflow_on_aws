#!/bin/sh

# check if scheduler is available, then start webserver
# i won't run any airflow db init/migrate options here, but i will run airflow db check

INPUT_MAX_RETRIES=120
INPUT_RETRY_DELAY=1

sleep 1

echo "checking migrations"
airflow db check-migrations
echo "migration check done"


airflow users create \
    --username admin \
    --password password \
    --firstname david \
    --lastname donnelly \
    --role Admin \
    --email Daviddonnellydev@gmail.com

echo "Database is ready to accept connections"


airflow webserver --port 8080