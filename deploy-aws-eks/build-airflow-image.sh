#!/bin/sh


docker build --target airflow-webserver --tag airflow-webserver:latest ../

docker build --target airflow-scheduler --tag airflow-scheduler:latest ../