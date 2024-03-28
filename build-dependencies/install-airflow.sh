#!/bin/sh

echo installing dependencies...

AIRFLOW_VERSION=2.8.0
PYTHON_VERSION="$(python --version | cut -d " " -f 2 | cut -d "." -f 1-2)"
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"

echo installing airflow...
# the below will be needed as of airflow 2.7.0
# pip install "apache-airflow[cncf.kubernetes]==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"
pip install "apache-airflow[cncf.kubernetes]==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"
pip install --no-cache-dir -r /build/requirements.txt --constraint "${CONSTRAINT_URL}"