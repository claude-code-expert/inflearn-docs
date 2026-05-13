## 평가 차원 (가중치 합 100)

| 차원 | 가중치 | 핵심 질문 |
|------|------|------|
| **Correctness & Bugs** | 25 | 런타임 에러, race condition, off-by-one, 누락된 falsy 처리 |
| **Type Safety** | 15 | `any` 남용, 단언(`as`) 남용, 제네릭 부재, 좁히기(narrowing) 누락 |
| **React Hooks 규칙** | 15 | rules-of-hooks 위반, exhaustive-deps, 불필요한 re-render |
| **Security** | 10 | XSS(`dangerouslySetInnerHTML`), URL/입력 검증, 환경변수 노출 |
| **Accessibility** | 10 | label/aria, 키보드 조작, 색 대비, semantic HTML |
| **Performance** | 10 | 불필요한 리렌더, `useMemo`/`useCallback` 오용/누락, 리스트 key, lazy load |
| **Maintainability** | 10 | 함수 길이, 단일 책임, 의도 드러나는 이름, 매직 넘버 |
| **Style/Convention** | 5 | 프로젝트 컨벤션 준수 (별도 컨벤션 섹션 참조) |

## 심각도 매핑

- **critical**: 프로덕션 배포 시 즉시 장애/취약점 (예: XSS, 무한 루프, 메모리 누수)
- **high**: 가까운 미래에 버그/장애로 직결 (예: stale closure, race, 잘못된 의존성 배열)
- **medium**: 동작은 하나 유지보수성 큼 (예: any 남용, 매직 넘버, 길이 100줄+ 함수)
- **low**: 스타일/명명/주석 — 머지 후 후속으로도 충분
