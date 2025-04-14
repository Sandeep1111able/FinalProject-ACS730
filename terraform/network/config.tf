terraform {
  backend "s3" {
    bucket = "acs730-finalproject"         
    key    = "prod/network/terraform.tfstate" 
    region = "us-east-1"            
  }
}
