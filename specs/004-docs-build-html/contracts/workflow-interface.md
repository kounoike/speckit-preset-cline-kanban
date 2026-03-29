# コントラクト: GitHub Actions ワークフローインターフェース（更新版）

**Date**: 2026-03-29
**Feature**: 004-docs-build-html
**Replaces**: specs/002-catalog-pages-deploy/contracts/workflow-interface.md

---

## ワークフローファイル

**パス**: `.github/workflows/deploy-pages.yml`（既存ファイルを更新）

---

## トリガーコントラクト

| トリガー | 条件 | 説明 |
|---------|------|------|
| `push` | branch: `main`, paths: `docs/**` または `mkdocs.yml` | ドキュメントまたはビルド設定の変更時（FR-001） |
| `workflow_dispatch` | なし | 手動実行（FR-004） |

---

## 権限コントラクト

```yaml
permissions:
  contents: read    # チェックアウト用
  pages: write      # GitHub Pages デプロイ用
  id-token: write   # OIDC トークン（Pages デプロイに必須）
```

---

## 並行制御コントラクト

```yaml
concurrency:
  group: pages
  cancel-in-progress: true   # 最新コミットを優先
```

---

## ジョブコントラクト

### build ジョブ

| 項目 | 値 |
|-----|-----|
| runner | `ubuntu-latest` |
| 依存 | なし |

### ステップ一覧（build）

| ステップ | アクション | 説明 |
|---------|-----------|------|
| docs/ 存在確認 | シェルコマンド | `docs/` と `.md` ファイルの存在確認（FR-003） |
| Checkout | `actions/checkout@v4` | ソースコードを取得 |
| Setup Python | `actions/setup-python@v5` | Python 3.12 + pip キャッシュ |
| Install MkDocs | pip | `mkdocs-material` をインストール |
| Build docs | `mkdocs build` | `docs/` → `site/` に HTML を生成（FR-002） |
| Setup Pages | `actions/configure-pages@v5` | GitHub Pages の設定 |
| Upload artifact | `actions/upload-pages-artifact@v3` | `site/` をアーティファクトとしてアップロード |

### deploy ジョブ

| 項目 | 値 |
|-----|-----|
| runner | `ubuntu-latest` |
| environment | `github-pages` |
| 依存 | `build` ジョブ完了後 |
| outputs | `page_url`（デプロイ後の公開 URL） |

### ステップ一覧（deploy）

| ステップ | アクション | 説明 |
|---------|-----------|------|
| Deploy Pages | `actions/deploy-pages@v4` | GitHub Pages にデプロイ（FR-003） |

---

## MkDocs 設定コントラクト

**パス**: `mkdocs.yml`（リポジトリルート）

```yaml
site_name: SpecKit Preset Catalog
docs_dir: docs
site_dir: site
theme:
  name: material
```

---

## 出力コントラクト

| 出力 | 型 | 説明 |
|-----|-----|------|
| `page_url` | URL | デプロイ後の GitHub Pages 公開 URL |
| `site/` | ディレクトリ | MkDocs が生成した HTML ファイル群（ビルド中間成果物） |

---

## 成否コントラクト

| 状態 | CI ステータス | 原因例 |
|-----|-------------|--------|
| 成功 | ✅ 緑チェック | ビルド・デプロイ正常完了 |
| 失敗（build） | ❌ 赤バツ | `docs/` なし、.md なし、MkDocs エラー |
| 失敗（deploy） | ❌ 赤バツ | Pages 設定エラー、権限エラー |
| キャンセル | ⚪ グレー | 新しいビルドが優先（concurrency） |
