# Facilitator notes

## Before the session

- Confirm the GCP project, quota, billing, and attendee count.
- Run `task infra:init`, `task infra:plan`, and `task infra:up`.
- Open each printed ttyd URL once and confirm that `kubectl get nodes` reports
  a Ready node.
- Verify that `kubectl get runtimeclass kata` succeeds before attendees start.
- Keep `task infra:down` available for cleanup.

## Suggested pacing

1. Explain the shared-kernel model and run Lab 1: 20 minutes.
2. Compare the guest kernel and device view in Lab 2: 20 minutes.
3. Measure startup and resource overhead in Lab 3: 25 minutes.
4. Leave time for discussion about threat models and workload trade-offs.

## Safety reminders

- The ttyd firewall rule is intended for temporary workshop environments.
- Do not use the default `0.0.0.0/0` source range for production systems.
- Destroy the instances and review the GCP project after the session.
