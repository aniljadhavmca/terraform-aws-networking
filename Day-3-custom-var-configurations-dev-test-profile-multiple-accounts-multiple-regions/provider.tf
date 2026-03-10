provider "aws" {
    region = "us-east-1"
    alias = "devenv"
    profile = "dev"
#defualt region is us-east-1 but we can specify the region here if we want to use a different region
#here dev = defualt profile in provider.tf
}

## test environment provider block##
provider "aws" {
    region = "us-east-1"
    alias = "testenv" #if multiple providers are used then we have to give alias to the provider and then we can call that provider in the resource block
    profile = "test"
}