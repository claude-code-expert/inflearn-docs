<!--
================================================================
문서 메타
================================================================
원본 작성일: 2026-02-14
정정본 작성일: 2026-05-13

[정정 사유 총괄]
Java/Spring 백엔드의 핵심 영역 보강. 

🔧 구조 개선 3건:
  1. 메타 룰(조사 원칙·언어 규칙) → 상단으로 이동
  2. 작업 규칙 ↔ 가드레일 중복 제거 (필드 주입 금지)
  3. 작업 규칙에 흩어진 정책 → 항목별로 묶음

================================================================
-->

# AGENTS.md

## 프로젝트 개요

Spring Boot 3.4 기반 Java 백엔드 API 서버.
Java 21(LTS), Layered Architecture.

---


## 메타 룰

### 언어
- 코드 · 변수명 · 주석 · 커밋 메시지: **영어**
- 사용자 응답 · 요약 · 설명: **한국어**

### 조사
- 경로 · 설정값 · 동작 방식은 **소스 코드를 먼저 읽고 답할 것**. 추측 금지
- `/compact` 후 새 세션 시작 시 본 AGENTS.md를 다시 읽고 컨텍스트 재확립

---

## 기술 스택


| 영역 | 기술 | 버전 |
|------|------|------|
| Language | Java | 21 (LTS) |
| Framework | Spring Boot | 3.4.x |
| ORM | Spring Data JPA | (Spring Boot 관리) |
| Query Builder | QueryDSL | 5.1.0 (`jakarta` classifier) |
| DB | PostgreSQL · Redis (cache) | 16.x · 7.x |
| Migration | Flyway | (Spring Boot 관리) |
| Build | Gradle Kotlin DSL | 8.x |
| Test | JUnit5 · Mockito · AssertJ · Testcontainers | — |
| Lint·Format | Spotless (google-java-format) | — |

---

## 명령어

```bash
./gradlew bootRun              # 개발 서버 실행
./gradlew clean build          # 전체 빌드 (테스트 포함)
./gradlew test                 # 전체 테스트
./gradlew check                # 테스트 + 린트 + 스타일
./gradlew spotlessApply        # 코드 포맷팅 자동 수정
./gradlew flywayMigrate        # DB 마이그레이션 수동 실행
docker-compose up -d           # 로컬 인프라 (DB · Redis)
```

---

## 프로젝트 구조 (분리 권장)

```
src/main/java/com/example/app/
├── domain/       Entity · VO · 도메인 핵심 로직 (외부 의존성 최소화)
├── repository/   Spring Data JPA · QueryDSL Repository
├── service/      비즈니스 로직 · 트랜잭션 경계 ★
├── controller/   REST API 엔드포인트 · 입력 검증
├── dto/          계층 간 데이터 전송 (record 권장)
├── config/       보안 · DB · Swagger 등 설정
└── common/       글로벌 예외 처리 · 유틸

src/main/resources/
└── db/migration/ Flyway 마이그레이션 (V1__init.sql 형식)
```

### 계층 경계 규칙

- **Controller** → Service만 호출. Repository 직접 접근 금지
- **Service** → Repository · 다른 Service 호출 가능
- **Repository** → 다른 계층 의존 금지 (domain Entity만 사용)
- **Domain** → 외부 프레임워크 의존 최소화 (JPA 어노테이션 외에는 가능한 한 순수 Java)

---

## 코딩 컨벤션 (분리 권장)

### 객체 설계
- DTO는 Java `record` 사용 (불변 + boilerplate 제거)
<!-- ✏️ 정정 2: "Entity 필드 불변" 표현이 JPA 현실과 충돌. 정확하게 표현. -->
- Entity의 **public setter 금지**. 상태 변경은 의미 있는 비즈니스 메서드로만
  (예: `order.cancel()`, `user.changeEmail(newEmail)`)
- 의존성 주입: **생성자 주입만 허용**
<!-- ✏️ 정정 3: Lombok 미사용 케이스 포함. -->
  - Lombok 사용 시 `@RequiredArgsConstructor`
  - Lombok 미사용 시 명시적 생성자

### 네이밍
- 클래스: PascalCase
- 메서드·변수: camelCase
- 상수: UPPER_SNAKE_CASE
- 패키지: 소문자, 점으로 구분


### 트랜잭션
- `@Transactional`은 **Service 계층에만**. Controller · Repository 금지
- 조회 메서드는 `@Transactional(readOnly = true)` 필수 (1차 캐시 dirty check 생략)
- propagation 기본값(`REQUIRED`) 유지. 변경은 합의 후
- ⚠️ **Self-invocation 금지** — 같은 Service 내부 메서드 호출은 proxy를 우회해
  `@Transactional`이 작동하지 않음


### API 응답 · 에러
- 성공: `ResponseEntity<T>` 또는 `ResponseEntity<ApiResponse<T>>`
- 에러: **RFC 7807 ProblemDetail** (`ResponseEntity<ProblemDetail>`)
- HTTP 상태: 비즈니스 에러 400대, 시스템 에러 500대
- 일괄 처리: `@RestControllerAdvice` + `@ExceptionHandler`
- ⚠️ Controller에서 try-catch로 응답 만들지 말 것 → ControllerAdvice가 처리

