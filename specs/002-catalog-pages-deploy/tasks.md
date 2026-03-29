---

description: "preset catalog の GitHub Pages 自動デプロイ — 実装タスク一覧"
---

# Tasks: preset catalog の GitHub Pages 自動デプロイ

**Input**: Design documents from `/specs/002-catalog-pages-deploy/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, contracts/ ✅, quickstart.md ✅

**Note**: このフィーチャーの成果物は単一の GitHub Actions ワークフロー YAML ファイル。
US1（push 自動デプロイ）・US2（CI ステータス表示）・US3（手動トリガー）はすべて1ファイルで実現。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 並列実行可能
- **[Story]**: 対応するユーザーストーリー（US1, US2, US3）
- ファイルパスを明記する

---

## Phase 1: Setup（プロジェクト初期化）

**Purpose**: GitHub Actions 標準ディレクトリ構造の確認・作成

- [x] T001 `.github/workflows/` ディレクトリを作成する（存在しない場合）

---

## Phase 2: User Story 1 - main プッシュによる自動デプロイ（Priority: P1）🎯 MVP

**Goal**: `docs/` 変更を含む main プッシュ時に GitHub Pages が自動更新される

**Independent Test**: `docs/index.md` に変更を加えて main にプッシュし、
5分以内に GitHub Pages サイトが更新されることで確認する（quickstart.md 参照）

- [x] T002 [US1] `.github/workflows/deploy-pages.yml` を作成する（push トリガー・docs/ アーティファクトアップロード・Pages デプロイ・docs/ 存在チェックを含む完全なワークフロー）
- [x] T003 [US1] `docs/` 変更を含まない push でワークフローがスキップされることを確認する（ローカルで path フィルター設定を検証）

**Checkpoint**: T002 完了時点で US1・US2・US3 の実装コードはすべて揃っている

---

## Phase 3: User Story 2 - デプロイ状態の可視化（Priority: P2）

**Goal**: デプロイ成否が GitHub CI ステータスで確認できる

**Independent Test**: Actions タブでワークフロー実行履歴と成否ステータスを確認する

- [x] T004 [US2] ワークフローの `name` フィールドが Actions UI で識別しやすい名称になっていることを検証する（`.github/workflows/deploy-pages.yml` の `name: Deploy GitHub Pages`）
- [x] T005 [P] [US2] リポジトリの Settings > Pages の Source が **「GitHub Actions」** に設定されていることを確認し、設定手順を `specs/002-catalog-pages-deploy/quickstart.md` に記載する

---

## Phase 4: User Story 3 - 手動デプロイトリガー（Priority: P3）

**Goal**: Actions タブから手動でデプロイを実行できる

**Independent Test**: GitHub Actions タブの「Run workflow」ボタンをクリックしてデプロイを実行する

- [x] T006 [US3] `.github/workflows/deploy-pages.yml` に `workflow_dispatch` トリガーが含まれていることを確認する（T002 の成果物に含まれているはず）

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: ドキュメントとリポジトリ整備

- [x] T007 [P] `README.md` に GitHub Pages のデプロイステータスバッジを追加する（`[![Deploy](https://github.com/kounoike/speckit-preset-cline-kanban/actions/workflows/deploy-pages.yml/badge.svg)](https://github.com/kounoike/speckit-preset-cline-kanban/actions/workflows/deploy-pages.yml)`）
- [x] T008 [P] `docs/index.md` の preset catalog エントリに preset の公開 URL を追記する

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 依存なし — 即時開始可能
- **US1 (Phase 2)**: Setup 完了後 — T002 が全ストーリーの実装コアをカバー
- **US2 (Phase 3)**: T002 完了後 — ワークフローファイルへの追加検証
- **US3 (Phase 4)**: T002 完了後 — `workflow_dispatch` は T002 に含まれる
- **Polish (Phase 5)**: T002 完了後 — 並列実行可能

### User Story Dependencies

- **US1 (P1)**: T001 完了後に開始 — 全フィーチャーの基盤
- **US2 (P2)**: T002 完了後 — US1 のワークフローに対する検証
- **US3 (P3)**: T002 完了後 — workflow_dispatch は US1 の成果物に含まれる

### Parallel Opportunities

- T004、T005 は並列実行可能
- T007、T008 は並列実行可能（異なるファイル）

---

## Implementation Strategy

### MVP First（US1 のみ）

1. Phase 1: T001 — ディレクトリ作成
2. Phase 2: T002 — ワークフローファイル作成（**これ1つでMVP達成**）
3. **STOP and VALIDATE**: `docs/` に変更を加えて push → Pages 更新を確認
4. 完了: preset catalog が自動デプロイされる

### Incremental Delivery

1. T001 + T002 → MVP（自動デプロイ + CI ステータス + 手動トリガーすべて含む）
2. T003〜T006 → 動作検証と設定確認
3. T007〜T008 → ドキュメント整備

---

## Notes

- T002 は US1・US2・US3 のすべてをカバーする単一ファイル
- GitHub Pages の Settings 変更（Source: GitHub Actions）はリポジトリ管理者が手動で行う必要がある
- ワークフローは GitHub に push して初めて動作確認できる（ローカル実行不可）
- `act` ツールを使うとローカルでの擬似実行も可能だが、Pages デプロイは擬似実行不可
