# Changelog

이 저장소(Claude Code 강의자료)의 주요 변경사항을 기록합니다.
형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/)를 따릅니다.

> 가이드 HTML(`docs/html/`)은 git 추적에서 제외되어 로컬/별도 배포로만 관리합니다.
> 따라서 본 changelog는 추적 대상 산출물과 함께 **로컬 HTML 산출물의 변경**도 기록합니다.

## [Unreleased]

## [2026-06-12]

### Changed
- **문서 전수 감사 반영** — 스테일 모델 표기(Sonnet 4.5 → 4.6, Gemini 2.5 → 3.1 등)·Node LTS·훅 예제 환경변수(`$CLAUDE_TOOL_INPUT` → stdin+jq)·SessionEnd 훅 `source` → `reason`·럭키드로우 코드 주석의 명세 참조 번호 등 일괄 수정. README의 `docs/claude_template_ts` 표를 실제 `.claude/rules/`·`.claude/templates/` 구조로 갱신, `docs/guide/` 누락 가이드 2종 추가.
- **GitHub 가이드 통합** — 레거시 `appendix-github-guide.html`(Notion 추출본)을 `github-guide-101.html`로 대체(README 목록 갱신)하고 `docs/html/_superseded/`로 이동.
- **터미널 가이드 통합** — 사본 `terminal-guide-101.html`의 고유 내용(WSL2 설치 안내 등)을 `terminal-guide-for-beginners.html`에 병합 후 `docs/html/_superseded/`로 이동.


## [2026-06-06]

### Added
- **Claude Code 훅 실무 가이드** (`template/claude-code-hook-guide.md`) — 개념 → 작동 구조 → 첫 훅 → 실무 레시피 마크다운 버전.
- **CLI Alias·권한 설정 레퍼런스** (`template/cli-alias-settings.md`).
- **Skills·Commands·Hooks 통합 가이드** (`docs/guide/skills-commands-hooks-guide.md`).

### Changed
- **템플릿 README 관련 문서 링크 정비** (`template/README.md`) — 새 훅 가이드·CLI 레퍼런스 연결.
- **`.DS_Store`·`docs/html` git 추적 제외** (`.gitignore`) — 추적 중이던 `.DS_Store` 파일 제거.

## [2026-06-02]

### Changed
- **가이드 문서를 run-ai 기준으로 이동·정리** — `docs/guide/github-guide-101.html`·`terminal-guide-101.html`을 git 추적에서 제거(run-ai로 이동).

## [2026-06-01]

### Added
- **zsh 설치 & 설정 가이드** (`docs/html/zsh-guide.html`) — 원본 `zsh-guide.md`를 동일 룩앤필 HTML로 변환. PlantUML 설치 흐름도를 인라인 SVG로 재작성, `[스크린샷 영역]` 자리 표시 포함.
- **10단계 프롬프트 구조 가이드** (`docs/html/prompt-structure-10-stacks.html`) — Anthropic "Prompting 101" 정리. 다이어그램 SVG를 HTML에 직접 인라인(외부 경로 의존 제거). "프롬프트 실전 예시" 섹션(제로샷·퓨샷·CoT·문제 분해·ReAct) 포함.
- **Git · GitHub 활용 가이드** (`docs/html/github-guide-101.html`).
- **Claude Code 훅 실무 가이드** (`docs/html/claude-code-hook-guide.html`) — 개념 → 작동 구조 → 첫 훅 → 실무 레시피. "필수 훅 베이스라인"(민감 파일 보호·세션 컨텍스트 주입·Bash 감사 로그·완료 알림) 섹션 추가.
- **비개발자 터미널 입문**: Apple 터미널 공식 단축키 표, "실전 예제 모음"(셸 설정 적용·파일 생성/권한(chmod)·복사/이동/삭제·폴더 열기) 추가.
- **비개발자 GitHub 입문**: "실전 — 개발 시점 자주 쓰는 흐름"(clone→commit→push, fetch, 브랜치 생성·푸시, pull 후 merge, unrelated-histories 처리, `.gitignore` 추적 제외) 추가.
- **워터마크 재사용 스킬** (`.claude/skills/watermark/SKILL.md`) — 표준 run-ai.kr 워터마크 캐논·적용법·`%40` 인코딩 주의를 문서화.
- **럭키드로우 앱** (`project/luckydraw/lucky-draw.html`) — 2단계(번호 추첨 → 경품 원판) 럭키 드로우 **단일 파일 구현**(HTML+CSS+JS, 외부 의존성 0, ~30KB). 인원수·경품 입력, 고정 섹션 원판+꽝, 번호 추첨(균등·중복없음), TRD 회전 알고리즘(휠 정지=결과 일치), 재고 차감·재배정, 결과 3중 표시+컨페티(당첨만), 접근성·`prefers-reduced-motion`. 설계 문서 `ANALYSIS.md` 추가.

### Changed
- **`docs/claude_template_ts` 재구성** — 평면 구조를 실제 프로젝트 레이아웃으로 정리: 규칙 6종을 `.claude/rules/`로, 대체 베이스라인 2종을 `.claude/templates/`로 이동(`git mv`로 이력 보존). `CLAUDE.md`의 `@.claude/rules/*` 임포트 경로가 실제 구조와 일치.
- **전체 가이드 워터마크 캐논 통일** — `opacity .12` / `font-size 19`로 표준화하고 `docs/html` 전 문서에 일괄 적용. 워터마크 없던 `appendix-github-guide.html`에도 추가.
- **`docs/html` git 추적 제외** (`.gitignore`) — 로컬/별도 배포 전용. 이전에 추적되던 HTML은 인덱스에서 제거(로컬 파일은 유지).
- **럭키드로우 문서 현행화** — `PRD`·`TRD`·`REQUIREMENTS`를 구현 기준으로 갱신(충돌 8건 해소: 단일→2단계, 제거→재배정, 꽝 추가, `color` 필드 제거 등). 역할 분리(PRD 목적 / TRD 기술 정본 / REQUIREMENTS 기능·검증 / ANALYSIS 결정·이력)로 문서 간 중복 제거.

### Fixed
- **이미지 깨짐** (`appendix-github-guide.html`) — GitHub `blob` URL을 `raw.githubusercontent.com` URL로 교체(98곳)하여 외부 환경에서 이미지가 표시되도록 수정.
- **CSP / 이메일 난독화 에러** — 워터마크 이메일의 `@`를 `%40`으로 인코딩. Cloudflare Email Obfuscation이 외부 디코드 스크립트(`email-decode.min.js`)를 주입해 호스트 CSP에 막히던 콘솔 에러 방지(렌더는 동일).
- **목차 앵커 이동** (`github-guide-101.html`) — 일부 IDE 내장 미리보기에서 해시 변경이 페이지 이동으로 처리되던 문제를, 방어용 부드러운 스크롤 핸들러(`scrollIntoView` + `history.replaceState`)로 해결.
