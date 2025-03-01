provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

locals {
  cluster_name = "airflow"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "airflow-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

# note: terrafrom will create a security group
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = local.cluster_name
  cluster_version = "1.29"

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true


  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }

    two = {
      name = "node-group-2"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
}

resource "aws_security_group_rule" "allow_http_https" {
  type              = "ingress"
  from_port         = 80
  to_port           = 443
  protocol         = "tcp"
  security_group_id = module.eks.cluster_security_group_id
  cidr_blocks       = ["0.0.0.0/0"]
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = local.cluster_name
}

data "aws_eks_cluster" "cluster_info" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster_info.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster_info.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token

  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}


# Ingress Controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  depends_on = [module.eks, data.aws_eks_cluster_auth.cluster_auth]

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
}

# ECR instance
resource "aws_ecr_repository" "airflow" {
  name                 = "airflow-ecr"
  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_iam_role_policy_attachment" "eks_ecr_readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = module.eks.cluster_iam_role_name
}

# make sure EKS can pull images from ECR
resource "aws_iam_role_policy_attachment" "node_ecr_read" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = module.eks.eks_managed_node_groups["one"].iam_role_name
}

# Airflow's DB backend
resource "aws_db_instance" "airflow" {
  identifier             = "airflow"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "16.3"
  username               = "airflow"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.airflow.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.airflow.name
  max_allocated_storage  = 0
  publicly_accessible    = true
  skip_final_snapshot    = true

}

resource "aws_db_parameter_group" "airflow" {
  name   = "airflow-db-param-group"
  family = "postgres16"

  parameter {
    name  = "log_statement"
    value = "all"
  }
}


resource "aws_db_subnet_group" "airflow" {
  name       = "airflow-subnet-group"
  subnet_ids = module.vpc.private_subnets
  description = "Subnet group for Airflow RDS instance"
}
 
 resource "aws_security_group" "rds" {
  name        = "rds-security-group"
  description = "Allows EKS to connect to RDS"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "allow_eks_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id 
  source_security_group_id = module.eks.cluster_security_group_id
}

# gets my IP address so that I can allow traffic from my computer to access RDS
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

resource "aws_security_group_rule" "allow_personal_computer" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol         = "tcp"
  security_group_id = aws_security_group.rds.id
  cidr_blocks = [
    "${chomp(data.http.my_ip.body)}/32"
  ]
}

resource "aws_security_group_rule" "allow_rds_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol         = "-1"
  security_group_id = aws_security_group.rds.id
  cidr_blocks       = ["0.0.0.0/0"]
}

