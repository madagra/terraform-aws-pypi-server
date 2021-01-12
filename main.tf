resource "aws_security_group" "ec2_instance_sg" {

  vpc_id = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = var.pypi_port
    to_port     = var.pypi_port
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

data "template_cloudinit_config" "config" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = <<EOT
#!/bin/bash

sudo mkdir -p /opt/pypi_server
cd /opt/pypi_server

# create username and password for authentication
sudo yum update -y
sudo yum install -y httpd-tools
sudo htpasswd -b -c htpasswd ${var.pypi_username} ${var.pypi_password} 

# launch script for the PyPi server
cat << EOF > ./run_pypi_server.sh
#!/bin/bash

sudo yum update -y
sudo yum install -y python3
sudo python3 -m pip install passlib
sudo python3 -m pip install pypiserver

sudo python3 -m pypiserver -v -p 8080 -P /opt/pypi_server/htpasswd -a download,update,list /opt/pypi_server/packages
EOF

sudo chmod u+x run_pypi_server.sh
sudo mkdir packages

# add the PyPi server to the running services
cat << EOF > ./pypi_server.service
[Unit]
Description=Private Pypi server
After=network.target

[Service]
Type=simple
ExecStart=/opt/pypi_server/run_pypi_server.sh
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=default.target
EOF

sudo mv ./pypi_server.service /etc/systemd/system
sudo systemctl enable pypi_server.service
sudo systemctl start pypi_server.service

EOT
  }

  dynamic "part" {
    for_each = local.user_data
    content {
      content_type = "text/x-shellscript"
      content      = part.value
    }
  }
}

resource "aws_instance" "pypi" {
  ami           = local.ami_id
  instance_type = var.instance_type
  user_data     = data.template_cloudinit_config.config.rendered

  subnet_id              = var.vpc_subnets[0]
  vpc_security_group_ids = [aws_security_group.ec2_instance_sg.id]

  tags = {
    Name      = "pypi-ec2-instance"
    Terraform = "true"
  }
}