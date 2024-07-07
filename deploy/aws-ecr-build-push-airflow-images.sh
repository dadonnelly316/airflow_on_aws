#!/bin/sh

REMOTE_IMAGE_REIGSTRY=${1-""}
IMAGE_TAG=${2-"latest"}

docker build \
    --pull \
    --tag airflow \
    --platform linux/amd64 \
    --file ../debian.Dockerfile \
    ../


if [[ ! -z $REMOTE_IMAGE_REIGSTRY ]]; then

    echo "$(date): Pushing images to container registry. This will fail if you're not signed into your container registry."
    docker tag airflow "${REMOTE_IMAGE_REIGSTRY}/airflow:${IMAGE_TAG}"
    docker push "${REMOTE_IMAGE_REIGSTRY}/airflow:${IMAGE_TAG}"
fi

