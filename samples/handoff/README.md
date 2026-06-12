# Claude Code Handoff 시스템 샘플

`~/.claude/hooks/` 의 커스텀 handoff 훅을 격리 환경에서 검증할 수 있는 샘플.

## 폴더 구성

```
samples/handoff/
├── handoff_core.py              # transcript 파싱 + 마크다운/JSON 작성 라이브러리
├── pre-compact-handoff.py       # PreCompact 엔트리
├── session-end-handoff.py       # SessionEnd(clear) 엔트리
├── session-restore.sh           # SessionStart 시 직전 handoff 주입
├── claude-handoff-supervisor.py # /compact → /clear 자동 치환 supervisor (참조용)
├── settings.example.json        # 훅 등록 스니펫
├── sample-transcript.jsonl      # 합성 transcript (user 5 turn + tool_use 2건)
├── run-test.sh                  # 격리 실행 러너 (HOME=./out/ 으로 분리)
├── expected-output.md           # 기대 결과 예시
└── README.md
```

## 빠른 테스트

```bash
chmod +x run-test.sh session-restore.sh

./run-test.sh          # PreCompact 시나리오
./run-test.sh end      # SessionEnd(clear) 시나리오
./run-test.sh restore  # SessionStart 주입 payload 확인
```

생성된 결과는 `./out/.claude/handoff/` 에 쌓이고, 본인의 진짜 `~/.claude/handoff/` 는 절대 건드리지 않습니다 (HOME 환경변수를 ./out/ 로 갈아끼움).

## 환경변수 튜닝

| 변수 | 기본값 | 효과 |
|------|--------|------|
| `HANDOFF_MAX_USER_MESSAGES` | 15 | handoff 에 포함할 최근 user 메시지 수 |
| `HANDOFF_MAX_ASSISTANT_CHARS` | 800 | assistant snippet 1건의 최대 길이 |
| `HANDOFF_DEDUP_THRESHOLD` | 0.85 | 중복 user 메시지 판정 임계값 (0~1) |
| `HANDOFF_LATEST_MAX_AGE_SEC` | 900 | `clear` fallback 으로 인정할 latest 의 최대 나이(초) |

## 자세한 설명

`docs/guide/handoff-system-guide.md` 참고.
