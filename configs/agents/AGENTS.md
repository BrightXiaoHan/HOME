# Agent Instructions

- When running tools or programs that download or generate reusable artifacts, keep caches and local state within the current project workspace whenever practical—for example virtual environments, package caches, model weights, and dataset downloads—rather than writing to global user-level locations.
- For Python workflows, prefer `uv`: run standalone scripts with inline dependency metadata via `uv run`, and manage project-level dependencies in a project-local virtual environment such as `.venv` using `uv venv`, `uv sync`, or equivalent `uv` commands.
