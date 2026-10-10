# Facilitator notes

## Before the session

- Confirm the GCP project, quota, billing, attendee count, attendees per node,
  and attendee CIDR.
- Export a restricted firewall range before provisioning:
  `export TF_VAR_source_ranges='["203.0.113.10/32"]'`.
- Run `task infra:init`, `task infra:plan`, and `task infra:up`.
- Open each printed ttyd URL once and confirm that `kubectl get nodes` reports
  a Ready node.
- Verify that `kubectl get runtimeclass kata` succeeds before attendees start.
- Tell attendees which VM URL they share; this phase provides one ttyd URL per
  VM, not one URL per attendee.
- Keep `task infra:down` available for cleanup.

## Suggested pacing

1. Explain the shared-kernel model and run Lab 1: 20 minutes.
2. Compare the guest kernel and device view in Lab 2: 20 minutes.
3. Measure startup and resource overhead in Lab 3: 25 minutes.
4. Leave time for discussion about threat models and workload trade-offs.

## Safety reminders

- The ttyd firewall rule is intended for temporary workshop environments.
- Never use `0.0.0.0/0`; OpenTofu rejects it.
- Destroy the instances and review the GCP project after the session.
