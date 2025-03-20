# This file contains the Terraform configuration to deploy the application on AWS.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS provider
provider "aws" {
  region = "eu-north-1"
  profile = "default"
}

# Generate a private key
resource "tls_private_key" "rsa-4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# variable "key_name" {}

# generate a key pair
resource "aws_key_pair" "key_pair" {
  key_name   = "cloud_1_key"
  public_key = tls_private_key.rsa-4096.public_key_openssh
}

# Save the private key to a file
resource "local_file" "tls_private_key" {
  content  = tls_private_key.rsa-4096.private_key_pem
  filename = "cloud_1_key.pem"

  provisioner "local-exec" {
    command = "chmod 400 cloud_1_key.pem"
  }
}

# Create an EC2 instance
resource "aws_instance" "ubuntu_server" {
  ami           = "ami-09a9858973b288bdd"
  instance_type = "t3.micro"
  key_name      = aws_key_pair.key_pair.key_name

  tags = {
    Name = "cloud_1"
  }
}

# deploy the application
resource "null_resource" "deploy" {
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.rsa-4096.private_key_pem
    host        = aws_instance.ubuntu_server.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "cd /home/ubuntu/cloud-1",
      "docker compose up -d"
    ]
  }

  triggers = {
    docker_compose_sha = filesha256("./cloud-1/docker-compose.yml")
  }

  depends_on = [null_resource.create_directories]
}

# Create directories
locals {
  directories = [
    "/home/ubuntu/data/db",
    "/home/ubuntu/data/wordpress",
  ]
}

resource "null_resource" "create_directories" {
  for_each   = toset(local.directories)
  depends_on = [null_resource.add_ip]
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.rsa-4096.private_key_pem
    host        = aws_instance.ubuntu_server.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p ${each.value}"
    ]
  }
}

# Install Docker and Docker Compose
resource "null_resource" "install_docker" {

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.rsa-4096.private_key_pem
    host        = aws_instance.ubuntu_server.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Installing Docker and Compose plugin and Terraform ...'",

      # Update system and install prerequisites
      "sudo -i apt-get update",
      "sudo -i apt-get install -y ca-certificates curl",

      # Add Docker'sofficial GPG keys
      "sudo -i install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo -i tee /etc/apt/keyrings/docker.asc > /dev/null",
      "sudo -i chmod a+r /etc/apt/keyrings/docker.asc",
      # "wget -O - https://apt.releases.hashicorp.com/gpg | sudo -i gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg",

      # Add the repository to Apt sources
      "export lsb_release=$(lsb_release -cs)",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $lsb_release stable\" | sudo -i tee /etc/apt/sources.list.d/docker.list > /dev/null",
      # "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $lsb_release main\" | sudo -i tee /etc/apt/sources.list.d/hashicorp.list",
      # Install Docker and Docker Compose plugins and Terraform
      "sudo -i apt-get update",
      "sudo -i apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      # add user to docker group
      "sudo -i usermod -aG docker ubuntu",
      # log in to docker hub
      "sudo -i docker login -u zaranyassen -p Justtest1337",
      "echo 'Docker installation completed!'"
    ]
  }
  depends_on = [aws_instance.ubuntu_server]
}

# copy directories
resource "null_resource" "copy_directories" {
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.rsa-4096.private_key_pem
    host        = aws_instance.ubuntu_server.public_ip
  }
  provisioner "file" {
    source      = "cloud-1"       # Local directory
    destination = "/home/ubuntu/" # Remote directory
  }
  depends_on = [null_resource.install_docker]
}

resource "null_resource" "add_ip" {

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.rsa-4096.private_key_pem
    host        = aws_instance.ubuntu_server.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "cd /home/ubuntu/cloud-1",
      # Use the Terraform variable for public IP
      "export ip=${aws_instance.ubuntu_server.public_ip}",
      "echo \"DOMAIN_NAME=$ip\" >> .env",
      "sed -i \"s/server_name IP;/server_name $ip;/g\" ./nginx/conf/default.conf"
    ]
  }
  depends_on = [null_resource.copy_directories]
}

# Set up the WordPress container
# resource "null_resource" "wp_setup" {
#   connection {
#     type        = "ssh"
#     user        = "ubuntu"
#     private_key = tls_private_key.rsa-4096.private_key_pem
#     host        = aws_instance.ubuntu_server.public_ip
#   }
#   provisioner "remote-exec" {
#     inline = [
#       "echo \"Waiting for WordPress container to be ready...\"",
#       "sleep 30",

#       "if docker ps | grep -q wordpress; then",
#       "  echo \"WordPress container is running, executing initialization script...\"",
#       "  docker exec wordpress bash /tmp/wp-init.sh",
#       "else",
#       "  echo \"WordPress container is not running. Please check your docker-compose configuration.\"",
#       "  exit 1",
#       "fi"
#     ]
#   }
#   depends_on = [null_resource.deploy]
# }

# Set up the Nginx container
# resource "null_resource" "nginx_setup" {
#   connection {
#     type        = "ssh"
#     user        = "ubuntu"
#     private_key = tls_private_key.rsa-4096.private_key_pem
#     host        = aws_instance.ubuntu_server.public_ip
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "echo \"Waiting for Nginx container to be ready...\"",
#       "sleep 30",
#       "if docker ps | grep -q nginx; then",
#       "  echo \"Nginx container is running, executing initialization script...\"",
#       "  docker exec nginx bash /tmp/ng-init.sh",
#       "else",
#       "  echo \"Nginx container is not running. Please check your docker-compose configuration.\"",
#       "  exit 1",
#       "fi"
#     ]

#   }

#   depends_on = [null_resource.deploy, null_resource.wp_setup]
# }

# print the public IP address when the deployment is complete
output "public_ip" {
  value = aws_instance.ubuntu_server.public_ip
}
