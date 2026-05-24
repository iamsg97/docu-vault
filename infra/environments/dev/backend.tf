terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Run infra/bootstrap/ first to provision this bucket and lock table.
    # Replace <YOUR_ACCOUNT_ID> with the output of: aws sts get-caller-identity --query Account --output text
    bucket         = "docuvault-terraform-state-<YOUR_ACCOUNT_ID>"
    key            = "environments/dev/terraform.tfstate"
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
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}
