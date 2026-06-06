# 10단계 프롬프트 구조 (Anthropic "Prompting 101")

> 동봉 이미지(`prompt-structure-10-stacks.svg` / `.png`)와 색상이 1:1로 매칭됩니다.
> 각 스택은 **하나의 액센트 색**을 가지며, 좌측 라벨 ↔ 우측 예시 블록의 색이 같으면 같은 스택입니다.

---

## 결론 먼저

이 구조는 Anthropic Applied AI Team의 공식 강의 **"Prompting 101"**(진행: Hannah · Christian)에서 제시한 **시스템 프롬프트 설계 체크리스트**다. 핵심은 **"장식이 아니라 건축(architecture)"** — 정보를 `정체성 → 데이터 → 규칙 → 예시 → 즉시 요청 → 출력형식` 순으로 쌓으면 출력이 **예측 가능(observable)** 해진다. 각 블록은 **단일 목적**만 가지며, **XML 태그**로 경계를 명확히 구분한다.

**개발자 진입 순서:** `1·2·9·10`(정체성·톤·출력형식·prefill) → 바로 동작 확인 → `3·4·5`(데이터·규칙·예시)를 결과 보며 반복 개선.

# 올바른 프롬프팅 기법 

제로샷 & 퓨샷 프롬프팅 (Zero-Shot and Few-Shot Prompting) 기법
### 제로샷 프롬프팅
- 모델이 이미 학습한 데이터를 기반으로 답변을 생성함, 예시 없이 바로 지시문으로 작성하는 프롬프트
- 빠르고 단순한 작업에 적합
- Pre-traind Knowledge → Generalization → Adaptation
**예시**
> "이 코드를 OOP 원칙에 맞게 리팩토링 해주고 테스트케이스 작성해줘"
### 퓨샷 프롬프팅
- 예시를 제공해서 정확성과 일관성을 가지도록 함
- 복잡한 문제나 특정 맥락이 필요한 긴 작업에 적합
**예시**
  
```sql
CREATE TABLE IF NOT EXISTS support_contacts (
id BIGINT NOT NULL AUTO_INCREMENT COMMENT '문의 ID',
name VARCHAR(100) NULL COMMENT '이름(선택)',
email VARCHAR(255) NOT NULL COMMENT '회신 이메일',
phone VARCHAR(20) NULL COMMENT '전화번호',
contact_type ENUM('general','bug','feature','collab','product','other') NOT NULL DEFAULT 'general' COMMENT '문의 유형',
subject VARCHAR(200) NOT NULL COMMENT '제목',
message TEXT NOT NULL COMMENT '문의 내용',
status ENUM('new','inProgress','resolved','closed') NOT NULL DEFAULT 'new' COMMENT '처리 상태',
locale VARCHAR(10) NULL COMMENT '언어(예: ko, en)',
created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '생성 시각',
updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '수정 시각',
deleted_at DATETIME(3) NULL COMMENT '삭제 시각(소프트 삭제)',
PRIMARY KEY (id),
INDEX idx_sc_status (status),
INDEX idx_sc_type (contact_type),
INDEX idx_sc_created (created_at)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='개발자에게 문의하기(지원 연락)';
```

