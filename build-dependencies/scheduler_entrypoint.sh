#!/bin/sh


# AIRFLOW DB CHECK COMMAND SETTINGS
INPUT_MAX_RETRIES=120
INPUT_RETRY_DELAY=1
echo "Checking if the airflow db can be reached."
bash airflow_db_check.sh $INPUT_MAX_RETRIES $INPUT_RETRY_DELAY



echo "doing migrations in scheduler"
airflow db migrations
echo "Airflow db has been initialized."


airflow scheduler