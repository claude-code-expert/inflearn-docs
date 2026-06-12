# 기대 출력 예시

## `./run-test.sh` (pre-compact 시나리오)

stdout 에 JSON 한 줄:

```json
{"systemMessage": "[PreCompact Handoff] Context snapshot saved to <out>/.claude/handoff/sample-session-0001.md. Captured 5 user messages and 2 file references. Updated latest handoff at <out>/.claude/handoff/latest-handoff.md."}
```

`out/.claude/handoff/sample-session-0001.md` 의 머리말:

```markdown
# Context Handoff

- **Generated**: 2026-05-13T11:55:00.000000
- **Session**: sample-session-0001
- **Trigger**: PreCompact (test)
- **Transcript**: `.../sample-transcript.jsonl`
- **CWD**: `.../samples/handoff`

## Recent User Requests

### Turn 1
```
slack 알림 훅을 설치하고 싶어. ~/.zshrc 에 webhook URL 을 어떻게 등록해?
```

...
```

## `./run-test.sh end`

`session-end-handoff.py` 는 동일 포맷의 markdown 을 `Trigger: SessionEnd(clear)` 로 표기해서 저장합니다.

## `./run-test.sh restore`

stdout 에 SessionStart hook payload (Claude Code 에 주입되는 형식):

```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<context-handoff>\nThe following is a context snapshot restored after a compaction cycle. ...\n</context-handoff>"
  }
}
```

## 확인 포인트

- `Captured N user messages` 에서 N 은 sample-transcript.jsonl 의 user 라인 수와 일치해야 함 (현재 5)
- `file references` 는 assistant tool_use 의 `file_path` 에서 수집된 절대경로 수
- 15분(`HANDOFF_LATEST_MAX_AGE_SEC=900`) 이상 지난 latest 는 restore 의 clear fallback 에서 거부됨
