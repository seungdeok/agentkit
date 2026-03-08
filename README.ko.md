# browser-pilot

**[English](./README.md) | 한국어**

**AI 네이티브 개발을 위한 에이전트 스킬 — AI 에이전트가 실시간 브라우저 탭과 모바일 WebView를 보고, 조작하고, 반복 개발할 수 있게 해줍니다.**

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

| 스킬            | 설명                                                          |
| --------------- | ------------------------------------------------------------- |
| `browser-pilot` | 실시간 브라우저 & WebView 검사를 활용한 AI 네이티브 개발 루프 |

---

## 지원 플랫폼

| 플랫폼                 | 프로토콜                       | 요구사항                                                     |
| ---------------------- | ------------------------------ | ------------------------------------------------------------ |
| Chrome (데스크탑)      | CDP over WebSocket             | `--remote-debugging-port` 옵션으로 Chrome 실행               |
| Safari (macOS)         | WebDriver / safaridriver       | Xcode + Safari에서 "원격 자동화 허용" 활성화                 |
| iOS 시뮬레이터 WebView | CDP via ios-webkit-debug-proxy | `brew install ios-webkit-debug-proxy`                        |
| Android WebView        | CDP via ADB port forward       | Android SDK + `WebView.setWebContentsDebuggingEnabled(true)` |

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

## 사용 예시

```
"로그인 페이지가 빈 화면만 나와. 고쳐줘"
"API /api/users 호출이 왜 401을 반환하는 거야?"
"iOS 시뮬레이터 켜져 있어, WebView 확인하고 레이아웃 버그 수정해줘"
"마지막 커밋 이후 localhost:3001에서 뭔가 깨졌어"
"Android 앱 WebView가 빈 화면이야 — 이유 찾아줘"
"현재 상태 스크린샷 찍고 문제 수정해줘"
"어드민 탭(localhost:3002) 콘솔 확인해줘"
```

---

## 멀티 서버 지원

다른 포트에서 실행 중인 여러 개발 서버에서 동작합니다:

```
localhost:3000  →  앱 쉘
localhost:3001  →  어드민 대시보드
localhost:3002  →  API 문서 / Swagger
```

에이전트가 열린 localhost 탭 목록을 확인하고 컨텍스트에 맞는 탭을 선택합니다.

---

## 개발 루프 동작 원리

1. **감지** — 열린 디버그 대상 스캔 (Chrome 포트, 시뮬레이터, ADB 기기)
2. **연결** — 올바른 탭 또는 WebView에 연결
3. **관찰** — 스크린샷, 콘솔 로그, DOM, 네트워크 호출 확인
4. **수정** — 확인한 내용을 바탕으로 코드 수정
5. **검증** — 새로고침 후 수정 사항 확인
6. **반복** — 해결될 때까지 반복

---

## 라이선스

MIT
