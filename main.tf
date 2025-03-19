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

variable "key_name" {}

resource "tls_private_key" "rsa_4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.rsa_4096.public_key_openssh
}

# Save private key locally
resource "local_file" "private_key" {
  content  = tls_private_key.rsa_4096.private_key_pem
  filename = "${var.key_name}.pem"

  provisioner "local-exec" {
    command = "chmod 400 ${var.key_name}.pem"
  }
}

resource "aws_instance" "cloud_1_instance" {
  ami           = "ami-09a9858973b288bdd"
  instance_type = "t3.micro"
  key_name      = aws_key_pair.key_pair.key_name

  tags = {
    Name = "cloud_1_instance"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${var.key_name}.pem")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /home/ubuntu/data/db",
      "sudo mkdir -p /home/ubuntu/data/wordpress",
      "sudo mkdir -p /home/ubuntu/ssl/certs",
      "sudo mkdir -p /home/ubuntu/ssl/private",
      "sudo chown -R ubuntu:ubuntu /home/ubuntu/ssl",
      "sudo chmod -R 755 /home/ubuntu/ssl",
      "sudo apt update -y",
      "sudo apt install docker.io -y",
      "sudo systemctl start docker",
      "sudo usermod -a -G docker $USER",
      "sudo curl -SL https://github.com/docker/compose/releases/download/v2.33.1/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
    ]
  }

  provisioner "local-exec" {
    command = "echo \"DOMAIN_NAME=${self.public_ip}\" >> ./content/.env"
  }

  provisioner "file" {
    source      = "content"
    destination = "/home/ubuntu"
  }

  provisioner "file" {
    source      = "content/.env"
    destination = "/home/ubuntu/.env"
  }

  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "/home/ubuntu/docker-compose.yml"
  }
}

resource "null_resource" "generate_ssl_certificates" {
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${var.key_name}.pem")
    host        = aws_instance.cloud_1_instance.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "openssl req -newkey rsa:2048 -x509 -nodes -days 365 -keyout ./ssl/private/private.key -out ./ssl/certs/certificate.crt -subj \"/C=MO/ST=KO/L=KO/O=42/CN=42.fr\""
    ]
  }
  depends_on = [aws_instance.cloud_1_instance]
}

resource "null_resource" "docker_compose" {
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${var.key_name}.pem")
    host        = aws_instance.cloud_1_instance.public_ip
  }

  provisioner "remote-exec" {
    inline = ["docker-compose up -d"]
  }
  triggers = {
    docker_compose_sha = filesha256("docker-compose.yml")
  }
  depends_on = [aws_instance.cloud_1_instance, null_resource.generate_ssl_certificates]
}

resource "null_resource" "wp_init" {
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${var.key_name}.pem")
    host        = aws_instance.cloud_1_instance.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "echo Waiting for WordPress container to be ready...",
      "sleep 30",
      "if docker ps | grep -q wordpress; then",
      "  echo WordPress container is running, executing initialization script...",
      "  docker exec wordpress bash /tmp/wp-init.sh",
      "else",
      "  echo WordPress container is not running. Please check your docker-compose configuration.",
      "  exit 1",
      "fi"
    ]
  }
  depends_on = [null_resource.docker_compose]
}

# resource "null_resource" "destroy" {
#   provisioner "local-exec" {
#     when    = destroy
#     command = "sed -i '/DOMAIN_NAME/d' ./content/.env"
#   }
# }
