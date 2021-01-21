output "pypi_public_dns" {
  value = aws_instance.pypi.public_dns
}

output "pypi_public_ip" {
  value = aws_instance.pypi.public_ip
}
