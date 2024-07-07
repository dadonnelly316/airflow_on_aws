#!/bin/sh

POSTGRES_CONN_STRING=${1}

cd "$(dirname "$0")"  

minikube start

# Reuse docker daemon inside minikube cluster to speed up build. (see method 1 - https://minikube.sigs.k8s.io/docs/handbook/pushing/)
eval $(minikube docker-env)

# shell script parameter will resolve to a blank string and cause docker to look in the local image repository since no registry was passed
bash aws-ecr-build-push-airflow-images.sh

# create ingress service for ingress controller to access webserver (https://minikube.sigs.k8s.io/docs/handbook/addons/ingress-dns/#Mac)
minikube addons enable ingress
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission

kube_deploy() {
    local FILE_NAME="$1"

    echo "$(date): Posting ${FILE_NAME} to the K8 API server."
    kubectl apply -f "../k8-manifests/${FILE_NAME}"
}

kube_deploy "init-role.yaml"
kube_deploy "init-service-account.yaml"
kube_deploy "init-svc-role-binding.yaml" 
kube_deploy "airflow-webserver-service.yaml"
kube_deploy "airflow-webserver-ingress.yaml" 

# creating secrets referenced in K8 manifest files
kubectl delete secret database-connection-string airflow-webserver-username airflow-webserver-password airflow-webserver-email airflow-webserver-secret-key --ignore-not-found
kubectl create secret generic "database-connection-string" --from-literal="database-connection-string"="${POSTGRES_CONN_STRING}" 
kubectl create secret generic "airflow-webserver-username" --from-literal="airflow-webserver-username"="non-prod-testing" 
kubectl create secret generic "airflow-webserver-password" --from-literal="airflow-webserver-password"="youshallpass" 
kubectl create secret generic "airflow-webserver-email" --from-literal="airflow-webserver-email"="shrek@getoutofmyswamp.com" 
kubectl create secret generic "airflow-webserver-secret-key" --from-literal="airflow-webserver-secret-key"="12345" 

# we are taking K8 manifest files that are acting as "templates", copying them to a temp directory where it will be reference in kubectl apply, and using sed to configure manifest to work on minikube
mkdir ../k8-manifests/_tmp
cp ./{../k8-manifests/airflow-scheduler-deployment.yaml,../k8-manifests/airflow-webserver-deployment.yaml,../k8-manifests/airflow-config-map.yaml} ../k8-manifests/_tmp

# using , as delimiter since we have slashes in the ingress host
sed -i '' 's,__INGRESS_HOST__,http://localhost:80,g' ../k8-manifests/_tmp/airflow-config-map.yaml

# We must set image pull policy to never (see tip 1 https://minikube.sigs.k8s.io/docs/handbook/pushing/)
sed -i '' 's,__IMAGE_PULL_POLICY__,Never,g' ../k8-manifests/_tmp/airflow-webserver-deployment.yaml
sed -i '' 's/__IMAGE_PULL_POLICY__/Never/g' ../k8-manifests/_tmp/airflow-scheduler-deployment.yaml

# find image in local docker repository
sed -i '' 's,__AIRFLOW_IMAGE__,airflow:latest,g' ../k8-manifests/_tmp/airflow-webserver-deployment.yaml
sed -i '' 's,__AIRFLOW_IMAGE__,airflow:latest,g' ../k8-manifests/_tmp/airflow-scheduler-deployment.yaml

kubectl delete deployments --ignore-not-found=true airflow-scheduler airflow-webserver
kube_deploy "_tmp/airflow-config-map.yaml"
kube_deploy "_tmp/airflow-scheduler-deployment.yaml"
kube_deploy "_tmp/airflow-webserver-deployment.yaml"


rm -rf ./_tmp

echo "starting minikube tunnel. The terminal will be locked. You might need to enter your password."
minikube tunnel


# kubectl exec --stdin --tty ${POD_NAME} -- /bin/bash
