# コントラクト: extensions.yml インターフェース

**Date**: 2026-03-29
**Feature**: 001-tasks-kanban-register

---

## extensions.yml スキーマ（after_tasks フック）

preset が提供する `extensions.yml` の形式:

```yaml
hooks:
  after_tasks:
    - extension: cline-kanban
      command: speckit.kanban-register
      description: "tasks.md 生成後に cline/kanban へ自動登録する"
      optional: true
      enabled: true
      prompt: |
        tasks.md のすべてのタスクを cline/kanban に登録または更新してください。
        スクリプトを実行: .specify/scripts/bash/kanban-register.sh "$TASKS_FILE"
```

### フィールド定義

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `extension` | string | ✅ | preset の識別名 |
| `command` | string | ✅ | 実行するコマンド名 |
| `description` | string | ✅ | フックの説明 |
| `optional` | boolean | ✅ | `true` = ユーザーが任意実行、`false` = 自動実行 |
| `enabled` | boolean | — | `false` で無効化（省略時は有効） |
| `prompt` | string | — | エージェントへ渡すプロンプト |

---

## kanban-register.sh インターフェース

### 引数

```bash
.specify/scripts/bash/kanban-register.sh <TASKS_FILE>
```

| 引数 | 説明 | 例 |
|------|------|----|
| `TASKS_FILE` | tasks.md のパス（絶対または相対） | `specs/001-xxx/tasks.md` |

### 環境変数（オプション）

| 変数 | 説明 | デフォルト |
|------|------|-----------|
| `KANBAN_PORT` | kanban サーバーのポート番号 | `3484` |
| `KANBAN_PROJECT_PATH` | kanban に渡すプロジェクトパス | カレントディレクトリ |

### 標準出力（JSON）

```json
{
  "status": "success" | "partial" | "skipped" | "error",
  "created": 3,
  "updated": 1,
  "skipped": 0,
  "failed": 0,
  "errors": []
}
```

### 終了コード

| コード | 意味 |
|--------|------|
| `0` | 全タスク登録成功（または kanban 未起動でスキップ） |
| `1` | 一部タスクの登録に失敗（tasks.md 生成は成功済み） |

---

## kanban-sync.sh インターフェース

### 引数

```bash
.specify/scripts/bash/kanban-sync.sh <TASKS_FILE>
```

| 引数 | 説明 | 例 |
|------|------|----|
| `TASKS_FILE` | 更新対象の tasks.md パス | `specs/001-xxx/tasks.md` |

### 標準出力（JSON）

```json
{
  "status": "success" | "error",
  "synced": 2,
  "errors": []
}
```

---

## cline/kanban CLI コントラクト（外部依存）

本 preset が使用する `kanban` コマンドのインターフェース:

```bash
# 前提: kanban サーバーがポート 3484 で稼働中

# カード一覧（JSON）
kanban task list
# 出力: [{"id": "uuid", "prompt": "[T001] タイトル", "column": "backlog", ...}, ...]

# カード作成
kanban task create --prompt "[T001] タイトル"
# 出力: {"id": "uuid", "prompt": "...", ...}

# カード更新
kanban task update --task-id <uuid> --prompt "[T001] 新タイトル"
# 出力: {"id": "uuid", "prompt": "...", ...}
```

**バージョン要件**: `kanban` npm package（任意の安定版）、Node.js 18+
