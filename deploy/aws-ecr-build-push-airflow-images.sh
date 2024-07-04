#!/bin/sh

REMOTE_IMAGE_REIGSTRY=${1}
IMAGE_TAG=${2}

# todo - allow to pass in other image tags to stage images for scanning before promoting to latest

docker build \
    --pull \
    --target airflow-webserver \
    --tag airflow-webserver \
    ../


 docker build \
    --pull \
    --target airflow-scheduler \
    --tag airflow-scheduler \
    ../

if [[ ! -z $REMOTE_IMAGE_REIGSTRY ]]; then

    echo "$(date): Pushing images to container registry. This will fail if you're not signed into your container registry."

    docker tag airflow-webserver "${REMOTE_IMAGE_REIGSTRY}/airflow-webserver:latest"
    docker tag airflow-scheduler "${REMOTE_IMAGE_REIGSTRY}/airflow-scheduler:latest"

    docker push "${REMOTE_IMAGE_REIGSTRY}/airflow-webserver:latest"
    docker push "${REMOTE_IMAGE_REIGSTRY}/airflow-scheduler:latest"
fi

