variable "env" {
  default = "prod"
}

variable "prefix" {
  default = "group"
}

variable "vpc_cidr" {
  default = "10.1.0.0/16"
}

variable "public_cidr_blocks" {
  default = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24", "10.1.4.0/24"]
}

variable "private_cidr_blocks" {
  default = ["10.1.5.0/24", "10.1.6.0/24"]
}

variable "default_tags" {
  default = {
    project = "acs730"
  }
}
