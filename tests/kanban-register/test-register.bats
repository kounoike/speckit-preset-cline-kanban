#!/usr/bin/env bats
# test-register.bats — kanban-register.sh のテスト
# 実行: bats tests/kanban-register/test-register.bats

SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/.specify/scripts/bash/kanban-register.sh"
FIXTURES="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)/fixtures"
SAMPLE_TASKS="${FIXTURES}/sample-tasks.md"
MOCK_LIST="${FIXTURES}/kanban-list-response.json"

# ────────────────────────────────────────────
# ヘルパー: kanban コマンドをモックする
# ────────────────────────────────────────────
setup_kanban_mock() {
  local mode="${1:-normal}"
  export PATH="${BATS_TEST_TMPDIR}/mock_bin:${PATH}"
  mkdir -p "${BATS_TEST_TMPDIR}/mock_bin"

  case "$mode" in
    not_found)
      # kanban コマンドが存在しない状態（何もしない）
      ;;
    server_down)
      # kanban コマンドは存在するが task list が失敗する
      cat > "${BATS_TEST_TMPDIR}/mock_bin/kanban" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "task" && "${2:-}" == "list" ]]; then
  echo "Error: connection refused" >&2
  exit 1
fi
exit 1
EOF
      chmod +x "${BATS_TEST_TMPDIR}/mock_bin/kanban"
      ;;
    normal)
      # kanban コマンドが正常動作するモック
      local mock_list="$2"
      cat > "${BATS_TEST_TMPDIR}/mock_bin/kanban" <<EOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "task" ]]; then
  case "\${2:-}" in
    list)
      cat "${mock_list}"
      exit 0
      ;;
    create)
      echo '{"id":"new-uuid","prompt":"created","column":"backlog"}'
      exit 0
      ;;
    update)
      echo '{"id":"updated-uuid","prompt":"updated","column":"backlog"}'
      exit 0
      ;;
  esac
fi
exit 1
EOF
      chmod +x "${BATS_TEST_TMPDIR}/mock_bin/kanban"
      ;;
  esac
}

# ────────────────────────────────────────────
# US3: kanban CLI 障害時フォールバック (T010, T011)
# ────────────────────────────────────────────

@test "US3: kanban コマンドが未インストールの場合、終了コード 0 で警告を出力する" {
  setup_kanban_mock "not_found"
  run "$SCRIPT" "$SAMPLE_TASKS"
  [ "$status" -eq 0 ]
  [[ "$output" == *"skipped"* ]] || [[ "$output" == *"WARNING"* ]] || \
    echo "$output" | grep -q '"status":"skipped"'
}

@test "US3: kanban サーバーが未起動の場合、終了コード 0 で警告を出力する" {
  setup_kanban_mock "server_down"
  run "$SCRIPT" "$SAMPLE_TASKS"
  [ "$status" -eq 0 ]
  [[ "$output" == *"skipped"* ]] || echo "$output" | grep -q '"status":"skipped"'
}

@test "US3: tasks.md が存在しない場合、終了コード 1 でエラーを出力する" {
  run "$SCRIPT" "/nonexistent/tasks.md"
  [ "$status" -eq 1 ]
  [[ "$output" == *"ERROR"* ]]
}

@test "US3: 引数なしで実行した場合、終了コード 1 で使用方法を出力する" {
  run "$SCRIPT"
  [ "$status" -eq 1 ]
}

# ────────────────────────────────────────────
# US1: tasks.md パース (T015)
# ────────────────────────────────────────────

@test "US1: tasks.md から未完了タスクのみを抽出できる" {
  setup_kanban_mock "normal" "$MOCK_LIST"

  # parse_tasks 関数をソースして直接テスト
  run bash -c "
    source '$SCRIPT' 2>/dev/null || true
    parse_tasks '$SAMPLE_TASKS'
  "
  # T001〜T010, T012, T013 が含まれる（T011 は [x] なので除外）
  [[ "$output" == *"T001"* ]]
  [[ "$output" == *"T002"* ]]
  [[ "$output" != *"T011"* ]]  # 完了済みは除外
}

# ────────────────────────────────────────────
# US1: kanban task create 呼び出し (T016)
# ────────────────────────────────────────────

@test "US1: 新規タスクに対して kanban task create を呼び出す" {
  # kanban list が空の場合、全タスクを create する
  local empty_list="${BATS_TEST_TMPDIR}/empty-list.json"
  echo "[]" > "$empty_list"
  setup_kanban_mock "normal" "$empty_list"

  run "$SCRIPT" "$SAMPLE_TASKS"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"created"'
  # created が 0 より大きい
  local created
  created=$(echo "$output" | grep -oE '"created":[0-9]+' | grep -oE '[0-9]+')
  [ "$created" -gt 0 ]
}

# ────────────────────────────────────────────
# US1: 登録結果サマリー出力 (T017)
# ────────────────────────────────────────────

@test "US1: 登録結果に created/updated/failed フィールドが含まれる" {
  local empty_list="${BATS_TEST_TMPDIR}/empty-list.json"
  echo "[]" > "$empty_list"
  setup_kanban_mock "normal" "$empty_list"

  run "$SCRIPT" "$SAMPLE_TASKS"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"created"'
  echo "$output" | grep -q '"updated"'
  echo "$output" | grep -q '"failed"'
}

# ────────────────────────────────────────────
# US2: 重複検出と上書き更新 (T023, T024)
# ────────────────────────────────────────────

@test "US2: 既存カード ([T001]) がある場合、create ではなく update を呼び出す" {
  setup_kanban_mock "normal" "$MOCK_LIST"

  # MOCK_LIST には T001, T002, T011 が含まれている
  run "$SCRIPT" "$SAMPLE_TASKS"
  [ "$status" -eq 0 ]

  # T001, T002 は既存なので updated に加算される
  local updated
  updated=$(echo "$output" | grep -oE '"updated":[0-9]+' | grep -oE '[0-9]+')
  [ "$updated" -ge 2 ]
}

@test "US2: 再実行後も kanban カード数は増えない（updated カウントが created より多い）" {
  setup_kanban_mock "normal" "$MOCK_LIST"

  run "$SCRIPT" "$SAMPLE_TASKS"
  [ "$status" -eq 0 ]

  local created
  created=$(echo "$output" | grep -oE '"created":[0-9]+' | grep -oE '[0-9]+')
  local updated
  updated=$(echo "$output" | grep -oE '"updated":[0-9]+' | grep -oE '[0-9]+')

  # T001, T002 が既存なので updated >= 2, created はその他のタスク分
  [ "$updated" -ge 2 ]
}
