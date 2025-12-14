terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.0.0"
    }
  }
  backend "s3" {
    bucket         = "khanhhocdevops-s3-bucket"
    region         = "ap-southeast-2"
    key            = "eks/terraform.tfstate"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws-region
}

