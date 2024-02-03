#!/bin/sh

# image pull policy must be never

# __AIRFLOW_WEBSERVER_IMAGE__: docker.io/library/airflow-webserver:latest
# __AIRFLOW_SCHEDULER_IMAGE__: docker.io/library/airflow-scheduler:latest
# __AIRFLOW_INGRESS_HOST__: airflow.com


cd "$(dirname "$0")"
    

mkdir -p tmp

cp ../ki8-templates/. DEST

minikube start

eval $(minikube docker-env)

minikube image ls --format table

docker ps

docker build --target airflow-webserver --tag airflow-webserver:latest ../

docker build --target airflow-scheduler --tag airflow-scheduler:latest ../

minikube start
minikube addons enable ingress

# kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission


kubectl apply -f ../k8-templates/airflow-webserver-deployment.yaml

kubectl apply -f ../k8-templates/airflow-scheduler-deployment.yaml

kubectl apply -f ../k8-templates/airflow-webserver-service.yaml

kubectl apply -f ../k8-templates/airflow-webserver-ingress.yaml



# minikube service airflow-webserver-service