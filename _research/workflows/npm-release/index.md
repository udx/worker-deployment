# NPM Release Workflow (GitHub Actions)

## Step 1: Inspect reusable workflow contract
- Task: Confirm required inputs/secrets for the reusable npm release workflow.
- Input: Local reusable workflow file at `/Users/jonyfq/git/udx/reusable-workflows/.github/workflows/npm-release-ops.yml`.
- Logic/Tooling: `codex exec` to open the workflow file and extract inputs/secrets.
- Expected output/result: List of inputs and secrets used by the reusable workflow.
- done: false

## Step 2: Add npm publish helper script
- Task: Add `scripts/npm-publish.sh` to this repo so the reusable workflow can publish.
- Input: Local script at `/Users/jonyfq/git/udx/reusable-workflows/scripts/npm-publish.sh`.
- Logic/Tooling: `codex exec` to copy the script into `scripts/` and align tag env var usage.
- Expected output/result: `scripts/npm-publish.sh` present and executable in this repo.
- done: false

## Step 3: Create GitHub Actions workflow
- Task: Add an npm release workflow that calls the reusable workflow on the `npm-release-workflow` branch.
- Input: Reusable workflow inputs; repo branch policy (release on `master`).
- Logic/Tooling: `codex exec` to create `.github/workflows/npm-release.yml` with `workflow_dispatch` and `push` triggers, and inputs/secrets wired.
- Expected output/result: `.github/workflows/npm-release.yml` created and referencing `udx/reusable-workflows/.github/workflows/npm-release-ops.yml@npm-release-workflow`.
- done: false

## Step 4: Validate changes
- Task: Verify workflow files are present and readable.
- Input: `.github/workflows/npm-release.yml` and `scripts/npm-publish.sh`.
- Logic/Tooling: `codex exec` to list files and optionally run `yamllint` if available.
- Expected output/result: Files exist; no syntax issues found.
- done: false
