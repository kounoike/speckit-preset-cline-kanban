# クイックスタート: MkDocs による GitHub Pages ビルドデプロイ

**Date**: 2026-03-29
**Feature**: 004-docs-build-html

---

## 前提条件

1. GitHub リポジトリの **Settings > Pages** で **Source: GitHub Actions** に設定済み
2. `docs/` ディレクトリに1つ以上の `.md` ファイルが存在する
3. `mkdocs.yml` がリポジトリルートに存在する

---

## セットアップ手順

### 1. MkDocs 設定ファイルを配置する

`mkdocs.yml` をリポジトリルートに作成する（このフィーチャーで実装）。

### 2. ワークフローファイルを更新する

`.github/workflows/deploy-pages.yml` にビルドステップが追加される（このフィーチャーで実装）。

---

## ローカルでの動作確認

### ビルドのプレビュー（Python 環境が必要）

```bash
# MkDocs Material をインストール
pip install mkdocs-material

# ローカルサーバーで確認（http://127.0.0.1:8000）
mkdocs serve

# または静的ビルドのみ
mkdocs build
# → site/ ディレクトリに HTML が生成される
```

### ビルド成功の確認

```bash
ls site/
# index.html が存在し、ナビゲーションを含む HTML が生成されていること

# ブラウザで開いて確認
open site/index.html  # macOS
xdg-open site/index.html  # Linux
```

---

## GitHub Actions での動作確認

### 自動デプロイの確認

```bash
# docs/ に変更を加えて main にプッシュ
echo "## 更新" >> docs/index.md
git add docs/index.md
git commit -m "docs: update catalog"
git push origin main
```

→ GitHub Actions タブで `build` ジョブと `deploy` ジョブが起動し、完了後に Pages URL が更新される。

### mkdocs.yml 変更時のデプロイ確認

```bash
# mkdocs.yml を変更して push
git add mkdocs.yml
git commit -m "docs: update mkdocs config"
git push origin main
```

→ 設定ファイルの変更もデプロイがトリガーされる。

### 手動デプロイの確認

1. GitHub リポジトリの **Actions** タブを開く
2. 左サイドバーから **Deploy GitHub Pages** ワークフローを選択
3. **Run workflow** ボタンをクリック → **Run workflow** で実行

---

## デプロイ結果の確認

- **成功**: コミットに緑のチェックマーク、Pages URL でナビゲーション付き HTML サイトが表示される
- **失敗（docs/ なし）**: `ERROR: docs/ directory not found` のエラーで `build` ジョブが赤になる
- **失敗（.md なし）**: `ERROR: No markdown files found in docs/` のエラーで `build` ジョブが赤になる

---

## トラブルシューティング

### ワークフローが実行されない

- `docs/` 以外のファイルのみの変更では実行されない（ただし `mkdocs.yml` 変更はトリガーされる）
- main ブランチ以外へのプッシュでは実行されない

### HTML が生成されるがナビゲーションが表示されない

- `mkdocs.yml` の `theme.name: material` が設定されているか確認する
- `pip install mkdocs-material` が完了しているか Actions ログを確認する

### ローカルで `mkdocs build` は成功するが CI で失敗する

- Python バージョンの差異を確認する（CI は Python 3.12）
- `mkdocs-material` のバージョンを `requirements.txt` で固定することを検討する

### `docs/` ディレクトリが見つからないエラー

- `docs/` ディレクトリが存在することを確認する
- `docs/index.md` 等のファイルが存在することを確認する
