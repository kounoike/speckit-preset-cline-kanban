# Implementation Plan: docs/ マークダウンを HTML にビルドして GitHub Pages にデプロイする

**Branch**: `004-docs-build-html` | **Date**: 2026-03-29 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/004-docs-build-html/spec.md`

## Summary

MkDocs + mkdocs-material を使用して `docs/` ディレクトリのマークダウンを HTML に変換し、
GitHub Actions でビルドして GitHub Pages にデプロイする。
既存の `.github/workflows/deploy-pages.yml` にビルドジョブを追加し、
リポジトリルートに `mkdocs.yml` 設定ファイルを新規作成する。
自動ナビゲーション（サイドバー・ヘッダー）は MkDocs が `docs/` 構造から自動生成する。

## Technical Context

**Language/Version**: YAML（GitHub Actions）+ Python 3.12（MkDocs ビルド）
**Primary Dependencies**: `actions/checkout@v4`、`actions/setup-python@v5`、
  `actions/configure-pages@v5`、`actions/upload-pages-artifact@v3`、`actions/deploy-pages@v4`、
  `mkdocs-material`（pip）
**Storage**: N/A（GitHub Pages がホスティングを担当）
**Testing**: 手動検証（ローカル `mkdocs serve` + push → Pages URL 確認）
**Target Platform**: GitHub Actions / GitHub Pages（クラウド）
**Project Type**: CI/CD ワークフロー更新 + 設定ファイル追加
**Performance Goals**: ビルド＋デプロイ完了まで5分以内（SC-001）
**Constraints**: `docs/` 変更または `mkdocs.yml` 変更時のみトリガー、最小権限、ビルドとデプロイの分離
**Scale/Scope**: 2ファイル変更（`deploy-pages.yml` 更新 + `mkdocs.yml` 新規作成）

## Constitution Check

*GATE: Phase 0 リサーチ前に確認。Phase 1 設計後に再確認。*

| 原則 | 状態 | 備考 |
|------|------|------|
| I. 仕様駆動開発 | ✅ PASS | spec.md 承認済み、clarify 完了 |
| II. ユーザーストーリー中心 | ✅ PASS | US1〜US3 すべてワークフローで対応 |
| III. テストファースト | ✅ PASS | quickstart.md でローカルビルド検証手順を先に定義 |
| IV. 段階的デリバリー | ✅ PASS | US1（HTML表示）単独でMVP成立 |
| V. シンプルさ (YAGNI) | ✅ PASS | 2ファイルのみ。`mkdocs.yml` は最小設定 |

**Phase 1 設計後再確認**: `deploy-pages.yml` 更新 + `mkdocs.yml` 追加の2ファイルのみ → シンプルさ原則遵守 ✅

## Project Structure

### Documentation (this feature)

```text
specs/004-docs-build-html/
├── plan.md                        # このファイル
├── research.md                    # Phase 0 リサーチ結果
├── quickstart.md                  # Phase 1 動作確認ガイド
├── contracts/
│   └── workflow-interface.md      # ワークフローインターフェース仕様（更新版）
├── checklists/
│   └── requirements.md            # 仕様品質チェックリスト
└── tasks.md                       # Phase 2 出力（/speckit.tasks で生成）
```

### Source Code (repository root)

```text
mkdocs.yml                              # MkDocs 設定ファイル（新規作成）
.github/
└── workflows/
    └── deploy-pages.yml                # 既存ワークフローにビルドステップを追加
docs/
└── index.md                           # 既存（変更なし）
```

**Structure Decision**: 既存の GitHub Actions ワークフローを更新する最小変更アプローチ。
`mkdocs.yml` はリポジトリルートに配置（MkDocs の慣例）。
ビルド成果物 `site/` は `.gitignore` に追加し、Git 管理外とする。

## Complexity Tracking

> **Constitution Check 違反はなし。このセクションへの記載不要。**

## Implementation Phases

### Phase 1: 設定ファイルとワークフロー更新

**実装タスク**:

#### 1. `mkdocs.yml` の新規作成

```yaml
site_name: SpecKit Preset Catalog
docs_dir: docs
site_dir: site
theme:
  name: material
```

#### 2. `.github/workflows/deploy-pages.yml` の更新

```yaml
name: Deploy GitHub Pages

on:
  push:
    branches: [main]
    paths:
      - 'docs/**'
      - 'mkdocs.yml'
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: docs/ ディレクトリとマークダウンファイルの存在確認
        run: |
          test -d docs/ || { echo "ERROR: docs/ directory not found"; exit 1; }
          ls docs/*.md > /dev/null 2>&1 || { echo "ERROR: No markdown files found in docs/"; exit 1; }

      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'
          cache: 'pip'

      - name: Install MkDocs Material
        run: pip install mkdocs-material

      - name: Build docs
        run: mkdocs build

      - name: Setup Pages
        uses: actions/configure-pages@v5

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./site

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

#### 3. `.gitignore` の更新

`site/`（MkDocs ビルド成果物）を追加する。

### Phase 2: 動作検証

- ローカルで `mkdocs build` を実行し `site/` の生成を確認
- main へ push → Pages URL で HTML ナビゲーション付きサイトを確認
- `docs/` 変更なし push でワークフローがスキップされることを確認
- 手動トリガーの動作確認
