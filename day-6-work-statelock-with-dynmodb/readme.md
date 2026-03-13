# 🔒 Terraform State Locking

> Prevent state corruption when multiple engineers deploy at the same time — using **S3** + **DynamoDB**.

![Terraform](https://img.shields.io/badge/Terraform-1.x-7B42BC?logo=terraform&logoColor=white)
![AWS S3](https://img.shields.io/badge/AWS-S3-FF9900?logo=amazons3&logoColor=white)
![AWS DynamoDB](https://img.shields.io/badge/AWS-DynamoDB-4053D6?logo=amazondynamodb&logoColor=white)

---

## 📌 The Problem

Terraform tracks your infrastructure in a state file (`terraform.tfstate`). Without locking, two engineers running `terraform apply` simultaneously causes a **race condition** — the second write silently overwrites the first, corrupting state and causing infrastructure drift.

```
Engineer 1 ──write──▶ terraform.tfstate ◀──write── Engineer 2
                             💥
                      State corrupted!
```

---

## ✅ The Solution

Use **S3** as a remote backend to store the state file, and **DynamoDB** to manage a distributed lock — only one writer is allowed at a time.

```
Engineer 1 ──lock acquired──▶ DynamoDB ◀──blocked── Engineer 2
Engineer 1 ──────────────────────▶ S3 (safe write)
                  lock released ──▶ Engineer 2 proceeds
```

---

## 🗂 How It Works

| Step | What happens |
|------|-------------|
| 1 | Engineer 1 runs `terraform apply` — requests a lock from DynamoDB |
| 2 | DynamoDB creates a `LockID` entry — lock granted |
| 3 | Engineer 1 reads and writes `terraform.tfstate` safely in S3 |
| 4 | Engineer 2 tries to apply — DynamoDB rejects, returns error |
| 5 | Engineer 1 finishes — DynamoDB `LockID` entry deleted |
| 6 | Engineer 2 retries — lock granted, proceeds safely |

---

## ⚙️ Setup

### 1. Create the S3 bucket

```bash
aws s3api create-bucket \
  --bucket my-terraform-state \
  --region us-east-1

# Enable versioning (recommended)
aws s3api put-bucket-versioning \
  --bucket my-terraform-state \
  --versioning-configuration Status=Enabled
```

### 2. Create the DynamoDB table

> The table **must** have a primary key named `LockID` of type `String`.

```bash
aws dynamodb create-table \
  --table-name terraform-lock-table \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### 3. Configure the Terraform backend

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"

    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}
```

### 4. Initialise

```bash
terraform init
```

---

## 🛠 Common Commands

```bash
# Normal apply — locking is automatic
terraform apply

# See who holds the lock (if stuck)
terraform force-unlock <LockID>

# Show current state
terraform show
```

---

## ⚠️ Handling a Stuck Lock

If a run crashes mid-apply, the lock may not be released automatically.

```bash
# Get the LockID from the error message, then:
terraform force-unlock abc-123-xyz
```

> Only force-unlock if you are certain no other apply is running.

---

## 💡 Tips

- Enable **S3 versioning** — lets you roll back to a previous state file if needed
- Enable **`encrypt = true`** — encrypts state at rest using AWS KMS
- Use **separate state files per environment** (`dev/terraform.tfstate`, `prod/terraform.tfstate`)
- DynamoDB cost is negligible on **PAY_PER_REQUEST** billing (~$0 for typical usage)
