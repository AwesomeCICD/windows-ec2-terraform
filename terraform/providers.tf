provider "aws" {
  assume_role {
    role_arn     = "arn:aws:iam::992382483259:role/fieldeng_aws_ci_oidc_oauth_role"
    session_name = "fieldeng_aws_oidc_oauth_terraform"
  }
  region = var.aws_region

  default_tags {
    tags = var.default_tags
  }
}