# TRD — Lucky Draw 기술 요구사항 문서

> **참고 문서**: `PRD.md` (비즈니스 요구사항), `REQUIREMENTS.md` (기능 명세 + UI 가이드)
> **구현 대상**: 단일 정적 HTML 파일 `lucky-draw.html`

---

## 1. 기술 스택

### 1.1 사용 기술
| 영역 | 선택 | 이유 |
|---|---|---|
| 마크업 | HTML5 | 표준 |
| 스타일 | 순수 CSS (단일 `<style>` 블록) | 빌드 도구 불필요 |
| 스크립트 | Vanilla JavaScript (ES2020+) | 프레임워크 불필요, 단일 파일 유지 |
| 그래픽 | SVG (휠), Canvas 2D (컨페티) | SVG는 정확한 도형·텍스트, Canvas는 다수 파티클 처리 |
| 폰트 | 시스템 폰트 스택 (`-apple-system`, `Pretendard`, `Noto Sans KR`) | 외부 의존성 회피 |

### 1.2 금지 기술
- React, Vue, Svelte, jQuery 등 모든 라이브러리
- Webpack, Vite, Rollup 등 모든 번들러
- TypeScript (HTML 단일 파일 유지)
- localStorage·sessionStorage (요구사항에 없음, claude.ai artifact 환경 호환성)
- 외부 CDN (Google Fonts는 선택적 — 동작은 시스템 폰트로 보장)
- 추적 코드, 광고 SDK

---

## 2. 파일 구조

```
lucky-draw.html
├── <head>
│   ├── meta (viewport, charset)
│   ├── <title>
│   └── <style>          ← 모든 CSS
└── <body>
    ├── <canvas id="confetti">  ← 컨페티 전용
    ├── .container
    │   ├── header
    │   └── .layout
    │       ├── .wheel-card   ← 휠 + 결과 패널
    │       └── .side         ← 경품 입력 + 기록
    ├── .modal               ← 당첨 모달
    └── <script>             ← 모든 JS
```

---

## 3. 데이터 모델

### 3.1 상태 (전역 변수)

```javascript
// 경품 배열
let prizes = [
  { id: number, name: string, count: number, color: string }
];

// 추첨 진행 중 여부
let isSpinning = false;

// 누적 회전 각도 (도) — 매 회전마다 누적, 휠의 현재 위치
let currentRotation = 0;

// 추첨 횟수
let totalDrawn = 0;

// 당첨 기록
let history = [
  { name: string, time: string }
];
```

### 3.2 불변 규칙
- `prizes` 배열의 순서가 변하면 휠의 슬라이스 위치가 바뀌므로, 추첨 중에는 prizes 변경 금지
- 같은 이름의 경품이 추가되면 새 항목을 만들지 말고 기존 항목의 `count`만 증가시킴
- `count`가 0이 된 경품은 추첨 직후 다음 휠 빌드 시 자동 제외 (배열에서 삭제하거나 필터링)
- `currentRotation`은 항상 누적 — 리셋 시에만 0으로 돌림

---

## 4. 컴포넌트 아키텍처

### 4.1 책임 분리
```
┌──────────────────────────────────────────────┐
│ 입력 모듈     │ addPrize, removePrize, ...   │
├──────────────────────────────────────────────┤
│ 렌더링 모듈   │ buildWheel, renderPrizeList, │
│              │ renderStats, renderHistory   │
├──────────────────────────────────────────────┤
│ 추첨 모듈     │ spin (각도 계산 + transition)│
├──────────────────────────────────────────────┤
│ 효과 모듈     │ confettiBurst, flashBulbs    │
├──────────────────────────────────────────────┤
│ 이벤트 바인딩 │ DOM 이벤트 ← 위 모듈 연결    │
└──────────────────────────────────────────────┘
```

### 4.2 단방향 데이터 흐름
```
사용자 입력
    ↓
상태 변경 (prizes, history, ...)
    ↓
refresh() 호출
    ↓
buildWheel + renderPrizeList + renderStats
    ↓
DOM 갱신
```

`refresh()` 함수가 모든 렌더링의 진입점이 되어 일관성 유지.

---

## 5. 핵심 알고리즘

