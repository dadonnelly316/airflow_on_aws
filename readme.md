## Airflow on AWS

A simple Apache Airflow deployment on Amazon _**Elastic Kubernetes Service**_ (_**EKS**_) with an **Elastic Compute Cloud (EC2)** node group  and a **Relational Database Service (RDS)** for PostgreSQL used as the database backend. 

## Description

This repo contains Airflow's dependancies and utility scripts that can be used to deploy it on Amazon Web Services (AWS). This basic depoyment uses Python 3.12 on Debian as its base image, and Airflow is installed using PyPI (pip). This repo also comes with utility scripts that build Airflow's image and deploy it on AWS, which can be plugged into a CI/CD tool. 

## Dependencies

*   MacOS or Linux host machine
*   Docker Desktop (Docker-Compose is optional for local testing purposes).
*   Minikube (optional for local testing purposes).
*   AWS Command Line Interface (CLI).

## Required AWS Services

*   AWS Virtual Private Cloud (VPC) where all AWS services will be launched.
*   AWS Elastic Kubernetes Service (EKS) with a EC2 Node Group on a linux/amd64 platform.
*   AWS Relational Database Service (RDS) for PostgreSQL (12, 13, 14, 15, 16).
*   AWS Elastic Container Registry (ECR) instance.
*   AWS Elastic Compute Cloud (EC2) for EKS node group

## Getting Started

### Provision AWS RDS Instance

Our first step is to provision an Amazon Relational Database Service (RDS) for PostgreSQL in your region of choice. This will serve as [Airflow's database backend](https://airflow.apache.org/docs/apache-airflow/stable/howto/set-up-database.html) where metadata will lbe stored, such as [user rules and DAG run history](https://www.astronomer.io/docs/learn/airflow-database). Note that Airflow also supports MySQL as a database backend, but this is not reccomend because this project was tested using PostgreSQL.

First, we will sign in to Amzon Relational Database Service [AWS Management Console](https://aws.amazon.com/console/) to provision a new postgreSQL instance. 

![Creating RDS instance from AWS Management Console using Standard Create](https://github.com/dadonnelly316/airflow_on_aws/blob/main/documentation/images/RDS_step_1.png)

Choose “Free Tier” in the templates section

![Configuring RDS instance from AWS Management Console to use free tier](https://github.com/dadonnelly316/airflow_on_aws/blob/main/documentation/images/RDS_step_2.png)

In the settings section, we chose a database cluster identifier. This project chose “airflow”, but you can choose any name you prefer. We leave the default Master Username as postgres, and choose a strong password. If you prefer, you can let AWS manage your password.

![Configuring RDS instance from AWS Management Console to to set cluster identifier, the postgres master username, and master password.](https://github.com/dadonnelly316/airflow_on_aws/blob/main/documentation/images/RDS_step_3.jpg)

Scroll down to “Conectivity” (pictured below). Note that we are keeping all other AWS default values, including “instance configuration=db.t3.micro". 

We create a new VPC, which will also be used by our EKS cluster and EC2 Node Group. However, you can choose an existing VPC if you wish, but these other required AWS services will also need to be provisioned in this VPC.

![Configuring RDS instance from AWS Management Console to create a new VPC.](https://github.com/dadonnelly316/airflow_on_aws/blob/main/documentation/images/RDS_step_4.png)

Click "Create Database", and you're done!

### Provision AWS ECR Instance

Amazon Elastic Kubernetes Service needs a private image registry to pull images from when creating the Airflow Webserver and Scheduler deployments. We are going to provision an Amazon Elastic Container Registry (ECR) instance to store our Airflow images. This project currently relies on the user to locally build the airflow image and then push it to the private registry.

First, you must navigate to the “Amazon Elastic Container Registry” service in AWS, and select “Create Repository”. Keep your repository private, and name it “airflow”. Note that we will only have one Airflow image, but the Kubernetes deployments for the Webserver and Scheduler will be invoked with their respective entrypoint scripts. 

![Configuring a private AWS Elastic Container Registry named Airflow in AWS Console](https://github.com/dadonnelly316/airflow_on_aws/blob/main/documentation/images/ECR_step_1.png)

## Authors

Contributors names and contact info

ex. David Donnelly  
ex. Daviddonnellydev@gmail.com