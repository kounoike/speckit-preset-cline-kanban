# Implementation Plan: preset catalog の GitHub Pages 自動デプロイ

**Branch**: `002-catalog-pages-deploy` | **Date**: 2026-03-29 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-catalog-pages-deploy/spec.md`

## Summary

GitHub Actions の公式 Pages デプロイアクション群（`configure-pages`、
`upload-pages-artifact`、`deploy-pages`）を使用して、
main ブランチの `docs/` ディレクトリ変更時に自動的に GitHub Pages を更新する
ワークフローファイル `.github/workflows/deploy-pages.yml` を作成する。
ビルドステップは不要。手動トリガーと並行制御を含む。

## Technical Context

**Language/Version**: YAML（GitHub Actions ワークフロー構文）
**Primary Dependencies**: `actions/checkout@v4`、`actions/configure-pages@v5`、
  `actions/upload-pages-artifact@v3`、`actions/deploy-pages@v4`
**Storage**: N/A（GitHub Pages がホスティングを担当）
**Testing**: 手動検証（`docs/` 変更 → push → Pages URL確認）
**Target Platform**: GitHub Actions / GitHub Pages（クラウド）
**Project Type**: CI/CD ワークフロー（単一 YAML ファイル）
**Performance Goals**: デプロイ完了まで5分以内（SC-001/SC-003）
**Constraints**: ビルドステップなし、`docs/` 変更時のみトリガー、最小権限
**Scale/Scope**: 単一ワークフローファイル。頻度は低い（docs/ 変更時のみ）

## Constitution Check

*GATE: Phase 0 リサーチ前に確認。Phase 1 設計後に再確認。*

| 原則 | 状態 | 備考 |
|------|------|------|
| I. 仕様駆動開発 | ✅ PASS | spec.md 承認済み、clarify 完了 |
| II. ユーザーストーリー中心 | ✅ PASS | US1〜US3 すべてワークフローで対応 |
| III. テストファースト | ✅ PASS | ワークフロー検証手順を先に quickstart.md で定義 |
| IV. 段階的デリバリー | ✅ PASS | US1（自動デプロイ）単独でMVP成立 |
| V. シンプルさ (YAGNI) | ✅ PASS | 単一 YAML ファイル。ビルドなし。外部サービスなし |

**Phase 1 設計後再確認**: ワークフロー1ファイルのみ → シンプルさ原則最大限遵守 ✅

## Project Structure

### Documentation (this feature)

```text
specs/002-catalog-pages-deploy/
├── plan.md              # このファイル
├── research.md          # Phase 0 リサーチ結果
├── quickstart.md        # Phase 1 動作確認ガイド
├── contracts/
│   └── workflow-interface.md  # ワークフローインターフェース仕様
├── checklists/
│   └── requirements.md  # 仕様品質チェックリスト
└── tasks.md             # Phase 2 出力（/speckit.tasks で生成）
```

### Source Code (repository root)

```text
.github/
└── workflows/
    └── deploy-pages.yml    # GitHub Pages 自動デプロイワークフロー（唯一の成果物）
```

**Structure Decision**: GitHub Actions 標準の配置先（`.github/workflows/`）に
単一ファイルを配置するシンプルな構造。

## Complexity Tracking

> **Constitution Check 違反はなし。このセクションへの記載不要。**

## Implementation Phases

### Phase 1: ワークフローファイル作成

**唯一の実装タスク**: `.github/workflows/deploy-pages.yml` を作成する。

ワークフロー仕様（contracts/workflow-interface.md より）:

```yaml
name: Deploy GitHub Pages

on:
  push:
    branches: [main]
    paths: ['docs/**']
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: true

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: docs/ ディレクトリの存在確認
        run: test -d docs/ || { echo "ERROR: docs/ directory not found"; exit 1; }

      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Pages
        uses: actions/configure-pages@v5

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./docs

      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

### Phase 2: GitHub Pages 設定確認

- リポジトリ Settings > Pages > Source: **GitHub Actions** への変更を文書化する
- quickstart.md に設定手順を記載済み

### Phase 3: 動作検証

- `docs/` 変更 → main push → Pages 更新を確認（quickstart.md 参照）
- 手動トリガーの動作確認
- `docs/` 変更なしの push でワークフローがスキップされることを確認
