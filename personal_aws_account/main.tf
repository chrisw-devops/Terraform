provider "aws" {
  region = "eu-west-1"
}

module "vpc" {
  source = "../modules/aws/networking"
  cidr_block = "10.0.0.0/16"
  vpc_name = "PersonalVPC"
}