### 5.1 슬라이스 분할 (가중치 추첨)
경품 갯수의 합만큼 슬라이스를 만든다. 갯수가 많은 경품은 더 많은 슬라이스를 차지하므로 자연스럽게 가중치 추첨이 된다.

```javascript
// 예: [{ name: 'A', count: 3 }, { name: 'B', count: 1 }]
// → units = [A, A, A, B]  // 슬라이스 4개, A가 3/4 확률
const units = [];
prizes.forEach(p => {
  for (let i = 0; i < p.count; i++) units.push(p);
});

const anglePer = 360 / units.length;  // 슬라이스 하나의 각도
```

### 5.2 SVG 슬라이스 path 계산
원의 중심에서 시작 → 시작 각도 점 → 호 → 끝 각도 점 → 중심으로 복귀.

```javascript
function describeSlice(cx, cy, r, startDeg, endDeg) {
  const s = polar(cx, cy, r, startDeg);
  const e = polar(cx, cy, r, endDeg);
  const largeArc = endDeg - startDeg > 180 ? 1 : 0;
  return `M ${cx} ${cy} L ${s.x} ${s.y} A ${r} ${r} 0 ${largeArc} 1 ${e.x} ${e.y} Z`;
}

function polar(cx, cy, r, deg) {
  const rad = deg * Math.PI / 180;
  return { x: cx + r * Math.cos(rad), y: cy + r * Math.sin(rad) };
}
```

**좌표계 합의**: SVG는 0도가 오른쪽(+X), 시계 방향. 휠의 12시 방향은 -90도. 슬라이스는 -90도에서 시작.

### 5.3 회전 정지 각도 계산 (가장 중요)

**불변식**: 휠이 멈췄을 때 포인터(12시 방향, -90도) 아래에 있는 슬라이스 = 당첨 경품.

```javascript
function spin() {
  if (isSpinning) return;
  const units = buildUnitsArray();        // 위 5.1 참조
  if (units.length === 0) return;

  isSpinning = true;
  const winIdx = Math.floor(Math.random() * units.length);
  const winner = units[winIdx];
  const anglePer = 360 / units.length;

  // 당첨 슬라이스의 "중심"이 휠 좌표계에서 어느 각도에 있는가
  //   슬라이스 i의 시작각: i * anglePer - 90
  //   슬라이스 i의 중심각: i * anglePer + anglePer/2 - 90
  const sliceCenter = winIdx * anglePer + anglePer / 2 - 90;

  // 그 중심을 -90도(12시, 포인터 위치)로 끌어오려면
  // 휠을 (-90 - sliceCenter)만큼 회전시켜야 한다
  let targetAngle = -90 - sliceCenter;

  // ±35% 범위의 jitter — 슬라이스 한가운데 너무 정확히 멈추면 부자연스러움
  const jitter = (Math.random() - 0.5) * anglePer * 0.7;
  targetAngle += jitter;

  // 누적 회전 (최소 6~8바퀴) — 시각적 풍성함
  const baseSpins = 6 + Math.floor(Math.random() * 3);
  const currentMod = currentRotation % 360;
  const deltaToTarget = ((targetAngle - currentMod) + 720) % 360;
  currentRotation += baseSpins * 360 + deltaToTarget;

  wheelEl.style.transform = `rotate(${currentRotation}deg)`;

  // CSS transition 종료 후 결과 처리
  setTimeout(() => onSpinEnd(winner), SPIN_DURATION_MS);
}
```

**검증 방법**: 슬라이스 갯수가 4일 때, `winIdx=0`이면 첫 슬라이스가 12시 방향에 멈춰야 한다. `winIdx=2`이면 휠이 절반 회전한 위치(원래 6시였던 슬라이스가 12시로 올라옴)에 멈춰야 한다.

### 5.4 CSS Transition (회전 감속)

```css
.wheel-svg {
  transition: transform 5.5s cubic-bezier(0.17, 0.67, 0.12, 0.99);
}
```

`cubic-bezier(0.17, 0.67, 0.12, 0.99)`은 처음에 빠르게 가속, 끝에서 매우 느리게 감속 — 실제 룰렛의 관성 느낌과 가장 유사. 다른 값을 쓰지 말 것.

### 5.5 컨페티 (Canvas 2D)

