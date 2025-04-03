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

# variable "gpg_passphrase" {
#   description = "the passphrase used to encrypt the SSH private key"
#   type        = string
#   sensitive = true
# }