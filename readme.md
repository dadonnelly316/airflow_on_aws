## Airflow on AWS

A simple Apache Airflow deployment on Amazon _**Elastic Kubernetes Service**_ (_**EKS**_) with an **Elastic Compute Cloud (EC2)** node group  and a **Relational Database Service (RDS)** for PostgreSQL used as the database backend. 

## Description

This repo contains Airflow's dependancies and utility scripts that can be used to deploy it on Amazon Web Services (AWS). This basic depoyment uses Python 3.12 on Debian as its base image, and Airflow is installed using PyPI (pip).

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

## Configuring Amazon Web Services (AWS) Services

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

### Provision AWS EKS Instance

[Apache Airflow is a Kubernetes friendly project](https://airflow.apache.org/docs/apache-airflow/stable/administration-and-deployment/kubernetes.html). Because this is an AWS focused project, we use Amazon's Elastic Kubernetes Service is used as our container orchestration. This step will also involve provisioning an EC2 instance, which will be used as our Node Group.

First, we navigate to the Elastic Kubernetes Service in the AWS console, and select "Create Cluster".

![In the Amazon Elastic Kubernetes Service in the AWS Console, we select "Create Cluster"](https://github.com/dadonnelly316/airflow_on_aws/blob/main/documentation/images/EKS_step_1.png)

You will be prompted to enter a name for your cluster, and select a cluster role. This project chooses "airflow", but you can use any name you prefer. Next, you must select "Create Role in IAM Console".

![After selecting "Create Cluster" in the AWS EKS service in AWS, we give our cluster a name and select "Create Role in IAM Console".](https://github.com/dadonnelly316/airflow_on_aws/blob/main/documentation/images/EKS_step_2.png)

You will be redirected to the IAM console where you will be prompted to create a new role. Keep all the defaults, and give your role a name.
![Name EKS Cluster Role.](https://github.com/dadonnelly316/airflow_on_aws/blob/main/documentation/images/EKS_step_3.png)

Navigate back to the webpage where you were creating your EKS instance. Press the refresh button next to  
![Select EKS Cluster Role.](https://github.com/dadonnelly316/airflow_on_aws/blob/main/documentation/images/EKS_step_4.png)

Keep the remaining defaults, and then navigate to the "Specify Networking" step for creating your EKS cluster. Select the VPC that was created along with your RDS database.
![Specify Networking of EKS Cluster](https://github.com/dadonnelly316/airflow_on_aws/blob/main/documentation/images/EKS_step_5.png)

Keep all other default values for the EKS cluster, and then select "Create Cluster". Once your EKS instance starts up you will then be required to create a Node Group by provisioning an EC2 instance. 

Navigate to the "Compute" tab of your newly created cluster, and select "Add Node Group"
![Add a Node Group to the EC2 Instance](https://github.com/dadonnelly316/airflow_on_aws/blob/main/documentation/images/EKS_step_6.png)

Give your node group any name you prefer. This project used "airflow-node-group". Then, select "Create Role in IAM Console"
![After selecting "Create Cluster" in the AWS EKS service in AWS, we give our cluster a name and select "Create Role in IAM Console".](https://github.com/dadonnelly316/airflow_on_aws/blob/main/documentation/images/EKS_step_7.png)

You will be redirected to the IAM Console to create a Role for the Node Group. Keep all the defaults, and give your role any name
![Giving the Node Group a name.](https://github.com/dadonnelly316/airflow_on_aws/blob/main/documentation/images/EKS_step_8.png)

You will be redirected back to the previous page where you will continue to configure your Node Group. Press the refresh button to populate the Node IAM role with the role you just created.
![Creating an IAM role for the Node Group.](https://github.com/dadonnelly316/airflow_on_aws/blob/main/documentation/images/EKS_step_9.png)

Choose Amazon Linux 2 as our IAM type. Note that this is just the OS running in your EC2 instance. Your containers can contain any OS you prefer, which is Debian in our case.
![Select Amazon Linux 2 as our EC2 OS.](https://github.com/dadonnelly316/airflow_on_aws/blob/main/documentation/images/EKS_step_10.png)

The final step to configuring our Node Group is to set the desired size to 1. You will want more nodes for a production enviorment, but 1 will suffice for testing purposes.
![We create a single node for our Node Group.](https://github.com/dadonnelly316/airflow_on_aws/blob/main/documentation/images/EKS_step_11.png)


## Deploying Airflow

This repo comes with code to help deploy Airflow on AWS. This will involve building the Airflow image locally, and then pushing it to your Amazon Elastic Container Registry. Before creating the Webserver and Scheduler deployments, we will need to create some additional configurations for our cluster, create ConfigMaps and Secrets, and then we can post the deployment mainfest files to the API server.

### Setting up the AWS CLI

You need the AWS CLI to communicate and configure your AWS resources. Navigate to the home directory of this project in your terminal, and run the below script

 ``` bash deploy/aws-cli-install-mac.sh  ```

You will need an API key and secret so that you can authenticate through the AWS CLI. Create a user in the "IAM" service in the AWS console, and attach AmazonEKSClusterPolicy and PowerUserAccess policies to this user. After creating your user, you must select "Create Access Key". Take note of your API key and secret because they will be needed for subsequent steps. 

Now you must execute the below command from the project's home directory. Pass in the API key and secret that were created in the previous step. You must also pass in the AWS region where you created your AWS resources.

 ``` bash deploy/deploy/aws-cli-login.sh ${AWS_API_KEY} ${AWS_API_KEY} ${AWS_REGION} ```

## Author

Name: David Donnelly  
Contact: Daviddonnellydev@gmail.com