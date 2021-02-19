# Terraform module to deploy a private PyPi server on AWS EC2

This simple module deploys a private, password-protected PyPi repository running on an AWS EC2 instance within a VPC.
Optionally, one can also provide the ARN of a load balancer to put in front of the PyPi server to allow querying
it with HTTPS requests.


## Usage

The module can be used in the following way:

```hcl

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.66.0"

  name = "sample_vpc"
  cidr = "10.0.0.0/16"

  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

}

module "pypi_server" {

  source = "github.com/madagra/terraform-aws-pypi-server"

  vpc_id        = module.vpc.vpc_id
  vpc_subnet    = module.vpc.public_subnets[0]
  pypi_username = "admin"
  pypi_password = "password"
}
```

The example above is minimal but complete. The only external resource necessary to run the server is the VPC where the
EC2 instance is provisioned. More detailed examples are contained in the folder `examples/`.


## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.5 |
| aws | >= 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.0.0 |
| template | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| alb\_arn | The ARN of the application load balancer forwarding HTTP requests to the PyPi server | `string` | `""` | no |
| certificate\_arn | The ARN of the certificate to enable HTTPS communication with the load balancer | `string` | `""` | no |
| ebs\_size | The size in GB of the EBS disk to use for PyPi package storage | `number` | `2` | no |
| has\_alb | A flag to determine whether the PyPi server should be put behind an application load balancer | `bool` | `false` | no |
| instance\_type | The type of the EC2 instance to install the PyPi server on | `string` | `"t3a.nano"` | no |
| pypi\_password | The password corresponding to the pypi\_username variable. Keep default only for testing. | `string` | `"password"` | no |
| pypi\_port | The port to which the PyPi server is listening | `number` | `8080` | no |
| pypi\_username | The username for uploading and download packages from the PyPi server. Keep default only for testing. | `string` | `"admin"` | no |
| security\_groups | Additional security groups to associate to the EC2 instance | `list(any)` | `[]` | no |
| vpc\_id | The ID of the VPC where the PyPi server should run | `string` | n/a | yes |
| vpc\_subnet | The VPC subnet where the PyPi server instance should run | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| pypi\_public\_dns | The public DNS of the EC2 instance running the PyPi server |
| pypi\_public\_ip | The public IP of the EC2 instance running the PyPi server |