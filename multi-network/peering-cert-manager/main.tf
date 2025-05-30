variable "cluster_1" {
  type    = string
  default = "cluster-1"
}

variable "cluster_2" {
  type    = string
  default = "cluster-2"
}

variable "vpc_cidr_block_1" {
  type    = string
  default = "10.1.0.0/16"
}

variable "vpc_cidr_block_2" {
  type    = string
  default = "10.2.0.0/16"
}

variable "vault_lb_name" {
  type = string
  default = "vault-lb"
}

module "cluster_1" {
  source = "../../modules/eks"

  name     = var.cluster_1
  vpc_cidr = var.vpc_cidr_block_1
  providers = {
    aws  = aws
    helm = helm.helm_1
  }
}

module "cluster_2" {
  source = "../../modules/eks"

  name     = var.cluster_2
  vpc_cidr = var.vpc_cidr_block_2
  providers = {
    aws  = aws.us_west_2
    helm = helm.helm_2
  }
}

module "istio-1" {
  depends_on = [module.cluster_1, helm_release.vault]
  source     = "../../modules/istio"

  cluster_name = var.cluster_1
  vault_lb_name    = var.vault_lb_name

  providers = {
    helm       = helm.helm_1
    kubernetes = kubernetes.kubernetes_1
  }
}

module "istio-2" {
  depends_on = [module.cluster_2, helm_release.vault]
  source     = "../../modules/istio"

  cluster_name = var.cluster_2
  vault_lb_name    = var.vault_lb_name

  providers = {
    helm       = helm.helm_2
    kubernetes = kubernetes.kubernetes_2
  }
}

resource "kubernetes_secret" "istio_reader_token_1" {
  depends_on = [module.istio-1]
  metadata {
    annotations = {
      "kubernetes.io/service-account.name" = "istio-reader-service-account"
    }
    name      = "istio-reader-service-account-istio-remote-secret-token"
    namespace = "istio-system"
  }
  type = "kubernetes.io/service-account-token"

  provider = kubernetes.kubernetes_1
}

resource "kubernetes_secret" "istio_reader_token_2" {
  depends_on = [module.istio-2]
  metadata {
    annotations = {
      "kubernetes.io/service-account.name" = "istio-reader-service-account"
    }
    name      = "istio-reader-service-account-istio-remote-secret-token"
    namespace = "istio-system"
  }
  type = "kubernetes.io/service-account-token"

  provider = kubernetes.kubernetes_2
}

module "multi_cluster_app_1" {
  source     = "../../modules/multi-cluster-app"
  depends_on = [module.cluster_1, module.cluster_2]

  other_cluster_certificate_authority_data = module.cluster_2.certificate_authority_data
  other_cluster_endpoint                   = module.cluster_2.cluster_endpoint
  other_cluster_name                       = module.cluster_2.cluster_name
  service_account_token                    = kubernetes_secret.istio_reader_token_2.data["token"]
  app_version                              = "v1"


  providers = {
    helm    = helm.helm_1
    kubernetes = kubernetes.kubernetes_1
  }
}

module "multi_cluster_app_2" {
  source     = "../../modules/multi-cluster-app"
  depends_on = [module.cluster_1, module.cluster_2]

  other_cluster_certificate_authority_data = module.cluster_1.certificate_authority_data
  other_cluster_endpoint                   = module.cluster_1.cluster_endpoint
  other_cluster_name                       = module.cluster_1.cluster_name
  service_account_token                    = kubernetes_secret.istio_reader_token_1.data["token"]

  providers = {
    helm    = helm.helm_2
    kubernetes = kubernetes.kubernetes_2
  }
}
