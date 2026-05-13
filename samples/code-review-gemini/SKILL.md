---
name: code-review-gemini
description: TypeScript/React 프론트엔드 코드를 Gemini API 로 리뷰합니다. 자기편향(self-bias) 제거 목적으로 Claude 가 아닌 외부 모델이 평가. "리뷰", "review", "PR 리뷰", "코드 리뷰", "외부 리뷰", "Gemini 리뷰" 키워드에 발화.
---

# Code Review (Gemini) Skill

## 언제 사용하나

- 사용자가 TS/React 프론트엔드 코드의 리뷰를 요청할 때
- 특히 "Claude 가 작성한 코드를 다른 모델로 검토하고 싶다" 류 요청
- PR 머지 전 객관적 평가가 필요할 때

## 실행 절차

1. **대상 파악**
   - 사용자가 파일을 명시 → 그 파일들 사용
   - "PR 리뷰" / "변경분 리뷰" → `git diff` 로 변경된 `*.ts(x)` 추출
   - 명시 없음 → 사용자에게 "현재 브랜치의 diff 를 리뷰할까요, 특정 파일을 지정하시겠어요?" 확인

2. **사전 점검 (객관 레이어)**
   ```bash
   bash samples/code-review-gemini/lint-check.sh <files>
   ```
   - ESLint/Prettier/tsc 결과를 먼저 사용자에게 보고
   - lint 실패가 있으면 그것부터 수정할지 묻고, 사용자가 진행 원하면 Gemini 호출

3. **Gemini 리뷰 (의미 레이어)**
   ```bash
   bash samples/code-review-gemini/review.sh <files>
   # 또는
   bash samples/code-review-gemini/review.sh --diff [base-ref]
   ```
   - 결과 JSON 은 `samples/code-review-gemini/output/review-<ts>.json` 에 저장
   - stdout 으로 verdict / score / findings 요약 출력

4. **결과 정리 및 사용자 보고**
   - findings 를 severity 순으로 정렬해서 보여주기
   - `BLOCK` 또는 `REQUEST_CHANGES` 면 다음 액션 제안 (직접 수정 / PR 코멘트 / 무시 후 진행)
   - 사용자가 "수정해줘" 라고 하면 finding 별로 Edit 도구로 패치

## 호출 시 주의

- `GEMINI_API_KEY` 미설정이면 즉시 안내하고 `.env.example` 참조 권장
- review.sh 는 외부 API 호출 — 비용 발생. 큰 PR (수천 라인) 은 모델/입력 제한 확인
- 결과는 참고용. 최종 결정은 사용자에게 — Gemini 도 모델이므로 false positive 가능

## 관련 파일

- 가이드: `docs/guide/gemini-code-review-guide.md`
- 메인 스크립트: `samples/code-review-gemini/review.sh`
- 정적 분석: `samples/code-review-gemini/lint-check.sh`
- 컨벤션: `samples/code-review-gemini/conventions/`
- 평가 기준: `samples/code-review-gemini/prompts/rubric.md`
