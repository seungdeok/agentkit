# browser-pilot

**AI가 실행 중인 브라우저와 모바일 WebView를 직접 보고, 조작하고, 반복하며 개발하는 agent skill.**

코드를 눈 감고 작성하는 대신, AI 에이전트가 스크린샷을 찍고, 콘솔 에러를 확인하고, DOM을 분석하고, 네트워크 요청을 검사한 다음 — 코드를 수정하고 다시 확인합니다. 코드 생성이 아닌, 진짜 개발 루프입니다.

---

## 동작 방식

```
사용자:  "결제 폼이 안 눌려요. 고쳐줘."

Agent:  → localhost:3001 탭에 연결
        → 스크린샷 촬영       ← UI를 직접 확인
        → 콘솔 로그 수집      ← TypeError: token is undefined 발견
        → auth.js 코드 분석
        → 버그 수정
        → 페이지 리로드
        → 스크린샷 재촬영     ← 수정 확인
        → "고쳤어요. Authorization 헤더에 token이 전달되지 않고 있었어요."
```

에이전트가 전체 루프를 처리합니다: **보기 → 진단 → 수정 → 검증**

---

## 포함된 Skills

| Skill           | 설명                                                        |
| --------------- | ----------------------------------------------------------- |
| `browser-pilot` | 실행 중인 브라우저 & WebView를 활용한 AI 네이티브 개발 루프 |

---

## 지원 플랫폼

| 플랫폼                 | 프로토콜                     | 필요 조건                                                    |
| ---------------------- | ---------------------------- | ------------------------------------------------------------ |
| Chrome (데스크탑)      | CDP over WebSocket           | `--remote-debugging-port`로 Chrome 실행                      |
| Safari (macOS)         | WebDriver / safaridriver     | Xcode + Safari에서 "원격 자동화 허용"                        |
| iOS 시뮬레이터 WebView | ios-webkit-debug-proxy → CDP | `brew install ios-webkit-debug-proxy`                        |
| Android WebView        | ADB 포트포워딩 → CDP         | Android SDK + `WebView.setWebContentsDebuggingEnabled(true)` |

---

## 설치

```bash
# 대화형 설치 (권장)
npx skills add your-username/browser-pilot

# 특정 에이전트에만 설치
npx skills add your-username/browser-pilot -a claude-code
npx skills add your-username/browser-pilot -a cursor
npx skills add your-username/browser-pilot -a opencode
npx skills add your-username/browser-pilot -a codex

# 모든 에이전트에 자동 설치
npx skills add your-username/browser-pilot --all -y
```

---

## 사용 예시

```
"로그인 페이지가 빈 화면이에요. 고쳐줘"
"/api/users 호출이 왜 401이 나는지 확인해줘"
"iOS 시뮬레이터 켜져 있어, WebView 확인하고 레이아웃 버그 고쳐줘"
"마지막 커밋 이후 localhost:3001이 이상해졌어"
"안드로이드 앱 WebView가 흰 화면이야 — 원인 찾아줘"
"지금 화면 스크린샷 찍고 문제 있는 거 고쳐줘"
"관리자 탭(localhost:3002) 콘솔 에러 확인해줘"
```

---

## 모노레포 지원

여러 포트에서 실행 중인 개발 서버를 동시에 지원합니다:

```
localhost:3000  →  앱 쉘
localhost:3001  →  관리자 대시보드
localhost:3002  →  API 문서 / Swagger
```

에이전트가 모든 열린 localhost 탭을 나열하고 컨텍스트에 맞는 탭을 자동으로 선택합니다.

---

## 개발 루프 흐름

1. **감지** — Chrome 포트, 시뮬레이터, ADB 기기 스캔
2. **연결** — 적절한 탭 또는 WebView에 attach
3. **관찰** — 스크린샷, 콘솔 로그, DOM, 네트워크 요청 수집
4. **수정** — 확인한 내용을 바탕으로 코드 수정
5. **검증** — 리로드 후 수정 확인
6. **반복** — 해결될 때까지 루프

---

## 라이선스

MIT
