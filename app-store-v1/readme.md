# 🚀 Terraform Stripe Application (Production Architecture)

## 📌 Overview

This project provisions a **production-ready AWS infrastructure** using Terraform for a Stripe-based application.

It includes:

* 🌐 VPC with public & private subnets
* 🔐 Bastion host for secure SSH
* ⚖️ Application Load Balancer (ALB)
* 🖥️ Auto Scaling Groups (Frontend & Backend)
* 🗄️ RDS (MySQL)
* 🌍 NAT Gateway for private internet access
* 🏷️ Centralized tagging strategy

---

## 🏗️ Architecture

```
Internet
   ↓
ALB (Public Subnets)
   ↓
Frontend ASG      Backend ASG
   ↓                  ↓
Private Subnets (No Public IP)
   ↓
NAT Gateway → Internet

SSH → Bastion → Private EC2
```

---

## 📁 Project Structure

```
terraform-stripe-app/
├── main.tf
├── variables.tf
├── terraform.tfvars
├── modules/
│   ├── vpc/
│   ├── alb/
│   ├── compute/
│   └── rds/
```

---

## ⚙️ Prerequisites

* Terraform ≥ 1.0
* AWS CLI configured (`aws configure`)
* IAM permissions for:

  * EC2
  * VPC
  * ALB
  * RDS

---

## 🚀 Deployment Steps

### 1️⃣ Initialize Terraform

```bash
terraform init
```

---

### 2️⃣ Update Variables

📍 `terraform.tfvars`

```hcl
ami = "ami-xxxxxxxx"   # Ubuntu or Amazon Linux

bastion_cidr = "YOUR_IP/32"
```

Get your IP:

```bash
curl ifconfig.me
```

---

### 3️⃣ Plan

```bash
terraform plan
```

---

### 4️⃣ Apply

```bash
terraform apply
```

---

## 🔑 SSH Access

### Get outputs:

```bash
terraform output bastion_public_ip
```

---

### Connect to Bastion

```bash
ssh -i modules/compute/stripe-key.pem ubuntu@<BASTION_IP>
```

---

### Connect to Private EC2

```bash
ssh ubuntu@<PRIVATE_IP>
```

---

## 🌐 Application Access

Get ALB DNS:

```bash
terraform output alb_dns
```

---

### Access:

* Frontend:

```
http://<ALB-DNS>/
```

* Backend API:

```
POST http://<ALB-DNS>/api/create-checkout-session
```

---

## 🧪 Testing Backend

```bash
curl -X POST http://<ALB-DNS>/api/create-checkout-session
```

---

## ⚠️ Common Issues

### ❌ 502 Bad Gateway

* Backend not running
* Port mismatch (must be 5000)
* App not listening on `0.0.0.0`

---

### ❌ Health Check Failed (404)

Add this route in backend:

```python
@app.route("/")
def health():
    return "OK", 200
```

---

### ❌ Method Not Allowed

Use POST instead of GET:

```bash
curl -X POST ...
```

---

## 🏷️ Tagging Strategy

All resources use centralized tags:

```hcl
Project     = "StripeApp"
Environment = "Dev"
Owner       = "Anil"
```

ASG uses:

```hcl
propagate_at_launch = true
```

---

## 🔐 Security

* Private EC2 have no public IP
* SSH only via Bastion
* Security Groups restrict traffic
* RDS is private

---

## 🔄 Auto Scaling

* Min: 2 instances
* Max: 4 instances
* Rolling updates enabled

---

## 📈 Production Best Practices

* Use HTTPS (ACM)
* Add WAF
* Use Secrets Manager for DB credentials
* Replace Bastion with SSM Session Manager
* Use CI/CD for deployments

---

## 🧠 Interview Summary

> “We built a highly available, scalable AWS architecture using Terraform with ALB routing, Auto Scaling in private subnets, NAT for outbound access, and secure bastion-based access.”

---

## 🧹 Cleanup

```bash
terraform destroy
```

---

## 👨‍💻 Author

**Anil Jadhav**
DevOps / Cloud Engineer

---
