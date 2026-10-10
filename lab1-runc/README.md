# Lab 1: Baseline `runc`

## Connect

Open the `https://EXTERNAL_IP:7681` URL printed by `task infra:up` and accept
the temporary self-signed certificate warning. The terminal runs as the
unprivileged `workshop` user.

## Run the baseline

```bash
kubectl apply -f 01-baseline-pod.yaml
kubectl wait --for=condition=Ready pod/runc-baseline --timeout=120s
kubectl exec -it runc-baseline -- sh
```

Inside the container, inspect the shared-kernel identity:

```sh
uname -r
cat /proc/version
ls -la /dev
ls /sys/module | head
```

The pod has no special privileges, but these probes show that ordinary
containers use the host kernel and expose the host's device and module view
according to the container runtime policy. Exit with `exit`, then clean up:

```bash
kubectl delete -f 01-baseline-pod.yaml
```
