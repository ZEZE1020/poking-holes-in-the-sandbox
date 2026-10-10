# Security and sharing checklist

The workshop is intentionally public-facing, but credentials and generated
infrastructure data are not part of the lesson.

## Before committing or uploading

- Run `task security:check`.
- Check `git status --short --untracked-files=all`.
- Review staged paths with `git diff --cached --name-only`.
- Confirm that no `.env`, `*.tfvars`, service-account JSON, kubeconfig, private
  key, state file, or plan file is staged.
- Review diffs with `git diff --cached`, including new files.
- Keep `provisioning/tofu-gcp/.terraform.lock.hcl`; it contains provider
  checksums, not credentials.

## Infrastructure hygiene

- Set `TF_VAR_project_id` through the shell or a local ignored `.env` file.
- Use `source_ranges` restricted to the attendee network. The configuration
  rejects `0.0.0.0/0`.
- Never paste access tokens, cloud credentials, kubeconfigs, or private keys
  into lab manifests, documentation, screenshots, or slide notes.
- Treat OpenTofu state and plans as sensitive because they can contain resource
  metadata and rendered values, even when they do not contain credentials.

Ignore rules reduce accidental uploads; they do not replace reviewing the
staged diff.
