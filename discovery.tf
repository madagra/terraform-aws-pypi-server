resource "aws_lb_target_group" "pypi_tg" {
  name     = "pypi-tg"
  port     = var.pypi_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_target_group_attachment" "pypi_tg_attachment" {
  target_group_arn = aws_lb_target_group.pypi_tg.arn
  target_id        = aws_instance.bastion.id
  port             = var.pypi_port
}

resource "aws_lb_listener" "pypi_listener" {
  load_balancer_arn = var.alb_arn
  port              = local.pypi_port
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pypi_tg.arn
  }
}