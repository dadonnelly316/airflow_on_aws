
WARNING: This repo/the docker image is not regularly maintained and therefore will contain vulnerabilities.

Directions:

1. Create your K8 Cluster
2. Run k8-init/init-k8-cluster.sh to...
    - Initialize Namespace
    - Create Service Account
    - Create Roles
    - Bind Roles to Service Account

3. Run deploy-aws-eks.build-airflow-image.sh to airflow source images