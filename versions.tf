terraform {
  backend "s3" {
    bucket = "fieldeng-supeng-server-module-bucket"
    key    = "fieldeng-windows-runner-ec2-terraform"
    region = "us-east-1"
    assume_role = {
      role_arn = "arn:aws:iam::992382483259:role/fieldeng_aws_ci_oidc_oauth_role"
    }
  }
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.47.0"
    }
    circleci = {
      source  = "kelvintaywl/circleci"
      version = "1.0.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.1"
    }
  }
}
