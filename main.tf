locals {
  directories = [
    "/home/ykhadiri/data/db",
    "/home/ykhadiri/data/wordpress",
    # "./ssl/certs", 
    # "./ssl/private"
  ]
}

resource "null_resource" "create_directories" {
  for_each = toset(local.directories)

  provisioner "local-exec" {
    command = "mkdir -p ${each.value}"
  }
}

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

resource "null_resource" "docker_compose" {
  provisioner "local-exec" {
    command = "docker-compose up -d"
  }
  triggers = {
    docker_compose_sha = filesha256("docker-compose.yml")
  }
  depends_on = [ null_resource.create_directories ]
}

resource "null_resource" "nginx" {
    provisioner "local-exec" {
     command = <<EOT
      echo "Waiting for nginx container to be ready..."
      sleep 30
      
      # Check if nginx container is running
      if docker ps | grep -q nginx; then
        echo "nginx container is running, executing initialization script..."
        docker exec nginx bash /tmp/nginx-init.sh
      else
        echo "nginx container is not running. Please check your docker-compose configuration."
        exit 1
      fi
    EOT
  }
  depends_on = [ null_resource.docker_compose ]
}

resource "null_resource" "wp_init" {
  provisioner "local-exec" {
     command = <<EOT
      echo "Waiting for WordPress container to be ready..."
      sleep 30
      
      # Check if WordPress container is running
      if docker ps | grep -q wordpress; then
        echo "WordPress container is running, executing initialization script..."
        docker exec wordpress bash /tmp/wp-init.sh
      else
        echo "WordPress container is not running. Please check your docker-compose configuration."
        exit 1
      fi
    EOT
  }
  depends_on = [ null_resource.docker_compose ]
}


# provisioner "local-exec" {
#   when    = destroy
#   command = "docker-compose -f ${path.module}/docker-compose.yml down"
# }
