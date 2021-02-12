
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
# the port used by the PyPi server must be opened in the security
# group associated with the load balancer
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

  target_groups = [
    {
      backend_protocol = "HTTP"
      backend_port     = var.pypi_port
      target_type      = "ip"
      "health_check" = {
        enabled = true,
        path    = "/"
      }
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      target_group_index = 0
      certificate_arn    = module.acm.this_acm_certificate_arn
    }
  ]

  tags = {
    Name      = "complete-example-alb"
    Terraform = "true"
  }
}