> → @table.sql을 참고해서 SupportController와 service, repository를 코드베이스 컨벤션을 참고해서 CRUD를 만들고 Entity를 만들어줘. 컨트롤러에는 프론트에서 호출 할 수 있는 HttpClient 호출 스펙을 주석을 정리해줘
> 단순한 경우 제로샷으로 시작, 좀 더 높은 정밀도가 필요하다면 퓨샷을 통해 해결
> 코딩 에이전트 선택도 마찬가지
> 토큰 소모가 비용에 직접 영향을 줌 (따라서 파일 첨부 형태로 진행하는걸 권고)
>
> 
## 생각의 사슬 프롬프팅 (Chain-of -Thought Prompting)
- 작업을 논리적 단계로 분해하여 AI의 문제 해결 능력을 강화하는 기법, 순차적 접근, 단계별 접근, 다양한 조건 케이스에 대한 작업을 지시
- Sequential Thinking, Ultra Think 등의 MCP등 내장된 명령어를 수행하는 경우도 생각의 사슬 프롬프팅에서 확장된, 구조화된 버전의 프롬프팅이라고 볼 수 있음. → MCP에서 다시 설명
- AI Agent의 사고 유형을 한단계 더 발전시켜 문제 해결을 높히는 기법
> 이 코드 실행시에 중간에 에러가 발생하는데 코드 실행 전후로 로깅을 남기고 해당 로깅을 읽어서 순차적으로 로직이 제대로 된 값을 호출하고 전달하는지 추적하고 에러 로그가 나온다면 원인이 뭔지 파악한 뒤에 근본적인 해결책을 제시해줘
>
> 
## 문제 분해 프롬프팅 (Problem Decomposition Prompting, Chaining)
- 큰 복잡한 작업을 더 작고 관리하기 쉬운 작업 단위로 나누는 기법 , 시스템 설계나 연동 단계에서 작은 규모로 임무를 나누고 진행하도록 유도
- 작은 작업에 집중하게 하여 출력 품질을 향상 시킬 수 있음
> 로그인 단계의 처리는 다음과 같아
> 1) 인풋에서 아이디, 패스워드를 입력 받는다. 아이디는 이메일 포맷 validation을 해야 하고 패스워드는 4글자 이상의 값을 유효하다고 판단해야 한다.
> 2) 서버 전송시 인증 요청을 처리하여 실패의 경우 토스트 메시지를 출력하고, 성공일 경우 토큰 발급과 쿠키를 설정하여 응답을 반환한다.
> 3) 로그인 성공 페이지는 xxx로 이동하고, 이동시 사용자 정보를 조회하여 등급과 닉네임, 랭킹등을 회원 정보 드롭다운 레이어에 표시한다.
> 이 로직을 구현해줘


## 리액트 (Reason and Act, React) 프롬프팅
- AI가 단계적으로 추론(reasoning) 하고, 행동(action)하여 문제를 좀 더 효과적으로 해결하는 기법 , 에이전트 탐색, 디버깅
> Rabbit MQ 연동에 계속 실패하는데 설정 파일을 분석해서 어떤 부분에서 연동이 제대로 안되는지 파악하고 샘플 코드 실행이 안될 경우 공식 문서를 참조해서 설정 값을 변경하여 다시 테스트 진행해. 문제가 발생하면 발생 한 코드 전 후로 로깅을 남기고 해당 로깅을 읽어서 어떤 문제가 발생하고 있고 어떻게 해결해야 하는지 리포팅해
### 기타 : Constitutional Prompting(헌법적 지침 기반 AI 준수 규칙), Plan-and-Solve Prompting(계획-해결 프롬프팅, 실행에 앞서 계획을 세우는 과정)

---
# 올바른 프롬프트 구조 (2026.04 기준)

## 한눈에 보기

| # | 스택 | 색상 | 한 줄 정의 | 필수도 |
|---|------|:---:|----------|:---:|
| 1 | Task context | 🔴 빨강 | 역할(persona)과 임무 부여 | 거의 필수 |
| 2 | Tone context | 🟠 주황 | 말투·태도 설정 | 권장 |
| 3 | Background data, documents, images | 🟢 초록 | 참조용 외부 데이터(context) | 작업에 따라 |
| 4 | Detailed task description & rules | 🟦 청록 | 행동 규칙·금지사항 | 거의 필수 |
| 5 | Examples | 🔵 파랑 | 이상적 응답 예시(few-shot) | 강력 권장 |
| 6 | Conversation history | 🟣 보라 | 직전 대화 맥락 | 멀티턴 시 |
| 7 | Immediate task description or request | 💗 핑크 | 지금 처리할 실제 요청 | 필수 |
| 8 | Thinking step by step | 🔴 빨강 | 응답 전 추론 유도(CoT) | 복잡 작업 시 |
| 9 | Output formatting | ⚪ 회색 | 출력 형식 강제 | 권장 |
| 10 | Prefilled response (if any) | ⚫ 검정 | Assistant 답변 선두 고정 | 선택 |

---

## 각 스택 상세

### 🔴 1. Task context — 역할과 임무

**개념.** AI에게 *누구이고 무엇을 하는가*를 가장 먼저 못 박는다. persona를 부여하면 톤·어휘·판단 기준이 한 방향으로 정렬된다.
**무엇을 입력하나.** 정체성 + 목표 + 사용 맥락(누구를 상대로 응답하는가).

```text
You will be acting as an AI career coach named Joe created by the company
AdAstra Careers. Your goal is to give career advice to users. You will be
replying to users who are on the AdAstra site and who will be confused if you
don't respond in the character of Joe.
```

