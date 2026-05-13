#!/bin/bash
# 객관적 정적 분석 레이어 — ESLint / Prettier / tsc
# Gemini 리뷰 전에 먼저 돌려서 "객관적으로 잡히는 것" 부터 처리합니다.
#
# 사용법:
#   ./lint-check.sh <file.tsx> [...]
#   ./lint-check.sh --all                  # 모든 *.ts(x) (대상 디렉토리에서)
#
# 환경변수:
#   LINT_CONFIG_DIR    기본 ./lint-config

set -uo pipefail   # -e 는 의도적으로 빠짐 — lint 실패해도 다른 단계는 계속

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${LINT_CONFIG_DIR:-$SCRIPT_DIR/lint-config}"

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 <file...> | --all" >&2
  exit 1
fi

if [ "$1" = "--all" ]; then
  mapfile -t TARGETS < <(find . -type f \( -name '*.ts' -o -name '*.tsx' \) ! -path '*/node_modules/*' ! -path '*/output/*')
else
  TARGETS=("$@")
fi

if [ "${#TARGETS[@]}" -eq 0 ]; then
  echo "[lint] 대상 파일 없음." >&2
  exit 0
fi

FAIL=0

# ── 1) Prettier ───────────────────────────────────────
if command -v prettier &>/dev/null; then
  echo "── prettier ──"
  prettier --config "$CONFIG_DIR/.prettierrc" --check "${TARGETS[@]}" || FAIL=1
else
  echo "[lint] prettier 미설치 — 'npm i -D prettier' 권장" >&2
fi

# ── 2) ESLint ────────────────────────────────────────
if command -v eslint &>/dev/null; then
  echo "── eslint ──"
  eslint --config "$CONFIG_DIR/.eslintrc.json" --no-eslintrc "${TARGETS[@]}" || FAIL=1
else
  echo "[lint] eslint 미설치 — 'npm i -D eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin eslint-plugin-react eslint-plugin-react-hooks eslint-plugin-jsx-a11y' 권장" >&2
fi

# ── 3) tsc (타입 검사 전용 — 빌드 X) ──────────────────
if command -v tsc &>/dev/null; then
  echo "── tsc --noEmit ──"
  tsc --project "$CONFIG_DIR/tsconfig.review.json" --noEmit "${TARGETS[@]}" || FAIL=1
else
  echo "[lint] tsc 미설치 — 'npm i -D typescript' 권장" >&2
fi

if [ "$FAIL" -ne 0 ]; then
  echo "[lint] 일부 검사 실패 — 위 출력 확인" >&2
  exit 1
fi

echo "[lint] all checks passed"
