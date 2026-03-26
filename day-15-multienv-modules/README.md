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


3_Custom_config_terraform-tfvars_each_env/
├── provider.tf # Shared for all environments
├── variables.tf # Shared for all environments
├── main.tf # Shared for all environments
├── outputs.tf # Shared for all environments
├── deploy.sh # Bash deployment script
├── deploy.ps1 # PowerShell deployment script
├── dev/
│ ├── terraform.tfvars # Dev-specific values only
│ └── terraform.tfstate # Dev state file (auto-created)
├── test/
│ ├── terraform.tfvars # Test-specific values only
│ └── terraform.tfstate # Test state file (auto-created)
└── prod/
├── terraform.tfvars # Prod-specific values only
└── terraform.tfstate # Prod state file (auto-created)

## Method 1: Using Deployment Scripts (Recommended)

Bash:

# Plan changes
./deploy.sh dev plan
./deploy.sh test plan
./deploy.sh prod plan

# Deploy changes
./deploy.sh dev apply
./deploy.sh test apply
./deploy.sh prod apply

# Destroy resources
./deploy.sh dev destroy
./deploy.sh test destroy
./deploy.sh prod destroy


# Method 2: Manual Commands from Root Directory

Development:

terraform init
terraform plan -var-file="./dev/terraform.tfvars"
terraform apply -var-file="./dev/terraform.tfvars"

Test:

terraform init
terraform plan -var-file="./test/terraform.tfvars"
terraform apply -var-file="./test/terraform.tfvars"

Production:

terraform init
terraform plan -var-file="./prod/terraform.tfvars"
terraform apply -var-file="./prod/terraform.tfvars"



# Plan changes for a specific environment

terraform plan -var-file="./dev/terraform.tfvars"

# Apply changes for a specific environment

terraform apply -var-file="./dev/terraform.tfvars"

# Show all resources in state

terraform state list

# Destroy resources (be careful!)

terraform destroy -var-file="./dev/terraform.tfvars"

# 1. Initialize (one time from root)

terraform init

# 2. Develop and test in 'dev' environment

terraform plan -var-file="./dev/terraform.tfvars" terraform apply -var-file="./dev/terraform.tfvars"

# 3. Promote to 'test' environment

terraform plan -var-file="./test/terraform.tfvars" terraform apply -var-file="./test/terraform.tfvars"

# 4. Deploy to 'production'

terraform plan -var-file="./prod/terraform.tfvars" terraform apply -var-file="./prod/terraform.tfvars"

# 5. View outputs

terraform output