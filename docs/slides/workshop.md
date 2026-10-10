---
marp: true
theme: default
paginate: true
title: Poking Holes in the Sandbox
---

# Poking Holes in the Sandbox

## Container isolation with `runc` and Kata Containers

OpenInfra workshop

---

## What are we testing?

- Ordinary containers share the host kernel.
- Kata Containers add a lightweight virtual-machine boundary.
- The same Kubernetes workload can expose different isolation behavior.

---

## Workshop flow

1. Provision a dedicated node with OpenTofu on GCP.
2. Connect through the browser terminal on port `7681`.
3. Compare `runc` and Kata kernel, device, and module views.
4. Measure startup and resource overhead.

---

## Lab 1: baseline `runc`

```bash
kubectl apply -f lab1-runc/01-baseline-pod.yaml
kubectl exec -it runc-baseline -- sh
```

Inspect:

```sh
uname -r
cat /proc/version
ls -la /dev
ls /sys/module | head
```

---

## Lab 2: Kata Containers

The workload is similar, but uses:

```yaml
runtimeClassName: kata
```

Repeat the probes and compare the guest kernel and device view with the
baseline pod.

---

## Lab 3: performance and contention

- Pin equivalent `stress-ng` workloads to one CPU.
- Time pod startup.
- Observe `kubectl top pod` and `kubectl top node`.
- Inspect VMM RSS with `ps`.

Isolation has a cost: measure it in the workload that matters.

---

## Discussion

- Which boundary does your threat model require?
- What is the acceptable cold-start and memory overhead?
- Which workloads benefit most from a VM boundary?
- How should network and browser-terminal access be restricted?
