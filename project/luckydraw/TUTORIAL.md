# Lucky Draw 따라하기 — Claude Code 단계별 실습

> **강의 목표**: 빈 Git 저장소에서 시작해 Claude Code로 단일 HTML 럭키 드로우 사이트를 완성한다.
> **핵심 메시지**: 코드부터 짜지 말고, **CLAUDE.md + 설계 문서(PRD/TRD/REQUIREMENTS)로 컨텍스트를 먼저 세팅**한 뒤 프롬프트를 던진다.

전체 동선: `저장소 생성 → clone → init → 요구사항 정리 → CLAUDE.md 작성 → 첫 프롬프트 → 문서 생성 → 단계별 구현 → 서버 실행`

---

## STEP 1. Git 저장소 생성 후 VSCode에서 clone

### 1-1. GitHub에서 저장소 생성
1. GitHub → **New repository**
2. Repository name: `lucky-draw`
3. **Add a README file** 체크 (clone 대상이 생기도록)
4. **Create repository**

### 1-2. VSCode에서 clone
방법 A — VSCode UI:
1. `Cmd+Shift+P` → **Git: Clone**
2. 저장소 URL 붙여넣기 (`https://github.com/<id>/lucky-draw.git`)
3. 저장할 로컬 폴더 선택 → **Open**

방법 B — 터미널:
```bash
git clone https://github.com/<id>/lucky-draw.git
cd lucky-draw
code .
```

> 💡 강의 포인트: clone 직후 VSCode 내장 터미널(`Ctrl+`` `)에서 작업하면 Claude Code 실행·git 명령이 한 화면에서 끝난다.

---

## STEP 2. Claude Code 실행 + init

### 2-1. 설치 확인 / 실행
```bash
# 프로젝트 루트(lucky-draw/)에서
claude
```

### 2-2. `/init` 실행
Claude Code 프롬프트에 입력:
```
/init
```
- `/init`은 현재 디렉터리를 분석해 **CLAUDE.md 초안**을 자동 생성한다.
- 빈 저장소라면 최소 골격만 만들어지므로, 다음 STEP에서 우리가 직접 채운다.

> 💡 강의 포인트: `/init`은 "프로젝트 규칙을 Claude에게 영구적으로 주입하는 파일"을 만드는 단계다. 매 프롬프트마다 같은 지시를 반복하지 않기 위함.

---

## STEP 3. 러키드로우 요구사항 정리 (한 줄 정의)

본격 문서 작성 전, 머릿속 요구사항을 한 문단으로 고정한다.

> **인원 번호를 랜덤으로 즉시 추첨**해 당첨자를 정한 뒤, **경품 원판을 돌려** 그 사람이 받을 상품을 정하는 **2단계 럭키 드로우**를, **단일 HTML 파일**(외부 의존성 0)로 만든다.

필수 기능 한눈에:
- 인원수 입력(1~N) / 경품 추가·삭제·동일명 병합
- 번호 추첨(균등 랜덤, 중복 없음) → 경품 원판 회전(고정 섹션 + 꽝 1칸)
- 결과 3중 표시(패널 + 모달 + 기록) + 당첨 시 컨페티
- 재고 차감 + 재배정(섹션 수 불변) + 통계 + 초기화 + 예시

---

## STEP 4. CLAUDE.md 기본 설정 작성

`.claude/CLAUDE.md`(또는 루트 `CLAUDE.md`)에 **이 프로젝트에서 Claude가 항상 지켜야 할 규칙**을 적는다. 핵심만:

```markdown
# CLAUDE.md — Lucky Draw

## 프로젝트
단일 HTML 파일(lucky-draw.html)로 만드는 2단계 럭키 드로우.
외부 빌드 도구·프레임워크·CDN·localStorage 사용 금지.

## 기술 제약
- HTML5 + 순수 CSS(단일 <style>) + Vanilla JS('use strict', ES2020+)
- 원판=SVG, 컨페티=Canvas 2D, 폰트=시스템 폰트 스택
- var 금지(let/const), 매직 넘버는 상수화, 사용자 입력은 escapeHtml

## 디자인 (AI 흔적 배제)
- 색: 흑/백 + 단일 액센트(빨강). 그라데이션/glassmorphism/다중 그림자 금지
- border-radius 6px 한 값, 카드 분리는 1px 테두리(그림자 X)
- 디스플레이 폰트·이모지 남용·호버 translateY 금지

## 작업 방식
- 코드 전에 PRD → TRD → REQUIREMENTS 순으로 설계 문서를 먼저 만든다
- 구현 후 REQUIREMENTS의 체크리스트를 한 줄씩 검증한다
```

> 💡 강의 포인트: CLAUDE.md는 "재현성"의 핵심이다. 같은 문서·같은 CLAUDE.md면 누가 돌려도 비슷한 결과가 나온다.

---

## STEP 5. 첫 프롬프트 — 설계 문서부터 만들게 하기

코드를 바로 요청하지 않는다. **문서를 먼저** 만들게 한다.

