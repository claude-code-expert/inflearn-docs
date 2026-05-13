# Claude Code Handoff 시스템 가이드

> `/compact` 나 `/clear` 처럼 컨텍스트가 끊기는 순간 직전 대화의 핵심을 자동 저장하고, 새 세션 시작 시 자동으로 주입해 "처음부터 다시 설명"을 없애는 메커니즘.

---

## 1. 전체 그림

```
┌───────────────────── 대화 진행 ─────────────────────┐
│                                                     │
│   [Claude Code 응답]                                │
│         ▼                                           │
│   (Stop hook → slack 알림 등 — 본 가이드 범위 외)    │
│                                                     │
└─────────────────────────────────────────────────────┘

   ▼ 컨텍스트 한계 / 사용자 /compact / 사용자 /clear
┌─────────────────────────────────────────────────────┐
│  PreCompact 이벤트  ─── pre-compact-handoff.py       │
│  SessionEnd(clear)  ─── session-end-handoff.py       │
│         │                                            │
│         ▼ stdin = { session_id, transcript_path,     │
│                     cwd, trigger, source }           │
│  handoff_core.extract_context()                      │
│         │  - transcript JSONL 라인별 파싱             │
│         │  - user/assistant 메시지 + tool_use 경로    │
│         │  - dedup (SequenceMatcher ≥ 0.85)          │
│         ▼                                            │
│  handoff_core.write_handoff()                        │
│         │  → ~/.claude/handoff/{session_id}.md        │
│         │  → ~/.claude/handoff/latest-handoff.md      │
│         │  → ~/.claude/handoff/latest-handoff.json    │
│         ▼                                            │
│  stdout 으로 systemMessage JSON 반환                  │
└─────────────────────────────────────────────────────┘

   ▼ 새 세션 시작
┌─────────────────────────────────────────────────────┐
│  SessionStart 이벤트 (matcher: compact / clear)       │
│  ─── session-restore.sh                              │
│         │                                            │
│         ▼ stdin = { session_id, source, cwd }        │
│  파일 결정 로직:                                       │
│   1) {session_id}.md 존재 → 그걸 사용                  │
│   2) source=clear && latest-handoff.md 가 신선        │
│      (≤ 15분 + cwd 일치) → fallback                   │
│   3) 둘 다 아니면 종료                                  │
│         ▼                                            │
│  stdout 으로 SessionStart hookSpecificOutput 반환     │
│   → Claude Code 가 <context-handoff> 블록으로         │
│     새 세션에 자동 주입                                │
└─────────────────────────────────────────────────────┘
```

---

## 2. 구성 요소

### 2-1. 라이브러리

| 파일 | 역할 |
|------|------|
| `~/.claude/hooks/handoff_core.py` | `extract_context()` / `write_handoff()` / `dedup_messages()` 제공. 다른 엔트리들이 import 해서 사용. |

추출 로직 핵심:

- **user 메시지**: `[Request interrupted by user]` 같은 노이즈 제거 후 최근 15개 (`HANDOFF_MAX_USER_MESSAGES`)
- **assistant snippet**: `API Error:`, `rate_limit`, `(no content)` 등 junk 제거, 800자 (`HANDOFF_MAX_ASSISTANT_CHARS`) 초과 시 truncate, 최근 10개 보존
- **files_touched**: assistant 의 `tool_use.input` 트리에서 `file_path` / `path` 키 재귀 수집 (셸 명령 토큰 포함 시 제외) → 최근 20개
- **dedup**: 직전 30개 user 메시지에 대해 `SequenceMatcher` 비율 ≥ 0.85 이면 중복 처리

### 2-2. 이벤트 엔트리 (커스텀 — 사용자 본인이 추가한 훅)

| 파일 | 이벤트 | 등록 위치(`~/.claude/settings.json`) |
|------|--------|----|
| `pre-compact-handoff.py` | `PreCompact` (matcher `*`) | line ~155-165 |
| `session-end-handoff.py` | `SessionEnd` (matcher `clear`) | line ~167-178 |
| `session-restore.sh` | `SessionStart` (matcher `compact` / `clear`) | line ~179-200 |

### 2-3. 보조 도구 (참조용)

| 파일 | 역할 |
|------|------|
| `~/.claude/hooks/claude-handoff-supervisor.py` | Claude Code 를 pty 로 감싸서 사용자가 친 `/compact` 한 줄을 `/clear` 로 자동 치환. 훅으로는 slash command 를 재작성할 수 없어서 외부 supervisor 가 필요한 케이스 — 현재 settings.json 에는 미등록(직접 `python3 ... claude-handoff-supervisor.py` 로 실행). |

### 2-4. 외부 플러그인

