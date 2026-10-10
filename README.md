# Poking Holes in the Sandbox

This OpenInfra workshop compares ordinary `runc` containers, which share the
host kernel, with Kata Containers, which run workloads inside lightweight
virtual machines.

## Quick start

1. Install [OpenTofu](https://opentofu.org/), `go-task`, and `kubectl`.
2. Authenticate to Google Cloud and select a project:

   ```bash
   gcloud auth application-default login
   gcloud config set project YOUR_PROJECT_ID
   ```

3. Set the project and attendee count, then provision the nodes:

   ```bash
   export TF_VAR_project_id=YOUR_PROJECT_ID
   export TF_VAR_attendee_count=1
   task infra:init
   task infra:plan
   task infra:up
   ```

4. Open the printed `http://EXTERNAL_IP:7681` URL. The browser terminal runs
   as the non-root `workshop` user and contains the K3s cluster for the labs.
5. Run the labs in order. Each lab README includes its `ttyd` connection
   instructions and cleanup commands.
6. Destroy the infrastructure when finished:

   ```bash
   task infra:down
   ```

The workshop intentionally exposes a browser terminal on port 7681. Use this
only on temporary workshop instances and restrict the firewall source ranges
for any non-workshop deployment.
