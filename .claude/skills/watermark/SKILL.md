---
name: watermark
description: Apply the house run-ai.kr / brewnet.dev watermark (faint repeating diagonal text overlay) to an HTML document. Use when creating or updating any run-ai.kr guide/doc HTML that should carry the standard watermark, or when an existing doc's watermark needs to match the canonical look (darkness/size).
---

# run-ai.kr 워터마크 적용

모든 run-ai.kr 가이드 HTML에 **고스란히 동일하게** 들어가야 하는 표준 워터마크입니다.
화면 전체에 옅게 반복되는 대각선 텍스트(`run-ai.kr   brewnet.dev@gmail.com`)이며, 클릭을 방해하지 않습니다.

## 적용 방법

HTML의 `<style>` 블록 안, `body { ... }` 규칙 바로 아래에 다음을 **그대로** 붙여넣습니다.

```css
  /* 워터마크 — 화면 전체에 옅게 반복(클릭 방해 없음) */
  body::before {
    content: ""; position: fixed; inset: 0; z-index: 9999; pointer-events: none; opacity: .12;
    background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='360' height='240'%3E%3Ctext x='15' y='130' font-family='monospace' font-size='19' fill='%23111111' transform='rotate(-30 180 120)'%3Erun-ai.kr%20%20%20brewnet.dev%40gmail.com%3C/text%3E%3C/svg%3E");
    background-repeat: repeat;
  }
```

이미 워터마크가 있는 문서를 이 표준에 맞출 때는 기존 `body::before` 블록을 위 내용으로 교체합니다.

## 캐논 값 (이 값을 기준으로 유지)

| 항목 | 값 | 의미 |
|---|---|---|
| `opacity` | `.12` | 체감 진하기/선명도. 색(`fill`)이 이미 검정이라 **가시성은 opacity로 조절**한다. |
| `font-size` | `19` | 워터마크 글자 크기. |
| `fill` | `%23111111` (#111111) | 검정. 더 진하게 하려면 색이 아니라 opacity를 올린다. |
| `transform` | `rotate(-30 180 120)` | 대각선 각도. |
| tile | `360 × 240`, `background-repeat: repeat` | 반복 타일 크기. |

## 중요 — 이메일은 반드시 `%40`으로 인코딩

워터마크 텍스트의 이메일은 `brewnet.dev@gmail.com`이 아니라 **`brewnet.dev%40gmail.com`** (`@` → `%40`)으로 둔다.

- 이유: 리터럴 `@`가 있으면 **Cloudflare Email Address Obfuscation**이 이메일로 감지해 외부 디코드 스크립트(`email-decode.min.js`)를 주입하고, 호스팅 환경(예: `<iframe srcdoc>` + 엄격한 CSP)에서 그 스크립트가 차단되어 콘솔에 CSP 에러가 난다.
- `%40`은 브라우저가 data-URI를 파싱할 때 `@`로 디코드되므로 **화면 표시는 동일**하지만, HTML 소스에는 리터럴 이메일이 없어 Cloudflare가 감지하지 못한다.

## 조절 가이드

- 워터마크가 **안 보이면**: `opacity`를 한 단계 올린다 (`.08` → `.12` → `.16`). `fill`을 바꾸지 말 것.
- 글자가 **너무 작/크면**: `font-size`를 조정한다(기본 `19`). 19 기준 텍스트 폭은 타일 너비 360 안에 들어간다.
- 인쇄(`@media print`)에서 숨기고 싶으면 `body::before { display:none }`를 print 미디어쿼리에 추가(선택).
