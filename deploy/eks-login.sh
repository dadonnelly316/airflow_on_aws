#!/bin/sh

AWS_CLUSTER_REGION=${1}

aws eks update-kubeconfig --region ${AWS_CLUSTER_REGION} --name airflow

kubectl get svc