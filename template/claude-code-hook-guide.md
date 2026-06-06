# 클로드 코드 훅(Hooks) 실무 가이드 — 개념부터 레시피까지

> AI에게 "부탁"이 아니라 **"강제 규칙"**으로 실행시키는 자동화 트리거입니다.
> 개념 → 작동 구조 → 첫 훅 만들기 → 실무 레시피 순으로, 한 화면에 몰아넣지 않고 단계별로 정리했습니다.
> 모든 사양은 Anthropic 공식 문서 기준으로 교차 확인했습니다.

**기준:** Anthropic 공식 문서(code.claude.com/docs) · 2026-06 확인 · 셸 예제는 macOS·Linux(zsh·bash)

> **한 줄 요약**
> 훅은 **Claude Code 동작의 특정 시점에 자동 실행되는 내 스크립트**입니다.
> "린트 돌려라"를 CLAUDE.md에 적으면 모델이 가끔 잊지만, 훅으로 걸면 **모델 판단과 무관하게 매번 실행**됩니다.
> 등록 확인은 세션에서 `/hooks`, 디버깅은 `claude --debug`.

## 목차

1. [훅이란? — 개념과 비유](#00-훅이란--개념과-비유)
2. [프롬프트(CLAUDE.md) vs 훅](#01-프롬프트claudemd-vs-훅)
3. [작동 구조 — 3계층](#02-작동-구조--3계층)
4. [이벤트(Event) — 언제 실행되나](#03-이벤트event--언제-실행되나)
5. [매처(Matcher) — 무엇에 반응하나](#04-매처matcher--무엇에-반응하나)
6. [핸들러(Handler) — 무엇을 실행하나](#05-핸들러handler--무엇을-실행하나)
7. [설정 파일은 어디에 두나](#06-설정-파일은-어디에-두나)
8. [첫 훅 만들기 — 저장 시 자동 포맷](#07-첫-훅-만들기--저장-시-자동-포맷)
9. [훅이 받는 입력 (stdin JSON)](#08-훅이-받는-입력-stdin-json)
10. [응답으로 Claude 제어하기](#09-응답으로-claude-제어하기)
11. [필수 훅 — 먼저 깔아둘 베이스라인](#10-필수-훅--먼저-깔아둘-베이스라인)
12. [실무 레시피 모음](#11-실무-레시피-모음)
13. [실무 체크리스트 · 보안 주의](#12-실무-체크리스트--보안-주의)
14. [부록 — 치트시트 · 출처](#부록--치트시트--출처)

---

## 00 훅이란? — 개념과 비유
*난이도 쉬움*

**훅(Hook)**은 Claude Code 라이프사이클의 정해진 시점에 자동으로 끼어들어 실행되는 **사용자 정의 스크립트**입니다. LLM이 "그렇게 하는 게 좋겠다"고 판단하는 것과 달리, 훅은 그 시점이 오면 **무조건 실행되는 결정론적 가드레일**입니다.

> **비유로 이해하기**
> CLAUDE.md에 적은 규칙이 **"부탁이 적힌 메모"**라면, 훅은 **"문에 달린 자동 잠금장치"**입니다. 메모는 읽고 지나칠 수 있지만, 잠금장치는 지나갈 때마다 무조건 작동합니다.

### 훅으로 흔히 하는 일

- 파일을 저장(Edit/Write)하면 **자동으로 포매터(Prettier 등)** 실행
- `rm -rf` 같은 **위험한 명령을 실행 직전에 차단**
- `git commit` 전에 **린트·타입체크를 강제**
- 작업이 끝나면 **Slack·소리로 알림**
- 세션 시작 시 **프로젝트 컨텍스트를 자동 주입**

---

## 01 프롬프트(CLAUDE.md) vs 훅
*난이도 쉬움*

둘 다 "이렇게 동작해라"를 지시하지만, **보장 수준**이 근본적으로 다릅니다.

| 구분 | CLAUDE.md / 프롬프트 | 훅(Hooks) |
|------|----------------------|-----------|
| 실행 보장 | 모델에 의존 (아마도) | **시스템이 보장 (항상)** |
| 판단 주체 | LLM (확률적) | 셸·스크립트 (결정적) |
| 차단 능력 | 없음 (안내만) | **도구 호출 차단 가능** |
| 적합한 대상 | 맥락·뉘앙스·스타일 | 린트·테스트·보안 정책 |

> **언제 무엇을 쓸까**
> "코드 스타일은 간결하게" 같은 **판단이 필요한 지시**는 CLAUDE.md에, "커밋 전 테스트 통과는 필수" 같은 **예외 없이 강제할 규칙**은 훅에 두세요. 둘은 경쟁이 아니라 보완 관계입니다.

---

## 02 작동 구조 — 3계층
*난이도 기본*

훅 하나는 **언제(Event) · 무엇에(Matcher) · 무엇을 실행(Handler)**의 3계층으로 정의됩니다. 이 셋만 이해하면 끝입니다.

```
  ① EVENT          ②  MATCHER            ③ HANDLER
   언제?      ─→     무엇에?       ─→     무엇을 실행?
PreToolUse·Stop   "Bash"·"Write|Edit"   command·http…
```
*이벤트가 발생하면 → 매처로 대상을 거르고 → 통과하면 핸들러를 실행한다.*

아래는 가장 흔한 형태의 설정(JSON) 예시입니다. "파일을 쓰거나 편집한 직후(`PostToolUse`), `Write`·`Edit` 도구라면, 셸 명령을 실행하라"는 뜻입니다.

```jsonc
{
  "hooks": {
    // ① EVENT — 언제
    "PostToolUse": [
      {
        // ② MATCHER — 무엇에
        "matcher": "Write|Edit",
        // ③ HANDLER — 무엇을 실행
        "hooks": [
          { "type": "command", "command": "echo saved" }
        ]
      }
    ]
  }
}
```

다음 세 섹션에서 각 계층(이벤트·매처·핸들러)을 하나씩 자세히 봅니다.

---

## 03 이벤트(Event) — 언제 실행되나
*난이도 기본*

이벤트는 **훅이 발화하는 라이프사이클 시점**입니다. 처음에는 아래 **핵심 이벤트**만 알아도 충분합니다.

```
SessionStart → UserPromptSubmit → PreToolUse → PostToolUse → Stop → SessionEnd
```
*한 턴의 대략적 순서. 도구를 여러 번 쓰면 PreToolUse↔PostToolUse가 반복된다.*

### 핵심 이벤트 (가장 자주 씀)

| 이벤트 | 발화 시점 | 대표 용도 |
|--------|-----------|-----------|
| `PreToolUse` | 도구 실행 **직전** (차단 가능) | 위험 명령 차단, 커밋 게이트 |
| `PostToolUse` | 도구 실행 **직후** (성공 시) | 저장 후 자동 포맷·로깅 |
| `UserPromptSubmit` | 사용자가 프롬프트를 **보낸 직후** | 컨텍스트 주입, 입력 검사 |
| `Notification` | 권한 요청·입력 대기 알림 시 | Slack·소리 알림 |
| `Stop` | Claude가 응답을 **마쳤을 때** | 작업 완료 알림 |
| `SessionStart` | 세션 시작·재개 시 | 환경 점검, 컨텍스트 로드 |
| `SessionEnd` | 세션 종료 시 | 정리·요약 저장 |

### 그 외 이벤트 (필요할 때)

공식 문서에는 위 외에도 다수의 이벤트가 정의돼 있습니다. 대표적으로:

| 이벤트 | 발화 시점 |
|--------|-----------|
| `PostToolUseFailure` | 도구 실행이 **실패**했을 때 |
| `PermissionRequest` | 권한 확인 창이 뜰 때 (동적 허용/거부) |
| `SubagentStart` / `SubagentStop` | 서브에이전트 시작 / 종료 시 |
| `PreCompact` / `PostCompact` | 컨텍스트 압축(compaction) 전 / 후 |
| `ConfigChange` | 세션 중 설정 파일이 바뀔 때 |

> **정확도 노트**
> 이벤트 목록은 버전에 따라 계속 추가됩니다. 새 이벤트를 쓰기 전엔 본인 환경에서 [공식 Hooks 레퍼런스](https://code.claude.com/docs/en/hooks)로 존재 여부를 확인하세요. 문서에 없는 이벤트 이름(예: 가공의 `PreCommit`)은 동작하지 않습니다.

---

## 04 매처(Matcher) — 무엇에 반응하나
*난이도 기본+*

매처는 같은 이벤트 안에서 **대상을 좁히는 필터**입니다. 이벤트 종류에 따라 **매칭하는 대상이 다릅니다.** 예컨대 `PreToolUse`·`PostToolUse`는 **도구 이름**에 매칭됩니다.

### 도구 이름 매칭 규칙

| matcher 값 | 의미 |
|------------|------|
| `"Bash"` | Bash 도구 호출에만 — **정확히 일치**(대소문자 구분) |
| `"Write\|Edit"` | Write 또는 Edit (`\|` = OR) |
| `""` 또는 생략 | 해당 이벤트의 **모든 경우**에 매칭 |
| `"mcp__github__.*"` | 특정 MCP 서버의 모든 도구 (정규식) |

> **자주 오해하는 점 — "항상 정규식"이 아니다**
> 알파벳·숫자·밑줄·`|`만으로 된 값(`"Bash"`, `"Write|Edit"`)은 **정확한 문자열 매칭**으로 처리됩니다. `.*`, `^$` 같은 **정규식 특수문자가 들어갈 때만 정규식**으로 평가됩니다.

### 이벤트마다 매칭 대상이 다르다

도구 이름이 아닌 다른 값에 매칭되는 이벤트도 있습니다. 몇 가지 예:

| 이벤트 | 매처가 거르는 대상 |
|--------|--------------------|
| `SessionStart` | `startup` · `resume` · `clear` · `compact` (시작 방식) |
| `Notification` | `permission_prompt` · `idle_prompt` 등 (알림 종류) |
| `PreCompact` | `manual` · `auto` (압축 트리거) |
| `UserPromptSubmit` · `Stop` | 매처 없음 — 항상 발화 |

---

## 05 핸들러(Handler) — 무엇을 실행하나
*난이도 기본+*

매칭되면 실제로 실행되는 실체가 핸들러입니다. `type` 필드로 종류를 정합니다. **대부분 `command` 하나면 충분**하고, 나머지는 고급 케이스용입니다.

| type | 하는 일 | 언제 쓰나 |
|------|---------|-----------|
| `command` | 셸 명령어·스크립트 실행 | **대다수 — 기본 선택** |
| `http` | 원격 엔드포인트로 POST 호출 | 외부 서비스 연동 |
| `mcp_tool` | 연결된 MCP 서버의 도구 호출 | MCP 워크플로 |
| `prompt` | 모델 단발 평가에 위임(기본 Haiku) | 간단한 판단형 검사 |
| `agent` | 서브에이전트로 다중 턴 검증 *(실험적)* | 파일까지 들여다보는 검증 |

> **처음이라면**
> `command`만 익히면 이 가이드의 모든 레시피를 만들 수 있습니다. `http`·`prompt`·`agent`는 나중에 필요할 때 공식 문서를 참고하세요.

---

## 06 설정 파일은 어디에 두나
*난이도 기본*

훅은 `settings.json`에 정의합니다. **어느 파일에 두느냐가 곧 적용 범위(스코프)**입니다.

| 경로 | 스코프 | Git 공유 | 적합한 용도 |
|------|--------|----------|-------------|
| `~/.claude/settings.json` | 사용자 전역 | 안 됨(내 PC) | 개인 알림·로깅 |
| `.claude/settings.json` | 프로젝트(팀) | **커밋되어 공유** | 팀 표준 린트·테스트 게이트 |
| `.claude/settings.local.json` | 프로젝트(개인) | 안 됨(.gitignore) | 개인 로컬 전용 설정 |

> **권장 시작점**
> 팀이 함께 지켜야 할 가드레일은 **프로젝트 스코프(`.claude/settings.json`)**에 두고 커밋하세요. 나만의 알림·디버깅용은 **사용자 스코프**에. (조직 차원의 관리 정책 설정도 별도로 존재합니다.)

---

## 07 첫 훅 만들기 — 저장 시 자동 포맷
*난이도 실무*

**시나리오:** Claude가 파일을 저장(Edit/Write)할 때마다 자동으로 Prettier를 돌려 포맷을 맞춥니다. (`PostToolUse` + `Write|Edit`)

### 1단계 — 설정 파일 만들기

프로젝트 루트에서 `.claude` 폴더와 설정 파일을 준비합니다.

```bash
$ mkdir -p .claude
$ nano .claude/settings.json   # 팀 공유용. 개인용만이면 settings.local.json
```

### 2단계 — 훅 정의(JSON) 작성

훅은 **stdin으로 JSON 입력을 받습니다.** 그래서 환경변수보다 `jq`로 값을 꺼내는 패턴이 표준입니다.

```jsonc
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            // stdin JSON에서 파일 경로를 꺼내 prettier 실행
            "command": "jq -r '.tool_input.file_path' | xargs -r npx prettier --write"
          }
        ]
      }
    ]
  }
}
```

### 3단계 — 등록 확인

Claude Code 세션에서 `/hooks`를 입력해 `PostToolUse` 항목에 방금 만든 훅이 잡히는지 확인합니다. 동작이 이상하면 `claude --debug`로 실행해 훅 실행 로그를 봅니다.

> **경로는 절대 기준으로**
> 훅 실행 시 작업 디렉터리(cwd)가 기대와 다를 수 있습니다. 스크립트 파일을 참조할 땐 공식 환경변수 `$CLAUDE_PROJECT_DIR`를 기준으로 쓰면 안전합니다 (예: `"$CLAUDE_PROJECT_DIR/.claude/hooks/foo.sh"`).

---

## 08 훅이 받는 입력 (stdin JSON)
*난이도 중급*

`command` 핸들러는 **stdin으로 JSON**을 받습니다. (HTTP 핸들러는 같은 JSON이 POST 본문으로 전달됩니다.) 주요 필드는 다음과 같습니다.

| 필드 | 의미 |
|------|------|
| `session_id` | 세션 식별자 |
| `cwd` | 실행 디렉터리 |
| `hook_event_name` | 이벤트명 (예: PreToolUse) |
| `tool_name` | 호출 도구 (Bash, Edit 등) |
| `tool_input.command` | (Bash) 실행할 명령 |
| `tool_input.file_path` | (Edit/Write) 대상 파일 경로 |
| `tool_response` | (PostToolUse) 도구 실행 결과 |
| `transcript_path` | 현재 세션 트랜스크립트 경로 |

### 표준 파싱 패턴

```bash
#!/bin/bash
INPUT=$(cat)                                                # stdin 전체 읽기
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')    # Bash 명령
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""') # 파일 경로
```

> **비표준 환경변수 주의**
> 일부 블로그의 `$CLAUDE_FILE_PATHS` 같은 변수는 비표준이거나 옛 방식입니다. 값은 위처럼 **stdin JSON에서 jq로 꺼내는 것**이 공식 패턴이고, 경로 기준만 `$CLAUDE_PROJECT_DIR`를 쓰세요.

---

## 09 응답으로 Claude 제어하기
*난이도 중급*

훅은 **① 종료 코드(exit code)**와 **② stdout JSON** 두 가지로 Claude의 다음 행동을 제어합니다.

### 방식 1 — 종료 코드 (간단·견고)

| exit code | 의미 |
|-----------|------|
| `0` | 통과 — 계속 진행 |
| `2` | **차단** — `PreToolUse`에서는 도구 호출을 막고, **stderr 내용이 Claude에게 전달**되어 대안을 찾게 함 |
| 그 외 0이 아님 | non-blocking 에러 — 진행은 되고 사용자에게만 표시 |

```bash
#!/bin/bash
CMD=$(jq -r '.tool_input.command // ""')
if [[ "$CMD" =~ rm[[:space:]]+-rf ]]; then
  echo "🚨 위험한 명령 차단: $CMD" >&2   # stderr → Claude에게 전달
  exit 2                               # 2 = 차단
fi
exit 0
```

### 방식 2 — stdout JSON (정교한 제어)

차단 사유나 허용/거부 결정을 구조화해 돌려줄 수 있습니다. `PreToolUse`는 `hookSpecificOutput.permissionDecision`으로 `allow`/`deny`/`ask`를 지정합니다.

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "프로덕션 경로 수정은 금지되어 있습니다."
  }
}
```

`PostToolUse`·`Stop` 등에서는 `{"decision":"block","reason":"..."}` 형태를, `UserPromptSubmit`·`SessionStart`에서는 `additionalContext`로 컨텍스트를 주입할 수 있습니다.

> **어느 방식을 쓸까**
> 단순 차단·통과는 **종료 코드(방식 1)**가 가장 견고합니다. 허용/거부를 명시적으로 나누거나 사유·컨텍스트를 정교하게 전달해야 할 때만 **JSON(방식 2)**을 쓰세요.

---

## 10 필수 훅 — 먼저 깔아둘 베이스라인
*난이도 실무*

프로젝트를 새로 시작할 때 **거의 항상 도움이 되는** 네 가지입니다. 07의 "저장 시 자동 포맷"과 함께 깔아두면 안전성·편의·추적성을 한 번에 챙길 수 있습니다. 스크립트는 `.claude/hooks/`에 두고 `chmod +x` 후 `settings.json`에 연결하세요.

### ① 민감 파일 보호 — .env·키 파일 차단 (PreToolUse)

Claude가 `.env`, 인증서, 개인키 등을 **읽거나 수정하려 할 때 실행 직전 차단**합니다. 실수로 비밀이 컨텍스트에 올라가거나 덮어써지는 사고를 막는 가장 중요한 베이스라인입니다.

```bash
#!/bin/bash
# .claude/hooks/protect-secrets.sh
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

if [[ "$FILE" =~ (^|/)\.env || "$FILE" =~ \.(pem|key|p12)$ \
   || "$FILE" =~ (^|/)(id_rsa|id_ed25519|credentials)$ ]]; then
  echo "🔒 민감 파일 접근 차단: $FILE" >&2
  echo "비밀 값은 환경변수/시크릿 매니저를 사용하세요." >&2
  exit 2
fi
exit 0
```

설정은 **읽기·쓰기 도구 모두**에 매칭되도록 묶습니다.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read|Edit|Write",
        "hooks": [
          { "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR/.claude/hooks/protect-secrets.sh\"" }
        ]
      }
    ]
  }
}
```

> **⚠️ 완벽한 차단은 아님**
> 훅은 `cat .env` 같은 **Bash 우회**까지 막지는 못합니다(그건 ②·레시피의 Bash 검사로 보완). 그래도 직접적인 파일 도구 접근을 막아주는 1차 방어선으로 충분히 가치가 있습니다.

### ② 세션 시작 시 컨텍스트 자동 주입 (SessionStart)

세션이 열릴 때마다 **현재 브랜치·최근 변경 요약을 Claude에게 자동으로 알려줍니다.** "지금 어디서 작업 중인지"를 매번 설명하지 않아도 됩니다. `SessionStart`는 **exit 0으로 출력한 stdout 텍스트가 그대로 컨텍스트에 주입**됩니다.

```bash
#!/bin/bash
# .claude/hooks/session-context.sh
BRANCH=$(git branch --show-current 2>/dev/null)
CHANGED=$(git status --short 2>/dev/null | head -10)

echo "현재 브랜치: ${BRANCH:-(git 아님)}"
if [ -n "$CHANGED" ]; then
  echo "작업 중 변경:"
  echo "$CHANGED"
fi
exit 0
```

> **정교하게 주입하려면**
> JSON으로 명시하고 싶으면 `{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"..."}}` 형태도 가능합니다. 위처럼 plain text를 출력하는 쪽이 더 간단합니다.

### ③ 모든 Bash 명령 감사 로그 (PostToolUse + Bash)

Claude가 실행한 **모든 Bash 명령을 타임스탬프와 함께 파일로 기록**합니다. "방금 뭘 실행했더라?"를 추적하고, 문제가 생겼을 때 되짚어볼 수 있습니다.

```bash
#!/bin/bash
# .claude/hooks/audit-bash.sh
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
LOG="$CLAUDE_PROJECT_DIR/.claude/logs/bash-audit.log"

mkdir -p "$(dirname "$LOG")"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] $CMD" >> "$LOG"
exit 0
```

> **로그는 추적에서 제외**
> `.claude/logs/`는 커밋되지 않도록 `.gitignore`에 추가하세요. 감사 로그가 저장소 이력에 섞이는 것을 막아줍니다.

### ④ 작업 완료 로컬 알림 (Stop)

Slack 없이도, 긴 작업이 끝나면 **소리나 음성으로 즉시 알려줍니다.** 다른 창을 보다가도 놓치지 않습니다.

```bash
#!/bin/bash
# .claude/hooks/notify-done.sh — macOS
afplay /System/Library/Sounds/Glass.aiff 2>/dev/null   # 소리
say "작업이 끝났습니다" 2>/dev/null                       # 음성 (선택)
exit 0
# Linux 예: paplay /usr/share/sounds/freedesktop/stereo/complete.oga
# Windows(Git Bash) 예: powershell -c "[console]::beep(800,400)"
```

> **연결**
> `settings.json`의 `Stop` 이벤트(매처 불필요)에 이 스크립트를 연결하면 끝입니다. 입력 대기 시점까지 알리려면 `Notification` 이벤트에도 함께 등록하세요.

---

## 11 실무 레시피 모음
*난이도 실무*

현장에서 가장 많이 쓰는 4가지입니다. 스크립트는 `.claude/hooks/`에 저장하고 `chmod +x`로 실행 권한을 준 뒤, `settings.json`에서 해당 이벤트에 연결합니다.

### ① 작업 완료·대기 Slack 알림 (Stop · Notification)

긴 작업이 끝나거나(`Stop`) 입력 대기로 멈췄을 때(`Notification`) Slack으로 통보합니다.

```bash
#!/bin/bash
# .claude/hooks/slack-notify.sh
INPUT=$(cat)
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name')
PROJECT=$(basename "$(pwd)")

if [ "$EVENT" = "Stop" ]; then
  TITLE="✅ 작업 완료"
else
  TITLE="⏳ 입력 대기 중"
fi

curl -s -X POST -H 'Content-Type: application/json' \
  --data "{\"text\":\"$TITLE · $PROJECT\"}" \
  "$SLACK_WEBHOOK_URL" > /dev/null
exit 0
```

> **설정**
> Slack [Incoming Webhook](https://api.slack.com/messaging/webhooks)을 만들어 `~/.zshrc`에 `export SLACK_WEBHOOK_URL="https://hooks.slack.com/..."`를 추가하고, `settings.json`의 `Stop`·`Notification` 두 이벤트에 이 스크립트를 연결하세요.

### ② 파괴적 명령 차단 (PreToolUse + Bash)

실행 직전 Bash 명령을 검사해 위험 패턴이면 `exit 2`로 막습니다.

```bash
#!/bin/bash
# .claude/hooks/block-destructive.sh
CMD=$(jq -r '.tool_input.command // ""')

if [[ "$CMD" =~ rm[[:space:]]+-rf[[:space:]]+(/|~|\$HOME) ]] \
   || [[ "$CMD" =~ git[[:space:]]+reset[[:space:]]+--hard ]] \
   || [[ "$CMD" =~ curl.*\|.*bash ]]; then
  echo "🚨 차단된 명령: $CMD" >&2
  echo "안전한 대안을 사용하세요." >&2
  exit 2
fi
exit 0
```

> **왜 유용한가**
> `--dangerously-skip-permissions`로 권한 확인을 건너뛸 때의 위험을 실질적으로 보완합니다. Claude는 stderr로 받은 차단 사유를 보고 다른 방법을 제안합니다.

### ③ 커밋 전 린트·타입체크 강제 (PreToolUse + Bash)

Claude가 `git commit`을 호출하면 가로채 먼저 검사를 돌리고, 실패하면 차단합니다.

```bash
#!/bin/bash
# .claude/hooks/pre-commit-gate.sh
CMD=$(jq -r '.tool_input.command // ""')

if [[ "$CMD" =~ git[[:space:]]+commit ]]; then
  if ! npx eslint . --max-warnings 0; then
    echo "ESLint 오류. 먼저 수정 후 커밋하세요." >&2
    exit 2
  fi
  if ! npx tsc --noEmit; then
    echo "타입 오류. 먼저 수정하세요." >&2
    exit 2
  fi
fi
exit 0
```

> **전용 커밋 이벤트는 없다**
> 현재 Claude Code에는 별도의 `PreCommit` 이벤트가 없습니다. 위처럼 **`PreToolUse` + Bash 매처로 커밋 명령을 가로채는 패턴**이 표준입니다.

### ④ 푸시·PR 생성 전 테스트 강제 (PreToolUse + Bash)

`git push`나 `gh pr create` 전에 테스트를 돌려, 깨진 변경이 원격·리뷰어에게 가지 않게 막습니다.

```bash
#!/bin/bash
# .claude/hooks/pre-push-gate.sh
CMD=$(jq -r '.tool_input.command // ""')

if [[ "$CMD" =~ gh[[:space:]]+pr[[:space:]]+create ]] \
   || [[ "$CMD" =~ git[[:space:]]+push ]]; then
  if ! npm test -- --run; then
    echo "테스트 실패. 푸시/PR 생성을 차단합니다." >&2
    exit 2
  fi
fi
exit 0
```

---

## 12 실무 체크리스트 · 보안 주의
*난이도 중급*

### 권장 (Do)

- `/hooks`로 등록을, `claude --debug`로 실행을 항상 확인
- 값은 **stdin JSON + jq**로 파싱, 경로는 `$CLAUDE_PROJECT_DIR` 기준
- 커밋 게이트는 **빠르게**(가능하면 수 초 내) — 느린 훅은 작업 흐름을 막음
- 팀 표준 가드레일은 **프로젝트 스코프에 커밋**해 공유
- 로그는 `.claude/logs/` 등 별도 위치에 남기기

### 함정 (Don't)

- 훅에서 또 다른 훅을 유발하는 작업 → **무한 루프** 주의
- 전체 테스트처럼 **오래 걸리는 작업을 동기로** 실행
- 비밀번호·토큰을 **stdout/stderr로 출력**
- 상대 경로 의존 (cwd가 기대와 다를 수 있음)
- 팀 합의 없이 **강제 차단 정책**을 프로젝트 스코프에 추가

> **⚠️ 보안 경고 — 훅은 풀 권한으로 실행됩니다**
> 공식 문서가 명시하듯, 훅은 **샌드박스 없이 현재 사용자 전체 권한**으로 실행됩니다. 잘못 짠 훅 하나가 파일을 지우거나 비밀을 유출할 수 있습니다. **훅 스크립트는 일반 코드처럼 리뷰**하고, 출처가 불분명한 훅 설정을 그대로 가져다 쓰지 마세요.

---

## 부록 — 치트시트 · 출처

### A. 3계층 한눈에

```
EVENT    = 언제   →  PreToolUse · PostToolUse · Stop · SessionStart …
MATCHER  = 무엇에 →  "Bash" · "Write|Edit" · "" (전체) · "mcp__x__.*"
HANDLER  = 무엇을 →  command(대다수) · http · mcp_tool · prompt · agent
```

### B. 자주 쓰는 동작

| 상황 | 명령 / 설정 |
|------|-------------|
| 등록된 훅 확인 | `/hooks` (세션 내) |
| 훅 디버깅 | `claude --debug` |
| stdin 값 꺼내기 | `jq -r '.tool_input.command'` |
| 도구 호출 차단 | stderr 출력 후 `exit 2` (PreToolUse) |
| 경로 기준 | `$CLAUDE_PROJECT_DIR` |
| 팀 공유 설정 | `.claude/settings.json` (커밋) |

### C. 막혔을 때 체크리스트

1. `/hooks`에 훅이 잡히나요? 안 잡히면 JSON 문법·경로 확인.
2. `claude --debug`로 훅이 실행은 되는지, 어떤 에러를 내는지 확인.
3. 차단이 안 되면 `PreToolUse`인지, `exit 2`인지 확인.
4. 이벤트·필드 이름이 **공식 문서에 실제로 있는지** 확인(가공의 이름 금지).

### D. 공식 출처

- Hooks 레퍼런스(공식) — [code.claude.com/docs/en/hooks](https://code.claude.com/docs/en/hooks)
- Hooks 가이드(공식) — [code.claude.com/docs/en/hooks-guide](https://code.claude.com/docs/en/hooks-guide)
- Agent SDK · Hooks — [platform.claude.com/docs/en/agent-sdk/hooks](https://platform.claude.com/docs/en/agent-sdk/hooks)
- Slack Incoming Webhooks — [api.slack.com/messaging/webhooks](https://api.slack.com/messaging/webhooks)

---

*사양은 Anthropic 공식 문서(code.claude.com/docs) 기준으로 2026-06에 교차 확인했습니다. 이벤트·필드 목록은 버전에 따라 추가될 수 있으니, 새 기능을 쓰기 전 위 공식 출처에서 최신 내용을 확인하세요. 셸 예제는 macOS·Linux(zsh·bash) 기준입니다.*
