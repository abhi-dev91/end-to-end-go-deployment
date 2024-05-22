locals {
  region      = "us-west-2"
  environment = "uat"
  name        = "eks"
  additional_aws_tags = {
    Owner      = "Organization_name"
    Expires    = "Never"
    Department = "Engineering"
  }
  kms_user                    = null
  vpc_cidr                    = "10.10.0.0/16"
  vpn_server_enabled          = false
  default_addon_enabled       = false
  aws_managed_node_group_arch = "amd64" #Enter your linux arch (Example:- arm64 or amd64)
  current_identity            = data.aws_caller_identity.current.arn
}
data "aws_caller_identity" "current" {}

data "aws_iam_roles" "autoscalingrole" {
  path_prefix = "/aws-service-role/autoscaling.amazonaws.com/"
}

resource "aws_iam_service_linked_role" "autoscalingrole" {
  count            = length(data.aws_iam_roles.autoscalingrole.arns) > 0 ? 0 : 1
  aws_service_name = "autoscaling.amazonaws.com"
}

data "aws_iam_roles" "eksrole" {
  path_prefix = "/aws-service-role/eks.amazonaws.com/"
}

resource "aws_iam_service_linked_role" "eksrole" {
  count            = length(data.aws_iam_roles.eksrole.arns) > 0 ? 0 : 1
  aws_service_name = "eks.amazonaws.com"
}

module "kms" {
  source = "terraform-aws-modules/kms/aws"

  deletion_window_in_days = 7
  description             = "Symetric Key to Enable Encryption at rest using KMS services."
  enable_key_rotation     = true
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"
  multi_region            = true

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
  key_statements = [
    {
      sid    = "AllowCloudWatchLogsEncryption",
      effect = "Allow"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ]
      resources = ["*"]

      principals = [
        {
          type        = "Service"
          identifiers = ["logs.${local.region}.amazonaws.com"]
        }
      ]
    }
  ]
  # Aliases
  aliases                 = ["${local.name}-KMS"]
  aliases_use_name_prefix = true
}

module "key_pair_vpn" {
  source             = "squareops/keypair/aws"
  count              = local.vpn_server_enabled ? 1 : 0
  key_name           = format("%s-%s-vpn", local.environment, local.name)
  environment        = local.environment
  ssm_parameter_path = format("%s-%s-vpn", local.environment, local.name)
}

module "key_pair_eks" {
  source             = "squareops/keypair/aws"
  key_name           = format("%s-%s-eks", local.environment, local.name)
  environment        = local.environment
  ssm_parameter_path = format("%s-%s-eks", local.environment, local.name)
}


module "vpc" {
  source                                          = "squareops/vpc/aws"
  version = "3.3.5"
  environment                                     = local.environment
  name                                            = local.name
  vpc_cidr                                        = local.vpc_cidr
  availability_zones                              = ["us-west-2a", "us-west-2b"]
  public_subnet_enabled                           = true
  private_subnet_enabled                          = true
  database_subnet_enabled                         = false
  intra_subnet_enabled                            = false
  one_nat_gateway_per_az                          = true
  vpn_server_enabled                              = local.vpn_server_enabled
  vpn_server_instance_type                        = "t3a.small"
  vpn_key_pair_name                               = local.vpn_server_enabled ? module.key_pair_vpn[0].key_pair_name : null
  flow_log_enabled                                = false
  flow_log_max_aggregation_interval               = 60
  flow_log_cloudwatch_log_group_retention_in_days = 90
  flow_log_cloudwatch_log_group_kms_key_arn       = module.kms.key_arn
}

