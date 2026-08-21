#https://airflow.apache.org/docs/apache-airflow/2.9.0/installation/dependencies.html#debian-bookworm-12
FROM python:3.12-slim-bookworm

# used to set AIRFLOW__KUBERNETES_EXECUTOR__POD_TEMPLATE_FILE. We want this to be '' when running in docker-compose
ARG K8_POD_TEMPLATE_INPUT=''
ARG AIRFLOW_IMAGE_NAME_INPUT='airflow:latest'

COPY app app
RUN mkdir -p app/{logs,dags,plugins}
COPY build build
COPY k8s/pod-template-file.yaml /
# keep this in docker-compose so you can easily use cat command to validate input. K8_POD_TEMPLATE_INPUT will never be passed in docker-compose, so pod template isn't used outside of k8.
RUN sed -i "s,__AIRFLOW_IMAGE__,${AIRFLOW_IMAGE_NAME_INPUT},g" /pod-template-file.yaml

# Setting Airflow to the right user (https://airflow.apache.org/docs/apache-airflow/2.9.0/howto/docker-compose/index.html#setting-the-right-airflow-user)
RUN export AIRFLOW_UID=$(id -u)
RUN chown -R "${AIRFLOW_UID}:0" app/{logs,dags,plugins}

# airflow home is where DAGs, Logs, and Plugins folder are located
RUN export AIRFLOW_HOME=~app

RUN apt-get update && apt-get upgrade -y
RUN chmod +x build/system_dependancies_airflow.sh && build/system_dependancies_airflow.sh
RUN chmod +x build/system_dependancies_postgres.sh && build/system_dependancies_postgres.sh
RUN chmod +x build/install-airflow.sh && build/install-airflow.sh

# RUN export $(cat .env | xargs)
# ENV AIRFLOW__LOGGING__LOGGING_LEVEL="CRITICAL"
# ENV AIRFLOW__LOGGING__FAB_LOGGING_LEVEL="CRITICAL"
ENV AIRFLOW__LOGGING__BASE_LOG_FOLDER=""
ENV AIRFLOW__CORE__LOAD_EXAMPLES=false
ENV AIRFLOW__KUBERNETES_EXECUTOR__POD_TEMPLATE_FILE=$K8_POD_TEMPLATE_INPUT


RUN chmod +x build/entrypoint_scheduler.sh build/entrypoint_api_server.sh build/entrypoint_dag_processor.sh




