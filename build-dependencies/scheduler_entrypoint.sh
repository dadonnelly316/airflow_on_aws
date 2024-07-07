#!/bin/bash

# We are checking if airflow can ping the database before we attempt to perform database migrations
INPUT_MAX_RETRIES=120
INPUT_RETRY_DELAY=1
echo "$(date): Checking if the airflow database can be reached."
bash ./build/airflow_db_check.sh $INPUT_MAX_RETRIES $INPUT_RETRY_DELAY

# performing db migrations - (https://airflow.apache.org/docs/apache-airflow/2.9.0/administration-and-deployment/production-deployment.html#database-backend)
echo "RUN_DB_MIGRATION_BOOLEAN=${RUN_DB_MIGRATION_BOOLEAN}"
if [[ $RUN_DB_MIGRATION_BOOLEAN==1 ]]; then
    echo "$(date): Performing airflow database migrations."
    airflow db migrate
    echo "$(date): Airflow database migrations complete."
fi

# starting scheduler - (https://airflow.apache.org/docs/apache-airflow/2.9.0/administration-and-deployment/scheduler.html)
echo "$(date): Starting airflow scheduler."
airflow scheduler