#!/bin/sh

# AIRFLOW DB CHECK COMMAND SETTINGS
INPUT_MAX_RETRIES=120
INPUT_RETRY_DELAY=1
echo "$(date): Checking if the airflow dadtabase can be reached."
bash airflow_db_check.sh $INPUT_MAX_RETRIES $INPUT_RETRY_DELAY


if [[ $RUN_DB_MIGRATION_BOOLEAN=='1' ]]; then
    sleep 10
    echo "$(date): Checking if migrations are complete."
    airflow db check-migrations
    echo "$(date): Database migrations are complete"
fi


if [[ $CREATE_WEBSERVER_USER_BOOLEAN=='1' ]]; then
    echo "$(date): Creating admin user for webserver."
    airflow users create \
        --username ${AIRFLOW_WEBSERVER_USERNAME} \
        --password ${AIRFLOW_WEBSERVER_PASSWORD}  \
        --firstname admin \
        --lastname admin \
        --role Admin \
        --email ${AIRFLOW_WEBSERVER_EMAIL}
fi

airflow webserver --port 8080