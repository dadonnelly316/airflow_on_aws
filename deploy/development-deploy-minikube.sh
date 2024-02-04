#!/bin/sh

cd "$(dirname "$0")"  

bash build-push-airflow-images.sh

minikube start
eval $(minikube docker-env)
minikube addons enable ingress
# kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission


kube_deploy() {
    local FILE_NAME="$1"

    echo "$(date): Posting ${FILE_NAME} to the K8 API server."
    kubectl apply -f "../k8-manifests/$FILE_NAME"
}

kube_deploy "init-namespace.yaml"
kube_deploy "init-role.yaml"
kube_deploy "init-service-account.yaml"
kube_deploy "init-svc-role-binding.yaml" 
kube_deploy "airflow-scheduler-deployment.yaml"
kube_deploy "airflow-webserver-deployment.yaml"
kube_deploy "airflow-webserver-service.yaml"
kube_deploy "airflow-webserver-ingress.yaml" 