module "eks" {
  source                               = "squareops/eks/aws"
  version = "4.0.8"
  depends_on                           = [module.vpc]
  name                                 = local.name
  vpc_id                               = module.vpc.vpc_id
  subnet_ids                           = [module.vpc.private_subnets[0]]
  min_size                             = 1
  max_size                             = 3
  desired_size                         = 1
  ebs_volume_size                      = 50
  capacity_type                        = "ON_DEMAND"
  instance_types                       = ["t3a.large"]
  environment                          = local.environment
  kms_key_arn                          = module.kms.key_arn
  cluster_version                      = "1.27"
  cluster_log_types                    = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  private_subnet_ids                   = module.vpc.private_subnets
  cluster_log_retention_in_days        = 30
  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = false
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
  create_aws_auth_configmap            = false
  managed_ng_pod_capacity              = 90
  default_addon_enabled                = local.default_addon_enabled
  eks_nodes_keypair_name               = module.key_pair_eks.key_pair_name
  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::222222222222:role/service-role"
      username = "username"
      groups   = ["system:masters"]
    }
  ]
  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::222222222222:user/aws-user"
      username = "aws-user"
      groups   = ["system:masters"]
    },
  ]
  additional_rules = {
    ingress_port_mgmt_tcp = {
      description = "mgmt vpc cidr"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = ["10.10.0.0/16"]
    }
  }
}

resource "aws_iam_policy_attachment" "ecr_policy_attachment" {
  name       = "attach-ec2-container-registry-poweruser"
  roles      = [module.eks.worker_iam_role_name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# module "eks_managed_node_group" {
#   source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"

#   name            = "infra-service"
#   cluster_name    = module.eks.cluster_name
#   cluster_version = "1.27"

#   subnet_ids = module.vpc.private_subnets

#   // The following variables are necessary if you decide to use the module outside of the parent EKS module context.
#   // Without it, the security groups of the nodes are empty and thus won't join the cluster.
#   cluster_primary_security_group_id = module.eks.cluster_security_group_id
#   vpc_security_group_ids            = [module.eks.cluster_security_group_id]

#   // Note: `disk_size`, and `remote_access` can only be set when using the EKS managed node group default launch template
#   // This module defaults to providing a custom launch template to allow for custom security groups, tag propagation, etc.
#   // use_custom_launch_template = false
#   // disk_size = 50
#   //
#   //  # Remote access cannot be specified with a launch template
#   //  remote_access = {
#   //    ec2_ssh_key               = module.key_pair.key_pair_name
#   //    source_security_group_ids = [aws_security_group.remote_access.id]
#   //  }

#   min_size     = 1
#   max_size     = 10
#   desired_size = 1

#   instance_types = ["t3.large"]
#   capacity_type  = "SPOT"

#   labels = {
#     "Addons-Services" = "true"
#   }


#   tags = local.additional_aws_tags
#   cluster_service_cidr = ""
# }
module "managed_node_group_production" {
  source                      = "squareops/eks/aws//modules/managed-nodegroup"
  version = "4.0.8"
  depends_on                  = [module.vpc, module.eks]
  name                        = "Infra"
  min_size                    = 2
  max_size                    = 5
  desired_size                = 2
  subnet_ids                  = [module.vpc.private_subnets[0]]
  environment                 = local.environment
  kms_key_arn                 = module.kms.key_arn
  capacity_type               = "ON_DEMAND"
  ebs_volume_size             = 50
  instance_types              = ["t3a.large"]
  kms_policy_arn              = module.eks.kms_policy_arn
  eks_cluster_name            = module.eks.cluster_name
  aws_managed_node_group_arch = local.aws_managed_node_group_arch
  default_addon_enabled       = local.default_addon_enabled
  worker_iam_role_name        = module.eks.worker_iam_role_name
  worker_iam_role_arn         = module.eks.worker_iam_role_arn
  managed_ng_pod_capacity     = 90
  eks_nodes_keypair_name      = module.key_pair_eks.key_pair_name
  k8s_labels = {
    "Addons-Services" = "true"
  }
  tags = local.additional_aws_tags
}

# module "farget_profle" {
#   source       = "squareops/eks/aws//modules/fargate-profile"
#   depends_on   = [module.vpc, module.eks]
#   profile_name = "app"
#   subnet_ids   = [module.vpc.private_subnets[0]]
#   environment  = local.environment
#   cluster_name = module.eks.cluster_name
#   namespace    = ""
#   labels = {
#     "App-Services" = "fargate"
#   }
# }
