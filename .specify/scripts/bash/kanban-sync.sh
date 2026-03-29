#!/usr/bin/env bash
# kanban-sync.sh — cline/kanban の完了カードを tasks.md のチェックボックスに反映するスクリプト
# Usage: kanban-sync.sh <tasks_md_path>
# Exit code: 0 (success), 1 (error)

set -euo pipefail

KANBAN_PORT="${KANBAN_PORT:-3484}"
KANBAN_HOST="${KANBAN_HOST:-localhost}"

# ────────────────────────────────────────────
# 引数検証
# ────────────────────────────────────────────
usage() {
  echo "Usage: $(basename "$0") <tasks_md_path>" >&2
  echo "  tasks_md_path: 更新対象の tasks.md ファイルへのパス" >&2
  exit 1
}

if [[ $# -lt 1 ]]; then
  usage
fi

TASKS_FILE="$1"

if [[ ! -f "$TASKS_FILE" ]]; then
  echo "ERROR: tasks.md が見つかりません: $TASKS_FILE" >&2
  exit 1
fi

# ────────────────────────────────────────────
# kanban コマンド存在確認
# ────────────────────────────────────────────
check_kanban_command() {
  if ! command -v kanban &>/dev/null; then
    echo "WARNING: kanban コマンドが見つかりません。" >&2
    return 1
  fi
  return 0
}

# ────────────────────────────────────────────
# メイン処理
# ────────────────────────────────────────────
main() {
  local synced=0
  local errors=()

  if ! check_kanban_command; then
    echo '{"status":"error","synced":0,"errors":["kanban command not found"]}'
    exit 1
  fi

  # kanban の全カードを取得 (T031)
  local all_cards
  if ! all_cards=$(kanban task list 2>/dev/null); then
    echo "ERROR: kanban task list に失敗しました。" >&2
    echo '{"status":"error","synced":0,"errors":["kanban task list failed"]}'
    exit 1
  fi

  # 完了列のカードから SpecKit タスクIDを抽出 (T031)
  # "completed" カラムにあるカードのみ対象
  # kanban の完了カラム名は "completed" と仮定（環境依存の場合は設定可能にする）
  local completed_task_ids
  completed_task_ids=$(echo "$all_cards" | jq -r \
    '.[] | select(.column == "completed") | .prompt' 2>/dev/null | \
    grep -oE '\[T[0-9]+\]' | tr -d '[]' || true)

  if [[ -z "$completed_task_ids" ]]; then
    echo '{"status":"success","synced":0,"errors":[]}'
    echo "ℹ️  同期対象のカードがありません（完了列が空）" >&2
    exit 0
  fi

  # tasks.md のチェックボックスを更新 (T032)
  local tmp_file
  tmp_file=$(mktemp)
  cp "$TASKS_FILE" "$tmp_file"

  while IFS= read -r task_id; do
    [[ -z "$task_id" ]] && continue
    # "- [ ] T001 ..." を "- [x] T001 ..." に置換
    if sed -i.bak -E "s/^(\s*-\s*)\[ \](\s+${task_id}\s)/\1[x]\2/" "$tmp_file" 2>/dev/null; then
      # 変更が実際に行われたか確認
      if ! diff -q "$tmp_file" "${tmp_file}.bak" &>/dev/null; then
        synced=$((synced + 1))
      fi
      rm -f "${tmp_file}.bak"
    else
      errors+=("Failed to update ${task_id} in tasks.md")
    fi
  done <<< "$completed_task_ids"

  # 変更を元のファイルに反映 (T032)
  if [[ $synced -gt 0 ]]; then
    mv "$tmp_file" "$TASKS_FILE"
  else
    rm -f "$tmp_file"
  fi

  # 結果出力 (T033)
  local errors_json
  errors_json=$(printf '%s\n' "${errors[@]+"${errors[@]}"}" | jq -R . | jq -s .)

  local status="success"
  [[ ${#errors[@]} -gt 0 ]] && status="error"

  echo "{\"status\":\"${status}\",\"synced\":${synced},\"errors\":${errors_json}}"

  if [[ $synced -gt 0 ]]; then
    echo "✅ kanban 同期完了: ${synced}件のタスクを完了に更新しました" >&2
  fi

  exit 0
}

main "$@"
