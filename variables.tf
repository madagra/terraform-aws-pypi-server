variable "vpc_id" {
  description = "The ID of the VPC where the PyPi server should run"
  type = string
}

variable "vpc_subnet" {
  description = "The VPC subnet where the PyPi server should run"
  type = string
}

variable "key_pair" {
  description = "A key pair to be used for accessing the PyPi server instance via SSH"
  type = string
}

variable "alb_arn" {
  description = "The ARN of the ALB to which PyPi server requests are forwarded"
  type = string
  default = null
}

variable "domain_name" {
  description = "The domain name to use for accessing the PyPi server"
  type = string
  default = null
}

variable "hashed_password" {
  type = string
  default = null
}

variable "certificate_arn" {
  type = string
  default = null
}

variable "pypi_username" {
  type = string
}

variable "pypi_password" {
  type = string
}

variable "pypi_port" {
  type    = number
  default = 8080
}

variable "user_data" {
  description = "A shell script will be executed at once at EC2 instance start."
  default     = ""
}

data "aws_ssm_parameter" "ec2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

locals {
  pypi_port = 8080
  user_data = var.user_data == "" ? [] : [var.user_data]
  ami_id = data.aws_ssm_parameter.ec2_ami.value
  instance_type = "t3a.nano"
}

