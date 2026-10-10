# Workshop helper materials

This folder contains material used to prepare and deliver the workshop. The
deployable labs remain in the repository root; these files are supporting
content rather than additional exercises.

## Folders

- [`notes/`](notes/) contains facilitator notes, timing, prerequisites, and
  presentation reminders.
- [`slides/`](slides/) contains the Markdown source for the slide deck.
- [`notes/security-and-sharing.md`](notes/security-and-sharing.md) contains the
  pre-upload security checklist.

The slide source is committed as Markdown. Exported PDF, PowerPoint, HTML, and
image files are intentionally ignored by the repository's `.gitignore`.

Run `task security:check` before committing or sharing workshop materials.

## Suggested slide workflow

The slide source uses [Marp](https://marp.app/) conventions. With Marp CLI
installed, export it locally without adding generated files to Git:

```bash
npx @marp-team/marp-cli docs/slides/workshop.md --pdf
```
