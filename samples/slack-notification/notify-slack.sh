#!/bin/bash
# Claude Code 작업 완료 Slack 알림 (with summary)
# Stop 이벤트 시 stdin으로 JSON 데이터가 전달됨
#
# stdin JSON fields:
#   session_id, cwd, hook_event_name, stop_hook_active,
#   last_assistant_message, transcript_path
#
# 환경변수:
#   CLAUDE_SLACK_WEBHOOK_URL - Slack Incoming Webhook URL (필수)

set -euo pipefail

# ── 설정 ──────────────────────────────────────────────
WEBHOOK_URL="${CLAUDE_SLACK_WEBHOOK_URL:-}"
DEBUG_LOG="${SLACK_HOOK_DEBUG_LOG:-$HOME/.claude/hooks/debug-slack.log}"
MAX_SUMMARY_CHARS=500
MAX_LOG_BYTES=10240  # 10KB

# UTF-8 로케일 강제 (cut -c 문자 단위 동작 보장)
export LC_ALL=en_US.UTF-8

# ── 유틸리티 함수 ─────────────────────────────────────
log() {
  mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null || true
  printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*" >> "$DEBUG_LOG"
}

rotate_log() {
  if [ -f "$DEBUG_LOG" ] && [ "$(wc -c < "$DEBUG_LOG" 2>/dev/null || echo 0)" -gt "$MAX_LOG_BYTES" ]; then
    local tmp
    tmp=$(mktemp "${DEBUG_LOG}.XXXXXX") || return 0
    tail -c "$MAX_LOG_BYTES" "$DEBUG_LOG" > "$tmp" && mv "$tmp" "$DEBUG_LOG" || rm -f "$tmp"
  fi
}

# Slack payload 전송 (공통)
send_slack() {
  local payload="$1"
  local response http_code body

  response=$(curl -s -w "\n%{http_code}" -X POST "$WEBHOOK_URL" \
    -H 'Content-type: application/json; charset=utf-8' \
    -d "$payload" 2>>"$DEBUG_LOG")

  http_code=$(printf '%s' "$response" | tail -1)
  body=$(printf '%s' "$response" | sed '$d')
  log "HTTP: $http_code | Response: $body"

  if [ "$http_code" != "200" ]; then
    log "ERROR: Slack API returned $http_code"
    return 1
  fi
  return 0
}

# ── 전제 조건 확인 ────────────────────────────────────
# Webhook URL 없으면 조용히 종료
if [ -z "$WEBHOOK_URL" ]; then
  echo "[notify-slack] CLAUDE_SLACK_WEBHOOK_URL 가 설정되지 않았습니다." >&2
  exit 0
fi

# jq 필수
if ! command -v jq &>/dev/null; then
  echo "[notify-slack] jq not found, skipping" >&2
  exit 0
fi

# ── 디버그 로그 초기화 ────────────────────────────────
rotate_log
log "=== Stop hook triggered ==="

# ── stdin → tmpfile (셸 변수 제한 회피) ───────────────
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT
cat > "$TMPFILE"

STDIN_SIZE=$(wc -c < "$TMPFILE")
log "stdin size: ${STDIN_SIZE} bytes"

# stdin이 비어있으면 기본 알림 발송
if [ "$STDIN_SIZE" -eq 0 ]; then
  log "WARN: empty stdin, sending basic notification"
  PAYLOAD=$(jq -n --arg ts "$(date '+%Y-%m-%d %H:%M:%S')" '{
    blocks: [{
      type: "section",
      text: { type: "mrkdwn", text: (":white_check_mark: *Claude Code 작업 완료*\n:clock3: " + $ts) }
    }]
  }')
  send_slack "$PAYLOAD"
  exit 0
fi

