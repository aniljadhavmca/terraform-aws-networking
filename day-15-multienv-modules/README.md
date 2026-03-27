# Basic Cost Optimized Terraform

## Environments
- dev (cheap)
- test (medium)
- prod (scalable)

## Run
cd env/dev
terraform init
terraform apply

## STEP 3 — CONFIGURE CLI
aws configure --profile dev
aws configure --profile prod

## Test
aws sts get-caller-identity --profile dev
aws sts get-caller-identity --profile prod

# STEP-BY-STEP (DEV ENV)
1️⃣ Go to dev folder

cd env/dev

If using profile-based auth (same account)

- terraform init
- terraform plan -var-file="terraform.tfvars"
- terraform apply -var-file="terraform.tfvars"

OR (explicit profile)

AWS_PROFILE=dev terraform plan -var-file="terraform.tfvars"

AWS_PROFILE=dev terraform apply -var-file="terraform.tfvars"

