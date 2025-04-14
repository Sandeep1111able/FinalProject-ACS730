variable "env" {
  default = "prod"
}

variable "prefix" {
  default = "group"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "default_tags" {
  default = {
    project = "acs730"
  }
}
