## Airflow on AWS

A simple Apache Airflow deployment on Amazon _**Elastic Kubernetes Service**_ (_**EKS**_) with an **Elastic Compute Cloud (EC2)** node group and a **Relational Database Service (RDS)** for PostgreSQL database backend. 

## Description

This project packages Airflow's dependancies into a Docker image that is capable of running inside of Kubernetes. This is an Amazon Web Services focused project, so it comes with additional scripts that facilitate the deployment of Airflow on Amazon Elastic Kubernetes Service. 

This Airflow deployment ships with Python 3.12 and Apache Airflow 2.9.0. This version of Airflow was tested with Debian Bookworm, so it uses python:3.12-slim-bookworm as its base image. Airflow is installed directly using PyPI (pip), and its dependancies and startup scripts are manually installed and configured without the assistance of any services or modules specific to Airflow. This project references Airflow's documentation and contains helpful commentary so that one can understand how to deploy Airflow from scratch.

This project uses Airflow's [Kubernetes Executor](https://airflow.apache.org/docs/apache-airflow-providers-cncf-kubernetes/stable/kubernetes_executor.html), and is safe to perform ETL tasks inside of Airflow if your operators pull data into memory in reasonable-sized batches. It is a common sentiment that Airflow is an orchestration tool, and should only be used to trigger your ETL jobs, which are executed somewhere else. This is absolutely true for big data workloads that require distributed processing. Additionally, this is also true if your Airflow is deployed in a VM or a single node bare-metal server using the celery executor. By design, the Celery Executor doesn't isolate compute resources for distinct tasks that are running on a given worker, which can lead to OOM errors. The Kubernetes Executor will spin up a transient pod that's dedicated to an individual task run, and you're able to define memory limits to control resource usage on your cluster. If Airflow is being operated at an enterprise scale or if your tasks have dependancy conflicts with Airflow, then you could store your DAG code inside of an image separate from airflow and then invoke it in your DAG using the KubernetesOperator. However, the end-effect is the same if your ETL is performed inside or outside of Airflow, so it's reasonable to perform your ETL directly inside of Airflow for use cases where your deployment is limited to a single team. You will just need to make sure that your operators commit data in small batches so that you're not pulling a full dataset into memory.

### Productionalizing Airflow

This is not a production ready deployment. This project does come with scripts that can be plugged into your CI/CD platform, but it's meant to run on a MacOS or Linux personal machine. A production deployment also needs robust build and unit testing, which isn't currently in the scope of this project. The logs will also need to be offloaded to external storage or an external logging service, which involves overwriting Airflow's default log handler. This project attempts to prevent Airflow from offloading the logs in EC2 by configuring base_log_folder (AIRFLOW__LOGGING__BASE_LOG_FOLDER) to an empty string, but this is was not well tested. 

Some additional considerations for a production deployment include configuring authentication for your Airflow webserver. Airflow's webserver is built on top of [Flask App Builder (F.A.B.)](https://flask-appbuilder.readthedocs.io/en/latest/), which is a customizable web application scafolding module. By default it stores your Airflow credentails in the database backend, but you're also able to override this default behavior in Airflow's (webserver_config.py)[https://airflow.apache.org/docs/apache-airflow/stable/configurations-ref.html#config-file] file so that you can [authenticate with SSO](https://flask-appbuilder.readthedocs.io/en/latest/security.html). 

By default, Airflow will store secrets inside the postgres database, which can be decrypted by an attacker if they obtain your [fernet key](https://airflow.apache.org/docs/apache-airflow/stable/security/secrets/fernet.html). A secure production environment should instead use a secure (secrets backend)[https://airflow.apache.org/docs/apache-airflow/stable/security/secrets/fernet.html].

If Airflow is being operated at an enterprise scale, then a robust deployment should also decouple the DAGs folder from the Airflow image. Typically, your DAGs are routinly updated relative to Airflow's other components. Moving your updated DAGs to production can be delayed if Airflow needs to build and deploy all of its components every time you want to update a DAG. Alternatly, your [dags_folder](https://airflow.apache.org/docs/apache-airflow/stable/configurations-ref.html#dags-folder) can be stored external to Airflow so that a new build isn't triggered every time a dag is updated.




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

 ``` bash deploy/aws-cli-login.sh ${AWS_API_KEY} ${AWS_API_KEY} ${AWS_REGION} ```

### Build and Push Images to ECR

You cannot yet interact with your image registry even though you're authenticated to AWS through the CLI. Run the below command from the project's home directory, and pass in your AWS account ID (found in the AWS console) and the AWS region where your resources were provisioned. 

 ``` bash deploy/aws-ecr-login.sh ${AWS_ACCOUNT} ${AWS_REGION} ```

Execute the below command from the project's home directory, and pass in the the image registry URL without the repository name (the project assumes that the repository is named airflow). If you don't know this, navigate to Amazon Elastic Container Registry in the AWS Console, select the airflow registry, and check the URI field. Don't include '/airflow' at the end of the URI.

 ``` bash deploy/aws-ecr-build-push-airflow-images ${REMOTE_IMAGE_REIGSTRY} ```

 You now built your Airflow image and pushed it to your private registry. Note that this one image is used for both the scheduler and the webserver, but the deployment manifest files for the webserver and scheduler have different entrypoint scripts that run different tasks to start their respective components correctly.

## Author

Name: David Donnelly  
Contact: Daviddonnellydev@gmail.com