# フィーチャー仕様: タスク生成時のkanban CLI自動登録

**Feature Branch**: `001-tasks-kanban-register`
**Created**: 2026-03-29
**Status**: Draft
**Input**: User description: "github/spec-kitのpresetで、タスク生成時にcline/kanbanにkanban cliコマンドで自動登録する"

## ユーザーシナリオ＆テスト *(必須)*

### ユーザーストーリー1 - タスク生成後のkanbanボード自動登録 (優先度: P1)

開発者がSpecKitの `/speckit.tasks` コマンドを実行すると、`tasks.md` に生成されたすべてのタスクが
自動的にkanban CLIコマンドを通じてcline/kanbanボードの「未着手」カラムにカードとして登録される。
開発者は手動でkanbanボードにタスクを転記する必要がなくなる。

**Why this priority**: タスクの自動同期はこの機能の核心価値であり、他のすべてのユーザーストーリーの基盤となる。

**Independent Test**: `/speckit.tasks` 実行後にkanban CLIでカード一覧を確認し、
tasks.md のすべてのタスクIDと一致するカードが存在することで検証可能。

**Acceptance Scenarios**:

1. **Given** 有効な `plan.md` と `spec.md` が存在し、kanban CLIが利用可能な状態で、
   **When** `/speckit.tasks` コマンドが正常に完了した、
   **Then** `tasks.md` 内のすべてのタスク（T001、T002等）がkanbanボードの「未着手」カラムに
   タスクIDとタイトルを持つカードとして登録されている。

2. **Given** 10件以上のタスクを含む `tasks.md` が生成された、
   **When** kanban登録処理が完了した、
   **Then** `tasks.md` に記載された全タスクがkanbanボードに登録され、
   ユーザーに登録件数のサマリーが表示される。

---

### ユーザーストーリー2 - タスク重複登録の防止 (優先度: P2)

`/speckit.tasks` を再実行した場合、または既存タスクと同じIDのタスクが存在する場合、
重複したkanbanカードを作成せず、既存カードを更新するか、重複をスキップする。

**Why this priority**: 仕様変更による再生成時にボードが汚染されることを防ぐ。P1の安定稼働後に対応。

**Independent Test**: 同じfeatureに対して `/speckit.tasks` を2回実行後、
kanbanボードのカード数が1回分のタスク数と等しいことで検証可能。

**Acceptance Scenarios**:

1. **Given** あるfeatureのタスクがすでにkanbanボードに登録されている状態で、
   **When** 同じfeatureに対して `/speckit.tasks` を再実行した、
   **Then** kanbanボードに重複カードは作成されず、既存カードのタイトルが最新の内容で上書き更新され、
   更新件数がログに記録される。

---

### ユーザーストーリー3 - kanban CLI障害時のフォールバック (優先度: P3)

kanban CLIが利用できない場合（未インストール、接続エラー等）でも、
`tasks.md` の生成は正常に完了し、開発者に明確なエラーメッセージを表示する。

**Why this priority**: 本来の目的（tasks.md生成）を損なわないための安全策。他ストーリーとは独立。

**Independent Test**: kanban CLIを一時的に無効化した状態で `/speckit.tasks` を実行し、
`tasks.md` が正常に生成され、エラーメッセージが出力されることで検証可能。

**Acceptance Scenarios**:

1. **Given** kanban CLIがインストールされていないか接続できない状態で、
   **When** `/speckit.tasks` コマンドを実行した、
   **Then** `tasks.md` は正常に生成され、kanban登録に失敗した旨の警告メッセージが
   表示されるが、コマンド全体は失敗しない。

---

### エッジケース

- `tasks.md` にタスクが1件もない場合、kanban CLIは呼び出されない（または空登録をスキップする）。
- タスクの一部がkanban登録に失敗した場合、成功した件数と失敗した件数を両方報告する。
- kanban CLIが予期しない終了コードを返した場合、エラー内容をユーザーに表示しワークフローを継続する。

## 要件 *(必須)*

### 機能要件