### 5-1. 첫 프롬프트 (PRD)
```
럭키 드로우 사이트를 만들 거야. 아직 코드는 짜지 마.
먼저 PRD.md를 만들어줘. 제품 개요(2단계 추첨), 대상 사용자,
핵심 사용 시나리오, 범위(In/Out), 디자인 원칙(흑백+빨강, AI 흔적 배제)을 담아줘.
```

### 5-2. TRD 프롬프트
```
PRD를 기준으로 TRD.md를 만들어줘.
기술 스택, 파일 구조, 데이터 모델(전역 상태), 상수,
핵심 알고리즘(섹션 구성/번호 추첨/회전 정지 각도/재고 재배정/컨페티),
CSS 디자인 토큰을 정의해줘. 이게 구현의 기술 정본이야.
```

### 5-3. REQUIREMENTS 프롬프트
```
TRD를 기준으로 REQUIREMENTS.md를 만들어줘.
기능 일람(F1~F14), 사용자 스토리 + 수용 기준(체크박스),
상호작용 명세, UI 가이드, 구현 후 검증 체크리스트를 담아줘.
```

> 💡 강의 포인트: **문서 3종을 분리**하는 이유 — PRD(왜·무엇), TRD(어떻게), REQUIREMENTS(검증). 한 문서에 다 넣으면 길어지고 Claude가 핵심을 놓친다. 역할 분리가 곧 컨텍스트 품질.

---

## STEP 6. 단계별 구현 프롬프트 (M0 → M7)

문서가 준비되면 **한 번에 다 만들지 말고** 마일스톤 단위로 쪼개서 요청한다.

| 단계 | 프롬프트 예시 |
|---|---|
| **M0 골격** | `PRD/TRD/REQUIREMENTS를 읽고 lucky-draw.html의 골격을 만들어줘. 디자인 토큰, 레이아웃(grid 1fr 360px), 빈 원판까지.` |
| **M1 입력** | `인원수 입력과 경품 추가/삭제/동일명 병합/검증(shake)/리스트 렌더를 구현해줘.` |
| **M2 원판** | `경품 갯수 합 + 꽝 1칸의 고정 섹션 원판을 SVG로 그려줘. 2색 교차 + 꽝 회색 + 슬라이스 라벨.` |
| **M3 번호 추첨** | `1~N 균등 랜덤·중복 없는 번호 추첨을 ~0.8초 공개로 구현해줘.` |
| **M4 회전** | `TRD §5.4 알고리즘 그대로 경품 원판 회전(5.5s, ease-out)을 구현해줘. 멈춘 슬라이스 = 결과 불변식을 지켜.` |
| **M5 결과+컨페티** | `결과 3중 표시(패널+모달+기록)와 당첨 시에만 Canvas 컨페티를 구현해줘. 접근성(aria-live, Esc)도.` |
| **M6 재고** | `재고 차감 + 재배정(섹션 수 불변, 재고 최다로, 없으면 꽝)과 통계를 구현해줘.` |
| **M7 마무리** | `초기화/예시 불러오기/모바일 360px/prefers-reduced-motion을 마무리해줘.` |

이후 검증:
```
REQUIREMENTS.md의 §6 검증 체크리스트를 한 줄씩 점검하고,
통과 못한 항목을 고쳐줘.
```

> 💡 강의 포인트: 마일스톤 분할의 핵심은 **검증 가능성**. 각 단계마다 "눈으로 확인"이 가능해 오류를 일찍 잡는다. (ANALYSIS.md의 빌드 단계 M0~M7이 바로 이 흐름)

---

## STEP 7. 서버 실행 / 결과 확인

이 프로젝트는 **단일 정적 HTML**이라 빌드·서버가 필요 없다.

### 방법 A — 더블클릭 (가장 간단)
```bash
open project/luckydraw/lucky-draw.html
```

### 방법 B — 로컬 서버 (권장: file:// 제약 회피)
```bash
# Python 내장 서버
python3 -m http.server 8000
# → 브라우저에서 http://localhost:8000/project/luckydraw/lucky-draw.html
```

### 방법 C — VSCode Live Server 확장
- `lucky-draw.html` 우클릭 → **Open with Live Server**

### 산출물 검증
```bash
node --check <(추출한 script)   # JS 문법 OK
wc -c lucky-draw.html           # 100KB 이하 확인
```

---

## STEP 8. 커밋 & 푸시

```bash
git add .
git commit -m "feat: lucky draw 2단계 추첨 구현 + 설계 문서"
git push origin main
```

---

## 한 장 요약 (강의 마무리 슬라이드)

```
1. GitHub 저장소 생성 → VSCode clone
2. claude 실행 → /init 으로 CLAUDE.md 골격
3. 요구사항 한 줄 정의
4. CLAUDE.md에 기술·디자인·작업방식 규칙 주입
5. 첫 프롬프트: 코드 X, PRD → TRD → REQUIREMENTS 문서부터
6. M0~M7 마일스톤 단위로 구현 → 체크리스트 검증
7. open / python http.server 로 실행
8. commit & push
```

**핵심 한 문장**: *"좋은 결과물은 좋은 프롬프트가 아니라 좋은 컨텍스트(CLAUDE.md + 설계 문서)에서 나온다."*
