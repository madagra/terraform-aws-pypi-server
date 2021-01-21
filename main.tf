resource "aws_security_group" "ec2_instance_sg" {

  vpc_id = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = var.pypi_port
    to_port     = var.pypi_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "pypi-ec2-sg"
    Terraform = "true"
  }
}

data "template_file" "cloud-init" {

  template = file("${path.module}/cloud-init.yaml")

  vars = {
    pypi_username = var.pypi_username
    pypi_password = var.pypi_password
  }
}

resource "aws_instance" "pypi" {
  ami           = local.ami_id
  instance_type = var.instance_type
  user_data     = data.template_file.cloud-init.rendered
  key_name      = "dev-kp-us-west-1"

  subnet_id              = var.vpc_subnet
  vpc_security_group_ids = [aws_security_group.ec2_instance_sg.id]

  tags = {
    Name      = "pypi-ec2-instance"
    Terraform = "true"
  }
}

resource "aws_lb_target_group" "pypi_tg" {
  count    = local.count_alb
  name     = "pypi-tg"
  port     = var.pypi_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_target_group_attachment" "pypi_tg_attachment" {
  count            = local.count_alb
  target_group_arn = aws_lb_target_group.pypi_tg[0].arn
  target_id        = aws_instance.pypi.id
  port             = var.pypi_port
}

resource "aws_lb_listener" "pypi_listener" {
  count             = local.count_alb
  load_balancer_arn = var.alb_arn
  port              = var.pypi_port
  protocol          = var.certificate_arn == null ? "HTTP" : "HTTPS"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pypi_tg[0].arn
  }
}