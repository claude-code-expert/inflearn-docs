# ~/.zshrc 에 아래 한 줄을 추가합니다.
# 실제 토큰은 Slack App 의 Incoming Webhook URL 로 교체하세요.

# claude hook for slack
export CLAUDE_SLACK_WEBHOOK_URL="https://hooks.slack.com/services/TXXXXXX/BXXXXXX/ASDFASDFASSDF"

# 적용:
#   source ~/.zshrc
# 확인:
#   echo "$CLAUDE_SLACK_WEBHOOK_URL"
