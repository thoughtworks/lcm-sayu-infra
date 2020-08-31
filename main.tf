# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  version = "~> 3.4.0"
}
terraform {
  backend "s3" {
    bucket = "***REMOVED***"
    key    = "***REMOVED***"
    region = "us-west-2"
  }
}