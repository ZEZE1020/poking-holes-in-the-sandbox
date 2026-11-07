# Lab 2: Kata Containers

## Connect

Use the browser terminal from `task infra:up` and accept the temporary
self-signed certificate warning. All commands below run as the unprivileged
`workshop` user.

## Run the Kata workload

```bash
kubectl apply -f 01-kata-pod.yaml
kubectl wait --for=condition=Ready pod/kata-baseline --timeout=120s
kubectl get pod kata-baseline -o wide
kubectl exec -it kata-baseline -- sh
```

Inside the container, run these probes:

```sh
uname -r
cat /proc/version
ls -la /dev
ls /sys/module | head
```

Expected result: `uname -r` reports a Kata guest kernel, such as `6.18.56`,
instead of the node's `6.8.0-1073-gcp` host kernel. The device and module
views are also different because the workload runs behind the Kata VM
boundary. This lets you compare the outputs without returning to Lab 1.
Kata places the container process in a lightweight VM while retaining the
Kubernetes pod interface.

Exit with `exit`, then clean up using this directory's manifest:

```bash
kubectl delete -f 01-kata-pod.yaml
```
