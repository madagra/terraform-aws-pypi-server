
# here it is assumed that a DNS zone is already available
# a public DNS zone is automatically created when the
# domain is purchased
data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

module "acm" {

  source = "terraform-aws-modules/acm/aws"

  domain_name = var.domain_name
  zone_id     = data.aws_route53_zone.this.zone_id

  wait_for_validation = true

  tags = {
    Name      = "complete-example-cert"
    Terraform = "true"
  }

}

resource "aws_route53_record" "dns_record" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = data.aws_route53_zone.this.name
  type    = "A"
  alias {
    name                   = module.alb.this_lb_dns_name
    zone_id                = module.alb.this_lb_zone_id
    evaluate_target_health = false
  }
}

# NOTE
# the port used by the PyPi server and HTTPS port must be opened 
# in the security group associated with the load balancer since Terraform
# does not currently support to add single rules to security groups after creation
resource "aws_security_group" "alb_sg" {

  vpc_id = module.vpc.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = var.pypi_port
    to_port     = var.pypi_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "complete-example-sg-alb"
    Terraform = "true"
  }

}

module "alb" {

  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.10.0"

  name               = "pypi-alb"
  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [aws_security_group.alb_sg.id]

  tags = {
    Name      = "complete-example-alb"
    Terraform = "true"
  }
}
