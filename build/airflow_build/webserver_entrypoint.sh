#!/bin/sh


is_db_ready () { 
    airflow db check;
    }


until is_db_ready; do
    if [ $? -ne 0 ]; then
        echo "database is not ready to accept connections"
    fi
done

airflow db init

airflow users create \
    --username admin \
    --password password \
    --firstname david \
    --lastname donnelly \
    --role Admin \
    --email david.donnelly1@ibm.com 

echo "Database is ready to accept connections"
airflow webserver --port 8081