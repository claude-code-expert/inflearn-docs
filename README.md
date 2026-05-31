# Claude Code Expert — 강의 자료 모음

> 📘 [github.com/claude-code-expert](https://github.com/claude-code-expert) — **클로드 코드 마스터** (한빛미디어) 공식 리포지토리
> ☕ [https://github.com/claude-code-expert/carve-harness](https://github.com/claude-code-expert/carve-harness) — 하네스 구성 CLI 

이 저장소는 Claude Code 강의를 통해 실무에 Claude Code를 적용하기 위한 **지침 파일 템플릿**, **실행 가능한 샘플(Hooks·Skill)**, **설계 문서 예제**, **개념 가이드**를 한곳에 모은 강의 자료다. 각 디렉토리는 독립적으로 사용할 수 있으며, 서로 `@` 참조와 워크플로로 연결된다.

---

## 목차

1. [전체 구조 한눈에 보기](#1-전체-구조-한눈에-보기)
2. [디렉토리별 가이드](#2-디렉토리별-가이드)
3. [디렉토리 간 연관 관계](#3-디렉토리-간-연관-관계)
4. [학습·적용 순서 추천](#4-학습적용-순서-추천)

---

## 1. 전체 구조 한눈에 보기

```
lecture/
├── template/     ← AI 코딩 에이전트 지침 파일 템플릿 (CLAUDE.md / AGENTS.md 계열)
├── docs/         ← 개념 가이드 + TypeScript 템플릿 + HTML 가이드 + 스크린샷
├── example/      ← CLAUDE.md 철학 예제 (Karpathy / Kent Beck 스타일)
├── project/      ← 설계 문서 예제 (PRD → TRD → REQUIREMENTS, 럭키드로우 앱)
└── samples/      ← 바로 돌려보는 Hooks·Skill 샘플 3종
```

| 디렉토리 | 핵심 질문 | 산출물 형태 |
|---------|----------|-----------|
| `template/` | "내 프로젝트에 어떤 지침 파일을 넣지?" | 복붙용 `.md` 템플릿 |
| `docs/` | "Claude Code의 기능·습관을 어떻게 설계하지?" | 개념 가이드 + 레퍼런스 |
| `example/` | "지침에 어떤 *철학*을 담지?" | 실제 작성 사례 |
| `project/` | "기능을 만들기 전에 무엇을 문서화하지?" | PRD/TRD/요구사항 명세 |
| `samples/` | "Hooks·Skill을 실제로 어떻게 짜지?" | 실행 가능한 스크립트 |

---

## 2. 디렉토리별 가이드

### 📁 `template/` — 지침 파일 템플릿 모음

AI 코딩 에이전트(Claude Code, Cursor, Codex 등)에게 프로젝트 맥락을 전달하는 지침 파일 템플릿이다. **자체 상세 README**가 있다 → [`template/README.md`](template/README.md)

- **CLAUDE.md 계열** — 싱글 앱 / 모노레포 루트·클라이언트·서버 / 개인 설정(`CLAUDE.local.md`)
- **AGENTS.md 계열** — 범용 지침(`AGENTS-template.md`), 작성 가이드(`AGENTS-Guide.md`), Java/Spring 실전 예시
- **Rules 파일** — `@` 참조로 불러오는 세부 규칙(code-style, testing, git-workflow, patterns 등)
- **멀티턴 방어 설계 가이드** — LLM이 멀티턴에서 평균 39% 성능이 하락하는 문제를 CLAUDE.md·Hooks·작업 구조화로 방어하는 4계층 전략 (README §4)

> 시나리오별 파일 조합(Next.js 단일 / pnpm 모노레포 / Spring Boot / 신규 프로젝트 / Skill 제작)은 `template/README.md`에 정리되어 있다.

### 📁 `docs/` — 개념 가이드와 레퍼런스

#### `docs/claude_template_ts/` — TypeScript 프로젝트 지침 세트
계층형 지침 한 벌. 행동 철학 → 프로젝트 규칙 → 품질 게이트로 이어진다.

| 파일 | 역할 |
|------|------|
| `CLAUDE.md` | 루트 지침 — 아래 규칙 파일들을 종합·참조 |
| `Karpathy_Behavioral_CLAUDE.md` | 언어 무관 행동 원칙(가정 금지·단순성·외과적 수정·목표 주도) |
| `Augmented_Coding_CLAUDE.md` | Kent Beck식 TDD·Tidy First 방법론 (Red→Green→Refactor) |
| `code-style.md` / `commands.md` / `techstack.md` | 코드 스타일·pnpm 명령어·기본 스택 정의 |
| `project-structure.md` / `safety.md` / `gotchas.md` | 디렉토리 맵·안전 가드레일·버그 패턴 로그 |

#### `docs/guide/` — 통합·워크플로 가이드 (한글)
| 파일 | 다루는 내용 | 연결되는 샘플 |
|------|-----------|-------------|
| `gemini-code-review-guide.md` | 자기편향 제거용 외부 모델(Gemini) 코드 리뷰 파이프라인 | → `samples/code-review-gemini/` |
| `handoff-system-guide.md` | `/compact`·`/clear` 시 컨텍스트 보존·복원 | → `samples/handoff/` |
| `slack-notification-hook-guide.md` | Stop 이벤트 → Slack 알림(Incoming Webhook) | → `samples/slack-notification/` |
| `interactive-mode-guide.md` | Claude Code 터미널 단축키·Vim 모드 전체 레퍼런스 | (독립) |

#### `docs/html/` & `docs/images/`
- `appendix-github-guide.html` — GitHub 사용 가이드 (스크린샷 약 50장: `docs/images/github-guide/`)
- `claude-code-hook-guide.html` — Claude Code Hooks 실전 가이드 (다크모드 HTML)

### 📁 `example/` — CLAUDE.md 철학 예제
지침에 담을 수 있는 두 가지 엔지니어링 철학의 실제 작성 사례.

- **`Karpathy-CLAUDE.md`** — *마인드셋* 중심. "코딩 전에 생각하라" — 가정 명시·단순성 우선·외과적 변경·목표 주도 실행
- **`Kentbeck-CLAUDE.md`** — *프로세스* 중심. TDD Red→Green→Refactor, 구조 변경과 행동 변경의 분리(Tidy First), 커밋 규율

> 둘 다 추측과 과잉 설계를 거부하지만, 한쪽은 *신중함*으로, 다른 한쪽은 *규율*로 접근한다. `docs/claude_template_ts/`의 Behavioral / Augmented 지침의 원형이다.

### 📁 `project/dluckydraw/` — 설계 문서 예제 (럭키드로우 앱)
"기능 구현 전에 무엇을 문서화하는가"를 보여주는 3단 명세. **왜 → 어떻게 → 무엇을**의 흐름.

| 문서 | 계층 | 핵심 내용 |
|------|------|----------|
| `PRD.md` | 왜(Why) | 비즈니스 목표·사용자 시나리오·범위·성공 지표. "AI 흔적 없는 디자인" 원칙 |
| `TRD.md` | 어떻게(How) | 단일 HTML·데이터 모델·룰렛 정지 각도 알고리즘·성능·접근성 |
| `REQUIREMENTS.md` | 무엇을(What) | 기능 요구사항 F1–F12 + 안티-AI 디자인 규칙 + 41개 검증 체크리스트 |

### 📁 `samples/` — 바로 실행하는 Hooks·Skill 샘플

| 샘플 | 시연하는 기능 | 핵심 동작 |
|------|-------------|----------|
| `code-review-gemini/` | **Skill** | 외부 모델(Gemini)로 코드 리뷰 — ESLint/Prettier/tsc(객관) → Gemini(시맨틱). `SKILL.md`·`review.sh`·rubric/conventions 포함 |
| `handoff/` | **Hooks** (PreCompact / SessionEnd / SessionStart) | 세션 종료 시 대화 컨텍스트를 추출·중복 제거·저장 → 새 세션에서 자동 주입 |
| `slack-notification/` | **Hooks** (Stop) | 세션 종료 시 마지막 응답 요약을 Slack Webhook으로 전송 |

각 샘플 디렉토리에 `README.md`, `settings.example.json`, `run-test.sh`가 있어 단독 실행·테스트가 가능하다.

---

## 3. 디렉토리 간 연관 관계

```
                    ┌──────────────────────────────────┐
                    │           example/               │
                    │  CLAUDE.md에 담을 "철학" 원형        │
                    │  (Karpathy / Kent Beck)          │
                    └────────────────┬─────────────────┘
                                     │ 철학을 구체화
                                     ▼
   ┌──────────────────────┐   참조   ┌──────────────────────────┐
   │      template/       │◀────────│  docs/claude_template_ts/│
   │  복붙용 지침 템플릿       │         │  TypeScript 계층형 지침 세트 │
   │ (CLAUDE/AGENTS/Rules)│         └──────────────────────────┘
   └──────────┬───────────┘
              │ 멀티턴 방어 §4에서 Hooks 설계 →
              ▼
   ┌─────────────────────┐  가이드↔샘플   ┌──────────────────────┐
   │     docs/guide/     │◀───────────▶│       samples/       │
   │  개념·설정 설명        │             │  실행 가능한 구현        │
   └─────────────────────┘             └──────────────────────┘

   ┌─────────────────────────────────────────────────────────┐
   │  project/luckydraw/  — 위 지침을 따라 만들 "대상 산출물"의     │
   │  설계 문서 예제 (PRD → TRD → REQUIREMENTS)                 │ 
   └─────────────────────────────────────────────────────────┘
```

**핵심 연결고리**

- **철학 → 지침**: `example/`의 Karpathy·Kent Beck 스타일이 `docs/claude_template_ts/`(Behavioral·Augmented)와 `template/`의 Investigation/Recovery 규칙으로 구체화된다.
- **가이드 ↔ 샘플**: `docs/guide/`의 각 가이드는 `samples/`의 실행 코드와 1:1로 짝을 이룬다(Gemini 리뷰·Handoff·Slack 알림).
- **지침 → Hooks**: `template/README.md` §4(멀티턴 방어)의 Hooks 설계가 `samples/`의 Hooks 구현으로 이어진다.
- **명세 → 구현**: `project/dluckydraw/`는 위 지침·습관을 적용해 만들 산출물의 설계 문서 표준을 보여준다.

---

## 4. 학습·적용 순서 추천

1. **`example/`** — CLAUDE.md에 어떤 철학을 담을지 두 사례로 감 잡기
2. **`template/README.md`** — 내 프로젝트 유형에 맞는 지침 파일 조합 선택, 멀티턴 방어 4계층 이해
3. **`docs/claude_template_ts/`** — TypeScript 실전 지침 세트로 계층형 규칙 구조 학습
4. **`docs/guide/` + `samples/`** — Hooks·Skill을 가이드로 이해하고 샘플로 직접 실행
5. **`project/luckydraw/`** — 실제 기능을 만들기 전 PRD/TRD/요구사항 명세 작성법 익히기

---

> 강의 본문과 함께 보면 가장 효과적입니다. 이슈·질문은 [github.com/claude-code-expert](https://github.com/claude-code-expert)로 남겨주세요.
