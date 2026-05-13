# Claude Code Slack 알림 훅 가이드

> Claude Code 가 응답을 완료하는 시점(`Stop` 이벤트)에 Slack 채널로 작업 완료 + 응답 요약을 자동 전송하는 훅을 설치하고 검증하는 방법.

---

## 1. 동작 개요

```
[Claude Code 응답 종료]
        │
        ▼
   Stop 이벤트 발화
        │  stdin = JSON
        │  { session_id, cwd, hook_event_name,
        │    stop_hook_active, last_assistant_message,
        │    transcript_path }
        ▼
  ~/.claude/hooks/notify-slack.sh
        │  jq 파싱 → Slack Block Kit payload 생성
        ▼
  curl POST  $CLAUDE_SLACK_WEBHOOK_URL
        │
        ▼
     Slack 채널에 알림 도착
```

핵심 구성:

| 구성 요소 | 위치 | 역할 |
|----------|------|------|
| Webhook URL | `~/.zshrc` 의 `CLAUDE_SLACK_WEBHOOK_URL` | 전송 대상 채널 |
| 훅 스크립트 | `~/.claude/hooks/notify-slack.sh` | stdin → Slack 전송 |
| 훅 등록 | `~/.claude/settings.json` 의 `hooks.Stop` | 호출 시점 정의 |
| 디버그 로그 | `~/.claude/hooks/debug-slack.log` | HTTP 응답 / 에러 추적 |

---

## 2. 사전 준비

### 2-1. Slack Incoming Webhook 발급

1. <https://api.slack.com/apps> 에서 앱 생성 (또는 기존 앱 선택)
2. **Incoming Webhooks** → `Activate Incoming Webhooks: On`
3. **Add New Webhook to Workspace** → 알림을 받을 채널 선택
4. 발급된 URL 을 복사 (`https://hooks.slack.com/services/T.../B.../...`)

### 2-2. 필수 도구

```bash
command -v jq    # 미설치 시: brew install jq
command -v curl  # macOS 기본 포함
```

---

## 3. 환경변수 등록

`~/.zshrc` 마지막에 한 줄을 추가합니다. 토큰 부분은 발급받은 값으로 교체하세요.

```bash
# claude hook for slack
export CLAUDE_SLACK_WEBHOOK_URL="https://hooks.slack.com/services/TXXXXXX/BXXXXXX/ASDFASDFASSDF"
```

적용 및 확인:

```bash
source ~/.zshrc
echo "$CLAUDE_SLACK_WEBHOOK_URL"   # 값이 출력되면 OK
```

> 보안: Webhook URL 은 토큰과 동급입니다. 깃에 커밋하지 말고 dotfiles 저장소에 올릴 때도 secret manager 를 사용하세요.

---

## 4. 훅 스크립트 설치

이 저장소의 `samples/slack-notification/notify-slack.sh` 를 그대로 사용합니다.

```bash
# 글로벌 훅 위치에 복사
mkdir -p ~/.claude/hooks
cp samples/slack-notification/notify-slack.sh ~/.claude/hooks/notify-slack.sh
chmod +x ~/.claude/hooks/notify-slack.sh
```

### 4-1. 스크립트가 수행하는 일

1. `CLAUDE_SLACK_WEBHOOK_URL` 환경변수 확인 — 없으면 조용히 종료
2. stdin JSON 을 임시파일로 받아 `jq empty` 로 유효성 검증
3. `stop_hook_active=true` 인 경우 종료 (무한루프 방지)
4. `cwd` 로부터 프로젝트명, 현재 시각 추출
5. `last_assistant_message` 를 500자로 truncate + Slack mrkdwn 이스케이프 (`&`, `<`, `>`) + 코드블록 `[code]` 치환
6. Block Kit payload 구성 후 `curl POST` 로 Webhook 전송
7. 결과를 `debug-slack.log` 에 기록 (10KB 초과 시 자동 로테이션)

### 4-2. 엣지 케이스 처리

