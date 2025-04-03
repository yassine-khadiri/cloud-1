variable "ami_id" {
  description = "the AMI ID to use for the EC2 instance"
  type        = string
  default     = "ami-09a9858973b288bdd"
}

variable "instance_type" {
  description = "the type of EC2 instance to create"
  type        = string
  default     = "t3.micro"
}

variable "region" {
  description = "the AWS region to create the EC2 instance in"
  type        = string
  default     = "eu-north-1"
}

variable "key_name" {
  description = "the name of the SSH key pair used to connect to EC2 instances (corresponds to cloud.pem file)"
  type        = string
  default     = "cloud"
}

variable "inventory_name" {
  description = "the name of the Ansible inventory file"
  type        = string
  default     = "inventory"
}

variable "ansible_vault_password" {
  description = "Password for Ansible Vault encryption"
  type        = string
  sensitive   = true
}
