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

Expected result: `uname -r` matches the node's host kernel. In this workshop,
that is a `6.8.0-1073-gcp` kernel. The device and module listings are also
provided by the shared host-kernel environment, subject to container runtime
policy.

Exit with `exit`, then clean up:

```bash
kubectl delete -f 01-baseline-pod.yaml
```
