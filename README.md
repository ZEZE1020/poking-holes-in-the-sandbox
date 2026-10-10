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
   export TF_VAR_attendees_per_node=2
   export TF_VAR_source_ranges='["YOUR_PUBLIC_IP/32"]'
   task infra:init
   task infra:plan
   task infra:up
   ```

4. Open the printed `https://EXTERNAL_IP:7681` URLs. The browser terminals run
   as the non-root `workshop` user and contain the K3s clusters for the labs.
   A short-lived self-signed certificate is generated on each node, so the
   browser will show a certificate warning during the workshop.
5. Run the labs in order. Each lab README includes its `ttyd` connection
   instructions and cleanup commands.
6. Destroy the infrastructure when finished:

   ```bash
   task infra:down
   ```

The workshop intentionally exposes a browser terminal on port 7681. Set
`TF_VAR_source_ranges` to the attendee network or instructor IP range before
provisioning; unrestricted internet access is rejected by OpenTofu.

Each VM is shared by `attendees_per_node` attendees. The number of VMs is
calculated as `ceil(attendee_count / attendees_per_node)`. This phase keeps one
terminal URL per VM; it does not yet provide per-attendee routing or dynamic
traffic-based autoscaling.

## Helper materials

Facilitator notes and the Markdown slide source are available in
[`docs/`](/home/ogembo/openinfra-workshop/poking-holes-in-the-sandbox/docs/).
