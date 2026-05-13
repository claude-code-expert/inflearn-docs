#!/bin/bash
# notify-slack.sh 동작 테스트 러너
#
# 사용법:
#   ./run-test.sh                # test-payload.json 으로 1회 발송
#   ./run-test.sh empty          # 빈 stdin 케이스 검증
#   ./run-test.sh invalid        # 잘못된 JSON 케이스 검증
#
# 전제:
#   1) ~/.zshrc 에 CLAUDE_SLACK_WEBHOOK_URL 가 export 되어 있어야 함
#   2) jq, curl 이 설치되어 있어야 함

set -euo pipefail

cd "$(dirname "$0")"

if [ -z "${CLAUDE_SLACK_WEBHOOK_URL:-}" ]; then
  echo "[run-test] CLAUDE_SLACK_WEBHOOK_URL 미설정 — ~/.zshrc 를 source 하거나 export 후 다시 실행하세요." >&2
  exit 1
fi

MODE="${1:-normal}"
LOG_PATH="$(pwd)/debug-slack.log"
export SLACK_HOOK_DEBUG_LOG="$LOG_PATH"

echo "[run-test] mode=$MODE log=$LOG_PATH"

case "$MODE" in
  normal)
    bash ./notify-slack.sh < ./test-payload.json
    ;;
  empty)
    : | bash ./notify-slack.sh
    ;;
  invalid)
    printf 'not a json' | bash ./notify-slack.sh
    ;;
  *)
    echo "Unknown mode: $MODE" >&2
    exit 2
    ;;
esac

echo "[run-test] done — Slack 채널과 $LOG_PATH 를 확인하세요."
