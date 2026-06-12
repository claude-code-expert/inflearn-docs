#!/bin/bash
# handoff 추출/작성 로직 검증 러너
#
# 사용법:
#   ./run-test.sh                  # pre-compact 시나리오
#   ./run-test.sh end              # session-end (clear) 시나리오
#   ./run-test.sh restore          # session-restore.sh 출력 확인 (compact source)
#
# 본인의 ~/.claude/handoff/ 는 건드리지 않도록
# HOME 을 ./out/ 으로 격리해서 실행합니다.

set -euo pipefail

cd "$(dirname "$0")"
OUT_DIR="$(pwd)/out"
mkdir -p "$OUT_DIR/.claude/handoff"

MODE="${1:-pre}"
SESSION_ID="sample-session-0001"
TRANSCRIPT="$(pwd)/sample-transcript.jsonl"
CWD="$(pwd)"

# 격리 환경: HOME 을 out/ 로 바꿔서 진짜 handoff 폴더를 안 건드림
export HOME="$OUT_DIR"
mkdir -p "$HOME/.claude/handoff"

case "$MODE" in
  pre|"")
    PAYLOAD=$(printf '%s' "{
      \"session_id\": \"$SESSION_ID\",
      \"transcript_path\": \"$TRANSCRIPT\",
      \"cwd\": \"$CWD\",
      \"trigger\": \"PreCompact (test)\"
    }")
    echo "$PAYLOAD" | python3 pre-compact-handoff.py
    echo "---"
    echo "[run-test] handoff 파일:"
    ls -la "$HOME/.claude/handoff/"
    ;;
  end)
    PAYLOAD=$(printf '%s' "{
      \"session_id\": \"$SESSION_ID\",
      \"transcript_path\": \"$TRANSCRIPT\",
      \"cwd\": \"$CWD\",
      \"reason\": \"clear\"
    }")
    echo "$PAYLOAD" | python3 session-end-handoff.py
    echo "---"
    ls -la "$HOME/.claude/handoff/"
    ;;
  restore)
    # 먼저 pre 단계로 handoff 파일을 생성한 뒤 restore 출력을 검증
    PRE_PAYLOAD=$(printf '%s' "{
      \"session_id\": \"$SESSION_ID\",
      \"transcript_path\": \"$TRANSCRIPT\",
      \"cwd\": \"$CWD\",
      \"trigger\": \"PreCompact (test)\"
    }")
    echo "$PRE_PAYLOAD" | python3 pre-compact-handoff.py > /dev/null
    RESTORE_PAYLOAD=$(printf '%s' "{
      \"session_id\": \"$SESSION_ID\",
      \"source\": \"compact\",
      \"cwd\": \"$CWD\"
    }")
    echo "$RESTORE_PAYLOAD" | bash session-restore.sh
    ;;
  *)
    echo "Unknown mode: $MODE" >&2
    exit 2
    ;;
esac

echo "---"
echo "[run-test] 결과 디렉토리: $OUT_DIR/.claude/handoff/"
