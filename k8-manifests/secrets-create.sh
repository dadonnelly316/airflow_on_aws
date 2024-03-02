#!/bin/sh


DATABASE_CONNECTION_STRING=${1}
AIRFLOW_FERNET_KEY=${2}
AIRFLOW_WEBSERVER_USERNAME=${3}
AIRFLOW_WEBSERVER_PASSWORD=${4}
AIRFLOW_WEBSERVER_EMAIL=${5}


# kubectl create secret generic NAME [--type=string] [--from-file=[key=]source] [--from-literal=key1=value1] [--dry-run]

createSecret() {

    local SECRET_NAME="$1"
    local SECRET_VALUE="$2"

    # kubectl create secret 

}


createSecret "${!DATABASE_CONNECTION_STRING@}" "${DATABASE_CONNECTION_STRING}" 