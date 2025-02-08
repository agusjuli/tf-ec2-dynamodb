# Backend configuration to store tfstate in an S3 bucket
terraform {
  backend "s3" {
    bucket = "sctp-ce9-tfstate"                    # This is an existing bucket to store terraform tfstate file
    key    = "agusjuli-tf-ec2-dynamodb.tfstate"     # Path to store tfstate
    region = "us-east-1"
  }
}