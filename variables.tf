

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

variable "aws_region" {
  description = "Region where instances get created"
  default     = "us-east-1"
}

variable "circle_server_endpoint" {
  description = "CircleCI Server Endpoint for Server Customers"
  default     = "server4.fieldeng-sphereci.com"
}

variable "windows_runner_ami" {
  type        = string
  default     = "ami-0888db1202897905c"
  description = "amazon/Windows_Server-2022-English-Full-Base-2024.09.11"
}

data "aws_subnet" "us_east_1a_subnet_id" {
  availability_zone = "us-east-1a"
  default_for_az    = true
}

variable "windows_runner_instance_type" {
  type    = string
  default = "t3a.medium"
}

variable "windows_server_keypair" {
  type        = string
  description = "Keypair to be associated with the Windows Servers"
  default     = "windows-rsa-support-keypair"
}

variable "windows_runner_security_groups" {
  type        = list(string)
  description = "Security Group to be assigned to Windows Runner instances"
  default     = ["sg-0c3c61cd884f24fd7"]
}

variable "default_tags" {
  type = map(string)
  default = {
    "Environment"       = "server4.fieldeng-sphereci.com"
    "Terraform"         = "true"
    "team"              = "fieldeng"
    "critical-resource" = "critical-until-2024-08-31"
    "owner"             = "fieldeng"
  }
}
