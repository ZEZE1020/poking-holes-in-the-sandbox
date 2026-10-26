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
    export TF_VAR_source_ranges='["YOUR_PUBLIC_IP/32"]' # Replace with your IP
    
    task infra:init
    task infra:plan
    task infra:up
    ```
3.  **Access the Workshop:**
    After `task infra:up` completes, it will output one or more URLs. Open one of these URLs in your browser.

### Option 3: Full Local Experience with Kata Containers
This option provides the full workshop experience on your local machine.

**Requirements:**
*   A machine that supports hardware virtualization (Intel VT-x or AMD-V).
*   `k3d` and `task` installed.

**Instructions:**
1.  **Create a Local Cluster with Kata Containers:**
    The `local:setup` task automates the download and configuration of Kata Containers with k3d.
    ```bash
    task local:setup
    ```
2.  **Verify the Setup:**
    Check that the `kata-qemu` runtime class is available:
    ```bash
    kubectl get runtimeclass
    ```

## Running the Labs

The labs are located in the following directories:
*   `lab1-runc/`
*   `lab2-kata/`
*   `lab3-metrics/`

Each lab directory contains a `README.md` with specific instructions.

## Cleanup

If you deployed your own infrastructure (Option 2), you can destroy all the created resources by running:
```bash
task infra:down
```

## Helper Materials
Facilitator notes and the Markdown slide source are available in [`docs/`](/home/ogembo/openinfra-workshop/poking-holes-in-the-sandbox/docs/).