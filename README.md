# Poking Holes in the Sandbox

This OpenInfra workshop compares  `runc` containers, which share the
host kernel, with Kata Containers, which run workloads inside lightweight
virtual machines.

## Prerequisites

Before you begin, you will need to install the following tools:

*   [**OpenTofu**](https://opentofu.org/docs/intro/install/): For provisioning infrastructure.
*   [**Go Task**](https://taskfile.dev/installation/): A task runner used to automate workshop commands.
*   [**kubectl**](https://kubernetes.io/docs/tasks/tools/install-kubectl/): The Kubernetes command-line tool.
*   [**gcloud CLI**](https://cloud.google.com/sdk/docs/install): The command-line interface for Google Cloud.

## Setup

Choose one of the following setup options to get started with the workshop.

### Option 1: Using a Pre-issued Workshop Environment (for Attendees)

If you are an attendee of a workshop session, you will likely be provided with a pre-configured environment.

1.  You will receive a URL to a browser-based terminal.
2.  Open the URL in your web browser.
3.  You may see a browser warning about a self-signed certificate. This is expected. You can safely proceed.
4.  The terminal provides access to a K3s cluster where you will run the labs.
5.  Follow the instructions in the `README.md` files for each lab.

### Option 2: Deploying Your Own Infrastructure on Google Cloud

This option is for those who want to run the workshop in their own Google Cloud project.

1.  **Authenticate to Google Cloud:**
    ```bash
    gcloud auth application-default login
    gcloud config set project YOUR_PROJECT_ID
    ```
    Replace `YOUR_PROJECT_ID` with your Google Cloud project ID.

2.  **Configure and Provision the Infrastructure:**
    Set the following environment variables.
    *   `TF_VAR_project_id`: Your Google Cloud project ID.
    *   `TF_VAR_attendee_count`: The number of attendees.
    *   `TF_VAR_attendees_per_node`: How many attendees will share a single VM.
    *   `TF_VAR_source_ranges`: A list of IP ranges that are allowed to access the workshop. To use your current IP address, you can set it to `["YOUR_PUBLIC_IP/32"]`. You can find your public IP by searching "what is my ip" in your browser. For security, do not set this to `["0.0.0.0/0"]`.

    ```bash
    export TF_VAR_project_id=YOUR_PROJECT_ID
    export TF_VAR_attendee_count=1
    export TF_VAR_attendees_per_node=1
    export TF_VAR_source_ranges='["YOUR_PUBLIC_IP/32"]'
    ```

3.  **Run the deployment tasks:**
    These commands will initialize OpenTofu, show you the planned changes, and then create the resources in your GCP project.
    ```bash
    task infra:init
    task infra:plan
    task infra:up
    ```

4.  **Access the Workshop:**
    After `task infra:up` completes, it will output one or more URLs. Open one of these URLs in your browser to access the workshop terminal.

### Option 3: Full Local Experience with Kata Containers

This option provides the full workshop experience on your local machine. It uses [k3d](https://k3d.io/) to create a local Kubernetes cluster and configures it with Kata Containers.

**Prerequisites for Local Setup:**

*   Your machine must support hardware virtualization (Intel VT-x or AMD-V).
*   You need to have `k3d` installed.

**1. Create a Local Cluster with Kata Containers:**

A new task, `local:setup`, has been added to automate the setup. This task will:

*   Download and install the Kata Containers binaries.
*   Create a `k3d` cluster.
*   Configure `containerd` to use Kata Containers as a runtime.
*   Create the `RuntimeClass` needed to use Kata Containers in Kubernetes.

To run the setup, use the following command:

```bash
task local:setup
```

**2. Verify the Setup:**

After the setup is complete, you can verify that the `kata-qemu` runtime class is available:

```bash
kubectl get runtimeclass
```

You should see `kata-qemu` in the output.

**3. Run the Labs:**

With the local environment set up, you can now run all the labs, including `lab2-kata`, on your local cluster.


## Running the Labs

The labs are located in the following directories:
*   `lab1-runc/`
*   `lab2-kata/`
*   `lab3-metrics/`

Each lab directory contains a `README.md` with specific instructions for that lab.

## Cleanup

If you deployed your own infrastructure (Option 2), you can destroy all the created resources by running:

```bash
task infra:down
```

## Helper Materials

Facilitator notes and the Markdown slide source are available in [`docs/`](/home/ogembo/openinfra-workshop/poking-holes-in-the-sandbox/docs/).