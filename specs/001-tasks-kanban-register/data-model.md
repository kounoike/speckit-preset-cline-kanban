# データモデル: タスク生成時のkanban CLI自動登録

**Date**: 2026-03-29
**Feature**: 001-tasks-kanban-register

---

## エンティティ定義

### SpecKitTask（tasks.md から読み取る）

| フィールド | 型 | 説明 | 例 |
|-----------|------|------|----|
| `id` | string | SpecKit タスクID | `T001` |
| `title` | string | タスクの説明文 | `プロジェクト構造を作成する` |
| `completed` | boolean | チェックボックス状態 | `false` |
| `parallel` | boolean | `[P]` フラグ | `true` |
| `user_story` | string? | `[US1]` 等のユーザーストーリー参照 | `US1` |
| `priority` | string? | 優先度 `P1`/`P2`/`P3` | `P1` |

**ソース行フォーマット**:
```
- [ ] T001 [P] [US1] プロジェクト構造を作成する
- [x] T002 [US2] モデルを実装する
```

**識別性**: `id` はfeature内で一意。重複防止のキーとして使用する。

---

### KanbanCard（cline/kanban サーバーが管理）

| フィールド | 型 | 説明 | 例 |
|-----------|------|------|----|
| `id` | string (UUID) | kanban 内部ID | `a1b2c3d4-...` |
| `prompt` | string | カードのプロンプト文（タイトル相当） | `[T001] プロジェクト構造を作成する` |
| `column` | enum | カラム（状態） | `backlog` |
| `project_path` | string | リポジトリパス | `/path/to/repo` |

**カラム一覧**:
| 値 | 意味 | tasks.md 対応 |
|----|------|--------------|
| `backlog` | 未着手 | `- [ ]` |
| `in_progress` | 進行中 | `- [ ]` |
| `review` | レビュー中 | `- [ ]` |
| `completed` / 完了列 | 完了 | `- [x]` |
| `trash` | 破棄 | （対応なし） |

**識別性**: `prompt` フィールドの `[T001]` 接頭辞でSpecKit タスクIDを照合する。

---

### SyncResult（登録・同期処理の結果）

| フィールド | 型 | 説明 |
|-----------|------|------|
| `created` | integer | 新規作成したカード数 |
| `updated` | integer | 上書き更新したカード数 |
| `skipped` | integer | スキップした件数 |
| `failed` | integer | 失敗した件数 |
| `errors` | string[] | エラーメッセージ一覧 |

---

## 状態遷移

### SpecKit → kanban（`after_tasks` フック）

```
tasks.md 生成
    ↓
サーバー疎通確認
    ↓ (失敗時は警告して終了)
kanban task list で既存カード取得
    ↓
各タスクについて:
  既存カードあり → kanban task update --task-id <uuid> --prompt "[Txxx] タイトル"
  既存カードなし → kanban task create --prompt "[Txxx] タイトル"
    ↓
SyncResult を標準出力に表示
```

### kanban → SpecKit（`/speckit.sync` コマンド）

```
kanban task list で全カード取得
    ↓
完了列のカードを抽出（`[Txxx]` 接頭辞で照合）
    ↓
tasks.md の対応チェックボックスを `[x]` に更新
    ↓
変更件数を表示
```

---

## 制約・バリデーション

- `SpecKitTask.id` は `T` + 数字3桁以上のパターン（正規表現: `^T[0-9]+$`）
- `KanbanCard.prompt` は `[T001]` 形式の接頭辞で始まらなければならない（MUST）
- tasks.md にタスクが0件の場合、kanban CLIは呼び出さない
- kanban サーバーが起動していない場合（ポート 3484 への接続失敗）、処理をスキップして警告を出す
