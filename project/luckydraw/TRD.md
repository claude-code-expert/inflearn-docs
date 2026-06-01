# TRD — Lucky Draw 기술 요구사항

> **역할**: 구현(`lucky-draw.html`)의 **기술 정본(single source of truth)**. 데이터 모델·알고리즘·CSS 토큰·상수는 여기에만 정의하고, 다른 문서는 이 문서를 참조한다.
> **참고**: `PRD.md`(목적·범위), `REQUIREMENTS.md`(기능·UI·검증), `ANALYSIS.md`(결정·이력)
> **구현 대상**: 단일 정적 HTML 파일.

---

## 1. 기술 스택

| 영역 | 선택 | 이유 |
|---|---|---|
| 마크업 | HTML5 | 표준 |
| 스타일 | 순수 CSS (단일 `<style>`) | 빌드 도구 불필요 |
| 스크립트 | Vanilla JS (ES2020+, `'use strict'`) | 프레임워크 불필요, 단일 파일 유지 |
| 그래픽 | SVG(원판), Canvas 2D(컨페티) | SVG=정확한 도형·텍스트, Canvas=다수 파티클 |
| 폰트 | 시스템 폰트 스택 | 외부 의존성 회피 |

**금지**: 모든 라이브러리·번들러·TypeScript·localStorage/sessionStorage·외부 CDN·추적/광고 SDK.

---

## 2. 파일 구조

```
lucky-draw.html
├── <head><style>            ← 모든 CSS (디자인 토큰 §6)
└── <body>
    ├── <canvas id="confetti">         ← 컨페티 (전체 화면, z-index 200)
    ├── .container
    │   ├── header
    │   └── .layout (grid 1fr 360px)
    │       ├── .wheel-card    ← 원판 SVG + 12시 포인터 + 번호 배지 + 결과 패널 + SPIN
    │       └── .side          ← 인원수 입력 · 경품 입력/리스트 · 통계 · 기록 · 예시/초기화
    ├── #modal (.modal)        ← 당첨 모달
    └── <script>              ← 모든 JS
```

---

## 3. 데이터 모델

### 3.1 상태 (전역)

```javascript
let prizes = [];              // { id:number, name:string, count:number }  — 색 필드 없음(원판은 2색 교차)
let sections = [];            // (prizeId | 'BLANK')[]  — 고정 길이 S = (경품 갯수 합) + 1(꽝)
let participantCount = 0;     // N (번호 풀 1..N)
let drawnNumbers = new Set(); // 이미 뽑힌 번호 (중복 방지)
let currentNumber = null;     // 직전 추첨 번호
let isSpinning = false;       // 추첨(번호 공개 + 회전) 진행 중
let currentRotation = 0;      // 누적 회전 각도(도). 리셋 시에만 0
let history = [];             // { number:number, name:string, time:'HH:MM:SS' }  — 최신이 위로 표시
```

### 3.2 불변 규칙
- **동일 이름 경품**은 새 항목을 만들지 않고 기존 `count`만 증가(색·id 유지).
- `sections`는 **추첨 세션 동안 길이 고정**. 셋업 단계(`drawnNumbers.size === 0 && !isSpinning`)에서만 `prizes`로부터 재구성하고, 추첨 중에는 **재배정(라벨 교체)만** 한다 — 삭제·길이 변경 금지.
- `count`가 0이 된 경품도 **리스트에는 회색으로 남긴다**(원판에서는 재배정으로 제외).
- `currentRotation`은 항상 누적, 리셋 시에만 0.
- 회전 중에는 `prizes`·`sections`·`participantCount` 변경 금지(입력 잠금).

### 3.3 상수

```javascript
const SPIN_DURATION_MS = 5500;   // 원판 회전 시간(=CSS transition)
const REDUCED_SPIN_MS  = 1000;   // prefers-reduced-motion 시 회전 시간
const NUMBER_REVEAL_MS = 800;    // 번호 공개 시간
const MIN_SPINS        = 6;      // 최소 회전 바퀴
const MAX_EXTRA_SPINS  = 3;      // 추가 바퀴(0~2) → 총 6~8바퀴
const PARTICLE_COUNT   = 180;    // 컨페티 중앙 발사 수
const WHEEL_RADIUS     = 98;     // SVG viewBox 200×200 기준 반지름
const MAX_COUNT        = 999;    // 인원·갯수 상한
const BLANK            = 'BLANK';// 꽝 섹션 식별자
```

---

## 4. 단방향 데이터 흐름

