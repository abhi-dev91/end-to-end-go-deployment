terraform {
  backend "s3" {
    region = "ap-south-1"
    bucket = "uat-example-p31rq5ij-767398031518"
    key    = "eks-addons/terraform.tfstate"
    dynamodb_table = "uat-example-p31rq5ij-lock-dynamodb-767398031518"
  }
}
