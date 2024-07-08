#!/bin/sh

INGRESS_HOST=${1}

# install ingress controller
bash helm-install-nginx-ingress-controller.sh

mkdir -p ../k8-manifests/_tmp
cp ../k8-manifests/airflow-config-map.yaml ../k8-manifests/_tmp
sed -i '' "s,__INGRESS_HOST__,${INGRESS_HOST},g" ../k8-manifests/_tmp/airflow-config-map.yaml

kube_deploy() {
    local FILE_NAME="$1"

    echo "$(date): Posting ${FILE_NAME} to the K8 API server."
    kubectl apply -f "../k8-manifests/${FILE_NAME}"
}

kube_deploy "init-namespace.yaml"
kube_deploy "init-role.yaml"
kube_deploy "init-service-account.yaml"
kube_deploy "init-svc-role-binding.yaml" 

kube_deploy "airflow-webserver-service.yaml"
kube_deploy "airflow-webserver-ingress.yaml" 
kube_deploy "_tmp/airflow-config-map.yaml"