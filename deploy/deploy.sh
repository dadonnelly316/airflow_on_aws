#!/bin/sh

kubectl apply -f airflow-webserver-deployment.yaml

kubectl apply -f airflow-scheduler-eks.yaml

kubectl apply -f airflow-webserver-service.yaml

kubectl apply -f airflow-webserver-ingress.yaml