#To Execute this module

Step 1. - Go inside the backend folder of infra `cd ./infra/backend/`
Step 2.- Run the command `terraform init` and `terraform apply --auto-approve`

Once run the above command successfully. A user will get the following value - 

```bucket_region = "ap-south-1"
dynamodb_table_name = "xyz-table-name"
log_bucket_name = "xyz-log-bucket-name"
state_bucket_name = "xyz-state-bucket-name```

Copy the following values and replce it in the backend.tf in the root directory of infra folder and addons folder - 

terraform {
  backend "s3" {
    region = "ap-south-1"
    bucket = "xyz-state-bucket-name"
    key    = "eks/terraform.tfstate"
    dynamodb_table = "xyz-table-name"
  }
}

after doing the following changes run `terraform init`

then run `terraform apply` and carefully see what all resources are going to create, once verified approve it using yes.
