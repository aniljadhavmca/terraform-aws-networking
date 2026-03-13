terraform {
  backend "s3" {
    bucket = "dev-test-anil"
    key    = "terraform.tfstate"
    region = "us-east-1"
    use_lockfile = true  #dynmodb no longer required for state locking in s3 backend we can use lockfile for state locking in s3 backend
    #terraform version shouid be 1.10 above to use lockfile for state locking in s3 backend
  }
}