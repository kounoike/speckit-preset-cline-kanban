# Feature Specification: docs/ マークダウンを HTML にビルドして GitHub Pages にデプロイする

**Feature Branch**: `004-docs-build-html`
**Created**: 2026-03-29
**Status**: Draft
**Input**: User description: "docs/ディレクトリの内容がマークダウンなのでhtmlになるようレンダリングする必要がある。actionsでビルドする方式に変更する"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - マークダウンが HTML としてブラウザで閲覧できる (Priority: P1)

`docs/` ディレクトリ内のマークダウンファイルが GitHub Actions のビルドステップで HTML に変換され、GitHub Pages サイトとして正しくレンダリングされる。閲覧者はブラウザで整形された HTML ページを確認できる。

**Why this priority**: 現状マークダウンをそのまま Pages に配信しており、ブラウザでは生テキストとして表示されてしまう。HTML 変換はこのフィーチャーの根幹であり、これがなければ他の改善も意味をなさない。

**Independent Test**: `docs/index.md` を変更して main に push し、GitHub Pages サイトをブラウザで開いたとき、マークダウン記法が HTML として整形表示されることを確認する（見出し・リスト・リンクが正しく描画される）。

**Acceptance Scenarios**:

1. **Given** `docs/index.md` に見出し・リスト・リンクを含むマークダウンがある, **When** main に push してビルドが完了する, **Then** GitHub Pages サイトでブラウザが HTML として整形表示する
2. **Given** `docs/` に複数のマークダウンファイルがある, **When** ビルドが実行される, **Then** すべてのファイルが対応する HTML ファイルに変換される
3. **Given** マークダウンに内部リンク（別の `.md` ファイルへの参照）がある, **When** ビルドが完了する, **Then** リンクが正しく HTML ページ間のリンクに変換される

---

### User Story 2 - docs/ 変更時に自動ビルド＆デプロイが実行される (Priority: P2)

`docs/` ディレクトリを変更して main にプッシュすると、GitHub Actions が自動でビルド（マークダウン→HTML変換）を実行し、生成した HTML を GitHub Pages にデプロイする。手動操作は不要。

**Why this priority**: 自動化により、ドキュメント更新のたびに手動ビルドする手間をなくす。US1（HTML表示）の前提として自動化フローが必要。

**Independent Test**: `docs/` に変更を加えて push し、5分以内に GitHub Pages サイトが更新されることを確認する。Actions タブでビルドジョブの実行履歴を確認する。

**Acceptance Scenarios**:

1. **Given** `docs/` 内のファイルを変更した, **When** main ブランチに push する, **Then** ビルドジョブが自動起動し HTML に変換後 Pages にデプロイされる
2. **Given** `docs/` 以外のファイルのみを変更した, **When** main ブランチに push する, **Then** ビルドジョブは実行されない

---

### User Story 3 - 手動デプロイトリガー (Priority: P3)

ドキュメント内容に変更がなくても、GitHub Actions の UI から手動でビルド＆デプロイを実行できる。

**Why this priority**: ビルド設定の変更後や障害復旧時に強制再デプロイが必要なケースに対応する。

**Independent Test**: Actions タブの「Run workflow」ボタンをクリックし、ビルドが実行されて Pages が更新されることを確認する。

**Acceptance Scenarios**:

1. **Given** GitHub Actions タブを開いた, **When** 「Run workflow」をクリックして実行する, **Then** ビルドジョブが起動し docs/ の現在の内容が HTML に変換されて Pages に公開される

---

### Edge Cases

- `docs/` ディレクトリが空またはマークダウンファイルがない場合、ビルドはエラー終了する（CI ステータスが赤になる）
- マークダウンの構文エラーがある場合も可能な限りビルドを継続し、エラー箇所はそのまま変換する（ビルド自体は成功扱い）
- 複数の push が短時間に重なった場合、最新の push によるビルドが優先され古いビルドはキャンセルされる
- 画像や添付ファイル等の非マークダウンアセットは HTML 変換されずそのまま出力に含まれる

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `docs/` 変更を含む main への push 時、自動的にビルドジョブが起動する
- **FR-002**: ビルドジョブはマークダウンファイルを HTML に変換する
- **FR-002a**: 変換された HTML サイトには全ページへのナビゲーション（ヘッダー/サイドバー）が自動生成される
- **FR-003**: 変換された HTML が GitHub Pages として公開される
- **FR-004**: 手動トリガーでいつでもビルド＆デプロイを実行できる
- **FR-005**: ビルド失敗時は CI ステータスに赤バツが表示され、エラー内容を確認できる
- **FR-006**: 複数の同時実行を防ぎ、最新のビルドが優先される

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `docs/` 変更の push から5分以内に GitHub Pages の HTML ページが更新される
- **SC-002**: ブラウザで GitHub Pages サイトを開いたとき、マークダウンが HTML として整形表示される（生テキストではない）
- **SC-003**: `docs/` 以外の変更ではビルドジョブが起動しない（不要なデプロイが0回）
- **SC-004**: ビルド成否が GitHub CI ステータスとして確認できる

## Clarifications

### Session 2026-03-29

- Q: 生成サイトのナビゲーション構造（フラット HTML のみ vs 自動ナビゲーション付き vs 手動管理） → A: 自動ナビゲーション付き（全ページへのリンクをヘッダー/サイドバーに自動生成）
- Q: `docs/` にマークダウンファイルが1件もない場合の動作（ビルド失敗 vs 警告してスキップ） → A: ビルド失敗（エラー終了）

## Assumptions

- マークダウンから HTML への変換は静的サイトジェネレーターまたは単純な変換ツールを使用する（具体的なツール選定はプランニングフェーズで決定）
- 現在の `docs/index.md` が変換の入力ファイルとなり、`index.html` として出力される
- カスタムデザイン（CSS テーマ）はデフォルトのものを使用し、ブランディング要件は本フィーチャーのスコープ外とする
- GitHub リポジトリの Settings > Pages > Source はすでに「GitHub Actions」に設定済みである
