variable "vpc_id" {
  description = "The ID of the VPC where the PyPi server should run"
  type        = string
}

variable "vpc_subnet" {
  description = "The VPC subnet where the PyPi server instance should run"
  type        = string
}

variable "pypi_username" {
  description = "The username for uploading and download packages from the PyPi server. Keep default only for testing."
  type        = string
  default     = "admin"
}

variable "pypi_password" {
  description = "The password corresponding to the pypi_username variable. Keep default only for testing."
  type        = string
  default     = "password"
}

variable "has_alb" {
  description = "A flag to determine whether the PyPi server should be put behind an application load balancer"
  type        = bool
  default     = false
}

variable "alb_arn" {
  description = "The ARN of the application load balancer forwarding HTTP requests to the PyPi server"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "The ARN of the certificate to enable HTTPS communication with the load balancer"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "The type of the EC2 instance to install the PyPi server on"
  type        = string
  default     = "t3a.nano"
}

variable "ebs_size" {
  description = "The size in GB of the EBS disk to use for PyPi package storage"
  type        = number
  default     = 2
}

variable "pypi_port" {
  type        = number
  description = "The port to which the PyPi server is listening"
  default     = 8080
}

data "aws_ssm_parameter" "ec2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

locals {
  ami_id    = data.aws_ssm_parameter.ec2_ami.value
  count_alb = var.has_alb == true ? 1 : 0
}
