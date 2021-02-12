output "pypi_public_dns" {
  description = "The public DNS of the EC2 instance running the PyPi server"
  value = aws_instance.pypi.public_dns
}

output "pypi_public_ip" {
  description = "The public IP of the EC2 instance running the PyPi server"
  value = aws_instance.pypi.public_ip
}
