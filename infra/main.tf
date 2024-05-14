module "key_pair_eks" {
  source             = "squareops/keypair/aws"
  version            = "1.0.2"
  key_name           = format("%s-%s-eks", local.environment, local.name)
  environment        = local.environment
  ssm_parameter_path = format("%s-%s-eks", local.environment, local.name)
}

data "aws_caller_identity" "current" {}

module "kms" {
  source = "terraform-aws-modules/kms/aws"

  deletion_window_in_days = 7
  description             = "Symetric Key to Enable Encryption at rest using KMS services."
  enable_key_rotation     = false
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"
  multi_region            = false

  # Policy
  enable_default_policy                  = true
  key_owners                             = [local.current_identity]
  key_administrators                     = local.kms_user == null ? ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS", local.current_identity] : local.kms_user
  key_users                              = local.kms_user == null ? ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS", local.current_identity] : local.kms_user
  key_service_users                      = local.kms_user == null ? ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS", local.current_identity] : local.kms_user
  key_symmetric_encryption_users         = [local.current_identity]
  key_hmac_users                         = [local.current_identity]
  key_asymmetric_public_encryption_users = [local.current_identity]
  key_asymmetric_sign_verify_users       = [local.current_identity]

  # Aliases
  aliases                 = ["${local.name}-KMS"]
  aliases_use_name_prefix = true
}

module "eks" {
  source                               = "squareops/eks/aws"
  depends_on                           = [module.vpc]
  version                              = "3.1.0"
  name                                 = local.name
  vpc_id                               = module.vpc.vpc_id
  environment                          = local.environment
  ipv6_enabled                         = false
  cluster_version                      = "1.28"
  kms_key_arn                          = module.kms.key_arn
  cluster_log_types                    = ["api", "scheduler"]
  private_subnet_ids                   = module.vpc.private_subnets
  cluster_log_retention_in_days        = 30
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
  create_aws_auth_configmap            = true
  aws_auth_users = []
  additional_rules = {
    ingress_port_mgmt_tcp = {
      description = "mgmt vpc cidr"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = ["172.10.0.0/16"]
    }
  }
}

module "managed_node_group_production" {
  source                 = "squareops/eks/aws//modules/managed-nodegroup"
  version                = "3.1.0"
  depends_on             = [module.vpc, module.eks]
  name                   = "Infra"
  environment            = local.environment
  eks_cluster_name       = module.eks.cluster_name
  eks_nodes_keypair_name = module.key_pair_eks.key_pair_name
  subnet_ids             = [module.vpc.private_subnets[0]]
  kms_policy_arn         = module.eks.kms_policy_arn
  worker_iam_role_name   = module.eks.worker_iam_role_name
  min_size               = 1
  max_size               = 3
  desired_size           = 1
  ipv6_enabled           = false
  capacity_type          = "SPOT"
  instance_types         = ["t3a.large", "t2.large", "t2.xlarge", "t3.large", "m5.large"]
  kms_key_arn            = module.kms.key_arn
  k8s_labels = {
    "Infra-Services" = "true"
  }
  tags = local.additional_aws_tags
}