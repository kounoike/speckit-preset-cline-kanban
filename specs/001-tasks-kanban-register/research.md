# リサーチ: タスク生成時のkanban CLI自動登録

**Date**: 2026-03-29
**Feature**: 001-tasks-kanban-register

---

## 1. cline/kanban の正体

**Decision**: `cline/kanban` は Cline AI チームが公開するスタンドアロンの npm パッケージ（`kanban`）。
VS Code 拡張ではなく独立したローカル Web アプリ兼 CLI ツール。

**Rationale**: SpecKit preset が依存する CLI ツールが明確に特定できた。
`npm i -g kanban` または `npx kanban` でインストール可能。

**Alternatives considered**: Cline VS Code 拡張の一機能として存在するかを確認したが、
スタンドアロンの別パッケージであることが判明。

---

## 2. kanban CLIのコマンド体系

**Decision**: `kanban task` サブコマンド群を使用する。

**主要コマンド**:

```bash
# サーバー起動（先に起動が必要）
kanban                              # ポート 3484 でサーバー起動
kanban --no-open                    # ブラウザを開かずに起動

# タスク一覧（JSON出力）
kanban task list
kanban task list --column backlog   # backlog カラムのみ

# タスク作成
kanban task create --prompt "[T001] タイトル"

# タスク更新
kanban task update --task-id <uuid> --prompt "[T001] 新しいタイトル"
```

**Rationale**: 全コマンドが JSON を stdout に返すため、シェルスクリプトからの自動化に適している。

**Alternatives considered**: kanban サーバーの REST API に直接アクセスする方法も可能だが、
CLIコマンドを使う方が公式インターフェースとして安定している。

---

## 3. サーバー起動要件

**Decision**: `kanban task` コマンドはローカルサーバー（デフォルト: ポート 3484）が
起動済みであることが前提。preset スクリプトはサーバーの稼働を確認してから処理を開始する。

**Rationale**: サーバーが停止している場合、`kanban task list` は接続エラーで失敗する。
preset スクリプトは事前チェックを行い、停止時は警告を出してワークフローを継続する（FR-005）。

**Alternatives considered**: スクリプトからサーバーを自動起動する案を検討したが、
バックグラウンドプロセスの管理が複雑になるため却下。サーバー起動はユーザーの責任とする。

---

## 4. SpecKit タスクID と kanban タスクID のマッピング

**Decision**: kanban カードの prompt フィールドに SpecKit タスクID を接頭辞として埋め込む。
形式: `[T001] タスクタイトル`

重複チェックは `kanban task list` の結果を jq でフィルタリングし、
prompt が `[T001]` で始まるカードを検索する方式とする。

**Rationale**: 外部ファイルへのマッピング保存が不要でシンプル。
kanban が返す `id`（UUID）は実行ごとに変わらないため、
一度作成されたカードは prompt 前置で確実に識別できる。

**Alternatives considered**: `.specify/kanban-mapping.json` にマッピングを保存する案は
ファイル管理の複雑さを増やすため却下。

---

## 5. tasks.md のパース方法

**Decision**: tasks.md の各行を正規表現でパースする。

**パターン**:
```bash
# タスク行の形式: - [ ] T001 [P] [US1] タイトル
TASK_PATTERN='^\s*-\s*\[[ x]\]\s*(T[0-9]+)\s*(.*)'
TASK_ID_GROUP=1
TASK_TITLE_GROUP=2

# 完了タスクの検出
COMPLETED_PATTERN='^\s*-\s*\[x\]\s*(T[0-9]+)'
```

**Rationale**: SpecKit の標準フォーマットに準拠したシンプルな正規表現でパース可能。
`[P]`、`[US1]` 等の補足情報は kanban カードの prompt に含めてもよいが、
最低限タスクID とタイトルのみで十分（FR-004）。

---

## 6. preset の配布方式

**Decision**: GitHub Pages 上の preset catalog（このリポジトリの `docs/` ディレクトリ）に
preset メタデータと参照方法を公開する。

**catalog エントリの形式（想定）**:
```yaml
name: cline-kanban
description: SpecKit タスク生成時に cline/kanban に自動登録するpreset
version: 1.0.0
requires:
  - kanban (npm package)
  - Node.js 18+
install_url: https://github.com/kounoike/speckit-preset-cline-kanban
```

**Rationale**: GitHub Pages は無料でホスティング可能。SpecKit の preset catalog 仕様に準拠。

**Alternatives considered**: npm registry への公開も検討したが、
SpecKit preset は GitHub 参照が標準的な配布方法。

---

## 7. 双方向同期（/speckit.sync）の実装方針

**Decision**: `kanban task list` でカード状態（カラム）を取得し、
`in_progress` または完了カラムのカードに対応する tasks.md のチェックボックスを更新する。

**カラムと tasks.md 状態のマッピング**:
| kanban カラム | tasks.md 状態 |
|--------------|--------------|
| backlog | `- [ ]`（未着手） |
| in_progress | `- [ ]`（着手中、チェックなし維持） |
| review | `- [ ]`（レビュー中、チェックなし維持） |
| 完了カラム | `- [x]`（完了） |

**Rationale**: tasks.md では「完了（[x]）」と「未完了（[ ]）」の2状態のみ表現可能。
kanban のより細かい状態は in_progress/review を「未完了」に対応させる。

**Alternatives considered**: カスタム状態マーカーの導入は却下（SpecKit 標準フォーマット変更不要）。
