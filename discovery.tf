locals {
  count_acm       = var.domain_name != null && var.alb_arn == null ? 1 : 0
  count_alb       = var.alb_arn == null ? 1 : 0
  alb_arn         = var.alb_arn == null ? module.alb.this_lb_arn : var.alb_arn
  certificate_arn = var.certificate_arn == null ? module.acm.this_acm_certificate_arn : var.certificate_arn
}

data "aws_route53_zone" "this" {
  count        = var.use_existing_route53_zone ? 1 : 0
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_zone" "this" {
  count = !var.use_existing_route53_zone ? 1 : 0
  name  = var.domain_name
}

module "acm" {

  count = local.count_acm

  source = "terraform-aws-modules/acm/aws"

  domain_name = var.domain_name
  zone_id     = coalescelist(data.aws_route53_zone.this.*.zone_id, aws_route53_zone.this.*.zone_id)[0]

  wait_for_validation = true

  tags = {
    Name      = local.cert_name
    Terraform = "true"
  }

}

resource "aws_route53_record" "alb_dns_record" {
  zone_id = coalescelist(data.aws_route53_zone.this.*.zone_id, aws_route53_zone.this.*.zone_id)[0]
  name    = coalescelist(data.aws_route53_zone.this.*.name, aws_route53_zone.this.*.name)[0]
  type    = "A"
  alias {
    name                   = module.alb.this_lb_dns_name
    zone_id                = module.alb.this_lb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_security_group" "alb_sg" {

  count = local.count_alb

  vpc_id      = var.vpc_id
  description = "PyPi server ALB security group"

  # PyPi server port
  ingress {
    protocol    = "tcp"
    from_port   = var.pypi_port
    to_port     = var.pypi_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS port
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
    Name      = "pypi-server-sg-alb"
    Terraform = "true"
  }

}

module "alb" {

  count = local.count_alb

  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.10.0"

  name               = "pypi_server_alb"
  load_balancer_type = "application"

  vpc_id          = var.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [aws_security_group.alb_sg.id]

  tags = {
    Name      = "pypi-server-alb"
    Terraform = "true"
  }
}

resource "aws_lb_target_group" "pypi_tg" {
  name     = "pypi-tg"
  port     = var.pypi_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_target_group_attachment" "pypi_tg_attachment" {
  target_group_arn = aws_lb_target_group.pypi_tg.arn
  target_id        = aws_instance.pypi.id
  port             = var.pypi_port
}

resource "aws_lb_listener" "pypi_listener" {
  load_balancer_arn = local.alb_arn
  port              = local.pypi_port
  protocol          = "HTTPS"
  certificate_arn   = local.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pypi_tg.arn
  }
}