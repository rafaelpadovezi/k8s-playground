terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "0.2.1"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.12.1"
    }
  }
}

provider "kind" {}

resource "kind_cluster" "default" {
  name       = "playground-cluster"
  node_image = "kindest/node:v1.27.3"

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      # https://kind.sigs.k8s.io/docs/user/ingress/#create-cluster
      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]

      extra_port_mappings {
        container_port = 80
        host_port      = 8000
      }
    }

    node {
      role = "worker"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "./playground-cluster-config"
  }
}

resource "helm_release" "ingress_controller" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  values = [
    "${file("./helm/ingress-nginx-values.yaml")}"
  ]

  namespace        = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.allowSnippetAnnotations"
    value = "true"
  }

  depends_on = [
    kind_cluster.default
  ]
}