> 개발 팁: 코딩 어시스턴트라면 `너는 {{기술스택}}에 능숙한 시니어 리뷰어다`처럼 **역할 + 도메인 + 책임 범위**를 한 문장으로.

---

### 🟠 2. Tone context — 말투

**개념.** 응답의 정서·격식 수준을 지정. 챗 인터페이스에서 특히 중요.
**무엇을 입력하나.** 한 줄 톤 지시.

```text
You should maintain a friendly customer service tone.
```

> 개발 팁: 리뷰/분석 작업엔 `사실 기반, 간결, 자신감 있게. 리스크 먼저, 권고는 그 다음`처럼 **순서까지** 톤에 담으면 출력 구조가 안정된다.

---

### 🟢 3. Background data, documents, and images — 배경 데이터

**개념.** AI가 *참조*할 외부 정보(=context). 지시가 아니라 **자료**다.
**무엇을 입력하나.** 문서·코드 diff·이미지(Base64)·검색 결과 등. **각 자료를 개별 XML 태그로** 감싸 경계를 분리한다.

```text
Here is the career guidance document you should reference when answering the
user: <guide>{{DOCUMENT}}</guide>
```

> 개발 팁: 여러 자료는 `<diff>…</diff>` `<tests>…</tests>`처럼 **태그를 나눠** 넣어야 모델이 혼동하지 않는다. 큰 데이터는 프롬프트 상단보다 **이 위치(중간)** 에 두는 것이 권장된다.

---

### 🟦 4. Detailed task description & rules — 규칙

**개념.** 상호작용의 *행동 규칙과 금지사항*을 단계 리스트로. 모델의 과잉/이탈 행동을 막는 가드레일.
**무엇을 입력하나.** "항상 ~하라", "모르면 ~라고 답하라", "~는 하지 마라" 형태의 명시적 규칙.

```text
Here are some important rules for the interaction:
- Always stay in character, as Joe, an AI from AdAstra Careers
- If you are unsure how to respond, say "Sorry, I didn't understand that.
  Could you repeat the question?"
- If someone asks something irrelevant, say, "Sorry, I am Joe and I give
  career advice. Do you have a career question today I can help you with?"
```

> 개발 팁: **부정형 제약**(`코드를 임의로 재작성하지 마`, `새 엔드포인트 추가 금지`)이 특히 효과적. 폴백 응답("모르면 ~")을 미리 정의해 두면 환각을 줄인다.

---

### 🔵 5. Examples — 예시 (few-shot)

**개념.** 말로 설명하는 대신 *이상적 입출력*을 보여준다.
**무엇을 입력하나.** `<example>` 태그로 감싼 User→응답 쌍. 엣지 케이스 예시가 가장 가치 높다.

```text
Here is an example of how to respond in a standard interaction:
<example>
User: Hi, how were you created and what do you do?
Joe: Hello! My name is Joe, and I was created by AdAstra Careers to give
career advice. What can I help you with today?
</example>
```

> 개발 팁: 예시 여러 개면 각각 별도 태그로 감싸고, **무엇의 예시인지** 라벨을 달아라. 코드 스타일 통일엔 설명보다 예시 1~2개가 빠르고 정확하다.

---

### 🟣 6. Conversation history — 대화 히스토리

**개념.** 직전까지의 멀티턴 맥락 주입. 비어 있을 수 있음을 명시.
**무엇을 입력하나.** `<history>` 태그 + 동적 변수.

```text
Here is the conversation history (between the user and you) prior to the
question. It could be empty if there is no history:
<history> {{HISTORY}} </history>
```

> 개발 팁: 히스토리가 길어지면 **Context Rot**(맥락 누적 노이즈로 정확도 저하)을 유발한다. 전체를 그대로 넣기보다 요약/슬라이딩 윈도우로 관리.

---

### 💗 7. Immediate task description or request — 즉시 요청

**개념.** *지금 이 순간 처리할 실제 요청*. 위의 1~6은 고정 골격, 이 블록만 매 호출 바뀐다.
**무엇을 입력하나.** `<question>` 태그 + 동적 변수.

```text
Here is the user's question: <question> {{QUESTION}} </question>
```

> 개발 팁: 1~6을 `CLAUDE.md`/시스템 프롬프트의 **영구 골격**으로, 6·7을 **세션 동적 입력**으로 분리하면 재사용성이 올라간다.

---

### 🔴 8. Thinking step by step — 추론 유도