# ── JSON 파싱 ─────────────────────────────────────────
if ! jq empty < "$TMPFILE" 2>>"$DEBUG_LOG"; then
  log "ERROR: invalid JSON in stdin"
  PAYLOAD=$(jq -n --arg ts "$(date '+%Y-%m-%d %H:%M:%S')" '{
    blocks: [{
      type: "section",
      text: { type: "mrkdwn", text: (":warning: *Claude Code 작업 완료* (요약 파싱 실패)\n:clock3: " + $ts) }
    }]
  }')
  send_slack "$PAYLOAD"
  exit 0
fi

# stop_hook_active 체크 — 무한루프 방지
STOP_ACTIVE=$(jq -r '.stop_hook_active // false' < "$TMPFILE" 2>>"$DEBUG_LOG")
if [ "$STOP_ACTIVE" = "true" ]; then
  log "stop_hook_active=true, skipping"
  exit 0
fi

# 프로젝트명 추출
PROJECT_DIR=$(jq -r '.cwd // empty' < "$TMPFILE" 2>/dev/null)
if [ -z "$PROJECT_DIR" ]; then
  PROJECT_DIR=$(pwd)
fi
PROJECT_NAME=$(basename "$PROJECT_DIR" 2>/dev/null || echo "unknown")

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
log "project: $PROJECT_NAME"

# ── last_assistant_message 추출 및 가공 ───────────────
RAW_MSG=$(jq -r '.last_assistant_message // empty' < "$TMPFILE" 2>>"$DEBUG_LOG")
RAW_MSG_LEN=${#RAW_MSG}
log "last_assistant_message length: $RAW_MSG_LEN chars"

if [ -n "$RAW_MSG" ]; then
  SUMMARY=$(printf '%s' "$RAW_MSG" | cut -c "1-${MAX_SUMMARY_CHARS}")
  ELLIPSIS=""
  if [ "$RAW_MSG_LEN" -gt "$MAX_SUMMARY_CHARS" ]; then
    ELLIPSIS="..."
  fi

  PAYLOAD=$(jq -n \
    --arg project "$PROJECT_NAME" \
    --arg timestamp "$TIMESTAMP" \
    --arg summary "$SUMMARY" \
    --arg ellipsis "$ELLIPSIS" \
    '
    def slack_safe:
      gsub("```[\\s\\S]*?```"; "[code]")
      | gsub("```[\\s\\S]*$"; "[code...]")
      | gsub("&"; "&amp;")
      | gsub("<"; "&lt;")
      | gsub(">"; "&gt;");

    ($summary + $ellipsis) | slack_safe | . as $safe_summary |
    {
      blocks: [
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: (":white_check_mark: *Claude Code 작업 완료*\n:file_folder: 프로젝트: `" + $project + "`\n:clock3: " + $timestamp)
          }
        },
        { type: "divider" },
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: (":memo: *요약*\n" + $safe_summary)
          }
        }
      ]
    }')

  if [ $? -ne 0 ] || [ -z "$PAYLOAD" ]; then
    log "WARN: jq payload construction failed, falling back to basic notification"
    PAYLOAD=$(jq -n \
      --arg project "$PROJECT_NAME" \
      --arg timestamp "$TIMESTAMP" \
      '{
        blocks: [{
          type: "section",
          text: {
            type: "mrkdwn",
            text: (":white_check_mark: *Claude Code 작업 완료*\n:file_folder: 프로젝트: `" + $project + "`\n:clock3: " + $timestamp)
          }
        }]
      }')
  fi
else
  log "last_assistant_message is empty, sending without summary"
  PAYLOAD=$(jq -n \
    --arg project "$PROJECT_NAME" \
    --arg timestamp "$TIMESTAMP" \
    '{
      blocks: [{
        type: "section",
        text: {
          type: "mrkdwn",
          text: (":white_check_mark: *Claude Code 작업 완료*\n:file_folder: 프로젝트: `" + $project + "`\n:clock3: " + $timestamp)
        }
      }]
    }')
fi

PAYLOAD_SIZE=${#PAYLOAD}
log "payload size: $PAYLOAD_SIZE chars"

# ── Slack 전송 ────────────────────────────────────────
send_slack "$PAYLOAD"

log "=== done ==="
exit 0
