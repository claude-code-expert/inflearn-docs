## React 컨벤션

### Hooks

- **rules-of-hooks**: 조건문/반복문/중첩 함수 안에서 hook 호출 금지.
- **exhaustive-deps**: `useEffect` / `useMemo` / `useCallback` 의존성 배열에 참조하는 모든 reactive value 포함.
- `useEffect` 안에서 **state 를 set 하는 무한 루프** 주의 — 새 객체/배열 참조를 deps 에 두면 안 됨.
- cleanup 함수 누락 금지 (구독, 타이머, AbortController).
- 동기 계산은 `useEffect` 가 아니라 렌더링 본문에서 — `useEffect` 는 "외부 시스템과의 동기화" 용도.

### 컴포넌트

- 함수 컴포넌트 + named export. `default export` 지양 (검색성/리팩토링 안전성).
- props 는 **destructuring** 으로 받고, `Props` 타입을 명시.
- **prop 직접 변경 금지**. 입력은 불변으로 취급.
- 리스트 렌더링 시 `key` 는 **안정적 고유 id**. index 사용은 추가/삭제 없는 정적 리스트에서만.
- 조건부 렌더링은 `&&` 보다 삼항 또는 early return 권장 (`0 && <X />` 함정 회피).
- 인라인 스타일/객체/함수는 자식이 memoized 일 때만 주의. 그 외에는 가독성 우선.

### 상태

- 파생 상태(derived state)는 state 가 아니라 **계산식** 또는 `useMemo`.
- 서버 상태는 React Query/SWR/RTK Query 등 전용 도구.  `useEffect + setState` 로 fetch 직접 X.

### 안티패턴 예

```tsx
// ❌
useEffect(() => {
  fetchUser().then(setUser);
}, []);  // user 의존성 누락 + 클린업 누락

// ✅
useEffect(() => {
  const ac = new AbortController();
  fetchUser({ signal: ac.signal }).then(setUser);
  return () => ac.abort();
}, []);
```
