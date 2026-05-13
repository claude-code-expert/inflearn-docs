# Slack Notification Hook 샘플

Claude Code 의 `Stop` 이벤트에서 Slack 으로 작업 완료 알림을 보내는 훅의 동작 샘플입니다.

## 폴더 구성

```
samples/slack-notification/
├── notify-slack.sh         # 실제 훅 본체 (stdin 으로 JSON 받고 Slack 전송)
├── zshrc.example.sh        # ~/.zshrc 에 추가할 환경변수 예시
├── settings.example.json   # ~/.claude/settings.json 에 등록할 훅 정의 예시
├── test-payload.json       # 정상 케이스 stdin 샘플
├── run-test.sh             # 로컬에서 훅을 호출해보는 러너
└── README.md
```

## 빠른 테스트

```bash
# 1) 환경변수가 살아있는지 확인 (없으면 ~/.zshrc 를 source)
echo "$CLAUDE_SLACK_WEBHOOK_URL"

# 2) 실행 권한 부여 (최초 1회)
chmod +x notify-slack.sh run-test.sh

# 3) 정상 케이스
./run-test.sh

# 4) 엣지 케이스
./run-test.sh empty      # 빈 stdin
./run-test.sh invalid    # 깨진 JSON
```

발송 후 `debug-slack.log` 의 마지막 라인에서 `HTTP: 200` 이 보이면 성공입니다.

## 글로벌 훅으로 등록

`samples/slack-notification/notify-slack.sh` 를 `~/.claude/hooks/notify-slack.sh` 로 복사하고,
`~/.claude/settings.json` 의 `hooks.Stop` 배열에 `settings.example.json` 처럼 한 줄 추가합니다.

## 자세한 설명

`docs/guide/slack-notification-hook-guide.md` 를 참고하세요.