물리 시뮬레이션:
- 각 파티클은 위치(x, y), 속도(vx, vy), 중력(g), 크기, 색, 회전각, 회전속도를 가짐
- 매 프레임: `vy += g`, `x += vx`, `y += vy`, `rot += vr`
- 화면 아래로 떨어진 파티클은 배열에서 제거
- 모든 파티클이 사라지면 `requestAnimationFrame` 루프 중단

```javascript
function confettiBurst() {
  const w = innerWidth, h = innerHeight;
  for (let i = 0; i < 180; i++) {
    particles.push({
      x: w / 2 + (Math.random() - 0.5) * 100,
      y: h / 2 - 50,
      vx: (Math.random() - 0.5) * 14,
      vy: -Math.random() * 18 - 4,
      g: 0.35 + Math.random() * 0.15,
      size: 6 + Math.random() * 8,
      color: pickPaletteColor(),
      rot: Math.random() * 360,
      vr: (Math.random() - 0.5) * 12,
      shape: Math.random() > 0.5 ? 'rect' : 'circle'
    });
  }
  if (!running) { running = true; requestAnimationFrame(loop); }
}
```

파티클 수는 **총 360개 이하**로 제한 (메인 180개 + 좌우 측면 80개씩). 그 이상은 저사양 기기에서 부담.

---

## 6. CSS 설계 원칙

### 6.1 CSS 변수 (필수)

```css
:root {
  /* 색상 — REQUIREMENTS.md의 디자인 가이드 준수 */
  --bg:        #FFFFFF;       /* 페이지 배경 */
  --surface:   #FAFAFA;       /* 카드 배경 */
  --border:    #E5E5E5;       /* 테두리 (1px만 사용) */
  --text:      #111111;       /* 본문 텍스트 */
  --muted:     #737373;       /* 보조 텍스트 */
  --accent:    #DC2626;       /* 단일 액센트 (빨강) */
  --accent-d:  #B91C1C;       /* 액센트 hover */

  /* 휠 슬라이스 팔레트 — 무지개 X, 2색 교차 */
  --wheel-a:   #111111;       /* 슬라이스 색상 A (검정) */
  --wheel-b:   #FAFAFA;       /* 슬라이스 색상 B (회백색) */
  --wheel-text-on-a: #FAFAFA; /* A 위 글자색 */
  --wheel-text-on-b: #111111; /* B 위 글자색 */

  /* 간격 — 4px 단위 */
  --space-1: 4px;
  --space-2: 8px;
  --space-3: 12px;
  --space-4: 16px;
  --space-6: 24px;
  --space-8: 32px;

  /* 모서리 — 한 가지 값만 */
  --radius: 6px;
}
```

### 6.2 금지 CSS 속성·값
- `backdrop-filter` 전부 (glassmorphism 차단)
- `background: linear-gradient(...)` 3색 이상 (장식용 그라데이션 차단)
- `-webkit-background-clip: text` (그라데이션 텍스트 차단)
- `box-shadow` 다중 레이어 (`box-shadow: 0 0 0 X, 0 0 0 Y, ...`)
- `filter: drop-shadow(...)` 장식용
- `text-shadow` 장식용

### 6.3 허용되는 효과
- `box-shadow: 0 1px 3px rgba(0,0,0,0.08)` 정도의 단일 그림자만 (카드 부각용)
- `transition` 모든 속성에 200~300ms ease-out
- `transform: scale/translate/rotate` (애니메이션 본질에 필요)
- `:hover`에서 색상·테두리 변경 (그림자·크기 변경은 자제)

---

## 7. 성능 요구사항

| 항목 | 목표 |
|---|---|
| 초기 로드 (HTML 파싱 + 첫 렌더) | < 100ms |
| SPIN 클릭 → 휠 회전 시작 | < 50ms |
| 휠 회전 중 프레임률 | 60fps (CSS transition이므로 GPU 가속) |
| 컨페티 360개 동시 표시 시 프레임률 | ≥ 30fps |
| 100개 경품 등록 후 휠 빌드 | < 100ms |

