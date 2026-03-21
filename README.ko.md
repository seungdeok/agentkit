# browser-pilot

**[English](./README.md) | 한국어**

**AI 네이티브 개발을 위한 에이전트 스킬 — AI 에이전트가 실시간 브라우저 탭을 보고, 조작하고, 반복 개발할 수 있게 해줍니다.**

코드를 눈 감고 작성하는 대신, 에이전트가 스크린샷을 찍고, 콘솔 에러를 잡고, DOM을 검사하고, 네트워크 호출을 확인한 뒤 코드를 수정하고 다시 확인할 수 있습니다. 단순한 코드 생성이 아닌, 진짜 개발 루프입니다.

---

## 동작 방식

```
당신:      "결제 폼이 제출이 안 돼. 고쳐줘."

에이전트:  → localhost:3001에 연결
           → 스크린샷 촬영  ← UI 확인
           → 콘솔 로그 확인 ← TypeError: token is undefined 발견
           → auth.js 읽기
           → 버그 수정
           → 페이지 새로고침
           → 스크린샷 촬영  ← 정상 작동 확인
           → "수정 완료. Authorization 헤더에 토큰이 전달되지 않았습니다."
```

에이전트가 전체 루프를 처리합니다: **확인 → 진단 → 수정 → 검증.**

---

## 스킬

| 스킬            | 설명                                                   |
| --------------- | ------------------------------------------------------ |
| `browser-pilot` | 실시간 브라우저 탭 검사를 활용한 AI 네이티브 개발 루프 |

---

## 지원 플랫폼

| 플랫폼            | 프로토콜                             | 요구사항                                       |
| ----------------- | ------------------------------------ | ---------------------------------------------- |
| Chrome (데스크탑) | agent-browser --cdp / --auto-connect | `--remote-debugging-port` 옵션으로 Chrome 실행 |
| Safari (macOS)    | agent-browser -p safari              | Xcode + Safari에서 "원격 자동화 허용" 활성화   |

---

## 설치

```bash
# Interactive (recommended)
npx skills add seungdeok/browser-pilot
```

### Claude Code

```
/plugin install browser-pilot@seungdeok
```

### Claude.ai

Claude.ai 인터페이스에서 직접 업로드합니다. 자세한 방법은 [Claude에서 스킬 사용하기](https://support.claude.com/en/articles/12512180-using-skills-in-claude#h_a4222fa77b)를 참고하세요.

### API

API를 통한 커스텀 스킬 업로드 및 사용 방법은 [Skills API 퀵스타트](https://docs.claude.com/en/api/skills-guide#creating-a-skill)를 참고하세요.

---

## 이럴 때 쓰세요

### 뭔가 깨진 것 같을 때
코드를 수정했는데 화면이 이상하거나, 버그 제보를 받았는데 어디가 문제인지 모를 때.

```
"결제 페이지가 빈 화면이야 — localhost:3000 확인해서 고쳐줘"
"마지막 커밋 이후 뭔가 깨진 것 같아, localhost:3001 보고 뭐가 문제인지 알려줘"
```

### 수정이 제대로 됐는지 확인하고 싶을 때
코드를 고쳤는데 실제로 의도한 대로 동작하는지 확인하고 다음으로 넘어가고 싶을 때.

```
"방금 인증 로직 수정했어 — localhost:3000/login 확인해서 잘 되는지 봐줘"
"방금 고친 게 /api/users 401 에러 해결했는지 확인해줘"
```

### 에러는 보이는데 원인을 모를 때
UI에서 뭔가 이상한 건 느끼지만 코드 어디를 봐야 할지 모를 때.

```
"제출 버튼 눌러도 아무 반응이 없어 — 이유 찾아줘"
"폼이 제출되는 것 같은데 그 이후에 아무것도 안 일어나 — 뭔지 확인해줘"
```

### 클릭하면 다른 페이지나 서비스로 넘어갈 때
페이지 간 또는 포트 간 이동이 포함된 흐름을 에이전트가 따라가면서 확인해야 할 때.

```
"localhost:3000에서 결제 버튼 누르고 완료 페이지까지 따라가줘"
"localhost:3000에서 로그인 흐름 진행하고 localhost:3001로 리다이렉트 잘 되는지 확인해줘"
```

### 페이지 안에 다른 출처가 임베드되어 있을 때
다른 URL의 iframe이나 위젯이 포함된 페이지를 검사하거나 조작해야 할 때.

```
"localhost:3000의 결제 위젯이 안 로딩돼 — 내부에서 뭔 일이 일어나는지 확인해줘"
```

---

## 개발 루프 동작 원리

1. **열기** — URL로 직접 접속 (예: `localhost:3000`)
2. **관찰** — 스크린샷, 요소 트리, 콘솔 로그, 네트워크 호출 확인
3. **수정** — 확인한 내용을 바탕으로 코드 수정
4. **검증** — 새로고침 후 수정 사항 확인
5. **반복** — 해결될 때까지 반복

```
당신:      "localhost:3000 확인해서 고쳐줘"

에이전트:  → npx agent-browser open http://localhost:3000
           → npx agent-browser screenshot snapshot.png   ← 빈 화면 확인
           → npx agent-browser eval "JSON.stringify(window.__devLoopLogs)"
                                                         ← TypeError: token is undefined 발견
           → auth.js 읽기
           → 버그 수정
           → npx agent-browser eval "location.reload(true)"
           → npx agent-browser screenshot after-fix.png  ← 정상 작동 확인
           → npx agent-browser close
           → "수정 완료. Authorization 헤더에 토큰이 전달되지 않았습니다."
```

---

## 라이선스

MIT
