#!/bin/sh


TOKEN=$(aws ecr get-authorization-token --output text --query 'authorizationData[].authorizationToken')
curl -i -H "Authorization: Basic $TOKEN" https://465579834180.dkr.ecr.us-east-1.amazonaws.com/v2/airflow/tags/list