# Gemini API 코드 리뷰 가이드 (TypeScript/React)

> Claude 가 작성한 코드를 Claude 가 다시 검토할 때 발생하는 **자기편향(self-bias)** 을 제거하기 위해, 외부 모델인 **Gemini** 를 호출해 객관적 리뷰를 받는 파이프라인.

---

## 1. 왜 외부 모델인가

LLM 으로 작성한 코드를 같은 모델로 리뷰하면 다음 패턴이 자주 관찰됩니다.

- 자기 출력 스타일에 가산점 부여
- 자기가 만든 결함(over-engineering, 불필요한 추상화) 을 정당화
- 동일 학습 분포에 의존 → 같은 사각지대 공유

본 가이드의 접근은 **두 단계 분리**입니다.

| 레이어 | 도구 | 책임 |
|--------|------|------|
| 객관 (Deterministic) | ESLint / Prettier / tsc | 규칙 기반으로 명확히 판정 가능한 결함 |
| 의미 (Semantic) | **Gemini 3.1 Pro** | 의도/설계/맥락이 필요한 결함 (자기편향 회피) |

Claude Code 는 **오케스트레이터** 로만 동작합니다 — diff 추출, 정적 분석 실행, Gemini 호출 결과 정리. 평가 자체는 Claude 가 하지 않습니다.

---

## 2. 시스템 구성

```
┌─────────────────────────────────────────────────────────┐
│ Claude Code (사용자)                                     │
│   │  "PR 리뷰해줘"                                       │
│   ▼                                                     │
│ SKILL: code-review-gemini                                │
│   │ ① git diff 또는 지정 파일 결정                        │
│   │ ② lint-check.sh — 객관 레이어                         │
│   │ ③ review.sh   — Gemini 호출                          │
│   │ ④ verdict / findings 사용자에게 정리                  │
│   ▼                                                     │
│ Gemini API (generativelanguage.googleapis.com)           │
│   │  systemInstruction (의도/형식)                       │
│   │  contents = rubric + conventions + 코드 본문          │
│   │  responseMimeType=application/json                   │
│   ▼                                                     │
│ JSON 응답 → output/review-<ts>.json                       │
└─────────────────────────────────────────────────────────┘
```

---

## 3. 설치

### 3-1. API key

1. <https://aistudio.google.com/apikey> 에서 발급
2. `~/.zshrc` 에 추가:
   ```bash
   export GEMINI_API_KEY="AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
   ```
3. `source ~/.zshrc` 후 `echo $GEMINI_API_KEY` 로 확인

> 보안: `GEMINI_API_KEY` 는 토큰과 동급. dotfiles 저장소에 평문으로 올리지 말고 secret manager 사용. 본 저장소에는 `.env.example` 만 두고 실제 키 파일은 `.gitignore`.

### 3-2. 필수 / 권장 도구

```bash
# 필수
command -v jq && command -v curl

# 권장 (lint-check.sh 용)
cd samples/code-review-gemini/lint-config
npm install      # eslint, prettier, typescript, plugins
```

### 3-3. Skill 등록 (Claude Code 에서 슬래시로 호출하려면)

```bash
mkdir -p ~/.claude/skills/code-review-gemini
cp samples/code-review-gemini/SKILL.md ~/.claude/skills/code-review-gemini/SKILL.md
```

이후 Claude Code 에서 "코드 리뷰" / "PR 리뷰" 등의 키워드를 입력하면 `code-review-gemini` 스킬이 발화됩니다.

---

## 4. 사용

### 4-1. 단일/복수 파일

```bash
./review.sh src/components/UserList.tsx src/hooks/useUser.ts
```

### 4-2. git diff 기반

```bash
./review.sh --diff           # working tree vs HEAD
./review.sh --diff main      # 현재 브랜치 vs main
./review.sh --diff origin/main HEAD~1
```

### 4-3. 정적 분석만 (Gemini 호출 없이)

```bash
./lint-check.sh src/components/UserList.tsx
./lint-check.sh --all
```

### 4-4. Claude Code 에서

```
"현재 브랜치 변경분을 Gemini 로 리뷰해줘"
"src/components/UserList.tsx 외부 리뷰해줘"
```

→ SKILL 이 자동으로 lint-check.sh → review.sh → 결과 정리 순으로 진행.

---

## 5. 출력 형식

`responseMimeType: "application/json"` 으로 강제하므로 항상 다음 스키마:

```json
{
  "verdict": "APPROVE | REQUEST_CHANGES | BLOCK",
  "score": 0,
  "summary": "한 문단 요약",
  "findings": [
    {
      "severity": "critical | high | medium | low",
      "category": "bug | security | a11y | performance | maintainability | style | type-safety",
      "file": "...",
      "line": 12,
      "message": "...",
      "rule": "react-hooks/exhaustive-deps",
      "suggested_fix": "코드 스니펫"
    }
  ],
  "suggestions": [ "..." ]
}
```

판정 규칙:

- `BLOCK` ← critical ≥ 1
- `REQUEST_CHANGES` ← high ≥ 1 또는 medium ≥ 3
- `APPROVE` ← 나머지

