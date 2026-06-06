# CLI Alias & Settings — 권한/설정 레퍼런스

> Claude Code를 매일 쓰면서 반복 입력을 줄이는 **셸 별칭(alias)**과,
> `settings.json`의 **권한(permissions)·스코프** 설정을 한 곳에 정리한 레퍼런스입니다.
> 권한 예시는 이 템플릿의 [`settings.json`](./settings.json)을 기준으로 합니다.

**기준:** Claude Code CLI · macOS·Linux(zsh·bash)

---

## 1. 셸 별칭 (CLI Alias)

`~/.zshrc` 또는 `~/.bashrc` 끝에 추가하고 `source ~/.zshrc`로 적용합니다.

```bash
# ── Claude Code 기본 ──────────────────────────────
alias cc='claude'                       # 대화형 세션 시작
alias ccc='claude --continue'           # 직전 세션 이어서
alias ccr='claude --resume'             # 세션 목록에서 골라 재개
alias ccp='claude --print'              # 비대화형(파이프/스크립트용) 1회 실행

# ── 디버깅 / 점검 ─────────────────────────────────
alias ccd='claude --debug'              # 훅·MCP 실행 로그까지 출력
alias ccdoc='claude doctor'             # 설치·환경 진단
alias ccup='claude update'              # 최신 버전으로 업데이트

# ── 모델 지정 ────────────────────────────────────
alias cco='claude --model opus'         # Opus로 시작
alias ccs='claude --model sonnet'       # Sonnet으로 시작
```

`--print`는 출력을 표준출력으로만 내보내므로 파이프와 함께 쓰기 좋습니다.

```bash
# 예: 변경 요약을 파일로
git diff | claude --print "이 diff를 3줄로 요약" > summary.txt
```

> **주의 — 권한 건너뛰기 별칭은 신중히**
> `--dangerously-skip-permissions`를 별칭으로 만들어 두면 편하지만, 모든 도구 호출의 확인을 건너뜁니다. 격리된 환경(컨테이너·일회성 작업)에서만 쓰고, 일상 별칭으로는 두지 마세요. 대신 `settings.json`의 `permissions.allow`로 **안전한 명령만 선별 허용**하는 편이 낫습니다(아래 3절).

---

## 2. 설정 파일 스코프 (어디에 두나)

설정은 **여러 파일에 분산**되며, 좁은 스코프가 넓은 스코프를 덮어씁니다.

| 경로 | 스코프 | Git 공유 | 용도 |
|------|--------|----------|------|
| `~/.claude/settings.json` | 사용자 전역 | 안 됨(내 PC) | 개인 기본값·알림 |
| `.claude/settings.json` | 프로젝트(팀) | **커밋되어 공유** | 팀 표준 권한·훅 |
| `.claude/settings.local.json` | 프로젝트(개인) | 안 됨(.gitignore) | 개인 로컬 오버라이드 |

> **권장**
> 팀이 함께 지킬 권한·가드레일은 **프로젝트 스코프(`.claude/settings.json`)**에 커밋하고, 나만의 임시 허용은 **`settings.local.json`**에 두세요. `settings.local.json`은 반드시 `.gitignore`에 포함합니다.

---

## 3. 권한(permissions) — 허용/차단

`permissions`는 훅과 **별도 시스템**입니다. 도구 호출을 패턴으로 허용·차단·확인합니다.

### 형식

```jsonc
"permissions": {
  "allow": [ "Tool(pattern)" ],   // 확인 없이 자동 허용
  "deny":  [ "Tool(pattern)" ],   // 무조건 차단
  "ask":   [ "Tool(pattern)" ]    // 매번 확인 (기본 동작)
}
```

- 패턴의 `*`는 **접두사 와일드카드**입니다. 예) `Bash(npm run *)`
- **`deny`가 `allow`보다 우선** 적용됩니다.

### 예시 (이 템플릿 `settings.json` 발췌)

```jsonc
"permissions": {
  "allow": [
    "Bash(npm run dev)",
    "Bash(npm run build)",
    "Bash(npm run lint)",
    "Bash(npm run test)"
  ],
  "deny": [
    "Bash(git push --force*)",
    "Bash(git reset --hard*)",
    "Bash(git commit --no-verify*)",
    "Bash(npm audit fix --force*)",
    "Bash(rm -rf /*)",
    "Bash(rm -rf .git*)",
    "Bash(*DROP TABLE*)",
    "Bash(*TRUNCATE*)",
    "Read(.env.local)",
    "Edit(.env.local)",
    "Write(.env.local)"
  ]
}
```

> **권한 vs 훅 — 언제 무엇을**
> 단순히 "이 명령은 허용/금지"는 **permissions**로 충분합니다. `git add && git commit`처럼 **체인 우회를 잡거나** stderr로 사유를 돌려줘야 하면 **훅(PreToolUse + exit 2)**으로 보완하세요. 자세한 훅 작성은 [Claude Code Hooks Guide](./claude-code-hook-guide.md)를 참고하세요.

---

## 4. 자주 쓰는 기타 설정

```jsonc
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",

  // 기본 모델
  "model": "opus",

  // 권한 기본 모드: default | acceptEdits | plan | bypassPermissions
  "permissions": {
    "defaultMode": "default",
    // 작업 디렉터리 밖에서 추가로 접근 허용할 경로
    "additionalDirectories": ["../shared"]
  },

  // 세션에 주입할 환경변수
  "env": {
    "NODE_ENV": "development"
  }
}
```

> **`settings.json`은 JSONC**
> Claude Code는 주석(`//`)이 포함된 JSONC를 읽습니다. 다만 일부 외부 도구는 표준 JSON만 읽으므로, 공유 전에는 주석 호환 여부를 확인하세요.

---

## 5. 점검 명령

| 상황 | 명령 |
|------|------|
| 등록된 권한·훅 확인 | 세션에서 `/hooks`, `/permissions` |
| 설정·환경 진단 | `claude doctor` |
| 훅·MCP 실행 로그 | `claude --debug` |
| 설정값 직접 보기 | `claude config` |

---

### 관련 문서

- [Claude Code Hooks Guide](./claude-code-hook-guide.md) — 훅 작성 상세 가이드
- [`settings.json`](./settings.json) — 이 템플릿의 권한·훅 실제 설정
