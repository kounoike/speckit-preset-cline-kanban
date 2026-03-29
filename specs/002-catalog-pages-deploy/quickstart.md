# クイックスタート: GitHub Pages 自動デプロイ

**Date**: 2026-03-29
**Feature**: 002-catalog-pages-deploy

---

## 前提条件

1. GitHub リポジトリの **Settings > Pages** で **Source: GitHub Actions** に設定済み
2. リポジトリに `docs/` ディレクトリが存在する

---

## セットアップ手順

### 1. ワークフローファイルを配置する

`.github/workflows/deploy-pages.yml` が自動的に配置される（このフィーチャーで実装）。

### 2. GitHub Pages を有効化する

リポジトリの Settings > Pages > Build and deployment > Source を
**「GitHub Actions」** に変更する。

---

## 動作確認

### 自動デプロイの確認

```bash
# docs/ に変更を加えて main にプッシュ
echo "# Updated" >> docs/index.md
git add docs/index.md
git commit -m "docs: update catalog"
git push origin main
```

→ GitHub Actions タブでワークフローが起動し、完了後に Pages URL が更新される。

### 手動デプロイの確認

1. GitHub リポジトリの **Actions** タブを開く
2. 左サイドバーから **Deploy GitHub Pages** ワークフローを選択
3. **Run workflow** ボタンをクリック → **Run workflow** で実行

### デプロイ結果の確認

- **成功**: コミットに緑のチェックマーク、Pages URL でサイトが更新されている
- **失敗**: コミットに赤の ✗、Actions タブで失敗ステップとエラーログを確認

---

## トラブルシューティング

### ワークフローが実行されない

- `docs/` 以外のファイルのみの変更では実行されない（仕様通り）
- main ブランチ以外へのプッシュでは実行されない

### デプロイは成功したがサイトが更新されない

- GitHub Pages のキャッシュにより数分かかる場合がある（最大5分）
- ブラウザのキャッシュをクリアして再確認する

### `docs/` ディレクトリが見つからないエラー

- `docs/` ディレクトリが存在することを確認する
- `docs/index.md` 等のファイルが存在することを確認する
