## Stage 0 addition — CLI preflight

Append the platform's block to stage 0's **same call**, before any branch, commit or push. The
platform resolves from that same call's own output, so unless it is already known, append **both**
blocks — three read-only lines between them — and read only the resolved platform's answer.
GitHub — this checks both installation and authentication:

```bash
gh auth status
```

Azure DevOps — check installation and extension; authentication is checked by the first repo API call:

```bash
az version -o tsv
az extension show --name azure-devops --query name -o tsv
```

**A failed check stops later stages. Never install a CLI or extension yourself.** Give the command:
`brew install gh` or `winget install --id GitHub.cli`; `gh auth login`;
`winget install --id Microsoft.AzureCLI`; `az extension add --name azure-devops`; `az login`, or a
PAT with `Code (read & write)` plus `Pull Request contribute` scope in `AZURE_DEVOPS_EXT_PAT`
(`TF400813`, a `401` or a prompt all mean auth). Wait for the user to resolve it, then recheck.

**Unknown platform** — a remote that is neither GitHub nor Azure (see the stage 0 table) has no
automated pull request: ignore whichever blocks ran, skip only stage 4, and tell the user to open it
in the host's web UI. Any branch, commit or push stage this skill runs still completes.
