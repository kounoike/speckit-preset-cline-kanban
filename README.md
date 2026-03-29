# speckit-preset-cline-kanban

[![Deploy](https://github.com/kounoike/speckit-preset-cline-kanban/actions/workflows/deploy-pages.yml/badge.svg)](https://github.com/kounoike/speckit-preset-cline-kanban/actions/workflows/deploy-pages.yml)

SpecKit の `/speckit.tasks` コマンドでタスクを生成した際に、
[cline/kanban](https://github.com/cline/kanban) ボードへ自動登録する SpecKit preset。

## 機能

- `/speckit.tasks` 完了後に `tasks.md` の全タスクを kanban backlog に自動登録
- 再実行時は既存カードを上書き更新（重複作成なし）
- kanban 未起動時はフォールバックして `tasks.md` 生成を継続
- `kanban-sync.sh` で kanban の完了カードを `tasks.md` に反映

## 必要条件

- [cline/kanban](https://github.com/cline/kanban) (`npm i -g kanban`)
- Node.js 18+
- `jq`
- SpecKit 0.4.x+

## インストール

```bash
# スクリプトをコピー
cp .specify/scripts/bash/kanban-register.sh /your-project/.specify/scripts/bash/
cp .specify/scripts/bash/kanban-sync.sh /your-project/.specify/scripts/bash/
chmod +x /your-project/.specify/scripts/bash/kanban-*.sh

# extensions.yml をコピー
cp .specify/extensions.yml /your-project/.specify/extensions.yml
```

## 使い方

```bash
# 1. kanban サーバーを起動
kanban --no-open

# 2. SpecKit でタスク生成（自動登録される）
# /speckit.tasks を実行

# 3. kanban の完了状態を tasks.md に同期（オプション）
.specify/scripts/bash/kanban-sync.sh specs/001-xxx/tasks.md
```

## テスト

```bash
npm test
```

## ライセンス

ISC
