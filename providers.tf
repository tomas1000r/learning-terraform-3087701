terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket = "terraform"
    key    = "state"
    region = "us-east-2"
  }
}

provider "aws" {
  region  = "us-east-2"
}
