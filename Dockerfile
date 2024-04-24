FROM python:3.9-slim-bullseye as airflow-init

RUN export AIRFLOW_UID=$(id -u)


COPY app app

RUN mkdir -p app/{logs,dags,plugins}
RUN chown -R "${AIRFLOW_UID}:0" app/{logs,dags,plugins}

# airflow home is where DAGs, Logs, and Plugins folder are located
COPY build-dependencies build
RUN export AIRFLOW_HOME=~app




# Install C Compiler, which is required by psycopg2, which is recomended for AIRFLOW__DATABASE__SQL_ALCHEMY_CONN conn URL

# update will refresh local index with packages that have updates. upgrade will install those changes
# todo - check if a different package manager can install updates/upgrades faster
# -y will answer "yes" for all prompts
# this installs dependancies for airflow and psycopg2
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y --no-install-recommends \
        libpq-dev \
        gcc \
        python3-dev  \
        freetds-bin \
        krb5-user \
        ldap-utils \
        #libffi6 \
        libsasl2-2 \
        libsasl2-modules \
        libssl1.1 \
        locales  \
        lsb-release \
        sasl2-bin \
        sqlite3 \
        unixodbc

#RUN pg_config --version

RUN export $(cat .env | xargs)
RUN chmod +x build/install-airflow.sh && build/install-airflow.sh


FROM airflow-init as airflow-webserver
RUN chmod +x build/webserver_entrypoint.sh
ENTRYPOINT ["build/webserver_entrypoint.sh"]

FROM airflow-init as airflow-scheduler
RUN chmod +x build/scheduler_entrypoint.sh
ENTRYPOINT ["build/scheduler_entrypoint.sh"]