### 7.1 최적화 가이드
- 휠은 SVG로 그리되, 슬라이스 갯수가 100을 넘으면 라벨을 생략 (각도가 너무 좁음)
- DOM 조작은 가능한 한 `innerHTML`로 batch 처리, 개별 `appendChild` 반복 회피
- 회전 애니메이션은 CSS `transform`으로 처리 (JS `setInterval` 사용 금지)
- 컨페티 파티클은 매 프레임 배열 필터링하여 자동 정리

---

## 8. 브라우저 호환성

| 브라우저 | 최소 버전 | 비고 |
|---|---|---|
| Chrome / Edge | 90+ | 주요 타겟 |
| Safari | 14+ | iOS 포함 |
| Firefox | 88+ | |
| 모바일 Safari (iOS) | 14+ | 터치 이벤트 호환 |
| 모바일 Chrome (Android) | 90+ | |

ES2020+ 문법(optional chaining, nullish coalescing) 자유롭게 사용 가능.

---

## 9. 접근성 (a11y)

| 요구사항 | 구현 방법 |
|---|---|
| 키보드 전용 조작 | 모든 button·input이 tab 이동 가능, Enter로 추가/SPIN 실행 |
| 색맹 대응 | 휠 슬라이스의 구분이 색에만 의존하지 않도록 슬라이스 안에 텍스트 라벨 |
| 스크린 리더 | 결과 표시 영역에 `aria-live="polite"` 부여 |
| 클릭 영역 | 모든 버튼 최소 44×44px 확보 |
| 색 대비 | 본문 텍스트 4.5:1 이상 |
| 동작 감소 옵션 | `@media (prefers-reduced-motion: reduce)` 시 회전 시간 단축(1초), 컨페티 생략 |

---

## 10. 보안·개인정보

- 사용자 입력은 모두 클라이언트 단에 머무름 (서버 전송 없음)
- 외부 스크립트 로드 없음 (XSS 표면 최소화)
- 사용자가 입력한 상품명은 DOM에 표시할 때 반드시 escape 처리

```javascript
function escapeHtml(s) {
  return s.replace(/[&<>"']/g, ch => ({
    '&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;'
  }[ch]));
}
```

---

## 11. 코드 스타일

- 들여쓰기: 2 spaces
- 세미콜론: 사용
- 따옴표: 작은 따옴표 우선 (`'`)
- 변수: `let`·`const`만 (var 금지)
- 함수: 최상위는 `function`, 콜백·짧은 함수는 화살표
- 한 함수의 책임은 하나 (단일 책임 원칙)
- 매직 넘버는 상수로 추출

```javascript
const SPIN_DURATION_MS  = 5500;
const MIN_SPINS         = 6;
const MAX_EXTRA_SPINS   = 3;
const PARTICLE_COUNT    = 180;
const WHEEL_RADIUS      = 98;
```

---

## 12. 테스트 시나리오 (수동 QA)

| 시나리오 | 기대 결과 |
|---|---|
| 경품 0개 상태에서 SPIN 클릭 | 아무 동작 없음 (버튼 disabled) |
| 같은 이름 경품 두 번 추가 | 갯수만 증가, 항목은 하나 |
| 갯수 0 입력하고 추가 | 추가 안 됨, 입력 필드 shake 피드백 |
| 100개 단일 경품으로 SPIN | 그 경품 당첨, 갯수 99로 차감 |
| 한 경품의 마지막 1개 당첨 | 휠에서 제거, 다음 SPIN 시 다른 경품으로만 추첨 |
| 모든 경품 소진 후 | SPIN 버튼 비활성화, 빈 휠 표시 |
| 모바일 360px 너비 | 휠과 입력 패널이 세로로 정렬, 휠 잘리지 않음 |
| 키보드만 사용 | Tab → 상품명 → 갯수 → 추가, Tab → SPIN → Enter |
| 추첨 중 추가 SPIN 클릭 | 무시 (가드) |
| 회전 종료 후 결과 = 휠 정지 위치 | 시각적으로 일치해야 함 (가장 중요) |

---

## 13. 산출물 확인

```bash
# 단일 파일 검증
file lucky-draw.html              # HTML document, UTF-8
wc -c lucky-draw.html              # 50,000~100,000 byte 사이 권장
node --check <(extract-script)     # JS 문법 OK

# 브라우저 검증
open lucky-draw.html               # 즉시 동작해야 함
```
