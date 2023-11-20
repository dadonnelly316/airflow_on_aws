#!/bin/sh

# create 'airflow' namespace
kubectl apply -f ./init-namespace.yaml

# create pod-reader role
kubectl apply -f ./init-role.yaml

# create service account
kubectl apply -f ./init-service-account.yaml

# bind pod-reader role to service account
kubectl apply -f ./init-svc-role-binding.yaml