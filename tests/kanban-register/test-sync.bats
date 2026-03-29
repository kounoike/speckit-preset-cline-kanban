#!/usr/bin/env bats
# test-sync.bats — kanban-sync.sh のテスト
# 実行: bats tests/kanban-register/test-sync.bats

SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/.specify/scripts/bash/kanban-sync.sh"
FIXTURES="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)/fixtures"
MOCK_LIST="${FIXTURES}/kanban-list-response.json"

# ────────────────────────────────────────────
# ヘルパー
# ────────────────────────────────────────────
setup_kanban_mock() {
  local mode="${1:-normal}"
  export PATH="${BATS_TEST_TMPDIR}/mock_bin:${PATH}"
  mkdir -p "${BATS_TEST_TMPDIR}/mock_bin"

  case "$mode" in
    normal)
      local mock_list="$2"
      cat > "${BATS_TEST_TMPDIR}/mock_bin/kanban" <<EOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "task" && "\${2:-}" == "list" ]]; then
  cat "${mock_list}"
  exit 0
fi
exit 1
EOF
      chmod +x "${BATS_TEST_TMPDIR}/mock_bin/kanban"
      ;;
  esac
}

make_temp_tasks() {
  local src="$1"
  local tmp="${BATS_TEST_TMPDIR}/tasks-copy.md"
  cp "$src" "$tmp"
  echo "$tmp"
}

# ────────────────────────────────────────────
# 双方向同期テスト (T029, T030)
# ────────────────────────────────────────────

@test "kanban 完了カードに対応する tasks.md チェックボックスが [x] に更新される" {
  setup_kanban_mock "normal" "$MOCK_LIST"
  local tasks_copy
  tasks_copy=$(make_temp_tasks "${FIXTURES}/sample-tasks.md")

  # 更新前: T011 は [x] でも [ ] でも OK（フィクスチャによる）
  run "$SCRIPT" "$tasks_copy"
  [ "$status" -eq 0 ]

  # MOCK_LIST には T011 が "completed" カラムにある
  # sample-tasks.md の T011 行が [x] になっているか確認
  grep -E '^\s*-\s*\[x\]\s+T011' "$tasks_copy"
}

@test "kanban 完了列のカードがない場合、synced が 0 で正常終了する" {
  local empty_list="${BATS_TEST_TMPDIR}/no-completed.json"
  echo '[{"id":"uuid-1","prompt":"[T001] test","column":"backlog"}]' > "$empty_list"
  setup_kanban_mock "normal" "$empty_list"

  local tasks_copy
  tasks_copy=$(make_temp_tasks "${FIXTURES}/sample-tasks.md")

  run "$SCRIPT" "$tasks_copy"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"synced":0'
}

@test "同期結果に synced フィールドが含まれる" {
  setup_kanban_mock "normal" "$MOCK_LIST"
  local tasks_copy
  tasks_copy=$(make_temp_tasks "${FIXTURES}/sample-tasks.md")

  run "$SCRIPT" "$tasks_copy"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"synced"'
}

@test "kanban コマンドが未インストールの場合、終了コード 1 でエラーを出力する" {
  # PATH から kanban を除外（モックを作らない）
  export PATH="${BATS_TEST_TMPDIR}/empty_bin:${PATH}"
  mkdir -p "${BATS_TEST_TMPDIR}/empty_bin"

  local tasks_copy
  tasks_copy=$(make_temp_tasks "${FIXTURES}/sample-tasks.md")

  run "$SCRIPT" "$tasks_copy"
  [ "$status" -eq 1 ]
  echo "$output" | grep -q '"status":"error"'
}

@test "引数なしで実行した場合、終了コード 1 で使用方法を出力する" {
  run "$SCRIPT"
  [ "$status" -eq 1 ]
}
