output "nginx_ingress_controller_dns_hostname" {
  description = "NGINX Ingress Controller DNS Hostname"
  value       = module.eks_addons.nginx_ingress_controller_dns_hostname
}

output "efs_id" {
  value       = module.eks_addons.efs_id
  description = "The ID of the EFS"
}

output "kubeclarity" {
  value       = module.eks_addons.kubeclarity
  description = "Hostname for the kubeclarity."
}

output "kubecost" {
  value       = module.eks_addons.kubecost
  description = "Hostname for the kubecost."
}

output "istio_ingressgateway_dns_hostname" {
  value       = module.eks_addons.istio_ingressgateway_dns_hostname
  description = "DNS hostname of the Istio Ingress Gateway"
}

output "argocd_details" {
  value = module.argocd.argocd
}

output "jenkins" {
  description = "Jenkins_Info"
  value = {
    username = nonsensitive(data.kubernetes_secret.jenkins.data["jenkins-admin-user"]),
    password = nonsensitive(data.kubernetes_secret.jenkins.data["jenkins-admin-password"]),
    url      = local.jenkins_hostname
  }
}