```
사용자 입력 → 상태 변경 → refresh() → buildWheel · renderPrizeList · renderStats · renderHistory · updateSpinButton → DOM
```
`refresh()`가 모든 렌더의 단일 진입점. 추첨 흐름은 `startDraw() → drawNumber()/revealNumber() → spin() → onSpinEnd()`.

---

## 5. 핵심 알고리즘

### 5.1 섹션 구성 (가중치 + 꽝)
경품을 `count`만큼 펼쳐 units를 만들고 **꽝 1칸**을 더한다. 갯수가 많을수록 칸이 많아 자연스러운 가중치가 된다.

```javascript
const units = [];
prizes.forEach(p => { for (let i = 0; i < p.count; i++) units.push(p.id); });
sections = units.length ? units.concat([BLANK]) : [];   // 경품 0개면 빈 휠(자리표시)
// 예: 키보드2+마우스3+스벅3 = units 8 → S = 9 (꽝 포함)
```

### 5.2 SVG 슬라이스 path
0도=오른쪽(+X), 시계방향, 12시=-90도. 슬라이스 i: `[i*anglePer-90, (i+1)*anglePer-90]`.

```javascript
function polar(cx, cy, r, deg) {
  const rad = deg * Math.PI / 180;
  return { x: cx + r * Math.cos(rad), y: cy + r * Math.sin(rad) };
}
function describeSlice(cx, cy, r, s, e) {
  const a = polar(cx, cy, r, s), b = polar(cx, cy, r, e);
  const large = e - s > 180 ? 1 : 0;
  return `M ${cx} ${cy} L ${a.x} ${a.y} A ${r} ${r} 0 ${large} 1 ${b.x} ${b.y} Z`;
}
```

**색·라벨 규칙**:
- 짝수 인덱스 = 검정(`--wheel-a`, 글자 흰색), 홀수 = 백색(`--wheel-b`, 글자 검정).
- **꽝 칸 = 중립 회색 `#D4D4D4`**(글자 검정). 액센트(빨강)는 슬라이스에 쓰지 않는다.
- 라벨 텍스트 = 경품명(또는 "꽝"). `각도 < 10°`(S>36)면 라벨 생략. `S ≥ 12`면 `max(2, floor(anglePer/3))`자로 truncate(`…`). 폰트 크기 `S>18 ? 5 : 6.5`. 라벨 위치 = 반지름 0.62r, 중심각으로 회전하되 90°<각<270°면 +180°(뒤집힘 방지).
- 중심 허브 원 r=10.

### 5.3 번호 추첨 (균등 · 중복 없음)

```javascript
function drawNumber() {
  const pool = [];
  for (let n = 1; n <= participantCount; n++) if (!drawnNumbers.has(n)) pool.push(n);
  if (pool.length === 0) return null;            // 모든 번호 소진
  const picked = pool[Math.floor(Math.random() * pool.length)];
  drawnNumbers.add(picked); currentNumber = picked;
  return picked;
}
```
공개: `NUMBER_REVEAL_MS` 동안 숫자 플리커(setInterval 60ms) 후 확정. `prefers-reduced-motion`이면 즉시 공개. (이 setInterval은 숫자 표시용이며 §5.4의 원판 회전과 무관.)

### 5.4 회전 정지 각도 (가장 중요 — 변경 금지)

**불변식 ⭐**: 회전이 멈췄을 때 12시 포인터 아래 슬라이스(`winIdx`) = 결과. 검증 완료(S=2·5·9·18·37, 각 5000회 편차 ≤ 슬라이스 반각).

```javascript
function spin(number) {
  const S = sections.length, anglePer = 360 / S;
  const winIdx = Math.floor(Math.random() * S);
  const sliceCenter = winIdx * anglePer + anglePer / 2 - 90;
  let targetAngle = -90 - sliceCenter;
  targetAngle += (Math.random() - 0.5) * anglePer * 0.7;     // ±35% jitter
  const baseSpins = MIN_SPINS + Math.floor(Math.random() * MAX_EXTRA_SPINS);
  const currentMod = currentRotation % 360;
  const deltaToTarget = ((targetAngle - currentMod) + 720) % 360;
  currentRotation += baseSpins * 360 + deltaToTarget;
  wheelEl.style.transform = `rotate(${currentRotation}deg)`;
  const dur = prefersReducedMotion() ? REDUCED_SPIN_MS : SPIN_DURATION_MS;
  setTimeout(() => onSpinEnd(winIdx, number), dur);
}
```

CSS transition(원판 회전, JS setInterval 금지):
```css
.wheel-svg { transform-origin: 50% 50%;
             transition: transform 5.5s cubic-bezier(0.17, 0.67, 0.12, 0.99); }
@media (prefers-reduced-motion: reduce) { .wheel-svg { transition: transform 1s ease-out !important; } }
```

