terraform {
  backend "s3" {
    region = "ap-south-1"
    bucket = "test-example-lbhuojzo-767398031518"
    key    = "eks-addons/terraform.tfstate"
    dynamodb_table = "test-example-lbhuojzo-lock-dynamodb-767398031518"
  }
}
