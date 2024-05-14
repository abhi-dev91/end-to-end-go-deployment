terraform {
  backend "s3" {
    region = "us-east-2"
    bucket = "sample-bucket"
    key    = "eks-addons/terraform.tfstate"
  }
}

