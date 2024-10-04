data "aws_secretsmanager_secret" "windows_ec2_runner_token" {
  name = "windows-ec2-terraform"
}

data "aws_secretsmanager_secret_version" "windows_ec2_runner_token_version" {
  secret_id = data.aws_secretsmanager_secret.windows_ec2_runner_token.id
}