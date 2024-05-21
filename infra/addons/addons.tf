locals {
  region      = "us-west-2"
  environment = "stg"
  name        = "eks"
  additional_aws_tags = {
    Owner      = "example"
    Expires    = "Never"
    Department = "Engineering"
  }
  ipv6_enabled = true
  vpc_cidr           = "172.10.0.0/16"
  vpn_server_enabled = false
  cert_manager_email = "sahuonwater@gmail.com"
  jenkins_hostname = "jenkins.test.atmosly.com"
  argocd_hostname = "argocd.test.atmosly.com"

}


data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    region = "ap-south-1"
    bucket = "uat-example-p31rq5ij-767398031518"
    key    = "eks/terraform.tfstate"
  }
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}


module "eks_addons" {
  source                              = "squareops/eks-addons/aws"
  version = "2.1.2"
  name                                = local.name
  vpc_id                              = data.terraform_remote_state.eks.outputs.vpc_id
  environment                         = local.environment
  ipv6_enabled                        = true
  kms_key_arn                         = "false"
  keda_enabled                        = false
  kms_policy_arn                      = data.terraform_remote_state.eks.outputs.kms_policy_arn ## eks module will create kms_policy_arn
  eks_cluster_name                    = data.terraform_remote_state.eks.outputs.cluster_name
  reloader_enabled                    = true
  karpenter_enabled                   = true
  private_subnet_ids                  = data.terraform_remote_state.eks.outputs.private_subnets
  single_az_sc_config                 = [{ name = "infra-service-sc", zone = "zone-name" }]
  coredns_hpa_enabled                 = false
  kubernetes_dashboard_enabled        = false
  k8s_dashboard_hostname              = "dashboard.prod.in"
  kubeclarity_enabled                 = false
  kubeclarity_hostname                = "kubeclarity.prod.in"
  kubecost_enabled                    = false
  kubecost_hostname                   = "kubecost.prod.in"
  defectdojo_enabled                  = false
  defectdojo_hostname                 = "defectdojo.prod.in"
  cert_manager_enabled                = true
  worker_iam_role_name                = data.terraform_remote_state.eks.outputs.worker_iam_role_name
  worker_iam_role_arn                 = data.terraform_remote_state.eks.outputs.worker_iam_role_arn
  ingress_nginx_enabled               = true
  metrics_server_enabled              = true
  external_secrets_enabled            = false
  amazon_eks_vpc_cni_enabled          = true
  cluster_autoscaler_enabled          = true
  service_monitor_crd_enabled         = true
  # enable_aws_load_balancer_controller = false
  falco_enabled                       = false
  slack_webhook                       = ""
  istio_enabled                       = false
  istio_config = {
    ingress_gateway_enabled       = true
    egress_gateway_enabled        = false
    envoy_access_logs_enabled     = true
    prometheus_monitoring_enabled = true
    istio_values_yaml             = ""
  }
  karpenter_provisioner_enabled = true
  karpenter_provisioner_config = {
    private_subnet_name    = format("%s-%s-%s", local.environment, local.name, "private-subnet")
    instance_capacity_type = ["spot"]
    excluded_instance_type = ["nano", "micro", "small"]
    instance_hypervisor    = ["nitro"]   ## Instance hypervisor is picked up only if IPv6 enable is chosen
  }
  cert_manager_letsencrypt_email                = local.cert_manager_email
  internal_ingress_nginx_enabled                = false
  efs_storage_class_enabled                     = false
  aws_node_termination_handler_enabled          = true
  amazon_eks_aws_ebs_csi_driver_enabled         = true
  cluster_propotional_autoscaler_enabled        = false
  single_az_ebs_gp3_storage_class_enabled       = false
  cert_manager_install_letsencrypt_http_issuers = true
  velero_enabled                                = false
  velero_config = {
    namespaces                      = "my-application" ## If you want full cluster backup, leave it blank else provide namespace.
    slack_notification_token        = "xoxb-slack-token"
    slack_notification_channel_name = "slack-notifications-channel"
    retention_period_in_days        = 45
    schedule_backup_cron_time       = "* 6 * * *"
    velero_backup_name              = "my-application-backup"
    backup_bucket_name              = "velero-cluster-backup"
  }
}



module "argocd" {
  source = "squareops/argocd/kubernetes"
  argocd_config = {
    hostname                     = local.argocd_hostname
    values_yaml                  = file("./helm/argocd.yaml")
    redis_ha_enabled             = false
    autoscaling_enabled          = true
    slack_notification_token     = ""
    argocd_notifications_enabled = true
  }
}

data "kubernetes_secret" "jenkins" {
  depends_on = [helm_release.jenkins]
  metadata {
    name      = "jenkins"
    namespace = "jenkins"
  }
}

resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"
  }
}
resource "helm_release" "jenkins" {
  depends_on = [ kubernetes_namespace.jenkins ]
  name       = "jenkins"
  chart      = "jenkins"
  timeout    = 600
  version    = "5.1.18"
  namespace  = "jenkins"
  repository = "https://charts.jenkins.io/"

  values = [
    templatefile("./helm/jenkins.yaml", 
    {
      hostname            = local.jenkins_hostname
      jenkins_volume_size = "20Gi"
    }
    )
  ]
}