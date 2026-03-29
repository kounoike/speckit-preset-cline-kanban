#!/usr/bin/env bash
# kanban-register.sh — tasks.md のタスクを cline/kanban へ登録・更新するスクリプト
# Usage: kanban-register.sh <tasks_md_path>
# Exit code: 0 (success or skipped), 1 (partial failure)

set -euo pipefail

KANBAN_PORT="${KANBAN_PORT:-3484}"
KANBAN_HOST="${KANBAN_HOST:-localhost}"

# ────────────────────────────────────────────
# 使用方法
# ────────────────────────────────────────────
usage() {
  echo "Usage: $(basename "$0") <tasks_md_path>" >&2
  echo "  tasks_md_path: tasks.md ファイルへのパス" >&2
  exit 1
}

# ────────────────────────────────────────────
# kanban コマンド存在確認 (T008/T013)
# ────────────────────────────────────────────
check_kanban_command() {
  if ! command -v kanban &>/dev/null; then
    echo "WARNING: kanban コマンドが見つかりません。" >&2
    echo "         インストール方法: npm i -g kanban" >&2
    return 1
  fi
  return 0
}

# ────────────────────────────────────────────
# kanban サーバー疎通確認 (T009/T012)
# ────────────────────────────────────────────
check_kanban_server() {
  if ! kanban task list &>/dev/null 2>&1; then
    echo "WARNING: kanban サーバーに接続できません（ポート ${KANBAN_PORT}）。" >&2
    echo "         起動方法: kanban --no-open" >&2
    return 1
  fi
  return 0
}

# ────────────────────────────────────────────
# tasks.md パース関数 (T018)
# 出力: "TASK_ID\tTITLE" の形式で各行を echo
# ────────────────────────────────────────────
parse_tasks() {
  local tasks_file="$1"
  # 形式: - [ ] T001 [P] [US1] タイトル (未完了のみ)
  grep -E '^\s*-\s*\[\s\]\s+T[0-9]+' "$tasks_file" | \
    sed -E 's/^\s*-\s*\[\s\]\s+(T[0-9]+)\s+(.*)/\1\t\2/'
}

# ────────────────────────────────────────────
# [Txxx] 接頭辞で既存カードを検索 (T025)
# 引数: task_id (例: T001), kanban_list_json
# 出力: 見つかった場合は UUID を echo、見つからなければ空文字
# ────────────────────────────────────────────
find_existing_card() {
  local task_id="$1"
  local list_json="$2"
  echo "$list_json" | jq -r \
    --arg prefix "[${task_id}]" \
    '.[] | select(.prompt | startswith($prefix)) | .id' 2>/dev/null | head -1
}

# ────────────────────────────────────────────
# メイン処理
# ────────────────────────────────────────────
main() {
  # 引数検証
  if [[ $# -lt 1 ]]; then
    usage
  fi

  local tasks_file="$1"

  if [[ ! -f "$tasks_file" ]]; then
    echo "ERROR: tasks.md が見つかりません: $tasks_file" >&2
    exit 1
  fi

  local created=0
  local updated=0
  local failed=0
  local errors=()

  # kanban コマンド確認 (T013)
  if ! check_kanban_command; then
    echo '{"status":"skipped","created":0,"updated":0,"skipped":1,"failed":0,"errors":["kanban command not found"]}'
    exit 0
  fi

  # サーバー疎通確認 (T012)
  if ! check_kanban_server; then
    echo '{"status":"skipped","created":0,"updated":0,"skipped":1,"failed":0,"errors":["kanban server not running"]}'
    exit 0
  fi

  # 既存カード一覧を取得 (T019)
  local existing_cards
  if ! existing_cards=$(kanban task list 2>/dev/null); then
    echo "WARNING: kanban task list に失敗しました。" >&2
    echo '{"status":"skipped","created":0,"updated":0,"skipped":1,"failed":0,"errors":["kanban task list failed"]}'
    exit 0
  fi

  # tasks.md をパースして各タスクを登録 (T020)
  while IFS=$'\t' read -r task_id task_title; do
    [[ -z "$task_id" ]] && continue

    local prompt="[${task_id}] ${task_title}"
    local existing_id
    existing_id=$(find_existing_card "$task_id" "$existing_cards")

    if [[ -n "$existing_id" ]]; then
      # 既存カードを上書き更新 (T026)
      if kanban task update --task-id "$existing_id" --prompt "$prompt" &>/dev/null; then
        updated=$((updated + 1))
      else
        failed=$((failed + 1))
        errors+=("Failed to update ${task_id} (id: ${existing_id})")
      fi
    else
      # 新規カードを作成 (T020)
      if kanban task create --prompt "$prompt" &>/dev/null; then
        created=$((created + 1))
      else
        failed=$((failed + 1))
        errors+=("Failed to create ${task_id}")
      fi
    fi
  done < <(parse_tasks "$tasks_file")

  # 結果出力 (T021/T027)
  local status="success"
  [[ $failed -gt 0 ]] && status="partial"

  local errors_json
  errors_json=$(printf '%s\n' "${errors[@]+"${errors[@]}"}" | jq -R . | jq -s .)

  echo "{\"status\":\"${status}\",\"created\":${created},\"updated\":${updated},\"skipped\":0,\"failed\":${failed},\"errors\":${errors_json}}"

  if [[ $created -gt 0 || $updated -gt 0 ]]; then
    echo "✅ kanban 登録完了: 作成 ${created}件 / 更新 ${updated}件 / 失敗 ${failed}件" >&2
  fi

  [[ $failed -gt 0 ]] && exit 1
  exit 0
}

# source されたときは main を実行しない（テスト用）
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
