terraform {
  backend "s3" {
    bucket = "dev-test-terraform-backup"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}