# Implementation Plan: タスク生成時のkanban CLI自動登録

**Branch**: `001-tasks-kanban-register` | **Date**: 2026-03-29 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-tasks-kanban-register/spec.md`

## Summary

SpecKit の `/speckit.tasks` コマンド完了後に `after_tasks` フックで自動起動し、
生成された `tasks.md` のタスクを `cline/kanban` CLI（npm package `kanban`）を通じて
kanban ボードの backlog カラムに登録するシェルスクリプト preset を構築する。
重複タスクは上書き更新（kanban task update）、kanban 未起動時はフォールバックで警告のみ。
kanban ボード → tasks.md の逆方向同期は専用コマンド `/speckit.sync` で手動実行する。

## Technical Context

**Language/Version**: Bash (sh互換、macOS/Linux対応)
**Primary Dependencies**: `kanban` npm package (cline/kanban)、`jq` (JSON処理)
**Storage**: N/A（kanban サーバーが状態を管理、tasks.md はファイル上書き）
**Testing**: bats-core（Bash Automated Testing System）
**Target Platform**: macOS / Linux（Node.js 18+ 環境）
**Project Type**: SpecKit preset（シェルスクリプト + YAML設定）
**Performance Goals**: `/speckit.tasks` 完了後60秒以内に全タスクを kanban に登録（SC-001）
**Constraints**: kanban サーバー未起動でも tasks.md 生成を妨げない（FR-005）
**Scale/Scope**: 1 プロジェクトあたり最大数十件のタスク（通常10〜30件）

## Constitution Check

*GATE: Phase 0 リサーチ前に確認。Phase 1 設計後に再確認。*

| 原則 | 状態 | 備考 |
|------|------|------|
| I. 仕様駆動開発 | ✅ PASS | spec.md 承認済み、clarify 完了 |
| II. ユーザーストーリー中心 | ✅ PASS | 全実装 US1〜US3 にトレース可能 |
| III. テストファースト | ✅ PASS | テストを先に実装してから本体コードを書く |
| IV. 段階的デリバリー | ✅ PASS | P1 → P2 → P3 順で独立デリバリー可能 |
| V. シンプルさ (YAGNI) | ✅ PASS | Bash + jq のみ。汎用化なし（cline/kanban 専用） |

**Phase 1 設計後再確認**: 外部マッピングファイル不要（prompt 接頭辞方式）→ シンプルさ原則違反なし ✅

## Project Structure

### Documentation (this feature)

```text
specs/001-tasks-kanban-register/
├── plan.md              # このファイル
├── research.md          # Phase 0 リサーチ結果
├── data-model.md        # Phase 1 データモデル
├── quickstart.md        # Phase 1 クイックスタートガイド
├── contracts/
│   └── extensions-yml.md  # インターフェースコントラクト
├── checklists/
│   └── requirements.md  # 仕様品質チェックリスト
└── tasks.md             # Phase 2 出力（/speckit.tasks で生成）
```

### Source Code (repository root)

```text
.specify/
├── extensions.yml                  # after_tasks フック設定
└── scripts/
    └── bash/
        ├── kanban-register.sh      # tasks.md → kanban 登録スクリプト (US1/US2/US3)
        └── kanban-sync.sh          # kanban → tasks.md 同期スクリプト (US1双方向)

docs/                               # GitHub Pages (preset catalog)
└── index.md                        # preset カタログエントリ

tests/
└── kanban-register/
    ├── test-register.bats          # kanban-register.sh のテスト (US1/US3)
    ├── test-sync.bats              # kanban-sync.sh のテスト (US2)
    └── fixtures/
        ├── sample-tasks.md         # テスト用 tasks.md サンプル
        └── kanban-list-response.json  # kanban API モックレスポンス
```

**Structure Decision**: SpecKit preset の単一プロジェクト構造。
`.specify/scripts/bash/` は既存の bash スクリプト群と同じ場所に配置。
`docs/` は GitHub Pages の preset catalog 用。

## Complexity Tracking

> **Constitution Check 違反はなし。このセクションへの記載不要。**

## Implementation Phases

### Phase 1: Setup

- プロジェクト構造の作成（ディレクトリ、空ファイル）
- bats-core のセットアップ

### Phase 2: US3 - kanban CLI 障害時フォールバック（P3）

**先にテストを作成してから実装**

1. `kanban-register.sh` の骨格（引数検証、サーバー疎通確認）
2. サーバー未起動時に warning を出して終了コード 0 で返す処理

### Phase 3: US1 - タスク登録（P1）

**先にテストを作成してから実装**

1. tasks.md パース（正規表現）
2. `kanban task list` で既存カード取得・照合
3. 新規タスク: `kanban task create --prompt "[Txxx] タイトル"`
4. 登録結果の表示（作成件数等）

### Phase 4: US2 - 重複上書き更新（P2）

**先にテストを作成してから実装**

1. 既存カード検出時: `kanban task update --task-id <uuid> --prompt "..."`
2. 更新件数のログ出力

### Phase 5: 双方向同期（kanban → tasks.md）

**先にテストを作成してから実装**

1. `kanban-sync.sh` の実装
2. 完了カラムのカードを抽出してチェックボックス更新

### Phase 6: GitHub Pages catalog & extensions.yml

1. `extensions.yml` の作成（after_tasks フック設定）
2. `docs/index.md` の preset catalog エントリ
3. quickstart.md の整備

### Phase 7: Polish

1. ドキュメント更新
2. エラーメッセージの整備
3. quickstart.md の動作確認