`~/.claude/settings.json` 의 `enabledPlugins` 에 `claude-handoff@claude-handoff` (v1.0.1, [kylesnowschwartz/claude-handoff](https://github.com/kylesnowschwartz/claude-handoff)) 가 활성화되어 있습니다.

플러그인의 hooks (`~/.claude/plugins/marketplaces/claude-handoff/handoff-plugin/hooks/hooks.json`):

- `PreCompact` → `pre-compact.sh`
- `SessionStart` (matcher `*`) → `session-start.sh`

→ **현황: PreCompact 가 플러그인 + 커스텀 두 곳에서 동시에 발화 중**. 출력 위치가 다르므로 충돌은 없지만, 동일 transcript 를 두 번 분석합니다. 이 가이드 시점에서는 일원화 결정을 보류하고 현황만 명시합니다.

---

## 3. 저장 결과

`~/.claude/handoff/` 디렉토리에 누적:

| 파일 | 의미 |
|------|------|
| `{session_id}.md` | 세션 id 별 영구 보관 (덮어쓰기 X) |
| `latest-handoff.md` | 가장 최근 handoff 의 사본 — clear fallback 용 |
| `latest-handoff.json` | `{ generated_at, trigger, session_id, cwd, handoff_file }` 메타 — 신선도/cwd 매칭 검증에 사용 |

마크다운 포맷:

```
# Context Handoff

- **Generated**: <ISO timestamp>
- **Session**: <session_id>
- **Trigger**: <PreCompact ... | SessionEnd(clear)>
- **Transcript**: `<path>`
- **CWD**: `<path>`

## Recent User Requests
### Turn 1
```
<user message, 500자 truncate>
```
...

## Files Touched
- `<absolute path>`
...

## Recent Assistant Context
> <snippet, 300자 truncate>
...
```

---

## 4. 환경변수 튜닝

| 변수 | 기본값 | 효과 | 추천 조정 시점 |
|------|--------|------|----------|
| `HANDOFF_MAX_USER_MESSAGES` | 15 | handoff 에 보존할 최근 user turn 수 | turn 이 많은 긴 세션에서 컨텍스트 부족하면 ↑ |
| `HANDOFF_MAX_ASSISTANT_CHARS` | 800 | assistant snippet 1건 길이 cap | 코드 응답 위주면 ↑, 비용 신경 쓰면 ↓ |
| `HANDOFF_DEDUP_THRESHOLD` | 0.85 | 중복 메시지 판정 (0~1) | 같은 질문 반복 패턴이면 ↓ (더 공격적으로 dedup) |
| `HANDOFF_LATEST_MAX_AGE_SEC` | 900 | clear fallback 으로 인정할 latest 의 최대 나이(초) | 자주 clear 하면 ↓, 긴 작업 사이 clear 가 흔하면 ↑ |

`~/.zshrc` 에 `export HANDOFF_MAX_USER_MESSAGES=25` 와 같이 추가하고 `source` 하면 됩니다.

---

## 5. 로컬 테스트

저장소 `samples/handoff/` 에 격리 실행 환경이 준비되어 있습니다.

```bash
cd samples/handoff
chmod +x run-test.sh session-restore.sh

./run-test.sh           # PreCompact 시나리오
./run-test.sh end       # SessionEnd(clear) 시나리오
./run-test.sh restore   # SessionStart 주입 출력 확인
```

`run-test.sh` 는 `HOME` 환경변수를 `./out/` 으로 갈아끼워 실제 `~/.claude/handoff/` 를 오염시키지 않습니다.

검증 포인트:

- stdout JSON 에 `Captured N user messages` 가 sample-transcript.jsonl 의 user 라인 수와 일치
- `./out/.claude/handoff/sample-session-0001.md` 가 생성되고 마크다운 골격이 정상
- restore 모드에서 `hookSpecificOutput.additionalContext` 가 `<context-handoff>` 블록을 포함

---

## 6. 트러블슈팅

| 증상 | 원인 / 해결 |
|------|------|
| 새 세션 시작했는데 context-handoff 가 안 뜸 | session-id 별 파일이 없고 latest 가 15분 이상 지남 → `/clear` 의 cwd 가 직전 세션과 다른 경우 일치. `HANDOFF_LATEST_MAX_AGE_SEC` 늘리거나 `/clear` 직후 즉시 작업 |
| handoff.md 가 비어있음 | transcript_path 가 유효한데도 user_messages/files_touched 가 둘 다 비면 `extract_context()` 가 빈 결과 반환 → `pre-compact-handoff.py` 가 일찍 exit 0. transcript 파일이 실제로 존재하는지 확인 |
| 같은 transcript 가 두 번 처리됨 | 플러그인(`claude-handoff`)과 커스텀 훅이 모두 PreCompact 에 걸려있음 — 정상 동작. 부하가 신경 쓰이면 settings.json 에서 커스텀 항목을 빼거나 enabledPlugins 에서 플러그인을 끄세요 |
| Files Touched 가 잘못된 경로를 잡음 | `_looks_like_real_file_path` 가 `/` 시작 + 줄바꿈/명령토큰 없는 문자열만 허용. 그래도 false positive 가 나면 `handoff_core.py` 의 `COMMAND_LIKE_TOKENS` 에 추가 |
| `/compact` 가 자꾸 PreCompact 만 호출하고 clear 동작은 안 됨 | 의도된 동작. `/compact` 와 `/clear` 는 다른 이벤트. supervisor 를 통해 `/compact → /clear` 로 자동 변환하려면 `claude-handoff-supervisor.py` 를 직접 실행 |

---

## 7. 관련 파일

- 라이브러리: `~/.claude/hooks/handoff_core.py`
- 엔트리: `~/.claude/hooks/pre-compact-handoff.py`, `session-end-handoff.py`, `session-restore.sh`
- 보조: `~/.claude/hooks/claude-handoff-supervisor.py`
- 등록: `~/.claude/settings.json` 의 `hooks.PreCompact` / `hooks.SessionEnd` / `hooks.SessionStart`
- 저장소: `~/.claude/handoff/`
- 플러그인: `~/.claude/plugins/marketplaces/claude-handoff/handoff-plugin/`
- 본 저장소 샘플: `samples/handoff/`
