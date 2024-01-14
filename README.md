# ☸️ K8S playground 🛝

A local k8s cluster setup with kind + terraform.

## Commands

```shell
 terraform -chdir=provision apply
```

Wait until ingress controller is ready

```shell
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

## Elasticsearch

https://www.elastic.co/guide/en/elasticsearch/reference/7.17/configuring-tls-docker.html
https://faun.pub/setup-elastic-search-cluster-kibana-fluentd-on-kubernetes-with-x-pack-security-part-2-593a01b79fbb

## Useful links

- https://github.com/nicolastakashi/k8s-labs (https://www.youtube.com/watch?v=SS_KFDjt8Ns)
- https://github.com/kubernetes-sigs/kind/issues/1693