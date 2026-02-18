# Fork Sync Scripts

Use these scripts to keep this fork updated without repeating manual edits.

## 1) Apply fork customizations only

```powershell
pwsh -File .\scripts\apply-codex-fork-customizations.ps1
```

What it does:
- Replaces any `CLAUDE.md` file in non-tooling folders with `AGENTS.md`.
- Replaces text case-insensitively (`Claude`, `Claude Code`, `CLAUDE.md`, `AENTS.md`) in:
  - root `README.md`
  - root `AGENTS.md`
  - non-binary files under the repository, excluding tooling folders (`scripts/`, `.github/`, `.git/`, etc.)
- Normalizes file references to `AGENTS.md`.
- Ensures the fork note block exists at the top of `README.md`.

You can limit processing to changed files:

```powershell
pwsh -File .\scripts\apply-codex-fork-customizations.ps1 -OnlyChangedPaths @(
  "Accessibility-Mod-Template/docs/setup-guide.md",
  "README.md"
)
```

## 2) Full upstream sync + reapply customizations

```powershell
pwsh -File .\scripts\sync-upstream.ps1 -Commit -Push
```

What it does:
1. Verifies you are on `master` and your working tree is clean.
2. Adds or updates `upstream` remote (`HappyStarfish/Accessibility-mod-template`).
3. Fetches upstream changes and merges `upstream/master`.
4. Computes files changed by the merge.
5. Runs the customization script only on those changed files.
6. Commits and pushes customization changes when `-Commit -Push` are passed.
7. Fails fast on unexpected merge conflicts; auto-resolves only known `CLAUDE.md` rename conflicts.

If you want to inspect changes before commit/push, run without flags:

```powershell
pwsh -File .\scripts\sync-upstream.ps1
```

## GitHub Actions Automation

This repo includes `.github/workflows/sync-upstream.yml`.

- Runs every 15 minutes and on manual trigger.
- Merges upstream into your target branch.
- Collects changed files from that merge.
- Applies customizations only to those files (skips run when there are no upstream changes).
- Commits and pushes automatically when changes exist.
- Calls `scripts/sync-upstream.ps1` directly so local and CI behavior stay aligned.
