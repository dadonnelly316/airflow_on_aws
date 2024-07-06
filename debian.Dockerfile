# bullseye is used since Airflow 2.8.0 was tested on tested on Ubuntu Bullseye LTS (see https://airflow.apache.org/docs/apache-airflow/2.8.0/installation/dependencies.html#system-dependencies)
FROM python:3.9-slim-bullseye as airflow-init

COPY app app
RUN mkdir -p app/{logs,dags,plugins}
COPY build-dependencies build

# Setting Airflow to the right user (https://airflow.apache.org/docs/apache-airflow/2.8.0/howto/docker-compose/index.html#setting-the-right-airflow-user)
RUN export AIRFLOW_UID=$(id -u)
RUN chown -R "${AIRFLOW_UID}:0" app/{logs,dags,plugins}

# airflow home is where DAGs, Logs, and Plugins folder are located
RUN export AIRFLOW_HOME=~app

# ensures that the system is aware of the latest available package updates
RUN apt-get update && apt-get upgrade -y

# Airflow dependancies (hhttps://airflow.apache.org/docs/apache-airflow/2.8.0/installation/dependencies.html#system-dependencies)
RUN apt-get install -y --no-install-recommends \
        freetds-bin \
        krb5-user \
        ldap-utils \
        # libffi6 \
        libsasl2-2 \
        libsasl2-modules \
        libssl1.1 \
        locales  \
        lsb-release \
        sasl2-bin \
        sqlite3 \
        unixodbc

# psycopg2 dependancies are needed because postgres is used as the db backend - (https://www.psycopg.org/docs/install.html#psycopg-vs-psycopg-binary)
RUN apt-get install -y --no-install-recommends \
        libpq-dev \
        gcc \
        python3-dev 

RUN export $(cat .env | xargs)
RUN chmod +x build/install-airflow.sh && build/install-airflow.sh

# ENV AIRFLOW__LOGGING__LOGGING_LEVEL="CRITICAL"
# ENV AIRFLOW__LOGGING__FAB_LOGGING_LEVEL="CRITICAL"
ENV AIRFLOW__LOGGING__BASE_LOG_FOLDER=""
ENV AIRFLOW__CORE__LOAD_EXAMPLES=false


# Scheduler and Webserver share the same dependancies in the above stage, but branch off here since these components are initialized differently and therefore need diffent entrypoint scripts
FROM airflow-init as airflow-webserver
RUN chmod +x build/webserver_entrypoint.sh
ENTRYPOINT ["build/webserver_entrypoint.sh"]

FROM airflow-init as airflow-scheduler
RUN chmod +x build/scheduler_entrypoint.sh
ENTRYPOINT ["build/scheduler_entrypoint.sh"]





