# ========= variables ==========

variable "ecs_role" {
  description = "The name of the role to be assumed by ECS tasks"
  type        = string
  default     = "EcsTaskExecutionRole"
}

variable "app_port" {
  description = "The port where it runs the qubec API server"
  default     = 27017
}

variable "profile" {
  description = "The AWS profile configured locally"
  type        = string
  default     = "default"
}

variable "region" {
  description = "The AWS region where to start the ECS service"
  type        = string
  default     = "us-east-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

# ========= providers ==========

provider "aws" {
  region  = var.region
  profile = var.profile
}

# ========= resources ==========

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.48.0"

  name = "sample_vpc"
  cidr = "10.0.0.0/16"

  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_ipv6          = false
  enable_nat_gateway   = true
  enable_vpn_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = "basic-example-vpc"
    Terraform = "true"
  }
}

# ========= service ==========

module "pypi_server" {

  count = local.build_pypi

  source = "../../"

  vpc_id          = module.vpc.vpc_id
  vpc_subnet      = module.vpc.public_subnets[0]
  pypi_username   = var.pypi_username
  pypi_password   = var.pypi_password
}

