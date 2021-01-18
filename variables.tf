variable "vpc_id" {
  description = "The ID of the VPC where the PyPi server should run"
  type        = string
}

variable "vpc_subnet" {
  description = "The VPC subnet where the PyPi server instance should run"
  type        = string
}

variable "alb_arn" {
  description = "The ARN of the ALB to which PyPi server requests are forwarded"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  type    = string
  default = null
}

variable "pypi_username" {
  description = "The username for uploading and download packages from the PyPi server"
  type        = string
}

variable "pypi_password" {
  description = "The password corresponding to the pypi_username variable"
  type        = string
}

variable "instance_type" {
  description = "The type of the EC2 instance to install the PyPi server on"
  type        = string
  default     = "t3a.nano"
}

variable "pypi_port" {
  type    = number
  default = 8080
}

data "aws_ssm_parameter" "ec2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

locals {
  ami_id    = data.aws_ssm_parameter.ec2_ami.value
  count_alb = var.alb_arn == null ? 1 : 0
}