### 로깅
- SLF4J 로거만 사용. `System.out.println` · `e.printStackTrace()` 금지
- 빈 `catch` 블록 금지 — 로그 기록 또는 예외 재발생
- ⚠️ **PII 로그 금지** — 이메일 · 전화번호 · 토큰 · 비밀번호 절대 금지

---

## 테스트 규칙

### 명명 컨벤션
- 메서드: `methodName_condition_expected`
  - 예: `createOrder_whenStockSufficient_thenReturnsOrderId`
- 클래스: `<대상>Test` (단위), `<대상>IntegrationTest` (통합)

### 정책
| 종류 | 도구 | 정책 |
|------|------|------|
| 단위 | JUnit5 + Mockito + AssertJ | Service 로직. Mock 적극 활용. PR 필수 |
| 통합 | @SpringBootTest + Testcontainers | DB · Redis 실제 컨테이너. 핵심 시나리오만 |
| E2E | RestAssured · MockMvc | API 외부 인터페이스. 최소화 |

### Testcontainers 사용
- PostgreSQL · Redis 컨테이너는 `@Container` static 필드로 재사용
- `@DynamicPropertySource`로 datasource URL 주입
- 통합 테스트는 `*IntegrationTest`로 명명 → CI에서 분리 실행 가능

---

## 작업 규칙

### 워크플로
1. Task 시작 전 관련 코드 읽기 (조사 원칙 적용)
2. 단위 테스트 먼저 작성 (TDD: Red)
3. 최소 구현으로 통과 (Green)
4. 리팩터 (Refactor)
5. `./gradlew check` 통과 확인 (테스트 + 린트)
6. 커밋

### 일반 원칙
- 모든 코드는 `docs/PATTERNS.md`의 구조를 따른다
- 스키마 변경 시 **Flyway 마이그레이션 파일만** — 직접 SQL 금지
- 신규 기능에는 반드시 단위 테스트 포함

---

## 🚨 금지 사항

<!--
⚠️ 중요: AGENTS.md 금지는 advisory(권고)다.
핵심 금지(force push · prod DB · 자동 push)는 git pre-commit · CI · Claude Code Hook으로 결정론적 차단을 병행할 것.
-->

### Git
- `git push --force`, `git reset --hard`, `git commit --no-verify` 금지
- 자동 커밋·푸시 금지 — 사용자 명시 요청 시에만
- main 브랜치 직접 push 금지 (PR 경유)

### DB
- Flyway 마이그레이션 파일 **수동 편집 금지** (이미 적용된 파일)
- 프로덕션 DB 직접 변경 금지
- raw SQL 문자열 보간 금지 — JPQL · Criteria · QueryDSL만


### 객체 생성·DI
- Spring 빈(`ObjectMapper`, `RestTemplate` 등)을 `new`로 생성 금지 — 주입받기
- 필드 주입(`@Autowired`) 금지 — 생성자 주입만 (위 코딩 컨벤션 참조)


### 보안
- secret(JWT 키 · DB 비번 · API 키)은 `application.yml` 노출 금지 — 환경변수 또는 Vault
- `@PreAuthorize`는 Service 계층. Controller는 `hasRole`까지만
- 사용자 입력은 `@Valid` + Bean Validation 필수
- 응답에 Entity 직접 반환 금지 — 항상 DTO 변환 (민감 정보 노출 방지)

---


## 참조 문서 (필요 시 읽기)

| 주제 | 경로 |
|------|------|
| 코드 패턴 레퍼런스 | `@docs/PATTERNS.md` |
| API 명세 (OpenAPI) | `@docs/api/openapi.yml` |
| DB 스키마 · ERD | `@docs/DATA_MODEL.md` |
| 보안 가이드 | `@docs/SECURITY.md` |

상세 정보가 필요한 task일 때만 위 문서를 추가로 읽는다.

---

<!--
📦 [분할 권장] 1: 코드 패턴 예시
docs/PATTERNS.md에 Good/Bad 예시가 길어지면 (50줄+) 영역별로 분리:
- docs/patterns/transaction-examples.md
- docs/patterns/dto-mapping-examples.md
- docs/patterns/exception-handling-examples.md

📦 [분할 권장] 2: 도구별 호환성
조직이 Claude Code 외에 Codex · Cursor도 함께 쓰면 별도 파일:
- agents-md-tool-compatibility.md

-->

<!--
================================================================
✅ 정정 후 자가 검증 체크리스트 주석 삭제할것
================================================================
[ ] 분량 200줄 이하 (현재 ~180줄)
[ ] 메타 룰(언어·조사)이 상단
[ ] 트랜잭션 규칙 명시 (Service 계층·readOnly·self-invocation)
[ ] API 응답: RFC 7807 ProblemDetail 명시
[ ] 테스트: 단위·통합·E2E 정책 분리
[ ] 보안: secret 관리·@PreAuthorize·DTO 변환 명시
[ ] 참조 문서 한 섹션으로 통합
[ ] 작업 규칙·가드레일 중복 제거
[ ] 작성 완료 후 모든 <!-- ... -->


