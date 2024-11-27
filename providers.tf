terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket = "6813-2019-4274-terraform"
    key    = "state"
    region = "us-east-2"
  }
}

provider "aws" {
  region  = "us-east-2"
}