| 상황 | 동작 |
|------|------|
| stdin 비어있음 | 요약 없이 기본 알림 발송 |
| stdin JSON 깨짐 | "요약 파싱 실패" 표기로 알림 발송 |
| `last_assistant_message` 비어있음 | 요약 블록 없이 발송 |
| 응답에 ` ``` ` 코드블록 포함 | `[code]` 로 치환되어 mrkdwn 깨짐 방지 |
| Webhook URL 미설정 | 무음 종료 (exit 0) — Claude Code 흐름 방해 X |

---

## 5. Claude Code 훅 등록

`~/.claude/settings.json` 의 `hooks` 객체에서 `Stop` 배열에 항목을 추가합니다.

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"작업 완료!\" with title \"Claude Code\"'; afplay /System/Library/Sounds/Hero.aiff"
          },
          {
            "type": "command",
            "command": "zsh ~/.claude/hooks/notify-slack.sh"
          }
        ]
      }
    ]
  }
}
```

> 위 예시는 macOS 시스템 알림 + 사운드도 함께 발화합니다. Slack 만 원하면 첫 번째 command 객체를 제거하세요.

이미 다른 `hooks.Stop` 항목이 있다면 `hooks` 배열 안에 객체로 끼워 넣기만 하면 됩니다.

---

## 6. 로컬 호출 테스트

샘플 폴더에는 글로벌 훅을 건드리지 않고 스크립트 자체를 검증하는 러너가 있습니다.

```bash
cd samples/slack-notification
chmod +x notify-slack.sh run-test.sh

./run-test.sh           # 정상 케이스: test-payload.json 으로 발송
./run-test.sh empty     # 빈 stdin 케이스
./run-test.sh invalid   # 깨진 JSON 케이스
```

성공 시:

- Slack 채널에 `:white_check_mark: Claude Code 작업 완료` 메시지 도착
- `samples/slack-notification/debug-slack.log` 에 `HTTP: 200` 로그 1줄 기록

실패 시 체크리스트:

| 증상 | 원인 / 해결 |
|------|-------------|
| `CLAUDE_SLACK_WEBHOOK_URL 미설정` | `source ~/.zshrc` 후 같은 셸에서 재실행 |
| `HTTP: 404` | Webhook URL 의 채널이 삭제되었거나 토큰 오타 |
| `HTTP: 403` | 워크스페이스에서 앱이 비활성화됨 — Slack App 페이지 확인 |
| `invalid_payload` | jq 패치 실패. log 파일에서 payload 원문 확인 |
| Slack 메시지에 `<`, `&` 등이 보임 | 이스케이프 영역 직접 수정 (기본 동작은 mrkdwn safe 변환) |

---

## 7. 운영 팁

- **테스트 시 채널 분리**: 개발 중에는 `#claude-test` 같은 별도 채널의 Webhook 을 따로 발급해 두면 동료 알림을 오염시키지 않습니다.
- **무한루프 방지**: Stop hook 내부에서 또 다른 Claude Code 세션을 시작하면 `stop_hook_active=true` 분기로 빠지도록 설계되어 있습니다. 임의로 이 분기를 제거하지 마세요.
- **여러 프로젝트 구분**: payload 의 프로젝트명은 `cwd` 의 basename 입니다. 동일 이름 디렉토리가 여럿이면 환경변수 `SLACK_PROJECT_LABEL` 을 추가하도록 스크립트를 확장하는 패턴을 권장합니다.
- **다른 이벤트로 확장**: `SubagentStop`, `PreToolUse`, `Notification` 등 다른 이벤트에 같은 패턴을 적용할 수 있습니다. stdin 으로 들어오는 JSON 필드만 이벤트별로 다르므로 jq 경로만 바꿔주면 됩니다.

---

## 8. 참고 파일

- 본 저장소 샘플: `samples/slack-notification/`
- 글로벌 훅 (현재 설치본): `~/.claude/hooks/notify-slack.sh`
- 훅 등록 위치: `~/.claude/settings.json` 의 `hooks.Stop`
- 디버그 로그: `~/.claude/hooks/debug-slack.log`
