#!/bin/sh

cd "$(dirname "$0")"  


minikube start
eval $(minikube docker-env)


bash build-push-airflow-images.sh

echo "loading images. This may take a momenet"
minikube image load airflow-webserver:latest
minikube image load airflow-scheduler:latest

minikube addons enable ingress
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission

kubectl delete deployment airflow-webserver airflow-scheduler
kubectl delete deployment airflow-webserver airflow-webserver

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
kube_deploy "airflow-scheduler-deployment.yaml"
kube_deploy "airflow-webserver-deployment.yaml"

kube_deploy "airflow-webserver-service.yaml"
kube_deploy "airflow-webserver-ingress.yaml" 

# kubectl exec --stdin --tty ${POD_NAME} -- /bin/bash

echo "starting minikube tunnel. The terminal will be locked."
minikube tunnel