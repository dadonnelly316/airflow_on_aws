#!/bin/bash

INPUT_MAX_RETRIES=120
INPUT_RETRY_DELAY=1
echo "$(date): Checking if the airflow database can be reached."
bash ./build/airflow_db_check.sh $INPUT_MAX_RETRIES $INPUT_RETRY_DELAY

# todo - check if NEW scheduler deployment is ready
# kubectl wait --for=condition=available deployment/airflow-scheduler
# todo - handle failures of db check better. Check state of other pod useing kubectl, and possible kill other pod


if [[ $RUN_DB_MIGRATION_BOOLEAN=='1' ]]; then
    sleep 30
    echo "$(date): Checking if migrations are complete."
    airflow db check-migrations
    echo "$(date): Database migrations are complete"
fi

airflow api-server --port 80