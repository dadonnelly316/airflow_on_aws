#!/bin/sh

IMAGE_VERSION=${1:-"latest"}
REMOTE_IMAGE_REIGSTRY_PREFIX=${2:-""}

WEBSERVER_TAG="${IMAGE_REIGSTRY_PREFIX}airflow-webserver:${IMAGE_VERSION}"
docker build \
    --pull \
    --target airflow-webserver \
    --tag "${WEBSERVER_TAG}" \
    ../


SCHEDULER_TAG="${IMAGE_REIGSTRY_PREFIX}airflow-scheduler:${IMAGE_VERSION}"
 docker build \
    --pull \
    --target airflow-scheduler \
    --tag "${SCHEDULER_TAG}" \
    ../

if [[ $REMOTE_IMAGE_REIGSTRY_PREFIX -ne "" ]]; then
    echo "$(date): Pushing images to container registry. This will fail if you're not signed into your container registry."
    docker push "${WEBSERVER_TAG}"
    docker push "${SCHEDULER_TAG}"
fi