`score` 차감: critical −25, high −10, medium −5, low −1 (0 미만은 0).

---

## 6. 평가 차원 (rubric)

| 차원 | 가중치 | 검사 항목 |
|------|------|---------|
| Correctness & Bugs | 25 | 런타임 에러, race, off-by-one, falsy 처리 |
| Type Safety | 15 | `any`, 단언, 제네릭 부재, narrowing 누락 |
| React Hooks | 15 | rules-of-hooks, exhaustive-deps, re-render |
| Security | 10 | XSS, 입력/URL 검증, 키 노출 |
| Accessibility | 10 | label/aria, 키보드, 대비, semantic HTML |
| Performance | 10 | 리렌더, memoization 오남용, key, lazy load |
| Maintainability | 10 | 길이, 단일 책임, 명명, 매직 넘버 |
| Style/Convention | 5 | 프로젝트 컨벤션 |

(상세 매핑은 `samples/code-review-gemini/prompts/rubric.md`)

---

## 7. 컨벤션 문서

리뷰 시 Gemini 에 함께 전달됩니다. 프로젝트별로 수정해서 사용하세요.

- `conventions/typescript.md` — `any` 금지, type 우선, type-only import, non-null 단언 금지 등
- `conventions/react.md` — hooks 규칙, props 불변, key 안정성, derived state 처리
- `conventions/accessibility.md` — WCAG 2.1 AA, WAI-ARIA, 키보드 trap, ARIA 사용 원칙

---

## 8. ESLint / Prettier / tsc 설정

`samples/code-review-gemini/lint-config/` 에 권장 설정 포함.

핵심 규칙 (eslintrc):

- `@typescript-eslint/no-explicit-any: error`
- `@typescript-eslint/no-non-null-assertion: error`
- `react-hooks/exhaustive-deps: error`
- `react/jsx-key: error`
- `jsx-a11y/click-events-have-key-events: error`
- `no-console: warn (allow: warn,error)`

tsc 권장 (`tsconfig.review.json`):

- `strict: true`
- `noUncheckedIndexedAccess: true`
- `exactOptionalPropertyTypes: true`
- `noImplicitReturns: true`

---

## 9. 검증 (dry-run / live)

```bash
cd samples/code-review-gemini

# dry-run: API 키 없이도 프롬프트 조립까지 확인
unset GEMINI_API_KEY
./run-test.sh

# live
export GEMINI_API_KEY="..."
./run-test.sh           # bad-component.tsx
./run-test.sh good      # good-component.tsx
```

기대 출력:

- bad-component → verdict `BLOCK`, score ≤ 30, critical 1개 (XSS), high 2~3개
- good-component → verdict `APPROVE`, score ≥ 85, findings 1~2개 (low 위주)

(`examples/expected-review.json` 가 기준치)

---

## 10. 트러블슈팅

| 증상 | 원인 / 해결 |
|------|----|
| `HTTP 400 — API key not valid` | 키 오타 또는 미발급 — AI Studio 에서 재발급 |
| `HTTP 429` | rate limit — 모델을 `gemini-3.5-flash` 로 다운그레이드하거나 요청 간격 늘리기 |
| `HTTP 503` | 일시 과부하 — 재시도 |
| 응답 JSON 파싱 실패 | 코드가 너무 길어 모델이 잘림 — 파일 단위 분할 호출 |
| `Cannot find module 'react'` in examples/*.tsx | 의도된 것. 샘플은 npm 미설치. Gemini 는 코드 텍스트만 받음 |
| Verdict 가 항상 BLOCK | system prompt 의 판정 기준이 너무 엄격 — `prompts/system.md` 의 차감점 조정 |
| Findings 이 일관성 없음 | temperature 가 너무 높음 — `review.sh` 의 `temperature: 0.2` 유지 |

---

## 11. 한계와 주의

- **Gemini 도 LLM**. 환각/오탐 발생 가능 → 자동 머지 차단 게이트로 쓰지 말 것. 사람의 최종 판단 필수.
- **API 비용**: 큰 PR 은 입력 토큰이 큼. 가격은 [Gemini API pricing](https://ai.google.dev/pricing) 참조.
- **데이터 거버넌스**: 코드가 Google AI 로 전송됨. 사내 보안 정책 확인 필요. 민감 코드는 Vertex AI 의 enterprise 채널 또는 사내 LLM 으로 대체.
- **CI 통합**: `verdict` 를 머지 게이트로 쓰려면 `score` 임계값을 직접 설정하고, 회의적인 PM/엔지니어와 합의 후 적용.

---

## 12. 관련 파일

- 가이드: 본 문서
- 메인 스크립트: `samples/code-review-gemini/review.sh`
- 정적 분석: `samples/code-review-gemini/lint-check.sh`
- Skill 정의: `samples/code-review-gemini/SKILL.md`
- 프롬프트: `samples/code-review-gemini/prompts/`
- 컨벤션: `samples/code-review-gemini/conventions/`
- Lint 설정: `samples/code-review-gemini/lint-config/`
- 예제: `samples/code-review-gemini/examples/`
