#!/bin/sh

echo "the airflow iam user should be created with the correct permissions before running this"

# todo: create service account here using the CLI

aws iam list-users

terraform init
terraform plan
terraform apply --target=module.eks --target=module.vpc

aws eks update-kubeconfig --region us-east-2 --name airflow
kubectl get nodes
export KUBECONFIG=~/.kube/config

terraform apply

