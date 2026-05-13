## TypeScript 컨벤션

- `tsconfig` 는 `strict: true` 가 기본. `noImplicitAny`, `strictNullChecks`, `noUncheckedIndexedAccess` 활성.
- **`any` 금지**. 외부 라이브러리 타입 부재 시 `unknown` + 좁히기.
- **타입 단언(`as Foo`) 최소화**. 가능하면 type guard 함수(`isFoo(x): x is Foo`)로 대체.
- **non-null 단언(`!`) 금지** — 대신 분기 처리 또는 invariant 함수 사용.
- 객체 모양은 **`type` 우선, `interface` 는 확장 가능성이 명시적으로 필요할 때만**.
- 함수 시그니처에 **반환 타입 명시** (특히 export 되는 함수).
- 열거 대신 `as const` 객체 + `keyof typeof` 패턴 권장 (`enum` 금지).
- `Record<string, unknown>` 보다 구체 타입을 우선.
- import: `import type { Foo } from '...'` 로 타입-only import 분리.

### 안티패턴 예

```ts
// ❌
function get(x: any) { return x.value; }
const u = users.find(u => u.id === id)!;

// ✅
function get<T extends { value: unknown }>(x: T) { return x.value; }
const u = users.find(u => u.id === id);
if (!u) throw new Error(`user ${id} not found`);
```
