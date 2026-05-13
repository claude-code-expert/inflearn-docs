#!/bin/bash
# 샘플 컴포넌트로 review.sh 동작 검증
#
# 사용법:
#   ./run-test.sh            # bad-component.tsx 리뷰
#   ./run-test.sh good       # good-component.tsx 리뷰

set -euo pipefail

cd "$(dirname "$0")"
TARGET="examples/bad-component.tsx"
[ "${1:-bad}" = "good" ] && TARGET="examples/good-component.tsx"

if [ -z "${GEMINI_API_KEY:-}" ]; then
  echo "[run-test] GEMINI_API_KEY 미설정 — .env.example 참고 후 export 하세요." >&2
  echo "[run-test] dry-run: 프롬프트 조립까지만 확인" >&2
  echo "---"
  echo "target=$TARGET"
  wc -l "$TARGET"
  exit 0
fi

./review.sh "$TARGET"
