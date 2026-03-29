---

description: "docs/ マークダウンを HTML にビルドして GitHub Pages にデプロイ — 実装タスク一覧"
---

# Tasks: docs/ マークダウンを HTML にビルドして GitHub Pages にデプロイする

**Input**: Design documents from `/specs/004-docs-build-html/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, contracts/ ✅, quickstart.md ✅

**Note**: このフィーチャーの成果物は2ファイル（`mkdocs.yml` 新規作成 + `.github/workflows/deploy-pages.yml` 更新）。
US1（HTML変換）・US2（自動デプロイ）・US3（手動トリガー）はすべて `deploy-pages.yml` で実現。
`mkdocs.yml` はナビゲーション自動生成を含む HTML 変換の設定ファイル。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 並列実行可能
- **[Story]**: 対応するユーザーストーリー（US1, US2, US3）
- ファイルパスを明記する

---

## Phase 1: Setup（プロジェクト初期化）

**Purpose**: ビルド成果物をバージョン管理から除外する

- [x] T001 `.gitignore` に `site/`（MkDocs ビルド成果物ディレクトリ）を追加する

---

## Phase 2: Foundational（ブロッキング前提条件）

**Purpose**: MkDocs 設定ファイルの作成（ワークフロー更新の前提）

**⚠️ CRITICAL**: T002 完了後に T003 を開始できる

- [x] T002 `mkdocs.yml` をリポジトリルートに作成する（`site_name: SpecKit Preset Catalog`、`docs_dir: docs`、`site_dir: site`、`theme.name: material` の最小設定）

**Checkpoint**: `mkdocs.yml` 完了 → ワークフロー更新を開始できる

---

## Phase 3: User Story 1 - マークダウンが HTML として閲覧できる（Priority: P1）🎯 MVP

**Goal**: `docs/` のマークダウンが自動ナビゲーション付き HTML としてブラウザで表示される

**Independent Test**: ローカルで `pip install mkdocs-material && mkdocs build` を実行し、
`site/index.html` が存在し HTML として整形されていることを確認する（quickstart.md 参照）

- [x] T003 [US1] `.github/workflows/deploy-pages.yml` を更新する（Python 3.12 セットアップ・mkdocs-material インストール・`mkdocs build` 実行・アーティファクトパスを `./site` に変更・`build` + `deploy` の2ジョブ構成・`docs/` と `.md` ファイルの存在確認を含む完全なワークフロー）
- [x] T004 [US1] ローカルで `mkdocs build` を実行して `site/index.html` とナビゲーション付き HTML が生成されることを確認する（`quickstart.md` のローカル確認手順参照）

**Checkpoint**: T003・T004 完了時点で US1・US2・US3 の実装コードはすべて揃っている

---

## Phase 4: User Story 2 - docs/ 変更時に自動ビルド＆デプロイが実行される（Priority: P2）

**Goal**: `docs/` または `mkdocs.yml` 変更時に自動でビルド＆デプロイが実行される

**Independent Test**: Actions タブでビルドジョブとデプロイジョブの実行履歴と成否ステータスを確認する

- [x] T005 [US2] ワークフローのパスフィルターに `docs/**` と `mkdocs.yml` の両方が含まれていることを確認する（`.github/workflows/deploy-pages.yml`）
- [x] T006 [P] [US2] `docs/` 以外のファイルのみの push でワークフローがスキップされることをパスフィルター設定で検証する

---

## Phase 5: User Story 3 - 手動デプロイトリガー（Priority: P3）

**Goal**: Actions タブから手動でビルド＆デプロイを実行できる

**Independent Test**: GitHub Actions タブの「Run workflow」ボタンをクリックしてデプロイを実行する

- [x] T007 [US3] `.github/workflows/deploy-pages.yml` に `workflow_dispatch` トリガーが含まれていることを確認する（T003 の成果物に含まれているはず）

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: ドキュメント整備と動作確認

- [x] T008 [P] `docs/index.md` の内容が MkDocs ナビゲーション付き HTML として正しく表示される構造になっていることを確認する（見出し・リスト・リンクを含む）
- [x] T009 [P] `README.md` の GitHub Pages デプロイステータスバッジが引き続き有効であることを確認する（ワークフロー名が変わっていないため変更不要なはず）

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 依存なし — 即時開始可能
- **Foundational (Phase 2)**: Setup 完了後 — T002（mkdocs.yml）が T003 の前提
- **US1 (Phase 3)**: T002 完了後 — T003 が全ストーリーの実装コアをカバー
- **US2 (Phase 4)**: T003 完了後 — ワークフローファイルへの追加検証
- **US3 (Phase 5)**: T003 完了後 — `workflow_dispatch` は T003 に含まれる
- **Polish (Phase 6)**: T003 完了後 — 並列実行可能

### User Story Dependencies

- **US1 (P1)**: T001・T002 完了後に開始 — 全フィーチャーの基盤
- **US2 (P2)**: T003 完了後 — US1 のワークフローに対する検証
- **US3 (P3)**: T003 完了後 — workflow_dispatch は US1 の成果物に含まれる

### Parallel Opportunities

- T005、T006 は並列実行可能
- T008、T009 は並列実行可能（異なるファイル）

---

## Implementation Strategy

### MVP First（US1 のみ）

1. Phase 1: T001 — `.gitignore` 更新
2. Phase 2: T002 — `mkdocs.yml` 作成
3. Phase 3: T003 — ワークフロー更新（**これで HTML 変換・自動デプロイ・手動トリガーすべて実現**）
4. Phase 3: T004 — ローカルビルド確認
5. **STOP and VALIDATE**: `docs/` に変更を加えて push → Pages HTML 表示を確認
6. 完了: マークダウンが HTML として自動デプロイされる

### Incremental Delivery

1. T001 + T002 + T003 → MVP（HTML変換 + 自動デプロイ + 手動トリガーすべて含む）
2. T004〜T007 → 動作検証と設定確認
3. T008〜T009 → ドキュメント整備

---

## Notes

- T003 は US1・US2・US3 のすべてをカバーする単一ファイル更新
- MkDocs のナビゲーションは `mkdocs.yml` の `nav:` を省略することで `docs/` 構造から自動生成される
- ビルド成果物 `site/` は Git 管理外とする（T001 で `.gitignore` に追加）
- ワークフローは GitHub に push して初めて動作確認できる（ローカル実行不可）
- ローカルでの事前確認は `mkdocs build` コマンドで可能（quickstart.md 参照）
