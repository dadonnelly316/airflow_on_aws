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

echo "Database is ready to accept connections"
airflow scheduler