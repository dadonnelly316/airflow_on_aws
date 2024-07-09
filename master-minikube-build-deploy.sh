#!/bin/sh

POSTGRES_CONN_STRING=${1}

bash development-deploy-minikube.sh ${POSTGRES_CONN_STRING}