#!/bin/sh

kube_deploy() {
    local FILE_NAME="$1"

    echo "$(date): Posting ${FILE_NAME} to the K8 API server."
    kubectl apply -f "../k8-manifests/${FILE_NAME}"
}


kube_deploy "airflow-scheduler-deployment.yaml"
kube_deploy "airflow-webserver-deployment.yaml"
kube_deploy "airflow-webserver-service.yaml"
kube_deploy "airflow-webserver-ingress.yaml" 