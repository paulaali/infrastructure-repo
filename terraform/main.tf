provider "aws" {
  region = var.region
}

resource "aws_instance" "app_server" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  security_groups = [aws_security_group.app_sg.name]
  key_name      = var.key_name
}

resource "aws_security_group" "app_sg" {
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "local_file" "ansible_inventory" {
  content = <<-EOT
    [app]
    ${aws_instance.app_server.public_ip}
  EOT
  filename = "../ansible/inventory.ini"
}

resource "null_resource" "ansible" {
  triggers = {
    instance_ip = aws_instance.app_server.public_ip
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ../ansible/inventory.ini ../ansible/playbook.yml"
  }

  depends_on = [local_file.ansible_inventory]
}