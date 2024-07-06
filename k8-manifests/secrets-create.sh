#!/bin/sh


DATABASE_CONNECTION_STRING=${1}
# AIRFLOW_FERNET_KEY=${2}
AIRFLOW_WEBSERVER_USERNAME=${2}
AIRFLOW_WEBSERVER_PASSWORD=${3}
AIRFLOW_WEBSERVER_EMAIL=${4}
AIRFLOW_WEBSERVER_SECRET_KEY=${5}


# kubectl create secret generic NAME [--type=string] [--from-file=[key=]source] [--from-literal=key1=value1] [--dry-run]

createSecret() {
    local SECRET_NAME="$1"
    local SECRET_VALUE="$2"

    kubectl create secret generic "${SECRET_NAME}" --from-literal="${SECRET_NAME}"="${SECRET_VALUE}" 
}

DATABASE_CONNECTION_STRING_SECRET_NAME=$(echo "${!DATABASE_CONNECTION_STRING@}" | tr _ - | tr '[:upper:]' '[:lower:]')
createSecret  "${DATABASE_CONNECTION_STRING_SECRET_NAME}" "${DATABASE_CONNECTION_STRING}"

# AIRFLOW_FERNET_KEY_SECRET_NAME=$(echo "${!AIRFLOW_FERNET_KEY@}" | tr _ - | tr '[:upper:]' '[:lower:]')
# createSecret  "${AIRFLOW_FERNET_KEY_SECRET_NAME}" "${AIRFLOW_FERNET_KEY}"

AIRFLOW_WEBSERVER_USERNAME_SECRET_NAME=$(echo "${!AIRFLOW_WEBSERVER_USERNAME@}" | tr _ - | tr '[:upper:]' '[:lower:]')
createSecret  "${AIRFLOW_WEBSERVER_USERNAME_SECRET_NAME}" "${AIRFLOW_WEBSERVER_USERNAME}"

AIRFLOW_WEBSERVER_PASSWORD_SECRET_NAME=$(echo "${!AIRFLOW_WEBSERVER_PASSWORD@}" | tr _ - | tr '[:upper:]' '[:lower:]')
createSecret  "${AIRFLOW_WEBSERVER_PASSWORD_SECRET_NAME}" "${AIRFLOW_WEBSERVER_PASSWORD}"

AIRFLOW_WEBSERVER_EMAIL_SECRET_NAME=$(echo "${!AIRFLOW_WEBSERVER_EMAIL@}" | tr _ - | tr '[:upper:]' '[:lower:]')
createSecret  "${AIRFLOW_WEBSERVER_EMAIL_SECRET_NAME}" "${AIRFLOW_WEBSERVER_EMAIL}"

echo "${AIRFLOW_WEBSERVER_SECRET_KEY}"

AIRFLOW_WEBSERVER_SECRET_KEY_NAME=$(echo "${!AIRFLOW_WEBSERVER_SECRET_KEY@}" | tr _ - | tr '[:upper:]' '[:lower:]')
createSecret  "${AIRFLOW_WEBSERVER_SECRET_KEY_NAME}" "${AIRFLOW_WEBSERVER_SECRET_KEY}"

# local development database server
# postgresql+psycopg2://postgres:postgres@localhost:5432/postgres
