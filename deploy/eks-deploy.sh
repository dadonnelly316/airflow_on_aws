#!/bin/sh

cd "$(dirname "$0")"  

# todo - ignore not found
# kubectl delete deployment airflow-webserver airflow-scheduler
# kubectl delete deployment airflow-webserver airflow-webserver

kube_deploy() {
    local FILE_NAME="$1"

    echo "$(date): Posting ${FILE_NAME} to the K8 API server."
    kubectl apply -f "../k8-manifests/${FILE_NAME}"
}

kube_deploy "airflow-scheduler-deployment.yaml"
kube_deploy "airflow-webserver-deployment.yaml"
