## Airflow on AWS

A simple Apache Airflow deployment on Amazon _**Elastic Kubernetes Service**_ (_**EKS**_) with a **data pipeline** to stream csv data from Amazon **Simple Storage (S3)** to Amazon **Relational Database Service (RDS)** for PostgreSQL.

## Description

An in-depth paragraph about your project and overview of use.

## Dependencies

*   Docker Desktop (Docker-Compose is optional for local testing purposes).
*   Minikube (Optional for local testing purposes).
*   AWS Command Line Interface (CLI).

## Required AWS Services

*   AWS Virtual Private Cloud (VPC) where all AWS services will be launched.
*   AWS Elastic Kubernetes Service (EKS) with a EC2 Node Group on a linux/amd64 platform.
*   AWS Relational Database Service (RDS) for PostgreSQL (12, 13, 14, 15, 16).
*   AWS Elastic Container Registry (ECR) instance.

## Getting Started

### Provision AWS RDS Instance

Our first step is to provision an Amazon Relational Database Service (RDS) for PostgreSQL in your region of choice. This will serve as [Airflow's database backend](https://airflow.apache.org/docs/apache-airflow/stable/howto/set-up-database.html) where metadata wil lbe stored, such as [user rules and DAG run history](https://www.astronomer.io/docs/learn/airflow-database). Note that Airflow also supports MySQL as a database backend, but this is not reccomend because this project was tested using PostgreSQL.

First, we will sign in to Amzon Relational Database Service [AWS Management Console](https://aws.amazon.com/console/) to provision a new postgreSQL instance. 

![Creating RDS Instance from AWS Management Console using Standard Create](https://github.com/dadonnelly316/airflow_on_aws/blob/main/documentation/images/RDS_step_1.png)

**FURTHER DOCUMENTATION TO COME…**

## Authors

Contributors names and contact info

ex. David Donnelly  
ex. Daviddonnellydev@gmail.com