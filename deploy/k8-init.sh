#!/bin/sh


kube_deploy() {
    local FILE_NAME="$1"

    echo "$(date): Posting ${FILE_NAME} to the K8 API server."
    kubectl apply -f "../k8-manifests/${FILE_NAME}"
}

kube_deploy "init-namespace.yaml"
kube_deploy "init-role.yaml"
kube_deploy "init-service-account.yaml"
kube_deploy "init-svc-role-binding.yaml" 
kube_deploy "airflow-config-map.yaml"