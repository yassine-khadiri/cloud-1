terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "eu-north-1"
  profile = "default"
}

# Generate SSH Key
resource "tls_private_key" "rsa_4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = "cloud_1_key"
  public_key = tls_private_key.rsa_4096.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.rsa_4096.private_key_pem
  filename = "cloud_1_key.pem"
  provisioner "local-exec" {
    command = "chmod 400 cloud_1_key.pem"
  }
}

# Create EC2 Instance
resource "aws_instance" "ubuntu_server" {
  ami           = "ami-09a9858973b288bdd"
  instance_type = "t3.micro"
  key_name      = aws_key_pair.key_pair.key_name

  tags = {
    Name = "cloud_1"
  }
}

# Run Ansible Playbook
resource "null_resource" "run_ansible" {
  depends_on = [aws_instance.ubuntu_server]

  provisioner "local-exec" {
  command = <<EOT
      sleep 30  # Wait for 30 seconds to ensure SSH is ready
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
      -i "${aws_instance.ubuntu_server.public_ip}," \
      -u ubuntu --private-key cloud_1_key.pem \
      -e "public_ip=${aws_instance.ubuntu_server.public_ip}" \
      ansible-playbook.yml
  EOT
}
}

output "public_ip" {
  value = aws_instance.ubuntu_server.public_ip
}
