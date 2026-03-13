terraform {
  backend "s3" {
    bucket = "aniljadhavdev"
    key    = "terraform.tfstate"
    region = "us-east-1"
    # Enable S3 native locking
    #use_lockfile = true   #tf version should be above 1.10
    # The dynamodb_table argument is no longer needed
    dynamodb_table = "terraform-state-lock-dynamo"

  }
}