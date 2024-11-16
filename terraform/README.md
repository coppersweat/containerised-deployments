# Infrastructure set-up

## Global
Format and validate the configuration:
- `terraform fmt`
- `terraform validate`

Inspect state: `terraform show`

## AWS
These terraform scripts create a publicly accessible Postgres RDS within its own VPC.

1. Authenticate to AWS with the official CLI tool, from a terminal: `aws sso login --profile <your-profile>`
3. Run `terraform init` from the `terraform` folder if it hasn't been initialised as a configuration directory previously. A hidden `.terraform` directory will be created with the modules needed to create the infrastructure on AWS.
4. Run `terraform validate` to validate the configuration.
5. Run `terraform apply -var="aws_profile=edu"` to create all the infrastructure resources needed.

## Clean up

```
terraform destroy -var="aws_profile=edu"
```
