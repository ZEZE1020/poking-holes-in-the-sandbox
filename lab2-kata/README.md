# Lab 2: Kata Containers

## Connect

Return to the `http://EXTERNAL_IP:7681` browser terminal from `task infra:up`.
All commands below run on the dedicated node as `workshop`.

## Run the Kata workload

```bash
kubectl apply -f 01-kata-pod.yaml
kubectl wait --for=condition=Ready pod/kata-baseline --timeout=120s
kubectl get pod kata-baseline -o wide
kubectl exec -it kata-baseline -- sh
```

Repeat Lab 1's probes (`uname -r`, `/proc/version`, `/dev`, and
`/sys/module`). Compare the guest kernel identity and device/module view with
the `runc` pod. Kata places the container process in a lightweight VM, adding a
hypervisor boundary and a dedicated guest kernel while retaining the Kubernetes
pod interface.

```bash
kubectl delete -f 01-kata-pod.yaml
```
