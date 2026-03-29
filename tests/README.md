# Tests

## 必要条件

[bats-core](https://github.com/bats-core/bats-core) が必要です。

```bash
# macOS
brew install bats-core

# npm (全プラットフォーム)
npm install --save-dev bats

# または手動インストール
git clone https://github.com/bats-core/bats-core.git
./bats-core/install.sh /usr/local
```

## テスト実行

```bash
# 全テスト
bats tests/kanban-register/

# 個別ファイル
bats tests/kanban-register/test-register.bats
bats tests/kanban-register/test-sync.bats
```

## テスト構造

```text
tests/
└── kanban-register/
    ├── test-register.bats   # kanban-register.sh のテスト
    ├── test-sync.bats       # kanban-sync.sh のテスト
    └── fixtures/
        ├── sample-tasks.md              # テスト用 tasks.md
        └── kanban-list-response.json    # kanban API モックレスポンス
```
