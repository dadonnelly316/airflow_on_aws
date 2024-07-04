#!/bin/sh

AWS_API_KEY=${1}
AWS_API_SECRET=${2}


aws configure set aws_access_key_id "${AWS_API_KEY}"
aws configure set aws_secret_access_key "${AWS_API_SECRET}"
aws configure set default.region us-east-1
# aws configure set default.ca_bundle /path/to/ca-bundle.pem
