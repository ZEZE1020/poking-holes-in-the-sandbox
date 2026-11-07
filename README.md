# Poking Holes in the Sandbox: A Container Security Workshop

This workshop explores the security differences between standard `runc` containers and `Kata Containers`. By running hands-on labs, you will learn how container runtimes can fundamentally change the security posture of your workloads.

## The "Why": `runc` vs. Kata Containers

### `runc`: The Standard Container Runtime
`runc` is the default, OCI-compliant container runtime used by Docker, containerd, and other container engines. It provides isolation by leveraging Linux namespaces and cgroups. While efficient, this means all containers on a host share the same Linux kernel. A kernel exploit in one container could potentially compromise the entire host and all other containers running on it.

### `Kata Containers`: Security Through Virtualization
`Kata Containers` adds a layer of hardware-virtualization to containerization. Each Kata Container (or group of containers) runs within its own lightweight virtual machine, with its own dedicated kernel. This provides much stronger isolation from the host and other containers, significantly reducing the attack surface. The trade-off is a small performance overhead compared to `runc`.

This workshop will allow you to experience these differences firsthand and understand when to choose one over the other.

## Prerequisites

Before you begin, you will need to install the following tools, depending on the setup option you choose:

*   [**OpenTofu**](https://opentofu.org/docs/intro/install/): For provisioning cloud infrastructure.
*   [**Go Task**](https://taskfile.dev/installation/): A task runner used to automate workshop commands.
*   [**kubectl**](https://kubernetes.io/docs/tasks/tools/install-kubectl/): The Kubernetes command-line tool.
*   [**gcloud CLI**](https://cloud.google.com/sdk/docs/install): The command-line interface for Google Cloud.
*   [**k3d**](https://k3d.io/): For running a local Kubernetes cluster.

## Ways to Run the Workshop

Choose one of the following setup options to get started.

### Option 1: Use a Pre-issued Workshop Environment (Recommended for Attendees)
If you are an attendee of a workshop session, you will likely be provided with a pre-configured environment.

**Requirements:**
*   A web browser.

**Instructions:**
1.  You will receive a URL to a browser-based terminal.
2.  Open the URL in your web browser. You may see a warning about a self-signed certificate, which you can safely accept.
3.  The terminal provides access to a K3s cluster where you will run the labs.

### Option 2: Deploy Your Own Infrastructure on Google Cloud
This option is for those who want to run the workshop in their own Google Cloud project.

**Requirements:**
*   A Google Cloud project with billing enabled.
*   `gcloud CLI`, `tofu`, and `task` installed.

**Instructions:**
1.  **Authenticate to Google Cloud:**
    ```bash
    gcloud auth application-default login
    gcloud config set project YOUR_PROJECT_ID
    ```
2.  **Configure and Provision:**
    Set the following environment variables, then run the deployment tasks.
    ```bash
    export TF_VAR_project_id=YOUR_PROJECT_ID
    export TF_VAR_attendee_count=1
    export TF_VAR_attendees_per_node=1
    # Task automatically detects your current public IPv4 address.
    # To override it, set WORKSHOP_SOURCE_CIDR="YOUR_PUBLIC_IP/32".

    task infra:init
    task infra:plan
    task infra:up
    ```
3.  **Access the Workshop:**
    After `task infra:up` completes, it will output one or more URLs. Open one of these URLs in your browser.
    The terminal includes a `workshop/` directory containing the README and all three lab directories.
    If you update the labs while the VM is running, refresh that directory with:
    ```bash
    task workshop:sync:gcp
    ```

### Option 2b: Deploy on Azure

After authenticating with `az login`, set the subscription and SSH public key:

```bash
az account set --subscription YOUR_SUBSCRIPTION_ID
export TF_VAR_admin_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"

task infra:azure:init
task infra:azure:plan
task infra:azure:up
```

The Azure tasks use the same automatically detected public IPv4 CIDR. Override it
with `WORKSHOP_SOURCE_CIDR="YOUR_PUBLIC_IP/32"` when necessary. Destroy the
resources with `task infra:azure:down`.

### Option 3: Full Local Experience with Kata Containers
This option provides the full workshop experience on your local machine.

**Requirements:**
*   A machine that supports hardware virtualization (Intel VT-x or AMD-V).
*   `k3d` and `task` installed.

Native Ubuntu Linux is recommended for the local Kata path. Ubuntu 22.04 or
24.04 with Docker, `kubectl`, `k3d`, and `task` is the supported local
environment. Hardware virtualization (Intel VT-x or AMD-V) must be enabled,
and `/dev/kvm` must be available to your user:

```bash
ls -l /dev/kvm
sudo usermod -aG kvm "$USER"
```

Log out and back in after adding yourself to the `kvm` group. Docker Desktop,
WSL2, and nested virtual machines may start the k3d cluster successfully but
still fail to boot the Kata guest kernel or connect to its guest agent because
they add another virtualization layer. If local Kata setup fails in WSL2,
repeat it on a native Ubuntu installation or use the GCP/Azure environment.

**Instructions:**
1.  **Create a Local Cluster with Kata Containers:**
    The `local:setup` task automates the download and configuration of Kata Containers with k3d.
    ```bash
    task local:setup
    ```
2.  **Verify the Setup:**
    Check that the `kata` runtime class is available:
    ```bash
    kubectl get runtimeclass
    ```

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

If you deployed your own infrastructure (Option 2), you can destroy all the created resources by running:
```bash
task infra:down
```

## Helper Materials
Facilitator notes and the Markdown slide source are available in [`docs/`](/home/ogembo/openinfra-workshop/poking-holes-in-the-sandbox/docs/).