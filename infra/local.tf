locals {
  region      = "us-east-2"
  environment = "uat"
  name        = "example"
  additional_aws_tags = {
    Owner      = "example"
    Expires    = "Never"
    Department = "Engineering"
  }
  ipv6_enabled = true
  vpc_cidr           = "172.10.0.0/16"
  vpn_server_enabled = false
  cert_manager_email = "sahuonwater@gmail.com"
  jenkins_hostname = "jenkins.abc.com"
  argocd_hostname = "argocd.abc.com"
  kms_user = null
  current_identity               = data.aws_caller_identity.current.arn
}