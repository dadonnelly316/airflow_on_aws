#!/bin/sh


kube_deploy() {
    local FULL_FILE_PATH="$1"

    echo "$(date): Posting ${FULL_FILE_PATH} to the K8 API server."
    kubectl apply -f $FULL_FILE_PATH
}

kube_deploy "../k8-manifests/init-namespace.yaml"
kube_deploy "../k8-manifests/init-role.yaml"
kube_deploy "../k8-manifests/init-service-account.yaml"
kube_deploy "../k8-manifests/init-svc-role-binding.yaml" 