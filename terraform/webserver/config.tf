terraform {
  backend "s3" {
    bucket = "acs730-finalbucket"         
    key    = "prod/webserver/terraform.tfstate" 
    region = "us-east-1"            
  }
}

