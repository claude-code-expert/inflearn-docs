<!--
================================================================
문서 메타
================================================================
원본 작성일: 2026-02-04 (v1.2)
정정본 작성일: 2026-05-13 (v2.0)

[수정 내역]
2026년 5월 기준 표준 기준으로 정정: 모든 에이전트 관련 항목들은 업데이트가 되기 때문에 현 문서를 기준으로 프로젝트에 적용할 때 에이전트를 통해 최신화 작업을 한번 더 요청해야함.

[주석 범례]
✏️  정정: 사실 오류를 바로잡음 (근거 포함)
➕  보강: 누락된 중요 정보 추가
⚠️  주의: 실무에서 헷갈리는 부분
📦  [분할 권장]: 별도 문서로 분리 권장 (이유 명시)
================================================================
-->

# AGENTS.md 작성 가이드 (v2.0)

> 이 문서는 **AI 코딩 에이전트가 프로젝트 작업 시 따라야 할 지침**을 정의하는 표준 문서, AGENTS.md의 작성 방법을 설명한다. Claude Code · OpenAI Codex · Cursor · Windsurf · Gemini CLI 등 다양한 에이전트가 같은 파일을 읽는 **도구 중립 표준**이다.

---

## 🤖 AGENTS.md란?


AGENTS.md는 OpenAI Codex · Amp · Google Jules · Cursor · Factory가 공동으로 만든 **도구 중립 오픈 표준**이다. 2025년 12월 Linux Foundation 산하의 **Agentic AI Foundation (AAIF)** 으로 거버넌스가 이관되었으며, 현재 60,000개 이상의 GitHub 리포지토리에서 사용된다.

- 공식 사이트: <https://agents.md>
- 표준 관리: Agentic AI Foundation (Linux Foundation)
- 핵심 비유: **"README가 사람용이라면, AGENTS.md는 AI 에이전트용 README다."**

### README vs AGENTS.md

| 파일 | 대상 | 목적 |
|------|------|------|
| **README.md** | 사람 개발자 | 프로젝트 소개, 설치 방법, 기여 가이드 |
| **AGENTS.md** | AI 코딩 에이전트 | 빌드/테스트 명령어, 코드 컨벤션, 금지 패턴, 아키텍처 경계 |

