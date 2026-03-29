---

description: "タスク生成時のkanban CLI自動登録 — 実装タスク一覧"
---

# Tasks: タスク生成時のkanban CLI自動登録

**Input**: Design documents from `/specs/001-tasks-kanban-register/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: 憲法の「テストファースト（非交渉的）」原則により、各ストーリーのテストを実装前に作成する。

**Organization**: ユーザーストーリーごとにフェーズを分割し、独立した実装・テストを可能にする。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 並列実行可能（異なるファイル、依存なし）
- **[Story]**: 対応するユーザーストーリー（US1, US2, US3）
- ファイルパスを明記する

## Path Conventions

- スクリプト: `.specify/scripts/bash/`
- テスト: `tests/kanban-register/`
- テストフィクスチャ: `tests/kanban-register/fixtures/`
- GitHub Pages: `docs/`
- SpecKit 設定: `.specify/`

---

## Phase 1: Setup（共有インフラ初期化）

**Purpose**: プロジェクト構造の初期化とテスト基盤のセットアップ

- [x] T001 テスト用ディレクトリ構造を作成する: `tests/kanban-register/fixtures/`
- [x] T002 [P] bats-core をセットアップする（`tests/` に git submodule または npm devDependency として追加）
- [x] T003 [P] `tests/kanban-register/fixtures/sample-tasks.md` を作成する（10件以上のタスクを含む標準フォーマットのサンプル）
- [x] T004 [P] `tests/kanban-register/fixtures/kanban-list-response.json` を作成する（`kanban task list` の想定 JSON レスポンスのモック）
- [x] T005 [P] `docs/` ディレクトリを作成しGitHub Pages の骨格ファイルを用意する

---

## Phase 2: Foundational（ブロッキング前提条件）

**Purpose**: 全ユーザーストーリーが依存するスクリプト骨格とサーバー疎通確認機能

**⚠️ CRITICAL**: このフェーズ完了前にいかなるユーザーストーリー実装も開始してはならない

- [x] T006 `kanban-register.sh` の骨格（引数検証・使用方法表示）を作成する: `.specify/scripts/bash/kanban-register.sh`
- [x] T007 [P] `kanban-sync.sh` の骨格（引数検証・使用方法表示）を作成する: `.specify/scripts/bash/kanban-sync.sh`
- [x] T008 [P] `kanban-register.sh` に `kanban` コマンド存在確認と実行権限チェックを追加する: `.specify/scripts/bash/kanban-register.sh`
- [x] T009 kanban サーバー疎通確認関数（`check_kanban_server`）を `kanban-register.sh` に実装する（ポート 3484 への接続テスト）: `.specify/scripts/bash/kanban-register.sh`

**Checkpoint**: スクリプト骨格完成 — ユーザーストーリー実装を開始できる

---

## Phase 3: User Story 3 - kanban CLI 障害時フォールバック（Priority: P3）🛡️ 基盤

**Goal**: kanban CLI が使用不可でも `tasks.md` 生成を妨げない安全策を確立する

**Independent Test**: `kanban` コマンドを一時的に PATH から除いた状態でスクリプトを実行し、
終了コード 0 で警告メッセージが出力されることを確認する

> **NOTE: テストを先に作成し FAIL を確認してから実装する**

### US3 のテスト

- [x] T010 [P] [US3] サーバー未起動時のフォールバックテストを作成する（終了コード 0、警告メッセージ確認）: `tests/kanban-register/test-register.bats`
- [x] T011 [P] [US3] `kanban` コマンド未インストール時のテストを作成する: `tests/kanban-register/test-register.bats`

### US3 の実装

- [x] T012 [US3] サーバー未起動時に警告メッセージを出力して終了コード 0 で終了するフォールバック処理を実装する: `.specify/scripts/bash/kanban-register.sh`
- [x] T013 [US3] `kanban` コマンド未インストール時に明確なエラーメッセージを出力するチェックを実装する: `.specify/scripts/bash/kanban-register.sh`
- [x] T014 [US3] US3 テストを実行して GREEN を確認する: `tests/kanban-register/test-register.bats`

**Checkpoint**: US3 完了 — サーバー障害時のフォールバックが動作する

---

## Phase 4: User Story 1 - タスク生成後の自動登録（Priority: P1）🎯 MVP

**Goal**: `/speckit.tasks` 完了後に `tasks.md` の全タスクが kanban backlog に登録される

**Independent Test**: サンプル tasks.md（10件）を使って `kanban-register.sh` を実行し、
`kanban task list` で 10件のカードが `[T001]` 〜 `[T010]` 接頭辞付きで存在することを確認する

> **NOTE: テストを先に作成し FAIL を確認してから実装する**

### US1 のテスト

- [x] T015 [P] [US1] tasks.md パース処理（タスクID・タイトル抽出）のテストを作成する: `tests/kanban-register/test-register.bats`
- [x] T016 [P] [US1] `kanban task create` 呼び出しのテストを作成する（モックレスポンス使用）: `tests/kanban-register/test-register.bats`
- [x] T017 [P] [US1] 登録結果サマリー出力（作成件数）のテストを作成する: `tests/kanban-register/test-register.bats`

### US1 の実装

- [x] T018 [US1] `tasks.md` パース関数（タスクID・タイトルを正規表現で抽出）を実装する: `.specify/scripts/bash/kanban-register.sh`
- [x] T019 [US1] `kanban task list` を呼び出して既存カード一覧を JSON で取得する処理を実装する: `.specify/scripts/bash/kanban-register.sh`
- [x] T020 [US1] 新規タスクに対して `kanban task create --prompt "[Txxx] タイトル"` を呼び出すループ処理を実装する: `.specify/scripts/bash/kanban-register.sh`
- [x] T021 [US1] SyncResult（作成件数・失敗件数）を標準出力に表示する処理を実装する: `.specify/scripts/bash/kanban-register.sh`
- [x] T022 [US1] US1 テストを実行して GREEN を確認する: `tests/kanban-register/test-register.bats`

**Checkpoint**: US1 完了 — tasks.md の全タスクが kanban に登録される（MVP 達成）

---

## Phase 5: User Story 2 - 重複タスクの上書き更新（Priority: P2）

**Goal**: 再実行時に既存カードを重複作成せず上書き更新する

**Independent Test**: 同じ tasks.md を 2回実行し、kanban のカード数が変わらず
タイトルが最新の内容で更新されていることを確認する

> **NOTE: テストを先に作成し FAIL を確認してから実装する**

### US2 のテスト

- [x] T023 [P] [US2] 既存カード（`[T001]` 接頭辞）の検出テストを作成する: `tests/kanban-register/test-register.bats`
- [x] T024 [P] [US2] `kanban task update` 呼び出しのテストを作成する（重複時に update が呼ばれることを確認）: `tests/kanban-register/test-register.bats`

### US2 の実装

- [x] T025 [US2] `kanban task list` の結果から `[Txxx]` 接頭辞で既存カードを検索する重複検出ロジックを実装する: `.specify/scripts/bash/kanban-register.sh`
- [x] T026 [US2] 既存カード検出時に `kanban task update --task-id <uuid> --prompt "..."` で上書き更新する処理を実装する: `.specify/scripts/bash/kanban-register.sh`
- [x] T027 [US2] SyncResult に更新件数（updated）を追加する: `.specify/scripts/bash/kanban-register.sh`
- [x] T028 [US2] US2 テストを実行して GREEN を確認する: `tests/kanban-register/test-register.bats`

**Checkpoint**: US1 + US2 が独立して動作する

---

## Phase 6: 双方向同期（kanban → tasks.md）

**Goal**: `/speckit.sync` で kanban の完了カードを tasks.md のチェックボックスに反映する

**Independent Test**: kanban-list-response.json の完了カードに対して `kanban-sync.sh` を実行し、
tasks.md の対応チェックボックスが `[x]` になることを確認する

> **NOTE: テストを先に作成し FAIL を確認してから実装する**

- [x] T029 [P] kanban 完了カードの tasks.md チェックボックス更新テストを作成する: `tests/kanban-register/test-sync.bats`
- [x] T030 [P] 同期結果（更新件数）出力のテストを作成する: `tests/kanban-register/test-sync.bats`
- [x] T031 `kanban task list` で全カードを取得し完了列のカードを抽出する処理を実装する: `.specify/scripts/bash/kanban-sync.sh`
- [x] T032 完了カードの `[Txxx]` 接頭辞を解析して tasks.md の対応行を `[x]` に更新する処理を実装する: `.specify/scripts/bash/kanban-sync.sh`
- [x] T033 同期結果（更新件数・エラー）を表示する処理を実装する: `.specify/scripts/bash/kanban-sync.sh`
- [x] T034 sync テストを実行して GREEN を確認する: `tests/kanban-register/test-sync.bats`

**Checkpoint**: 全ユーザーストーリーが独立して動作する

---

## Phase 7: SpecKit Preset 設定と GitHub Pages Catalog

**Purpose**: preset として配布可能な設定ファイルと catalog エントリを作成する

- [x] T035 [P] `.specify/extensions.yml` を作成する（after_tasks フック: `optional: true`, cline-kanban）: `.specify/extensions.yml`
- [x] T036 [P] `docs/index.md` に preset catalog エントリを作成する（名前・説明・必要条件・インストール手順）: `docs/index.md`
- [x] T037 [P] GitHub Pages 設定（`docs/` ディレクトリ）を確認・整備する

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: 複数ユーザーストーリーにまたがる改善

- [x] T038 [P] `quickstart.md` を最終動作確認シナリオで検証し必要に応じて更新する: `specs/001-tasks-kanban-register/quickstart.md`
- [x] T039 [P] `CLAUDE.md` に使用コマンド（`kanban task list/create/update`）とテスト実行方法を追記する: `CLAUDE.md`
- [x] T040 全テストを実行して全 GREEN を確認する: `tests/kanban-register/`
- [x] T041 [P] `README.md` を作成してプロジェクト概要・インストール手順・使用方法を記載する

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 依存なし — 即時開始可能
- **Foundational (Phase 2)**: Setup 完了後 — 全ユーザーストーリーをブロック
- **US3 (Phase 3)**: Foundational 完了後 — スクリプト骨格に依存（他ストーリーの前提）
- **US1 (Phase 4)**: Foundational + US3 完了後（フォールバック機能が必要）
- **US2 (Phase 5)**: US1 完了後（`kanban task list` と create のコードを再利用）
- **双方向同期 (Phase 6)**: US1 完了後（独立して実装可能）
- **Preset 設定 (Phase 7)**: US1 完了後（スクリプトパスが確定してから）
- **Polish (Phase 8)**: 全ストーリー完了後

### User Story Dependencies

- **US3 (P3)**: Foundational 完了後に開始 — フォールバック基盤として最初に実装
- **US1 (P1)**: US3 完了後 — 実際の登録処理
- **US2 (P2)**: US1 完了後 — US1 のコードを拡張

### Within Each User Story

- テストを先に作成し FAIL を確認 → 実装 → GREEN 確認
- フォールバック（US3）→ コア機能（US1）→ 重複処理（US2）

### Parallel Opportunities

- Setup フェーズの T002〜T005 はすべて並列実行可能
- Foundational の T006〜T009 は T006 完了後に T007〜T009 を並列実行可能
- 各ストーリーのテスト作成タスク（[P] マーク）は並列実行可能
- T035〜T037（Preset設定）はすべて並列実行可能

---

## Parallel Example: User Story 1

```bash
# US1 のテストを並列作成:
Task: "tasks.md パース処理のテスト (T015)"
Task: "kanban task create 呼び出しのテスト (T016)"
Task: "登録結果サマリー出力のテスト (T017)"

