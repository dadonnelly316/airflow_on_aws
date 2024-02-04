#!/bin/sh

kube_deploy() {
    local FULL_FILE_PATH="$1"

    echo "$(date): Posting ${FULL_FILE_PATH} to the K8 API server."
    kubectl apply -f $FULL_FILE_PATH
}

kube_deploy "../k8-manifests/airflow-scheduler-deployment.yaml"
kube_deploy "../k8-manifests/airflow-webserver-deployment.yaml"
kube_deploy "../k8-manifests/airflow-webserver-service.yaml"
kube_deploy "../k8-manifests/airflow-webserver-ingress.yaml" 