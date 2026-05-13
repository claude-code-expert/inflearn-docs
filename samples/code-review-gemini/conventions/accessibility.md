## Accessibility (WAI-ARIA / WCAG 2.1 AA)

### 의미 있는 HTML

- 클릭 가능한 요소는 `<button>`. `<div onClick>` 금지 — 키보드 조작과 스크린리더 지원이 사라짐.
- 링크는 `<a href>`, 버튼은 `<button type="button">`. form 안에서는 type 명시 필수 (기본값 submit).
- 헤딩(`h1`~`h6`)은 순서대로. 페이지당 `h1` 1개.

### 입력 / 폼

- 모든 `<input>` 은 `<label htmlFor>` 매칭 또는 `aria-label` 보유.
- placeholder 는 label 대체가 아님.
- 에러 메시지는 `aria-invalid` + `aria-describedby` 로 연결.

### 키보드

- 포커스 가능한 요소는 자연 tab order 유지. `tabIndex={-1}` 은 의도된 케이스에만.
- 모달/드롭다운은 **focus trap** + Esc 닫기 + 스크롤 잠금.
- 키보드 이벤트는 `onKeyDown` 으로 처리하고 Enter/Space 분기.

### 이미지 / 미디어

- `<img>` 는 `alt` 필수. 장식용은 `alt=""`.
- 정보성 SVG 는 `<svg role="img" aria-label="...">`.

### ARIA

- 가능하면 native HTML 먼저. ARIA 는 부족한 부분만.
- `aria-hidden="true"` 인 요소는 포커스 가능하면 안 됨.
- 상태 변화는 `aria-live` (status / alert).

### 색 / 대비

- 텍스트 대비비 4.5:1 (큰 글자 3:1) 이상.
- 색만으로 의미 전달 금지 — 아이콘/텍스트 보조.