- **FR-001**: システムは `/speckit.tasks` コマンド完了後に自動的にkanban登録処理を実行しなければならない（MUST）。
- **FR-002**: システムは `tasks.md` からタスクID、タイトル、優先度、ユーザーストーリー関連を抽出しなければならない（MUST）。
- **FR-003**: システムは `cline/kanban` 専用CLIコマンドを使用して各タスクをkanbanボードに登録しなければならない（MUST）。
- **FR-004**: 登録されるカードは最低限タスクIDとタイトルを含まなければならない（MUST）。
- **FR-005**: kanban登録の失敗は `tasks.md` 生成を妨げてはならない（MUST NOT）。
- **FR-006**: システムは重複タスクID検出時、既存カードのタイトルを最新の `tasks.md` の内容で上書き更新しなければならない（MUST）。
- **FR-007**: 登録結果（成功件数・失敗件数）をユーザーに表示しなければならない（MUST）。
- **FR-008**: 本機能はSpecKit presetの `extensions.yml` の `after_tasks` フックメカニズムを通じて実装されなければならない（MUST）。
- **FR-011**: presetはGitHub Pages上のpreset catalogに登録・公開され、ユーザーがcatalogを参照してインストールできなければならない（MUST）。
- **FR-012**: catalog上のpresetエントリにはインストール手順と必要な前提条件（`cline/kanban` CLI等）を記載しなければならない（MUST）。
- **FR-009**: システムはタスクの状態変化（未着手→進行中→完了等）をkanbanカードの状態に反映しなければならない（MUST）。
- **FR-010**: 専用の同期コマンド実行時に、kanbanボード上のカード状態変化を `tasks.md` のタスク完了状態（チェックボックス）に反映しなければならない（MUST）。

### キーエンティティ

- **タスク**: タスクID（T001等）、タイトル（説明文）、優先度（P1/P2等）、
  ユーザーストーリー関連（US1等）、並列実行フラグ（[P]）
- **Kanbanカード**: タイトル（タスクID + タイトル）、カラム（未着手／進行中／完了）、
  タスクIDへの参照（重複防止・双方向同期用）
- **登録結果**: 成功件数、失敗件数、スキップ件数、エラー詳細

## 成功基準 *(必須)*

### 測定可能な成果

- **SC-001**: `/speckit.tasks` 完了から60秒以内に、tasks.md の全タスクがkanbanボードに反映されている。
- **SC-002**: 同一featureに対して `/speckit.tasks` を複数回実行しても、
  kanbanボードのカード数は各タスクにつき1枚を超えない。
- **SC-003**: kanban CLIが利用不可な状態でも、`/speckit.tasks` のタスク生成成功率は100%を維持する。
- **SC-004**: kanban登録処理の結果（成功・失敗・スキップ件数）が毎回ユーザーに表示される。

## 明確化

### Session 2026-03-29

- Q: kanban CLIの対象ツールは何か → A: `cline/kanban` 専用CLI（このプロジェクト専用）
- Q: 重複タスクID検出時のデフォルト動作は → A: 上書き更新（既存カードのタイトルを最新のtasks.mdで更新）
- Q: タスク同期のスコープは → A: タスク状態変化（完了・進行中等）もkanbanカードに双方向で同期する
- Q: kanbanボード→SpecKit方向の同期トリガーは → A: 専用コマンド実行時（例: `/speckit.sync`）に手動同期
- Q: presetの配布形式は → A: preset catalogをGitHub Pagesに公開し、ユーザーがそこを参照してインストールする

## 前提条件

- `cline/kanban` CLIはユーザーの環境にインストール済みで、実行可能なパスに配置されている。
- `cline/kanban` CLIはコマンドラインからカードの作成・検索・更新が可能である。
- SpecKitのextensions.yml `after_tasks` フックが本バージョンのSpecKitでサポートされている。
- `tasks.md` はSpecKitの標準フォーマット（`T001 [P] [US1] タイトル` 形式）に従って生成される。
- 本機能はSpecKit presetとして提供され、ユーザーはGitHub Pages上のpreset catalogを参照してインストールする。
- preset catalogはこのリポジトリのGitHub Pagesとして公開される。