**개념.** 답하기 전에 먼저 생각하게 만드는 Chain-of-Thought.
**무엇을 입력하나.** "먼저 생각하라"는 지시.

```text
How do you respond to the user's question?
Think about your answer first before you respond.
```

> ⚠️ **최신 보충(중요):** Opus 4.x / Sonnet 4.5 등 최신 모델에서는 수동 CoT보다 **extended thinking** 기능 사용이 공식 권장된다. 강의 슬라이드는 이 기능 보편화 이전 표준이므로, 강의 시 "최신 모델에선 extended thinking으로 대체"를 반드시 보충할 것.

---

### ⚪ 9. Output formatting — 출력 형식

**개념.** 응답의 구조/형식을 강제. 후속 자동 파싱을 위해 필수적.
**무엇을 입력하나.** 형식 지시(XML 태그, JSON 스키마 등).

```text
Put your response in <response></response> tags.
```

> 개발 팁: 파이프라인에 물릴 출력은 `<review>심각도 | 위치 | 설명 | 권고</review>`처럼 **파싱 가능한 형식**을 명시.

---

### ⚫ 10. Prefilled response (if any) — 프리필

**개념.** Assistant 답변의 **첫 부분을 미리 채워** 형식·태도를 고정하고 군더더기(preamble)를 생략시키는 고급 기법.
**무엇을 입력하나.** Assistant 턴 선두 토큰.

```text
Assistant (prefill)
<response>
```

> 개발 팁: `<response>`까지 미리 넣으면 모델이 곧바로 본문부터 출력. JSON 강제 시 `{`를 prefill하면 서두 잡설을 막는다.

---

## 개발자용 변형 — 코드 리뷰 어시스턴트

강의 구조를 그대로 실무 프롬프트로 옮긴 예. (스택 번호 = 위 10단계)

```text
[1 Task]    너는 {{기술스택}}에 능숙한 엄격한 코드 리뷰어다.
[2 Tone]    전문적·간결. 리스크 먼저, 권고는 그 다음.
[3 Data]    <diff>{{이 PR의 git diff}}</diff>
            <tests>{{관련 테스트/CI 로그}}</tests>
[4 Rules]   - 보안 → 성능 → 가독성 → 타입 안정성 순으로 검토
            - 근거 없는 추측 금지. 확인 불가 항목은 "확인 불가"로 표기
            - 코드를 임의로 재작성하지 말 것
[5 Example] <example>
            지적: SQL 문자열 직접 결합 → 인젝션 위험
            권고: 파라미터 바인딩 사용
            </example>
[7 Request] <question>{{리뷰 요청 내용}}</question>
[8 Think]   지적 전에 영향 범위를 먼저 분석하라. (※최신 모델은 extended thinking)
[9 Format]  <review>심각도 | 위치 | 설명 | 권고</review> 표로 출력.
[10 Prefill]<review>
```

**활용 워크플로 (권장 순서)**
1. **골격 먼저** — 1·2·9·10만 채워 동작 확인 → 재사용 템플릿화
2. **데이터 주입** — 3에 diff·로그를 XML 태그로 분리 투입
3. **규칙·예시 반복 개선** — 4·5를 출력 결과 보며 튜닝(엣지 케이스 예시 추가가 최고 ROI)
4. **분리 배치** — 1·2·4·9는 `CLAUDE.md` 영구 규칙, 3·6·7은 세션 동적 입력

---

## 출처 (링크 유효성 확인 완료)

| 자료 | URL |
|------|-----|
| Anthropic 공식 — Prompt Library: Career coach (Joe 원문) | https://docs.claude.com/en/resources/prompt-library/career-coach |
| Anthropic 공식 — Prompt engineering overview | https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/overview |
| AWS Bedrock 공식 블로그 — 10단계 구조 명칭·순서 출처 | https://aws.amazon.com/blogs/machine-learning/prompt-engineering-techniques-and-best-practices-learn-by-doing-with-anthropics-claude-3-on-amazon-bedrock/ |
| AWS 샘플 노트북 — Joe 프롬프트 빌드업(09_Complex_Prompts_from_Scratch) | https://github.com/aws-samples/prompt-engineering-with-anthropic-claude-v-3/blob/main/09_Complex_Prompts_from_Scratch.ipynb |
| Anthropic "Prompting 101" 정리(Hannah·Christian 강의 = 이미지 출처) | https://dev.to/bokuno_log/anthropics-prompting-101-a-practical-guide-to-building-production-quality-claude-prompts-23k4 |

---
