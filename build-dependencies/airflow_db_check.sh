#! /bin/bash

INPUT_MAX_RETRIES=$1
INPUT_RETRY_DELAY=$2

if [ $# -ne 2 ] ; then 
    echo "airflow_db_check.sh requires 3 arguments."
fi

# checks if the database can be reached.
# this should be run prior to db init or db migrate

airflow_db_check() {
    local MAX_RETRIES="$1"
    local RETRY_DELAY="$2"

    local DB_CHECK_ATTEMPTS=0

    while [ $DB_CHECK_ATTEMPTS -le $MAX_RETRIES ]; do

        AIRFLOW_DB_CHECK_OUTPUT=$(airflow db check)
        local EXIT_CODE=$?

        if [ $EXIT_CODE -eq 0 ]; then 
            echo "Successfully connected to the airflow database."
            return $EXIT_CODE
        else
            sleep $RETRY_DELAY
            DB_CHECK_ATTEMPTS = $ (( DB_CHECK_ATTEMPTS + 1))
            echo "airflow db check failed. Attempting retry $DB_CHECK_ATTEMPTS "
        fi

    done

    echo "Failed to conect to the airflow database. Printing command output... "
    echo $AIRFLOW_DB_CHECK_OUTPUT
    return $EXIT_CODE
}

exit $(airflow_db_check $INPUT_MAX_RETRIES $INPUT_RETRY_DELAY)