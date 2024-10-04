# windows-ec2-terraform

A simple Terraform template for spinning up CircleCI Windows EC2 instances with Machine Runner 3.0 pre-installed.

## Prerequisites 

Create a runner resource class and token for your Windows Runner and store the token in AWS Secrets Manager using the command below:

```
aws secretsmanager create-secret \
    --name windows-ec2-terraform \
    --description "Token for Windows EC2 Terraform runner" \
    --secret-string '{"win_runner_token":"your_token_value"}'
```

## Disclaimer

This repo, is a collection of solutions developed by members of CircleCI's field engineering teams through our engagement with various customer needs.

   - ✅ Created by engineers @ CircleCI
   - ✅ Used by real CircleCI customers
   - ❌ not officially supported by CircleCI support
