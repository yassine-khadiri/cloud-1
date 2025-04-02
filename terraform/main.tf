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

resource "tls_private_key" "rsa_4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.rsa_4096.public_key_openssh
}

# Save encrypted private key locally
# resource "null_resource" "encrypt_key" {
#   provisioner "local-exec" {
#     command = <<-EOT
#       echo '${tls_private_key.rsa_4096.private_key_pem}' | \
#       gpg --batch --passphrase "${var.gpg_passphrase}" \
#           --symmetric --cipher-algo AES256 \
#           --output "${var.key_name}.pem.gpg"
#     EOT
#   }
# }

# output "decrypt_command" {
#   value = "gpg --decrypt ${var.key_name}.pem.gpg"
# }

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
  ami           = "ami-09a9858973b288bdd"
  instance_type = "t3.micro"
  key_name      = aws_key_pair.key_pair.key_name

  tags = {
    Name = "cloud_1_instance"
  }
}

resource "local_file" "ansible_inventory" {
  content = <<-EOT
    [wordpress_servers]
    ${aws_instance.cloud_1_instance.public_ip}

    [wordpress_servers:vars]
    ansible_user=ubuntu
    ansible_ssh_private_key_file=${abspath(path.module)}/${var.key_name}.pem
    ansible_python_interpreter=/usr/bin/python3
  EOT

  filename = "../ansible/inventory/inventory.ini"

  depends_on = [aws_instance.cloud_1_instance,null_resource.encrypt_key]
}

#   provisioner "local-exec" {
#     command = "echo \"DOMAIN_NAME=${self.public_ip}\" >> ./content/.env"
#   }

# resource "null_resource" "cleanup" {
#   triggers = {
#     instance_id = aws_instance.cloud_1_instance.id
#   }

#   provisioner "local-exec" {
#     when    = destroy
#     command = "sed -i '/DOMAIN_NAME=/d' ./content/.env"
#   }

#   depends_on = [aws_instance.cloud_1_instance]
# }
