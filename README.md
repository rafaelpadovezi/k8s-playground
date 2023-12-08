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

## Useful links

- https://github.com/nicolastakashi/k8s-labs (https://www.youtube.com/watch?v=SS_KFDjt8Ns)
- https://github.com/kubernetes-sigs/kind/issues/1693