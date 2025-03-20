terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                   = "eu-north-1"
  shared_config_files      = ["/home/ymoutaou/.aws/config"]
  shared_credentials_files = ["/home/ymoutaou/.aws/credentials"]
}

resource "tls_private_key" "rsa-4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# variable "key_name" {}

resource "aws_key_pair" "key_pair" {
  key_name   = "cloud_1_key"
  public_key = tls_private_key.rsa-4096.public_key_openssh
}

resource "local_file" "tls_private_key" {
  content  = tls_private_key.rsa-4096.private_key_pem
  filename = "cloud_1_key.pem"
}

# resource "aws_security_group" "instance_sg" {
#   name        = "instance_security_group"
#   description = "Allow SSH, HTTP, and HTTPS inbound traffic"

#   vpc_id = "vpc-0dfc5f41d0c93a10b"

#   # Allow SSH access from anywhere (or specify a restricted IP range)
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   # Allow HTTP (80) access from anywhere
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   # Allow HTTPS (443) access from anywhere
#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   # Allow all outbound traffic (default behavior)
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "cloud_1_sg"
#   }
# }


resource "aws_instance" "ubuntu_server" {
  ami                    = "ami-09a9858973b288bdd"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.key_pair.key_name
  # vpc_security_group_ids = [aws_security_group.instance_sg.id] # Attach SG

  tags = {
    Name = "cloud_1"
  }
}

resource "null_resource" "install_packages" {
  depends_on = [aws_instance.ubuntu_server]

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
}

resource "null_resource" "copy_directories" {
  depends_on = [null_resource.install_packages]

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
}

resource "null_resource" "add_ip" {
  depends_on = [null_resource.copy_directories]

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
      "sed -i \"s/server_name IP;/server_name $ip;/g\" ./nginx/default.conf"
    ]
  }
}

locals {
  directories = [
    "/home/ubuntu/data/db",
    "/home/ubuntu/data/wordpress",
    # "./ssl/certs",  
    # "./ssl/private"
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

resource "null_resource" "nginx_init" {
  provisioner "remote-exec" {
    # inline = [
    #   "openssl req -newkey rsa:2048 -x509 -nodes -days 365 -keyout /home/ubuntu/ssl/private/private.key -out /home/ubuntu/ssl/certs/certificate.crt -subj \"/C=MO/ST=KO/L=KO/O=42/CN=42.fr\""
    # ]
    inline = [
      "echo \"Waiting for Nginx container to be ready...\"",
      "sleep 30",
      "if docker ps | grep -q nginx; then",
      "  echo \"Nginx container is running, executing initialization script...\"",
      "  docker exec nginx bash /tmp/ng-init.sh",
      "else",
      "  echo \"Nginx container is not running. Please check your docker-compose configuration.\"",
      "  exit 1",
      "fi"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.rsa-4096.private_key_pem
      host        = aws_instance.ubuntu_server.public_ip
    }
  }

  depends_on = [null_resource.deploy, null_resource.wp_init]
}

resource "null_resource" "deploy" {
  provisioner "remote-exec" {
    inline = [
      "cd /home/ubuntu/cloud-1",
      "docker compose up -d"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.rsa-4096.private_key_pem
      host        = aws_instance.ubuntu_server.public_ip
    }
  }
  triggers = {
    docker_compose_sha = filesha256("./cloud-1/docker-compose.yml")
  }

  depends_on = [null_resource.create_directories]
}

resource "null_resource" "wp_init" {
  provisioner "remote-exec" {
    inline = [
      "echo \"Waiting for WordPress container to be ready...\"",
      "sleep 30",

      "if docker ps | grep -q wordpress; then",
      "  echo \"WordPress container is running, executing initialization script...\"",
      "  docker exec wordpress bash /tmp/wp-init.sh",
      "else",
      "  echo \"WordPress container is not running. Please check your docker-compose configuration.\"",
      "  exit 1",
      "fi"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.rsa-4096.private_key_pem
      host        = aws_instance.ubuntu_server.public_ip
    }
  }
  depends_on = [null_resource.deploy]
}
