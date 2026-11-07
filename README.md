# Poking Holes in the Sandbox: Container Isolation and Digital Sovereignty

[![License](https://img.shields.io/github/license/ZEZE1020/poking-holes-in-the-sandbox)](LICENSE)
[![Workshop labs](https://img.shields.io/badge/workshop-labs-blue)](#running-the-labs)
[![Kubernetes](https://img.shields.io/badge/kubernetes-k3s-326ce5?logo=kubernetes&logoColor=white)](#choose-an-environment)
[![Kata Containers](https://img.shields.io/badge/runtime-kata%20containers-6f42c1)](#the-why-runc-vs-kata-containers)

Modern digital sovereignty is not only about where workloads are hosted. It is
also about who controls the infrastructure, how much trust is placed in the
platform, and whether sensitive workloads can be separated from the host and
from one another. Container runtime choice is one practical part of that
conversation.

This workshop is a hands-on exploration of that boundary. You will deploy the
same Kubernetes workloads with the standard `runc` runtime and with Kata
Containers, then inspect what changes. The goal is not to claim that one
runtime solves sovereignty on its own, but to show how stronger workload
isolation can reduce dependence on a shared host kernel and make security
assumptions visible and testable.

## What you will learn

By the end of the workshop, you will be able to:

- Explain the shared-kernel isolation model used by ordinary containers.
- Describe how Kata adds a lightweight virtual-machine boundary and guest
  kernel.
- Verify isolation differences from inside a workload rather than relying on
  labels or configuration alone.
- Measure the startup and resource trade-offs of stronger isolation.
- Identify which sovereignty and security questions remain outside the
  container runtime, including control of the host, cloud account, keys, data,
  and operational policies.

## The "Why": `runc` vs. Kata Containers

### `runc`: The Standard Container Runtime
`runc` is the default, OCI-compliant container runtime used by Docker, containerd, and other container engines. It provides isolation by leveraging Linux namespaces and cgroups. While efficient, this means all containers on a host share the same Linux kernel. A kernel exploit in one container could potentially compromise the entire host and all other containers running on it.

### `Kata Containers`: Security Through Virtualization
`Kata Containers` adds a layer of hardware-virtualization to containerization. Each Kata Container (or group of containers) runs within its own lightweight virtual machine, with its own dedicated kernel. This provides much stronger isolation from the host and other containers, significantly reducing the attack surface. The trade-off is a small performance overhead compared to `runc`.

The labs make these differences observable: `runc` exposes the host kernel
identity, while Kata reports a guest kernel. You will then compare the
performance and operational trade-offs before deciding where each runtime is
appropriate.

## Workshop flow

The workshop follows a simple progression:

1. Establish the baseline with a standard `runc` container.
2. Repeat the inspection with a Kata workload.
3. Compare startup time, CPU, memory, and host-level VMM overhead.
4. Relate the technical findings to trust boundaries, platform control, and
   digital sovereignty.

You can use a pre-issued browser environment, provision a temporary GCP or
Azure environment, or run the workshop locally on native Ubuntu Linux.

## Reproduction options

Choose the option that matches the goal of your session:

| Option | Best for | Requirements | Isolation and cost |
| --- | --- | --- | --- |
| Pre-issued browser terminal | Attendees and short demonstrations | Browser and workshop URL | Fastest start; shared environment, no local install |
| Google Cloud | Repeatable single-user or facilitator deployment | GCP project with billing, `gcloud`, OpenTofu, and Task | VM-backed Kata; billed while running |
| Azure | Multi-terminal workshops | Azure subscription, `az`, OpenTofu, Task, and SSH key | Separate terminal users and namespaces; shared VM resources |
| Native Ubuntu | Local development and offline work | Ubuntu 22.04/24.04, Docker, KVM, `kubectl`, `k3d`, and Task | Local control; hardware virtualization required |
| WSL2/Docker Desktop | Only if Kata guest boot is known to work | Same tools plus nested virtualization support | May start k3d but fail Kata guest startup; use cloud or native Ubuntu if it does |

All routes use the same Kubernetes manifests in `lab1-runc/`, `lab2-kata/`,
and `lab3-metrics/`. Cloud routes provide a browser terminal; local setup
provides a local Kubernetes context.

## Choose an environment

| Path | Use when | Requirements |
| --- | --- | --- |
| Pre-issued terminal | You are attending a hosted session | Browser and workshop URL |
| GCP or Azure | You need a repeatable cloud environment | Cloud account, billing/subscription, OpenTofu, Task, and CLI |
| Native Ubuntu | You want to run Kata locally | Ubuntu 22.04/24.04, Docker, `kubectl`, `k3d`, Task, and KVM |

All paths use the same manifests. Cloud environments provide a browser
terminal; local setup uses your local Kubernetes context. Cloud resources are
billable until destroyed.

### Hosted environment

Open the provided browser-terminal URL and accept the temporary certificate
warning. The lab files are in `~/workshop`.

### Google Cloud

Requirements: a project with billing, `gcloud`, OpenTofu, and Task.

```bash
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
export TF_VAR_project_id=YOUR_PROJECT_ID
export TF_VAR_attendee_count=1
export TF_VAR_attendees_per_node=2
task infra:init
task infra:plan
task infra:up
```

The Taskfile detects your public IPv4 CIDR. Override it with
`WORKSHOP_SOURCE_CIDR="YOUR_PUBLIC_IP/32"` when needed. The terminal includes
the labs under `~/workshop`. Use `task workshop:sync:gcp` to refresh them.

### Azure

Requirements: an Azure subscription, `az`, OpenTofu, Task, and an SSH key.

```bash
az login
az account set --subscription YOUR_SUBSCRIPTION_ID
export TF_VAR_admin_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
task infra:azure:init
task infra:azure:plan
task infra:azure:up
```

Override the detected firewall range with `WORKSHOP_SOURCE_CIDR` if needed.

### Native Ubuntu

Requirements: Ubuntu 22.04/24.04, Docker, `kubectl`, `k3d`, Task, and
hardware virtualization with `/dev/kvm` available.

```bash
ls -l /dev/kvm
sudo usermod -aG kvm "$USER"
# Log out and back in after changing the group.
task local:setup
kubectl get runtimeclass
```

WSL2, Docker Desktop, and nested VMs may start k3d but fail to boot the Kata
guest or connect to its agent. Use native Ubuntu or a cloud environment if
that happens.

## Running the Labs

The labs are located in the following directories:
*   `lab1-runc/`
*   `lab2-kata/`
*   `lab3-metrics/`

Each lab directory contains a `README.md` with specific instructions.
Run them in order from the workshop directory:

```bash
cd ~/workshop/lab1-runc
# Follow this README, then clean up the runc pod.

cd ../lab2-kata
# Follow this README, then clean up the Kata pod.

cd ../lab3-metrics
# Follow this README, then clean up both stress pods.
```

Each lab is self-contained; Lab 2 includes its own kernel and device probes
so you do not need to copy commands from Lab 1.

Each terminal is assigned its own Kubernetes namespace and restricted
kubeconfig. The lab commands can therefore use their normal `kubectl` form
while remaining isolated from other participants. CPU, memory, and pod-count
quotas prevent one participant from consuming the entire cluster.

Participants still share the VM's physical CPU, memory, and Kata
virtualization capacity. Namespace isolation prevents accidental interference
between labs; it is not a replacement for provisioning a separate VM when
strong hardware-level separation is required.

## Cleanup

Destroy cloud resources when you finish:

```bash
task infra:down
# Azure deployments:
task infra:azure:down
```

## Helper Materials
Facilitator notes and the Markdown slide source are available in [`docs/`](/home/ogembo/openinfra-workshop/poking-holes-in-the-sandbox/docs/).