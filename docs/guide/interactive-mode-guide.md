# Claude Code 인터랙티브 모드 완전 정리

> 출처: [code.claude.com/docs/en/interactive-mode](https://code.claude.com/docs/en/interactive-mode)  
> 프롬프트 창에서 `?`를 누르면 현재 터미널 환경에서 사용 가능한 단축키 목록을 확인할 수 있다.

---

## macOS Option 키 설정 (먼저 확인)

`Alt+B`, `Alt+F`, `Alt+Y`, `Alt+M`, `Alt+P`, `Alt+T` 등 Option 키 단축키는 터미널 설정이 필요하다.

| 터미널 | 설정 방법 |
|--------|---------|
| **iTerm2** | Settings → Profiles → Keys → General → Left/Right Option key를 `Esc+`로 변경 |
| **Apple Terminal** | Settings → Profiles → Keyboard → `Use Option as Meta Key` 체크 |
| **VS Code** | settings.json에 `"terminal.integrated.macOptionIsMeta": true` 추가 |

---

## 1. 일반 제어 단축키

| 단축키 | 설명 |
|--------|------|
| `Ctrl+C` | 현재 입력 또는 생성 중인 응답 취소 |
| `Ctrl+D` | Claude Code 세션 종료 |
| `Ctrl+L` | 입력창 초기화 + 화면 다시 그리기 (대화 히스토리는 유지) |
| `Ctrl+O` | 트랜스크립트 뷰어 토글 — 도구 사용 내역, MCP 호출 상세 보기 |
| `Ctrl+R` | 이전 명령어 역방향 검색 |
| `Ctrl+B` | 실행 중인 Bash 명령을 백그라운드로 전환 (tmux 사용자는 두 번) |
| `Ctrl+T` | 태스크 목록 토글 (터미널 하단에 표시) |
| `Ctrl+G` 또는 `Ctrl+X Ctrl+E` | 기본 텍스트 편집기로 프롬프트 열기 |
| `Ctrl+X Ctrl+K` | 모든 백그라운드 에이전트 종료 (3초 내 두 번 눌러 확인) |
| `Esc` + `Esc` | 이전 시점으로 되돌리기(Rewind) 또는 특정 메시지부터 요약 |
| `Shift+Tab` | 권한 모드 순환 (default → acceptEdits → plan → auto 등) |
| `Option+P` / `Alt+P` | 프롬프트 지우지 않고 모델 전환 |
| `Option+T` / `Alt+T` | Extended Thinking 모드 토글 |
| `Option+O` / `Alt+O` | Fast Mode 토글 |
| `←` / `→` 화살표 | 권한 다이얼로그 탭 간 이동 |
| `↑` / `↓` 화살표 또는 `Ctrl+P` / `Ctrl+N` | 멀티라인 입력 내 커서 이동 / 명령어 히스토리 탐색 |

> **`Ctrl+V` 또는 `Cmd+V` (iTerm2) 또는 `Alt+V` (Windows)**: 클립보드 이미지 붙여넣기. `[Image #N]` 칩으로 삽입되며 프롬프트에서 참조 가능

---

## 2. 텍스트 편집 단축키

| 단축키 | 설명 |
|--------|------|
| `Ctrl+A` | 현재 줄 맨 앞으로 커서 이동 |
| `Ctrl+E` | 현재 줄 맨 끝으로 커서 이동 |
| `Ctrl+K` | 커서부터 줄 끝까지 삭제 (삭제한 텍스트 붙여넣기 가능) |
| `Ctrl+U` | 커서부터 줄 시작까지 삭제 (macOS: `Cmd+Backspace`와 동일) |
| `Ctrl+W` | 이전 단어 삭제 (Windows: `Ctrl+Backspace`와 동일) |
| `Ctrl+Y` | `Ctrl+K` / `Ctrl+U` / `Ctrl+W`로 삭제한 텍스트 붙여넣기 |
| `Alt+Y` | 붙여넣기 후 이전 삭제 텍스트 순환 (Ctrl+Y 이후에 사용) |
| `Alt+B` | 단어 단위 왼쪽 이동 (macOS: Option as Meta 설정 필요) |
| `Alt+F` | 단어 단위 오른쪽 이동 (macOS: Option as Meta 설정 필요) |

---

## 3. 여러 줄 입력 방법

| 방법 | 단축키 | 지원 환경 |
|------|--------|---------|
| 백슬래시 + Enter | `\` + `Enter` | 모든 터미널 |
| Option + Enter | `Option+Enter` | macOS (Option as Meta 설정 후) |
| Shift + Enter | `Shift+Enter` | iTerm2, WezTerm, Ghostty, Kitty, Warp, Apple Terminal |
| Ctrl + J | `Ctrl+J` | 모든 터미널 (설정 불필요) |
| 직접 붙여넣기 | 코드·로그 그대로 붙여넣기 | 모든 터미널 |

> VS Code, Cursor, Windsurf, Alacritty, Zed에서 `Shift+Enter`를 쓰려면 `/terminal-setup` 을 한 번 실행해야 한다.

---

## 4. 빠른 입력 접두어

| 접두어 | 설명 |
|--------|------|
| `/` | 슬래시 커맨드 또는 스킬 실행. 글자를 이어 입력하면 필터링됨 |
| `!` | 셸 모드 — 명령어를 직접 실행하고 출력 결과를 세션에 추가 |
| `@` | 파일 경로 자동완성 트리거 |

### `!` 셸 모드 예시

```bash
# Claude Code 프롬프트에서 직접 셸 명령 실행
! ls src/
! git status
! npm run test
```

셸 모드로 실행한 명령어의 출력 결과가 현재 대화 컨텍스트에 자동으로 추가된다. 별도 파일을 열거나 터미널 탭을 전환하지 않아도 된다.

---

## 5. 트랜스크립트 뷰어 단축키

`Ctrl+O`로 트랜스크립트 뷰어를 열면 아래 단축키가 활성화된다.

| 단축키 | 설명 |
|--------|------|
| `Ctrl+E` | 모든 내용 펼치기/접기 토글 |
| `[` | 전체 대화를 터미널 스크롤백으로 출력 (Cmd+F 검색 가능) |
| `v` | 대화를 임시 파일로 저장 후 기본 편집기로 열기 |
| `q` 또는 `Ctrl+C` 또는 `Esc` | 트랜스크립트 뷰어 종료 |

---

## 6. 백그라운드 실행

오래 걸리는 명령어를 백그라운드로 돌리고, 그 사이에 다른 작업을 계속할 수 있다.

**실행 방법**

- Claude에게 "백그라운드로 실행해줘"라고 요청
- 실행 중인 Bash 명령에서 `Ctrl+B` 누르기 (tmux 사용자는 두 번)

**자주 백그라운드로 돌리는 명령어**

```bash
# 빌드 도구
webpack, vite, make

# 패키지 설치
npm install, yarn, pnpm install

# 테스트 러너
jest --watch, pytest

# 개발 서버
npm run dev, python manage.py runserver

# 오래 걸리는 작업
docker build, terraform apply
```

> 백그라운드 태스크 출력은 파일로 저장되며, Claude가 `Read` 도구로 내용을 가져올 수 있다. 출력이 5GB를 초과하면 자동으로 종료된다. 백그라운드 기능을 완전히 끄려면 `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` 환경 변수를 설정한다.

---

## 7. 명령어 히스토리

- 히스토리는 **작업 디렉터리별로 저장**된다
- `/clear` 실행 시 히스토리 초기화 (이전 대화는 보존되어 재개 가능)
- `↑` / `↓` 화살표로 탐색
- `!` 히스토리 확장은 기본적으로 비활성화됨

**`Ctrl+R` 역방향 검색 사용법**

1. `Ctrl+R` → 역방향 검색 활성화
2. 검색어 입력 → 매칭 결과가 실시간으로 표시됨
3. `Ctrl+R` 반복 → 이전 매칭으로 이동
4. `Tab` 또는 `Esc` → 선택 후 편집 계속
5. `Enter` → 선택 후 즉시 실행
6. `Ctrl+C` → 검색 취소 (원래 입력 복원)

---

## 8. Vim 편집 모드

`/config` → Editor mode에서 Vim 모드를 활성화할 수 있다.

### 모드 전환

| 명령어 | 동작 | 현재 모드 |
|--------|------|---------|
| `Esc` | NORMAL 모드 진입 | INSERT, VISUAL |
| `i` | 커서 앞에서 INSERT 진입 | NORMAL |
| `I` | 줄 맨 앞에서 INSERT 진입 | NORMAL |
| `a` | 커서 뒤에서 INSERT 진입 | NORMAL |
| `A` | 줄 맨 끝에서 INSERT 진입 | NORMAL |
| `o` | 아래 줄 추가 후 INSERT | NORMAL |
| `O` | 위 줄 추가 후 INSERT | NORMAL |
| `v` | 문자 단위 비주얼 선택 | NORMAL |
| `V` | 줄 단위 비주얼 선택 | NORMAL |

### 이동 (NORMAL 모드)

| 명령어 | 동작 |
|--------|------|
| `h` / `j` / `k` / `l` | 좌 / 하 / 상 / 우 이동 |
| `w` | 다음 단어 |
| `e` | 단어 끝 |
| `b` | 이전 단어 |
| `0` | 줄 맨 앞 |
| `$` | 줄 맨 끝 |
| `^` | 첫 번째 비공백 문자 |
| `gg` | 입력 맨 앞 |
| `G` | 입력 맨 끝 |
| `f{문자}` | 해당 문자로 앞으로 점프 |
| `F{문자}` | 해당 문자로 뒤로 점프 |

### 편집 (NORMAL 모드)

| 명령어 | 동작 |
|--------|------|
| `x` | 문자 삭제 |
| `dd` | 줄 삭제 |
| `D` | 줄 끝까지 삭제 |
| `dw` / `de` / `db` | 단어 삭제 |
| `cc` | 줄 변경 |
| `C` | 줄 끝까지 변경 |
| `cw` | 단어 변경 |
| `yy` / `Y` | 줄 복사 |
| `p` | 커서 뒤에 붙여넣기 |
| `P` | 커서 앞에 붙여넣기 |
| `u` | 실행 취소 |
| `.` | 마지막 변경 반복 |
| `J` | 줄 합치기 |

### 텍스트 객체 (NORMAL 모드)

`d`, `c`, `y` 연산자와 조합해서 사용한다.

| 명령어 | 동작 |
|--------|------|
| `iw` / `aw` | 단어 안쪽 / 단어 포함 |
| `i"` / `a"` | 쌍따옴표 안쪽 / 포함 |
| `i'` / `a'` | 홑따옴표 안쪽 / 포함 |
| `i(` / `a(` | 괄호 안쪽 / 포함 |
| `i[` / `a[` | 대괄호 안쪽 / 포함 |
| `i{` / `a{` | 중괄호 안쪽 / 포함 |

### Visual 모드

| 명령어 | 동작 |
|--------|------|
| `d` / `x` | 선택 영역 삭제 |
| `y` | 선택 영역 복사 |
| `c` / `s` | 선택 영역 변경 |
| `>` / `<` | 들여쓰기 / 내어쓰기 |
| `~` / `u` / `U` | 대소문자 토글 / 소문자 / 대문자 |
| `J` | 선택 줄 합치기 |
| `o` | 커서와 선택 시작점 교체 |

> `Ctrl+V` (블록 비주얼 모드)는 지원하지 않는다.

---

## 9. 기타 유용한 기능

### `/btw` — 사이드 질문

작업 흐름을 끊지 않고 간단한 질문을 할 때 사용한다.

```
/btw TypeScript에서 타입 단언과 타입 가드의 차이가 뭐야?
```

현재 작업 컨텍스트를 유지한 채 짧게 답변을 받을 수 있다.

### `/tasks` — 태스크 목록

`Ctrl+T`로도 토글 가능. 터미널 하단에 현재 진행 중인 태스크 목록을 표시한다.

### 음성 입력

음성 받아쓰기가 활성화된 경우 `Space`를 누르거나 길게 눌러 음성으로 프롬프트를 입력할 수 있다. `/voice tap`으로 탭 방식으로 전환 가능.

---

## 빠른 참조 카드

```
자주 쓰는 단축키 top 10

Ctrl+C    → 취소
Ctrl+L    → 화면 정리
Ctrl+R    → 히스토리 검색
Ctrl+O    → 도구 사용 내역 보기
Ctrl+B    → 백그라운드 전환
Shift+Tab → 권한 모드 전환
Esc Esc   → 되돌리기
/         → 커맨드 목록
!         → 셸 명령 직접 실행
@         → 파일 자동완성
```
