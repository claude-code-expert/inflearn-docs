# Code Review (Gemini) 샘플

TypeScript/React 코드를 **Claude 대신 Gemini API** 로 리뷰하는 파이프라인. Claude 가 작성한 코드를 Claude 가 다시 검토할 때 발생하는 자기편향(self-bias) 을 제거하기 위해 외부 모델을 호출합니다.

## 폴더 구성

```
samples/code-review-gemini/
├── README.md
├── SKILL.md                       # ~/.claude/skills/code-review-gemini/SKILL.md 로 복사
├── review.sh                      # 메인: Gemini API 호출
├── lint-check.sh                  # 객관 레이어: ESLint / Prettier / tsc
├── run-test.sh                    # 샘플로 동작 검증 (GEMINI_API_KEY 없으면 dry-run)
├── .env.example                   # API 키 예시
├── prompts/
│   ├── system.md                  # Gemini system instruction
│   └── rubric.md                  # 평가 기준 / 가중치 / severity 매핑
├── conventions/
│   ├── typescript.md              # TS 컨벤션 (any 금지, type 우선 등)
│   ├── react.md                   # React 컨벤션 (hooks, props 불변 등)
│   └── accessibility.md           # WCAG 2.1 AA / WAI-ARIA
├── lint-config/
│   ├── .eslintrc.json             # 권장 ESLint 설정 (typescript-eslint, react-hooks, jsx-a11y)
│   ├── .prettierrc                # Prettier 설정
│   ├── tsconfig.review.json       # 리뷰용 strict tsc 설정
│   └── package.json               # 권장 devDependencies
├── examples/
│   ├── bad-component.tsx          # 문제 11종 주입한 컴포넌트
│   ├── good-component.tsx         # bad 의 클린업 버전
│   └── expected-review.json       # bad 에 대한 기대 출력 예시
└── output/                        # 런타임 결과 (review-<ts>.json)
```

## 사전 준비

1. **Gemini API key 발급**: <https://aistudio.google.com/apikey>
2. **`~/.zshrc` 에 export 추가** (또는 `.env.example` 참고):
   ```bash
   export GEMINI_API_KEY="AIza..."
   ```
3. **필수 도구**: `jq`, `curl` (이미 macOS 에 있거나 `brew install jq`)
4. **선택**: `lint-check.sh` 까지 쓰려면 `cd lint-config && npm install`

## 빠른 사용

```bash
cd samples/code-review-gemini
chmod +x review.sh lint-check.sh run-test.sh

# 1) 샘플 검증 (API 키 없으면 dry-run)
./run-test.sh

# 2) 실제 파일 리뷰
./review.sh examples/bad-component.tsx

# 3) git diff 기반 리뷰
./review.sh --diff main
```

## 출력

stdout 요약 + `output/review-<timestamp>.json` 풀 응답:

```
[review] saved → output/review-20260513-130000.json
---
Verdict: BLOCK
Score: 25/100

## Findings
- [CRITICAL] examples/bad-component.tsx:38 — 서버 응답을 정제 없이 dangerouslySetInnerHTML 로 렌더 → XSS 가능
    rule: react/no-danger
- [HIGH] examples/bad-component.tsx:16 — useEffect 의존성 배열에 query 누락
    rule: react-hooks/exhaustive-deps
...
```

## 왜 Gemini 인가

- **자기편향 제거**: 같은 모델이 작성+리뷰하면 자체 선호 패턴에 가산점을 주는 경향이 보고됨. 외부 모델은 다른 학습 분포 → 독립적 신호.
- **2차 의견(second opinion)**: Anthropic 모델 한계가 노출되는 영역(특정 TS 패턴, React 18 동시성, 새 ECMAScript) 을 다른 관점에서 평가.
- **재현성**: 동일 프롬프트/모델 버전 핀 → CI 에 통합 가능.

## 알려진 한계

- `examples/*.tsx` 의 TypeScript 진단(`Cannot find module 'react'`)은 의도된 것. 샘플 폴더는 React 를 설치하지 않음 — review.sh 는 코드를 **텍스트로** Gemini 에 전달하므로 컴파일 컨텍스트 불필요.
- Gemini 도 결국 LLM. false positive 가능 → `verdict` 만 보고 자동 머지 차단하지 말고 사람이 한 번 확인.
- 큰 PR (수천 라인) 은 컨텍스트 한계에 걸릴 수 있음 — 파일 단위 분할 호출 권장.

## 가이드

`docs/guide/gemini-code-review-guide.md` 참고.
