terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "docuvault-terraform-state-<YOUR_ACCOUNT_ID>"
    key            = "environments/preprod/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "docuvault-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "docuvault"
      Environment = "preprod"
      ManagedBy   = "terraform"
    }
  }
}
