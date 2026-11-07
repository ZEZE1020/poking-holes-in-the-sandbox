# Lab 3: Metrics and blast radius

## Connect

Use the browser terminal from `task infra:up` and accept the temporary
self-signed certificate warning. The terminal is already on the node hosting
the K3s control plane.

## Compare contention

Start each workload separately so the comparison is repeatable:

```bash
time kubectl apply -f stress-runc.yaml
kubectl wait --for=condition=Ready pod/stress-runc --timeout=120s
until kubectl top pod stress-runc; do
  echo "Waiting for metrics-server to report pod metrics..."
  sleep 10
done
kubectl top node
kubectl delete -f stress-runc.yaml

time kubectl apply -f stress-kata.yaml
kubectl wait --for=condition=Ready pod/stress-kata --timeout=120s
until kubectl top pod stress-kata; do
  echo "Waiting for metrics-server to report pod metrics..."
  sleep 10
done
kubectl top node
kubectl delete -f stress-kata.yaml
```

Both pods are pinned to one requested CPU core and run the same `stress-ng`
workload. Record `time` as a cold-start approximation, then repeat while
another workload runs to observe scheduler contention. The Kata start includes
the guest VM startup overhead.

`kubectl top pod` may fail for the first 10–30 seconds while metrics-server
collects its first sample. The retry loop above is expected and avoids treating
that normal startup delay as a failed lab.

For host-level VMM resident set size, inspect the node while the Kata pod runs:

```bash
ps -eo pid,comm,rss,args --sort=-rss | grep -E 'kata|qemu|cloud-hypervisor' | head
free -m
```

Compare the VMM RSS with the node's baseline and with the `runc` run. RSS is
host process memory, not the guest's complete memory accounting. If you stop
the lab early, clean up with:

```bash
kubectl delete -f stress-runc.yaml --ignore-not-found
kubectl delete -f stress-kata.yaml --ignore-not-found
```
