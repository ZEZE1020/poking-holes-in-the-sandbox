# Lab 3: Metrics and blast radius

## Connect

Use the `http://EXTERNAL_IP:7681` URL printed by `task infra:up`. The terminal
is already on the node hosting the K3s control plane.

## Compare contention

Start each workload separately so the comparison is repeatable:

```bash
time kubectl apply -f stress-runc.yaml
kubectl wait --for=condition=Ready pod/stress-runc --timeout=120s
kubectl top pod stress-runc
kubectl top node
kubectl delete -f stress-runc.yaml

time kubectl apply -f stress-kata.yaml
kubectl wait --for=condition=Ready pod/stress-kata --timeout=120s
kubectl top pod stress-kata
kubectl top node
```

Both pods are pinned to one requested CPU core and run the same `stress-ng`
workload. Record `time` as a cold-start approximation, then repeat while
another workload runs to observe scheduler contention. The Kata start includes
the guest VM startup overhead.

For host-level VMM resident set size, inspect the node while the Kata pod runs:

```bash
ps -eo pid,comm,rss,args --sort=-rss | grep -E 'kata|qemu|cloud-hypervisor' | head
free -m
```

Compare the VMM RSS with the node's baseline and with the `runc` run. RSS is
host process memory, not the guest's complete memory accounting. Clean up:

```bash
kubectl delete -f stress-kata.yaml
```
