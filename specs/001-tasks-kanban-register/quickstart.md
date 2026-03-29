# クイックスタート: cline-kanban SpecKit Preset

**Date**: 2026-03-29
**Feature**: 001-tasks-kanban-register

---

## 前提条件

1. **Node.js 18+** がインストール済みであること
2. **cline/kanban** がインストール済みであること:
   ```bash
   npm i -g kanban
   # または都度実行: npx kanban
   ```
3. **SpecKit** がセットアップ済みのプロジェクト
4. **jq** がインストール済みであること（JSON 処理用）:
   ```bash
   # macOS
   brew install jq
   # Ubuntu/Debian
   apt-get install jq
   ```

---

## インストール手順

### 1. preset catalog を参照

GitHub Pages の preset catalog（`https://kounoike.github.io/speckit-preset-cline-kanban`）
でインストール方法を確認する。

### 2. preset ファイルをコピー

SpecKit プロジェクトのルートに以下をコピーする:

```bash
# extensions.yml をプロジェクトに追加
cp .specify/extensions.yml /path/to/your-project/.specify/extensions.yml

# スクリプトをコピー
cp .specify/scripts/bash/kanban-register.sh /path/to/your-project/.specify/scripts/bash/
cp .specify/scripts/bash/kanban-sync.sh /path/to/your-project/.specify/scripts/bash/
chmod +x /path/to/your-project/.specify/scripts/bash/kanban-register.sh
chmod +x /path/to/your-project/.specify/scripts/bash/kanban-sync.sh
```

---

## 使い方

### 1. kanban サーバーを起動する

```bash
kanban --no-open   # ブラウザを開かずにサーバー起動
# → http://localhost:3484 でサーバーが起動
```

### 2. SpecKit でタスクを生成する

```
/speckit.tasks
```

タスク生成完了後、`after_tasks` フックが自動的に実行され、
kanban ボードの backlog カラムにカードが登録される。

**出力例**:
```
✅ kanban 登録完了: 作成 8件 / 更新 0件 / 失敗 0件
```

### 3. kanban ボードを確認する

ブラウザで `http://localhost:3484` を開くと、SpecKit のタスクが
backlog カラムにカードとして表示されている。

### 4. kanban の状態を tasks.md に同期する（オプション）

kanban ボードでカードを完了列に移動した後:

```
/speckit.sync
```

tasks.md の対応タスクのチェックボックスが `[x]` に更新される。

---

## トラブルシューティング

### kanban サーバーが起動していない場合

```
⚠️  kanban サーバーに接続できません（ポート 3484）。
   tasks.md の生成は完了しています。
   kanban への登録は `kanban` コマンドを起動後に再実行してください。
```

### kanban コマンドが見つからない場合

```bash
# インストール確認
which kanban || npx kanban --version

# グローバルインストール
npm i -g kanban
```

### 一部タスクの登録に失敗した場合

登録結果に `failed` が表示された場合、エラーメッセージを確認して
再度 `/speckit.tasks` を実行してください（冪等性があります）。