# テスト GREEN 確認後、実装を順次実行:
Task: "tasks.md パース関数の実装 (T018)"
Task: "kanban task list 呼び出し実装 (T019)" ← T018 完了後
Task: "kanban task create ループ実装 (T020)" ← T019 完了後
```

---

## Implementation Strategy

### MVP First (US3 + US1 のみ)

1. Phase 1: Setup 完了
2. Phase 2: Foundational 完了（CRITICAL）
3. Phase 3: US3（フォールバック）完了
4. Phase 4: US1（タスク登録）完了
5. **STOP and VALIDATE**: サンプル tasks.md で kanban への自動登録を確認
6. デモ可能: `kanban` 起動 → `/speckit.tasks` 実行 → カード自動登録を確認

### Incremental Delivery

1. Setup + Foundational → 基盤完成
2. US3 追加 → フォールバック確認（サーバー停止でもエラーにならない）
3. US1 追加 → 自動登録確認（MVP！）
4. US2 追加 → 重複上書き確認
5. 双方向同期追加 → `/speckit.sync` 動作確認
6. Preset 設定追加 → catalog から参照可能

---

## Notes

- `[P]` タスク = 異なるファイル、依存なし → 並列実行推奨
- `[Story]` ラベルでタスクとユーザーストーリーのトレーサビリティを維持
- 各テストは実装前に作成し FAIL を確認すること（憲法 III 原則）
- `kanban task list/create/update` は kanban サーバー（ポート 3484）が起動中であることが前提
- `[Txxx]` 接頭辞が重複検出・双方向同期の要（フォーマットを変えないこと）
- 各 Checkpoint でストーリー単体の動作を検証してから次フェーズへ進む
