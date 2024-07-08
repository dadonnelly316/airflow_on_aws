#!/bin/sh

AWS_ACCOUNT=${1}
AWS_REGION=${1}

TOKEN=$(aws ecr get-authorization-token --output text --query 'authorizationData[].authorizationToken')
curl -i -H "Authorization: Basic $TOKEN" https://${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/v2/airflow/tags/list

aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com
