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

resource "kubernetes_namespace" "apps" {
  metadata {
    name = "apps"
  }

  depends_on = [
    kind_cluster.default
  ]
}

resource "null_resource" "wait_for_ready_ingress_controller" {
  provisioner "local-exec" {
    command = <<EOT
    kubectl wait --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller \
      --namespace ingress-nginx \
      --timeout=90s
EOT
  }

  depends_on = [helm_release.ingress_controller]
}

resource "kubernetes_manifest" "ingress" {
  manifest = yamldecode(file("../recipes/ingress.yaml"))

  depends_on = [
    null_resource.wait_for_ready_ingress_controller
  ]
}

resource "kubernetes_manifest" "elastic" {
  manifest = yamldecode(file("../recipes/elastic/deployment.yaml"))

  depends_on = [
    null_resource.wait_for_ready_ingress_controller
  ]
}

resource "kubernetes_manifest" "elastic_service" {
  manifest = yamldecode(file("../recipes/elastic/service.yaml"))

  depends_on = [
    null_resource.wait_for_ready_ingress_controller
  ]
}

resource "helm_release" "fluentd" {
  name       = "fluentd"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluentd"

  values           = ["${file("./helm/fluentd-values.yaml")}"]
  namespace        = "logging"
  create_namespace = true

  depends_on = [
    kubernetes_manifest.elastic
  ]
}
