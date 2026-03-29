# コントラクト: GitHub Actions ワークフローインターフェース

**Date**: 2026-03-29
**Feature**: 002-catalog-pages-deploy

---

## ワークフローファイル

**パス**: `.github/workflows/deploy-pages.yml`

---

## トリガーコントラクト

| トリガー | 条件 | 説明 |
|---------|------|------|
| `push` | branch: `main`, paths: `docs/**` | docs/ 変更を含む main プッシュ時（FR-001） |
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

### deploy ジョブ

| 項目 | 値 |
|-----|-----|
| runner | `ubuntu-latest` |
| environment | `github-pages` |
| outputs | `page_url`（デプロイ後の公開 URL） |

### ステップ一覧

| ステップ | アクション | 説明 |
|---------|-----------|------|
| docs/ 存在確認 | シェルコマンド | `docs/` がない場合に失敗（FR-006） |
| Checkout | `actions/checkout@v4` | ソースコードを取得 |
| Configure Pages | `actions/configure-pages@v5` | GitHub Pages の設定 |
| Upload artifact | `actions/upload-pages-artifact@v3` | `docs/` をアーティファクトとしてアップロード |
| Deploy Pages | `actions/deploy-pages@v4` | GitHub Pages にデプロイ（FR-002） |

---

## 出力コントラクト

| 出力 | 型 | 説明 |
|-----|-----|------|
| `page_url` | URL | デプロイ後の GitHub Pages 公開 URL |

---

## 成否コントラクト

| 状態 | CI ステータス | 通知 |
|-----|-------------|------|
| 成功 | ✅ 緑チェック | なし |
| 失敗 | ❌ 赤バツ | GitHub 標準メール（FR-006） |
| キャンセル | ⚪ グレー | なし（後続デプロイが優先） |
