#!/bin/bash


# AIRFLOW DB CHECK COMMAND SETTINGS
INPUT_MAX_RETRIES=120
INPUT_RETRY_DELAY=1
echo "$(date): Checking if the airflow database can be reached."
bash ./build/airflow_db_check.sh $INPUT_MAX_RETRIES $INPUT_RETRY_DELAY

echo "RUN_DB_MIGRATION_BOOLEAN=${RUN_DB_MIGRATION_BOOLEAN}"
if [[ $RUN_DB_MIGRATION_BOOLEAN==1 ]]; then
    echo "$(date): Performing airflow database migrations."
    airflow db migrate
    echo "$(date): Airflow database migrations complete."
fi

echo "$(date): Starting airflow scheduler."
airflow scheduler