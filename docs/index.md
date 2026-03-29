# SpecKit Preset Catalog

このリポジトリは SpecKit preset のカタログです。

## 利用可能な Preset

### cline-kanban

**説明**: SpecKit の `/speckit.tasks` コマンドでタスクを生成した際に、
自動的に [cline/kanban](https://github.com/cline/kanban) ボードへカードを登録する preset。

**バージョン**: 1.0.0

**必要条件**:
- [cline/kanban](https://github.com/cline/kanban) (`npm i -g kanban`)
- Node.js 18+
- `jq` (JSON処理)

**機能**:
- `/speckit.tasks` 完了後に tasks.md の全タスクを kanban backlog に自動登録
- 再実行時は既存カードを上書き更新（重複作成なし）
- kanban 未起動時はフォールバックして tasks.md 生成を継続
- `/speckit.sync` コマンドで kanban の完了カードを tasks.md に反映

**インストール**:

```bash
# 1. このリポジトリから extensions.yml をコピー
curl -o .specify/extensions.yml \
  https://raw.githubusercontent.com/kounoike/speckit-preset-cline-kanban/main/.specify/extensions.yml

# 2. スクリプトをコピー
curl -o .specify/scripts/bash/kanban-register.sh \
  https://raw.githubusercontent.com/kounoike/speckit-preset-cline-kanban/main/.specify/scripts/bash/kanban-register.sh
curl -o .specify/scripts/bash/kanban-sync.sh \
  https://raw.githubusercontent.com/kounoike/speckit-preset-cline-kanban/main/.specify/scripts/bash/kanban-sync.sh

# 3. 実行権限を付与
chmod +x .specify/scripts/bash/kanban-register.sh
chmod +x .specify/scripts/bash/kanban-sync.sh
```

**使い方**:

```bash
# 1. kanban サーバーを起動
kanban --no-open

# 2. SpecKit でタスクを生成 (自動登録される)
# /speckit.tasks を実行

# 3. (オプション) kanban の完了状態を tasks.md に同期
.specify/scripts/bash/kanban-sync.sh specs/001-xxx/tasks.md
```

**ソースコード**: [github.com/kounoike/speckit-preset-cline-kanban](https://github.com/kounoike/speckit-preset-cline-kanban)
