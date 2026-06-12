#!/bin/bash
# TypeScript/React 코드 리뷰 — Gemini API 호출
#
# 사용법:
#   ./review.sh <file1.tsx> [file2.tsx ...]
#   ./review.sh --diff                       # git diff (working tree)
#   ./review.sh --diff main                  # main 대비 diff
#
# 환경변수:
#   GEMINI_API_KEY        Google AI Studio 발급 키 (필수)
#   GEMINI_MODEL          기본 gemini-3.1-pro-preview
#   REVIEW_OUTPUT_DIR     기본 ./output

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL="${GEMINI_MODEL:-gemini-3.1-pro-preview}"
OUTPUT_DIR="${REVIEW_OUTPUT_DIR:-$SCRIPT_DIR/output}"
PROMPTS_DIR="$SCRIPT_DIR/prompts"
CONV_DIR="$SCRIPT_DIR/conventions"

mkdir -p "$OUTPUT_DIR"

# ── 전제 조건 ─────────────────────────────────────────
if [ -z "${GEMINI_API_KEY:-}" ]; then
  echo "[review] GEMINI_API_KEY 미설정 — .env 또는 ~/.zshrc 에서 export 하세요." >&2
  exit 2
fi

for tool in jq curl; do
  if ! command -v "$tool" &>/dev/null; then
    echo "[review] $tool 가 필요합니다." >&2
    exit 2
  fi
done

# ── 입력 결정 ────────────────────────────────────────
MODE="files"
FILES=()
DIFF_BASE=""

if [ "${1:-}" = "--diff" ]; then
  MODE="diff"
  DIFF_BASE="${2:-HEAD}"
elif [ "$#" -eq 0 ]; then
  echo "Usage: $0 <file...> | --diff [base-ref]" >&2
  exit 1
else
  FILES=("$@")
fi

# ── 코드 본문 수집 ────────────────────────────────────
CODE_BLOB="$(mktemp)"
trap 'rm -f "$CODE_BLOB"' EXIT

if [ "$MODE" = "files" ]; then
  for f in "${FILES[@]}"; do
    if [ ! -f "$f" ]; then
      echo "[review] 파일 없음: $f" >&2
      exit 1
    fi
    printf '\n----- FILE: %s -----\n' "$f" >> "$CODE_BLOB"
    cat "$f" >> "$CODE_BLOB"
  done
else
  if ! git -C "$(dirname "${FILES[0]:-$PWD}")" rev-parse --is-inside-work-tree &>/dev/null; then
    echo "[review] git 저장소가 아닙니다 — --diff 모드는 git 안에서만 동작." >&2
    exit 1
  fi
  printf '\n----- GIT DIFF (base: %s) -----\n' "$DIFF_BASE" >> "$CODE_BLOB"
  git diff "$DIFF_BASE" -- '*.ts' '*.tsx' >> "$CODE_BLOB"
fi

CODE_SIZE=$(wc -c < "$CODE_BLOB")
if [ "$CODE_SIZE" -lt 20 ]; then
  echo "[review] 리뷰할 코드가 비어있습니다." >&2
  exit 0
fi

# ── 프롬프트 조립 ─────────────────────────────────────
SYSTEM_PROMPT="$(cat "$PROMPTS_DIR/system.md")"
RUBRIC="$(cat "$PROMPTS_DIR/rubric.md")"
CONV_TS="$(cat "$CONV_DIR/typescript.md")"
CONV_REACT="$(cat "$CONV_DIR/react.md")"
CONV_A11Y="$(cat "$CONV_DIR/accessibility.md")"
CODE_TEXT="$(cat "$CODE_BLOB")"

USER_PROMPT=$(cat <<EOF
다음은 리뷰 대상 TypeScript/React 코드입니다.

# 평가 기준 (Rubric)
$RUBRIC

# 컨벤션 — TypeScript
$CONV_TS

# 컨벤션 — React
$CONV_REACT

# 컨벤션 — Accessibility
$CONV_A11Y

# 코드
$CODE_TEXT

위 코드에 대해 JSON 으로 리뷰 결과를 반환하세요.
EOF
)

# ── Gemini 호출 ───────────────────────────────────────
REQ_BODY=$(jq -n \
  --arg sys "$SYSTEM_PROMPT" \
  --arg usr "$USER_PROMPT" \
  '{
    systemInstruction: { parts: [{ text: $sys }] },
    contents: [
      { role: "user", parts: [{ text: $usr }] }
    ],
    generationConfig: {
      temperature: 0.2,
      responseMimeType: "application/json"
    }
  }')

ENDPOINT="https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_API_KEY}"
RAW_RESPONSE="$OUTPUT_DIR/last-raw-response.json"

echo "[review] model=$MODEL bytes=$CODE_SIZE → POST $ENDPOINT" | sed "s/key=[^ ]*/key=***/" >&2

HTTP_CODE=$(curl -sS -o "$RAW_RESPONSE" -w "%{http_code}" \
  -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  --data-binary @<(printf '%s' "$REQ_BODY"))

if [ "$HTTP_CODE" != "200" ]; then
  echo "[review] HTTP $HTTP_CODE" >&2
  jq -r '.error.message // .' < "$RAW_RESPONSE" >&2
  exit 3
fi

# ── 응답 추출 ────────────────────────────────────────
REVIEW_JSON=$(jq -r '.candidates[0].content.parts[0].text' < "$RAW_RESPONSE")
TS="$(date '+%Y%m%d-%H%M%S')"
OUT_FILE="$OUTPUT_DIR/review-$TS.json"
printf '%s\n' "$REVIEW_JSON" > "$OUT_FILE"

# ── 사람 친화적 요약 ──────────────────────────────────
echo "[review] saved → $OUT_FILE"
echo "---"
if echo "$REVIEW_JSON" | jq empty 2>/dev/null; then
  echo "$REVIEW_JSON" | jq -r '
    "Verdict: " + .verdict,
    "Score: \(.score)/100",
    "",
    "## Findings",
    (.findings[] | "- [\(.severity | ascii_upcase)] \(.file // "?"):\(.line // "?") — \(.message)\n    rule: \(.rule // "n/a")")
  '
else
  echo "[review] 응답이 유효한 JSON 이 아닙니다 — $RAW_RESPONSE 확인" >&2
  cat "$RAW_RESPONSE"
fi
