# Agent Instructions

- When running tools or programs that download or generate reusable artifacts, keep caches and local state within the current project workspace whenever practical—for example virtual environments, package caches, model weights, and dataset downloads—rather than writing to global user-level locations.
- For Python workflows, prefer `uv`: run standalone scripts with inline dependency metadata via `uv run`, and manage project-level dependencies in a project-local virtual environment such as `.venv` using `uv venv`, `uv sync`, or equivalent `uv` commands.

## Secrets and Credentials

When credentials, API tokens, or other secrets are required, use the `pass` password-store tool to retrieve them when available; do not hard-code secrets into files, commands, logs, or conversation output.

## GitHub Organization Context

Use the following organization context when inferring repository ownership, business context, or project background. On local machines, place organization repositories under `$HOME/gitrepo/<org>/<repo>`; if a needed repository is not present, clone it into the corresponding organization directory before working with it.

- `gz-yuyi`: Projects for Guangzhou Yuyi Technology Co., Ltd.
- `TariAgentBenchmark`: My freelance and part-time project work.
- `Lighthunter-PTE-ltd`: Projects for Lighthunter.
- `Nervlet`: My product and app projects.

## Container Registry Context

Some GitHub Actions workflows may build container images that should be published to Aliyun Container Registry. When registry credentials are required, configure repository-level GitHub secrets instead of embedding credentials in workflow files. The usual secret names are `ALIYUN_REGISTRY_USERNAME` and `ALIYUN_REGISTRY_PASSWORD`; use `beat_might` as the registry username and retrieve the password from `pass` when needed.

Example:

```bash
gh secret set ALIYUN_REGISTRY_USERNAME --body "beat_might" --repo <org>/<repo>
gh secret set ALIYUN_REGISTRY_PASSWORD --body "<password-from-pass>" --repo <org>/<repo>
```

Personal Aliyun registry endpoint:

```text
crpi-lxfoqbwevmx9mc1q.cn-chengdu.personal.cr.aliyuncs.com
```

Namespace mapping:

- `yuyi_tech`: Guangzhou Yuyi Technology (`gz-yuyi`) projects.
- `tari_tech`: Freelance and part-time (`TariAgentBenchmark`) projects.
- `hanbing_personal`: Personal product/app projects, including `Nervlet` repositories.
- `Lighthunter-PTE-ltd`: Do not use this registry unless explicitly requested.