### 5.5 재고 차감 + 재배정 (섹션 수 불변)
당첨(경품) 시 `count--`. 0이 되면 그 경품의 모든 섹션을 **재고 최다 경품(동률은 등록순)**으로 교체, 재고 있는 경품이 없으면 **꽝**으로. 꽝 당첨은 차감 없음.

```javascript
function reassignDepleted(depletedId) {
  let target = null;
  for (const p of prizes) if (p.count > 0 && (target === null || p.count > target.count)) target = p;
  const fill = target ? target.id : BLANK;
  sections = sections.map(s => (s === depletedId ? fill : s));   // 길이 불변
}
```
> 트레이드오프: 섹션 수 고정으로 **확률이 잔여 재고와 정확히 비례하지 않는다**(소진 시 자기보정). 시각 안정성·단순성 우선의 의도된 선택.

### 5.6 컨페티 (Canvas 2D, 당첨만)
중력 시뮬레이션. 중앙 `PARTICLE_COUNT`개 + 0.2초 후 좌(`w*0.2`)·0.4초 후 우(`w*0.8`) 80개씩, **총 360개 이하**. 매 프레임 `vy+=g; x+=vx; y+=vy; rot+=vr`, 화면 밖 파티클 제거, 모두 사라지면 `requestAnimationFrame` 중단. 팔레트 = **`['#111111','#404040','#737373','#DC2626']`**(흑·회색·빨강, 무지개 금지). `prefers-reduced-motion`이면 생략. 꽝은 발사 안 함.

---

## 6. CSS 설계

### 6.1 디자인 토큰 (정본)
```css
:root{
  --bg:#FFFFFF; --surface:#FAFAFA; --border:#E5E5E5; --text:#111111; --muted:#737373;
  --accent:#DC2626; --accent-d:#B91C1C;            /* 단일 액센트(빨강) — 포인터·SPIN에만 */
  --wheel-a:#111111; --wheel-b:#FAFAFA;            /* 원판 2색 교차 */
  --wheel-text-on-a:#FAFAFA; --wheel-text-on-b:#111111;
  --space-1:4px; --space-2:8px; --space-3:12px; --space-4:16px; --space-6:24px; --space-8:32px;
  --radius:6px;
}
```

### 6.2 금지 / 허용
- **금지**: `linear/radial-gradient`(장식 배경), `-webkit-background-clip:text`, `backdrop-filter`, 다중 `box-shadow`, 장식용 `filter:drop-shadow`/`text-shadow`, 액센트 색 슬라이스, 무지개/네온 팔레트.
- **허용**: 카드 분리는 1px 테두리(그림자는 쓰지 않음), `transition` 200~300ms, 애니메이션 본질에 필요한 `transform`, hover 시 색·테두리 변경(translateY 금지). 모달 fade/scale 0.3s, SPIN 호버 배경색 변경.

---

## 7. 성능 · 호환성 · 접근성 · 보안

| 항목 | 기준 |
|---|---|
| 초기 렌더 | < 200ms |
| 회전 프레임률 | 60fps (CSS transform, GPU) |
| 컨페티(≤360개) | ≥ 30fps |
| 브라우저 | Chrome/Edge 90+, Safari 14+(iOS), Firefox 88+ |
| 접근성 | Tab 전체 조작, input Enter=추가, 결과·번호 영역 `aria-live="polite"`, 모달 `role=dialog`/Esc·포커스 관리, 텍스트 대비 4.5:1, `prefers-reduced-motion`(회전 1s·컨페티 생략·모달 애니 없음). 주요 버튼 ≥44px(경품 삭제 X는 36px) |
| 보안 | 입력은 클라이언트에만 머무름, 외부 스크립트 없음, 사용자 입력은 `escapeHtml`로 이스케이프 |

```javascript
function escapeHtml(s){return String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));}
```

---

## 8. 코드 스타일
들여쓰기 2 spaces · 세미콜론 사용 · 작은따옴표 우선 · `let`/`const`만(`var` 금지) · 최상위는 `function` 선언, 콜백은 화살표 · 단일 책임 · 매직 넘버는 §3.3 상수로 추출.

---

## 9. 산출물 검증
```bash
file lucky-draw.html        # HTML document, UTF-8
wc -c lucky-draw.html       # 100KB 이하 (현재 ~30KB)
# <script> 추출 후: node --check  → 문법 OK / var 0건 / 외부 의존성 0
open lucky-draw.html        # 더블클릭으로 즉시 동작 (서버 불필요)
```
