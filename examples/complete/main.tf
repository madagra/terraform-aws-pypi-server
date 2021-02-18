# ========= variables ==========

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

variable "pypi_port" {
  description = "The port needed by the PyPi server"
  type        = number
  default     = 8080
}

variable "domain_name" {
  description = "The domain name to reach the PyPi server"
  type        = string
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
  version = "~> 2.66.0"

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
    Name      = "complete-example-vpc"
    Terraform = "true"
  }
}

# ========= service ==========

module "pypi_server" {

  source = "../../"

  vpc_id          = module.vpc.vpc_id
  vpc_subnet      = module.vpc.private_subnets[0]
  pypi_username   = "admin"
  pypi_password   = "password"
  has_alb         = true
  alb_arn         = module.alb.this_lb_arn
  certificate_arn = module.acm.this_acm_certificate_arn
}


output "upload_package_pypi" {
  value = "To upload a package to the PyPi server, modify ~/.pypirc file and use: python setup.py sdist upload -r cloud"
}

output "install_package_pypi" {
  value = "To install a package available in the PyPi server use: pip install --index-url https:/admin:password@${var.domain_name}:8080/simple/ PACKAGE [PACKAGE2...]"
}