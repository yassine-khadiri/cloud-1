variable "key_name" {
    description = "the name of the SSH key pair used to connect to EC2 instances (corresponds to cloud.pem file)"
    type = string
    default = "cloud"
}