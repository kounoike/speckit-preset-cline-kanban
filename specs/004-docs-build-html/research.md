# リサーチ: docs/ マークダウンを HTML にビルドして GitHub Pages にデプロイする

**Date**: 2026-03-29
**Feature**: 004-docs-build-html

---

## 1. 静的サイトジェネレーターの選定

**Decision**: MkDocs + mkdocs-material テーマを採用する。

**比較表**:

| 項目 | MkDocs + Material | Jekyll | mdBook | Hugo |
|------|------------------|--------|--------|------|
| セットアップの簡易さ | ✅ 最簡単（pip 1行） | 中程度（Ruby） | ✅ 簡単 | 中程度（Go） |
| 自動ナビゲーション | ✅ 設定不要（ディレクトリ構造から自動生成） | 手動 YAML | SUMMARY.md 必要 | 手動設定 |
| CI インストール時間 | ~40秒（pip） | ~2分（Ruby gems） | ~5秒 | ~10秒 |
| GitHub Pages 対応 | ✅ upload-pages-artifact 対応 | ✅ ネイティブ | 手動 | 手動 |
| ドキュメント特化 | ✅ | △（汎用） | ✅（書籍向き） | △（汎用） |

**Rationale**: `nav:` セクションを省略するだけでディレクトリ構造からナビゲーションを自動生成できる。
`mkdocs.yml` の必須設定は `site_name` の1行のみ。CI での Python セットアップは標準的で安定している。
Material テーマはヘッダー・サイドバー・パンくずリスト・検索を標準装備し、追加設定不要。

**Alternatives considered**:
- Jekyll: ネイティブ GitHub Pages 対応だが、ナビゲーションに手動 YAML 設定が必要。Ruby セットアップが複雑。
- mdBook: 書籍向け UX で SUMMARY.md の手動管理が必要。エコシステムが小さい。
- Hugo: 高速だが、ナビゲーションはテーマ依存で設定が複雑。このスケールには過剰。

---

## 2. GitHub Actions ワークフロー設計

**Decision**: 既存の `deploy-pages.yml` を更新し、Python/MkDocs ビルドステップを追加する。
ビルドジョブとデプロイジョブを分離する2ジョブ構成を採用する。

**Rationale**: ビルドとデプロイを分離することで、Pages デプロイに必要な `id-token: write` 権限を最小スコープに限定できる。
また、ビルド失敗時のデプロイジョブ未実行が自動的に保証される。

**ワークフロー仕様**:

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

**Alternatives considered**:
- `mkdocs gh-deploy --force`: `gh-pages` ブランチへのプッシュ方式だが、既存の「GitHub Actions」ソース設定と矛盾するため却下。
- シングルジョブ構成: シンプルだが権限スコープが広くなるため却下。

---

## 3. MkDocs 設定ファイル

**Decision**: `mkdocs.yml` をリポジトリルートに配置する。

**最小設定**:

```yaml
site_name: SpecKit Preset Catalog
docs_dir: docs
site_dir: site
theme:
  name: material
```

**Rationale**: `nav:` を省略することで `docs/` ディレクトリ構造から自動的にナビゲーションを生成する。
`site_dir: site` を明示して `.gitignore` への追加を容易にする。

---

## 4. パスフィルター設定

**Decision**: `docs/**` に加え `mkdocs.yml` の変更もワークフローをトリガーする。

**Rationale**: `mkdocs.yml` の設定変更（テーマ変更・サイト名変更など）もサイトの見た目に影響するため、
設定ファイル変更時も自動デプロイが必要。

---

## 5. エラーハンドリング方針

**Decision**: `docs/` のマークダウンファイルが0件の場合はビルドをエラー終了させる。
マークダウン構文エラーはデフォルトでビルドを継続させる（`--strict` フラグは使用しない）。

**Rationale**: 仕様の clarify で「空 docs/ はビルド失敗」と確定済み。
`--strict` は内部リンク切れや参照エラーもエラー扱いにするが、
小規模ドキュメントでは管理コストが高いため採用しない。
