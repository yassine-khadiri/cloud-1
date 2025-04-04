terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = "default"
}

resource "tls_private_key" "rsa_4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.rsa_4096.public_key_openssh
}

# Save private key locally and encrypt with Ansible Vault
resource "null_resource" "encrypt_key" {
  provisioner "local-exec" {
    command = <<-EOT
      echo '${tls_private_key.rsa_4096.private_key_pem}' > "${var.key_name}.pem" 
      chmod 600 "${var.key_name}.pem"
      echo "${var.ansible_vault_password}" | ansible-vault encrypt --vault-password-file=/bin/cat "${var.key_name}.pem"
    EOT
  }
}

resource "aws_instance" "cloud_1_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.key_pair.key_name

  tags = {
    Name = "cloud_1_instance"
  }
}

resource "null_resource" "create_inventory_directory" {
  provisioner "local-exec" {
    command = "mkdir -p \"../ansible/inventory\""
  }
}

resource "null_resource" "encrypt_inventory" {
  provisioner "local-exec" {
    command = <<-EOT
      echo '[wordpress_servers]
    ${aws_instance.cloud_1_instance.public_ip}

    [wordpress_servers:vars]
    ansible_user=ubuntu
    ansible_ssh_private_key_file=${abspath(path.module)}/${var.key_name}.pem
    ansible_python_interpreter=/usr/bin/python3
    ' > "../ansible/inventory/${var.inventory_name}.ini"

      chmod 600 "../ansible/inventory/${var.inventory_name}.ini"

      echo "${var.ansible_vault_password}" | ansible-vault encrypt --vault-password-file=/bin/cat "../ansible/inventory/${var.inventory_name}.ini"
    EOT
  }

  depends_on = [
    aws_instance.cloud_1_instance,
    null_resource.create_inventory_directory
  ]
}
