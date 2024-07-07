# Airflow 2.9.0 was tested on Debian bullseye and bookworm (see https://airflow.apache.org/docs/apache-airflow/2.9.0/installation/dependencies.html#debian-bookworm-12)
FROM python:3.12-slim-bookworm as airflow-init

COPY app app
RUN mkdir -p app/{logs,dags,plugins}
COPY build-dependencies build

# Setting Airflow to the right user (https://airflow.apache.org/docs/apache-airflow/2.9.0/howto/docker-compose/index.html#setting-the-right-airflow-user)
RUN export AIRFLOW_UID=$(id -u)
RUN chown -R "${AIRFLOW_UID}:0" app/{logs,dags,plugins}

# airflow home is where DAGs, Logs, and Plugins folder are located
RUN export AIRFLOW_HOME=~app

# ensures that the system is aware of the latest available package updates
RUN apt-get update && apt-get upgrade -y

# Airflow dependancies (https://airflow.apache.org/docs/apache-airflow/2.9.0/installation/dependencies.html#debian-bookworm-12)
RUN apt-get install -y --no-install-recommends \
        apt-transport-https \
        apt-utils \
        ca-certificates \
        curl \
        dumb-init \
        freetds-bin \
        krb5-user \
        libgeos-dev \
        ldap-utils \
        libsasl2-2 \
        libsasl2-modules \
        libxmlsec1 locales \
        libffi8 \
        libldap-2.5-0 \
        libssl3 \
        netcat-openbsd \
        lsb-release \
        openssh-client \
        python3-selinux \
        rsync \
        sasl2-bin \
        sqlite3 \
        sudo \
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

# make entrypoint scripts executable
RUN chmod +x build/scheduler_entrypoint.sh build/webserver_entrypoint.sh



