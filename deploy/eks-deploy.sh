#!/bin/sh

AIRFLOW_IMAGE=${1}

cd "$(dirname "$0")"

cp ./{../k8-manifests/airflow-scheduler-deployment.yaml,../k8-manifests/airflow-webserver-deployment.yaml} ../k8-manifests/_tmp

# We must set image pull policy to never (see tip 1 https://minikube.sigs.k8s.io/docs/handbook/pushing/)
sed -i "" "s,__IMAGE_PULL_POLICY__,Always,g" ../k8-manifests/_tmp/airflow-webserver-deployment.yaml
sed -i "" "s/__IMAGE_PULL_POLICY__/Always/g" ../k8-manifests/_tmp/airflow-scheduler-deployment.yaml

# find image in local docker repository
sed -i "" "s,__AIRFLOW_IMAGE__,${AIRFLOW_IMAGE},g" ../k8-manifests/_tmp/airflow-webserver-deployment.yaml
sed -i "" "s,__AIRFLOW_IMAGE__,${AIRFLOW_IMAGE},g" ../k8-manifests/_tmp/airflow-scheduler-deployment.yaml

kube_deploy() {
    local FILE_NAME="$1"

    echo "$(date): Posting ${FILE_NAME} to the K8 API server."
    kubectl apply -f "../k8-manifests/${FILE_NAME}"
}

kube_deploy "_tmp/airflow-scheduler-deployment.yaml"
kube_deploy "_tmp/airflow-webserver-deployment.yaml"
