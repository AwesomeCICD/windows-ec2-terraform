

output "us_east_1a_subnet_id" {
  value = data.aws_subnet.us_east_1a_subnet_id.id
}


output "account_id" {
  value = data.aws_caller_identity.current.account_id
}