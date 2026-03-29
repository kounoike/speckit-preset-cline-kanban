# リサーチ: preset catalog の GitHub Pages 自動デプロイ

**Date**: 2026-03-29
**Feature**: 002-catalog-pages-deploy

---

## 1. GitHub Pages デプロイ方式

**Decision**: GitHub Actions 公式アクション群（`actions/configure-pages`、
`actions/upload-pages-artifact`、`actions/deploy-pages`）を使用した
「GitHub Pages deployment」方式を採用する。

**コンフィグ方式との比較**:

| 方式 | 説明 | 採用可否 |
|------|------|--------|
| リポジトリ設定のみ（branch/folder指定） | GitHub UI での設定のみ。CI ステータスに反映されない。 | ❌ |
| GitHub Actions（公式アクション） | ワークフローで制御。CI ステータス・手動トリガー対応。 | ✅ 採用 |
| カスタムスクリプト（gh CLI等） | `gh-pages` ブランチ管理が必要。複雑。 | ❌ |

**Rationale**: 公式アクションは GitHub がメンテナンスし、
`permissions: pages: write` / `id-token: write` の組み合わせで
安全かつ確実に Pages デプロイが可能。CI ステータスに反映されるため FR-003 を満たす。

**Alternatives considered**: `peaceiris/actions-gh-pages` 等のサードパーティアクションは
`gh-pages` ブランチが必要となり、ソース方式（A）と矛盾するため却下。

---

## 2. ワークフロートリガー設定

**Decision**: `on.push.paths: ['docs/**']` + `on.workflow_dispatch` の組み合わせ。

```yaml
on:
  push:
    branches: [main]
    paths: ['docs/**']
  workflow_dispatch:
```

**Rationale**: `paths` フィルターにより `docs/` 変更時のみ実行（FR-001）。
`workflow_dispatch` により手動トリガーを提供（FR-004）。

**Alternatives considered**: `paths-ignore` は他の変更を除外するアプローチだが、
`paths` で明示的に含める方が意図が明確で保守しやすい。

---

## 3. 並行デプロイ制御

**Decision**: `concurrency` グループを設定し、進行中のデプロイをキャンセルして
最新コミットのデプロイを優先する。

```yaml
concurrency:
  group: pages
  cancel-in-progress: true
```

**Rationale**: 同時に複数のプッシュが発生した場合、最新コミットを優先（エッジケース対応）。

---

## 4. 必要な権限

**Decision**: ワークフローに以下の最小権限を付与する。

```yaml
permissions:
  contents: read
  pages: write
  id-token: write
```

**Rationale**: `pages: write` と `id-token: write` は GitHub Pages デプロイに必須。
`contents: read` はリポジトリチェックアウトに必要。最小権限の原則に従う。

---

## 5. docs/ の検証

**Decision**: ワークフロー内で `docs/` ディレクトリの存在チェックを行い、
存在しない場合は明確なエラーメッセージで失敗させる。

```bash
test -d docs/ || { echo "ERROR: docs/ directory not found"; exit 1; }
```

**Rationale**: エッジケース「`docs/` が存在しない場合、デプロイは失敗」への対応（FR-006）。

---

## 6. GitHub Pages 環境設定

**Decision**: GitHub リポジトリの Settings > Pages で以下を設定する前提とする。
- Source: `GitHub Actions`（ブランチ指定ではなく Actions 経由）

**Rationale**: Actions 経由のデプロイには「Source: GitHub Actions」設定が必要。
ワークフロー内の `environment: name: github-pages` と連動する。
