#!/bin/bash

# todo - better handle failures if the migration isn't complete, or the db can't be reached. Should code exit right away upon error?

# https://airflow.apache.org/docs/apache-airflow/stable/cli-and-env-variables-ref.html#check
INPUT_MAX_RETRIES=120
INPUT_RETRY_DELAY=1
echo "$(date): Checking if the airflow database can be reached."
bash ./build/airflow_db_check.sh $INPUT_MAX_RETRIES $INPUT_RETRY_DELAY

# https://airflow.apache.org/docs/apache-airflow/stable/cli-and-env-variables-ref.html#check-migrations
if [[ $RUN_DB_MIGRATION_BOOLEAN=='1' ]]; then
    sleep 30
    echo "$(date): Checking if migrations are complete."
    airflow db check-migrations
    echo "$(date): Database migrations are complete"
fi

# https://airflow.apache.org/docs/apache-airflow/2.9.0/administration-and-deployment/scheduler.html
echo "$(date): Starting airflow dag-processor."
airflow dag-processor