
locals {
  account_id = data.aws_caller_identity.current.account_id
}

variable "aws_region" {
  description = "Region where instances get created"
  default     = "us-east-1"
}

data "aws_subnet" "us_east_1a_subnet_id" {
  availability_zone = "us-east-1a"
  default_for_az    = true
}

output "us_east_1a_subnet_id" {
  value = data.aws_subnet.us_east_1a_subnet_id.id
}

variable "ec2_bastion_security_groups" {
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