<!--
➕ 보강: 2026년 표준으로 전면 교체.
근거:
- Cursor: 2.2 이후 .cursorrules는 legacy, .cursor/rules/*.mdc가 표준 (cursor.com 공식 docs)
- Codex: AGENTS.md를 직접 지원, 시작 시 컨텍스트 윈도우에 자동 연결
  - 명명 우선순위: AGENTS.override.md > AGENTS.md > TEAM_GUIDE.md > .agents.md
  - 출처: developers.openai.com/codex/guides/agents-md
- Windsurf: AGENTS.md 또는 .windsurfrules 모두 지원 (둘 다 현행)
- Claude Code: CLAUDE.md 우선이지만 @AGENTS.md import로 표준 연계 가능
-->


> ⚠️ **Cursor `.cursorrules`는 2026년 현재 deprecated**. Cursor 2.2부터 Agent 모드는 `.cursorrules`를 **읽지 않는다**. 새 프로젝트는 `.cursor/rules/*.mdc` 형식만 사용할 것.
>
> 근거: [Cursor 공식 forum / awesome-cursor-rules-mdc](https://github.com/sanjeed5/awesome-cursor-rules-mdc) · [devtk.ai (2026-03)](https://devtk.ai/en/blog/complete-guide-cursorrules/)

<!--
➕ 보강: Codex의 명명 우선순위는 실무에서 매우 중요
모노레포에서 하위 폴더가 다른 규칙을 가져야 할 때 AGENTS.override.md가 결정적 역할.
근거: developers.openai.com/codex/guides/agents-md
-->

### Codex의 AGENTS.md 명명 우선순위 (모노레포 대응)

Codex는 디렉터리 트리를 따라 내려가며 다음 순서로 파일을 찾는다.

```
1. AGENTS.override.md    (해당 디렉터리의 강제 오버라이드)
2. AGENTS.md             (표준)
3. TEAM_GUIDE.md         (fallback, ~/.codex/config.toml에 등록 시)
4. .agents.md            (fallback, 등록 시)
```

루트의 `AGENTS.md`로 공통 룰을 깔고, 하위 폴더에 `AGENTS.override.md`를 두면 **그 폴더의 규칙이 상위를 덮어쓴다**. 모노레포에서 패키지별 규칙을 분리할 때 유용.

---

## 🎯 핵심 원칙

### 1. 실행 가능한(Executable) 정보 중심
AI는 추상적인 철학보다 당장 터미널에 입력할 **명령어**와 준수해야 할 **타입 정의**를 더 잘 이해한다. "좋은 코드를 작성하라" 대신 `pnpm test --run`을 적는다.


### 2. 토큰 효율성 (분량 가이드)
AGENTS.md는 모든 대화의 컨텍스트에 포함된다. **상한선을 정해두자.**

- **권장 분량**: 단일 파일 **150~200줄 이하**
- **상한 (Codex 기본값)**: 32 KiB (`project_doc_max_bytes` 기본값). 초과 시 잘림
- **합쳐서 항상 적용되는 규칙**: 2,000 토큰 이하 (Cursor 권장 기준)

길어지면 **상세 문서는 외부로 분리**하고 AGENTS.md에는 포인터(`@경로`)만 두는 Progressive Disclosure 패턴을 쓴다.


### 3. "Do"와 "Don't" — 둘 다 명시 (균형)
AI가 가장 잘 못하는 것은 **"무엇을 해야 하는지"** 와 **"무엇은 절대 하면 안 되는지"** 의 동시 지정이다.

- **Do (긍정 지시)**: "API 응답은 `Result<T, E>` 패턴 사용"
- **Don't (금지 제약)**: "`any` 타입 절대 금지"

특히 **보안·돌이킬 수 없는 행동**(force push, `rm -rf`, 프로덕션 DB 수정)은 **금지 사항**으로 명확히 못 박는다. 이 영역은 [Hook으로 결정론적 강제](#)를 병행하는 것이 안전하다.

---

## 📋 필수 섹션 구성

<!--
➕ 보강: 5개 섹션은 원본 그대로 유지하되, 예시를 markflow + Next.js 로 적용함. 각자의 프로젝트 상황에 맞도록 커스텀 필요
근거:
- 사용자 메모리: Tika/brewnet은 deprecated, markflow가 강의 캐논
- markflow 스택: Next.js 16 · Drizzle · PostgreSQL 16 · pnpm · Biome · Vitest
-->

### 1. 프로젝트 개요 (Project Context)
프로젝트의 목적과 핵심 아키텍처를 2~3문장으로 설명한다.

> **예시 (markflow):**
> *"Next.js 16(App Router) + Drizzle ORM + PostgreSQL 16 기반의 마크다운 팀 KMS. apps/web(Next.js) · packages/editor(CodeMirror 6) · packages/db(Drizzle)의 pnpm 모노레포 구조. Vercel 단일 배포."*

### 2. 프로젝트 구조 (Structure)
핵심 로직이 어디에 있는지 명시한다. AI가 파일을 생성할 위치를 헷갈리지 않게 한다. 가급적 분리하는걸 추천 

```
apps/web/                       Next.js 앱 (App Router + Route Handlers)
  app/api/v1/                   REST API 라우트
  app/(routes)/                 페이지 라우트
  components/                   도메인별 UI 컴포넌트
  lib/server/                   서버 전용 모듈 (Route Handler·SC만 import)
  lib/client/                   클라이언트 안전 모듈

packages/editor/                @markflow/editor — CodeMirror 6 기반 에디터
packages/db/                    @markflow/db — Drizzle 스키마 · 클라이언트
```

### 3. 주요 명령어 (Commands)
AI가 스스로 테스트·린트·타입체크를 돌리는 데 쓴다. **문서 상단에 배치**해 가장 먼저 보이게 한다.

| 명령 | 용도 |
|------|------|
| `pnpm dev` | 개발 서버 (apps/web, 포트 3000) |
| `pnpm test` | Vitest 단위 테스트 |
| `pnpm test:e2e` | Playwright E2E |
| `pnpm typecheck` | TypeScript 타입 검사 |
| `pnpm lint` | Biome 린트 |
| `pnpm lint:fix` | Biome 자동 수정 |
| `pnpm db:migrate` | Drizzle 마이그레이션 적용 |
| `pnpm db:studio` | Drizzle Studio (DB GUI) |

### 4. 코딩 컨벤션 (Conventions)
프로젝트 특유의 비자명한 패턴만 적는다. 자명한 것(camelCase 등)은 코드가 보여주므로 생략한다.

- **API 응답**: `{ success: boolean, data: T | null, error: string | null }`
- **에러 처리**: `Result<T, E>` 패턴 (`throw` 금지)
- **입력 검증**: 모든 외부 입력은 Zod 스키마 (`apps/web/lib/schemas/`)
- **ID**: CUID2 (`createId()` 사용, UUID 금지)
- **시간**: Day.js + `Asia/Seoul` 기본
- **계층 경계**: 클라이언트 컴포넌트는 Route Handler와 `fetch`로만 통신 — 서버 모듈 직접 `import` 금지

### 5. 🚨 금지 사항 (Critical Constraints)

<!--
⚠️ 주의: 금지 사항은 AGENTS.md만으로 100% 강제되지 않는다 (advisory).
반드시 Hook (Claude Code) 또는 pre-commit (git) 으로 결정론적 차단을 병행할 것.
근거: Claude Code 공식 — "Unlike CLAUDE.md instructions which are advisory, hooks..."
-->

- TypeScript `any` 사용 금지 (`unknown` + 타입 가드 또는 명시 타입)
- `dangerouslySetInnerHTML` / `innerHTML` 직접 사용 금지
- 마크다운 렌더링 시 `rehype-sanitize`를 파이프라인 **마지막**에 위치 (XSS 방지)
- DB 쿼리에 raw SQL 문자열 보간 금지 — Drizzle 쿼리 빌더 또는 parameterized만
- `main` 브랜치 직접 push 금지 (PR 경유 필수)
- `.env*` 파일 git 커밋 금지
- 환경 변수 코드 내 하드코딩 금지

> ⚠️ **AGENTS.md는 advisory(권고)다.** 위 금지사항을 100% 강제하려면 **Claude Code Hook** 또는 **git pre-commit hook**으로 결정론적 차단을 함께 걸어야 한다.

---


## 🛠 도구별 실전 호환성

### Claude Code에서 AGENTS.md 사용하기 (권장: @import)

Claude Code는 `CLAUDE.md`를 우선 읽지만, `@경로` 문법으로 다른 MD 파일을 가져올 수 있다. **단일 출처 원칙**을 지키려면 다음 패턴이 가장 깔끔하다.

```markdown
<!-- CLAUDE.md -->

# markflow

@AGENTS.md 를 반드시 먼저 읽고 모든 지침을 따른다.

## Claude Code 전용 추가 사항
- 마크다운 파싱 변경 시 `/security-review` 자동 실행
- 큰 변경은 plan mode (Shift+Tab 두 번)
- 서브에이전트 활용 시 `markdown-security` Skill 사전 로드
```

이 패턴의 장점:
- **단일 출처**: AGENTS.md가 진실. CLAUDE.md는 Claude 전용 추가만
- **다도구 안전**: Codex가 와도 AGENTS.md 그대로 읽음
- **OS 무관**: 심볼릭 링크 같은 Windows 호환 이슈 없음


#### 심볼릭 링크 방식 (비권장, 호환성 문제)

```bash
# ⚠️ 비권장 — Windows · 일부 git 워크플로에서 문제 발생
ln -s AGENTS.md CLAUDE.md
```

심볼릭 링크는 git에서 평문이 아닌 링크 객체로 저장돼 일부 도구가 인식 못 하는 경우가 있고, Windows 환경에서 권한 문제가 빈번하다. **@import 방식이 표준이다.**

---

<!--
📦 [분할 권장] 아래 "도구별 상세 설정"·"실전 템플릿" 두 섹션은 별도 문서로 분리 권장.
이유:
1. AGENTS.md 작성 자체는 위 5개 섹션 + 호환성 한 페이지면 충분
2. 도구별 디테일(Cursor .mdc frontmatter, Codex config.toml 등)은 도구별로 빠르게 변하므로 별도 문서로 분리하면 유지 보수 비용 ↓
3. 실전 템플릿은 프로젝트별로 다르므로 examples/ 폴더에 두는 게 적합

분리 권장 파일:
- agents-md-tool-compatibility.md  (Cursor .mdc, Codex config 등 도구별 디테일)
- agents-md-templates/              (markflow·Express·FastAPI 등 스택별 템플릿)

-->

## 📚 다도구 팀을 위한 패턴

여러 AI 에이전트를 함께 쓰는 팀이라면 다음 구조를 권장한다.

```
project-root/
├── AGENTS.md                       # 단일 진실 — 모든 도구가 읽음
├── CLAUDE.md                       # @AGENTS.md import + Claude 전용 추가
├── .cursor/
│   └── rules/
│       ├── general.mdc             # alwaysApply, AGENTS.md 핵심 요약
│       └── frontend.mdc            # globs: src/components/**
├── .github/
│   └── copilot-instructions.md     # AGENTS.md 핵심을 Copilot 형식으로
└── .codex/
    └── config.toml                 # Codex 추가 설정 (fallback 파일명 등)
```

**원칙**: AGENTS.md를 진실로 두고, 도구별 파일은 그것을 **참조하거나 요약**한다. 같은 내용을 여러 곳에 복제하지 않는다.

> 💡 **자동 동기화 스크립트**: AGENTS.md 변경 시 다른 파일들을 자동 업데이트하는 git pre-commit hook을 두면 편하다. 단, **AGENTS.md만 직접 편집**하는 규칙을 팀에서 합의해야 함.

---

## 📋 작성 체크리스트

본 가이드 따라 AGENTS.md 작성을 마쳤다면 다음을 확인한다.

- [ ] 분량 **200줄 이하** (Codex 32 KiB 한도 내)
- [ ] **Commands 섹션을 상단**에 배치 (`pnpm test`, `pnpm typecheck` 등)
- [ ] 프로젝트 구조 + 계층 경계 명시
- [ ] **비자명한** 컨벤션만 적기 (자명한 것은 코드가 보여줌)
- [ ] 금지사항을 **Do와 균형 있게** 명시
- [ ] 핵심 금지사항은 **Hook으로 결정론적 차단도 별도 설정**
- [ ] Claude Code 쓴다면 `CLAUDE.md`에서 `@AGENTS.md` import
- [ ] Cursor 쓴다면 `.cursor/rules/*.mdc` 사용 (`.cursorrules` 아님)
- [ ] 모노레포면 하위 폴더에 `AGENTS.override.md` 활용 검토

---


