# Deployment versioning

This project deploys only after a pull request is merged into `main`.

## Updating the version

Edit `server_version.json` and set the version in this format:

```json
{
  "version": "15/09/2026-1"
}
```

Rules:
- Use the format `DD/MM/YYYY-N`
- `N` must be a positive integer
- The number after `-` must be different from the current version on the server

Example:
- current: `15/09/2026-1`
- next: `15/09/2026-2`

After merging the PR to `main`, the GitHub Action checks the version, updates the remote `server_version.json`, and runs the deploy script.
