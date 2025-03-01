#!/bin/sh

echo "Type 'Yes' to delete resources that were provisioned by terraform"
read confirmation

if [ "$confirmation" == "Yes" ]; then
  echo "Proceeding with terraform destroy..."
  terraform destroy
else
  echo "Operation canceled. Infrastructure was not destroyed."
fi
