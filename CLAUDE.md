# speckit-preset-cline-kanban Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-03-29

## Active Technologies
- YAML（GitHub Actions ワークフロー構文） + `actions/checkout@v4`、`actions/configure-pages@v5`、 (002-catalog-pages-deploy)
- N/A（GitHub Pages がホスティングを担当） (002-catalog-pages-deploy)
- YAML（GitHub Actions）+ Python 3.12（MkDocs ビルド） + `actions/checkout@v4`、`actions/setup-python@v5`、 (004-docs-build-html)

- Bash (sh互換、macOS/Linux対応) + `kanban` npm package (cline/kanban)、`jq` (JSON処理) (001-tasks-kanban-register)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for Bash (sh互換、macOS/Linux対応)

## Code Style

Bash (sh互換、macOS/Linux対応): Follow standard conventions

## Recent Changes
- 004-docs-build-html: Added YAML（GitHub Actions）+ Python 3.12（MkDocs ビルド） + `actions/checkout@v4`、`actions/setup-python@v5`、
- 002-catalog-pages-deploy: Added YAML（GitHub Actions ワークフロー構文） + `actions/checkout@v4`、`actions/configure-pages@v5`、

- 001-tasks-kanban-register: Added Bash (sh互換、macOS/Linux対応) + `kanban` npm package (cline/kanban)、`jq` (JSON処理)

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
