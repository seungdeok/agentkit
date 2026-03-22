# browser-pilot

**[English](./README.md) | 한국어**

AI 에이전트가 실시간 브라우저 탭을 보고, 조작하고, 검증하면서 코드를 작성할 수 있는 AI 네이티브 개발 루프입니다.

```
URL 열기 → 관찰 → 코드 수정 → 새로고침 → 검증 → 반복
```

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

## 지원 플랫폼

| 플랫폼                         | 플래그 / 프로토콜            | 환경변수                         | 요구사항                                       |
| ------------------------------ | ---------------------------- | -------------------------------- | ---------------------------------------------- |
| Chrome (데스크탑)              | `-p chrome` (기본값)         | `AGENT_BROWSER_PROVIDER=chrome`  | `--remote-debugging-port` 옵션으로 Chrome 실행 |
| Safari (macOS)                 | `-p safari`                  | `AGENT_BROWSER_PROVIDER=safari`  | Xcode + Safari에서 "원격 자동화 허용" 활성화   |
| iOS 시뮬레이터 / 실제 기기     | `-p ios --device <name>`     | `AGENT_BROWSER_PROVIDER=ios`     | Xcode + iOS 시뮬레이터 또는 연결된 기기        |
| Android 에뮬레이터 / 실제 기기 | `-p android --device <name>` | `AGENT_BROWSER_PROVIDER=android` | Android SDK + `adb`                            |

### 기기 선택

```bash
# iOS
npx agent-browser -p ios --device "iPhone 16 Pro" open http://localhost:3000

# Android
npx agent-browser -p android --device "Pixel 8" open http://localhost:3000

# 환경변수로 설정 (CI 환경에 유용)
export AGENT_BROWSER_PROVIDER=ios
export AGENT_BROWSER_IOS_DEVICE="iPhone 16 Pro"
npx agent-browser open http://localhost:3000
```

### 세션

`--session <name>`으로 작업별 격리된 브라우저 인스턴스를 실행합니다. 임시 상태로, 종료 시 초기화됩니다.

```bash
# 두 개의 격리된 인스턴스 병렬 실행
npx agent-browser --session checkout open http://localhost:3000/checkout
npx agent-browser --session admin open http://localhost:3001/admin
```

---

## 이럴 때 쓰세요

- **뭔가 깨진 것 같을 때** — 코드를 수정했는데 화면이 이상하거나, 버그 제보를 받았는데 어디가 문제인지 모를 때.
  ```
  "결제 페이지가 빈 화면이야 — localhost:3000 확인해서 고쳐줘"
  ```
- **수정이 제대로 됐는지 확인하고 싶을 때** — 코드를 고쳤는데 실제로 의도한 대로 동작하는지 확인하고 다음으로 넘어가고 싶을 때.
  ```
  "방금 인증 로직 수정했어 — localhost:3000/login 확인해서 잘 되는지 봐줘"
  ```
- **에러는 보이는데 원인을 모를 때** — UI에서 뭔가 이상한 건 느끼지만 코드 어디를 봐야 할지 모를 때.
  ```
  "제출 버튼 눌러도 아무 반응이 없어 — 이유 찾아줘"
  ```
- **클릭하면 다른 페이지나 서비스로 넘어갈 때** — 페이지 간 또는 포트 간 이동이 포함된 흐름을 에이전트가 따라가면서 확인해야 할 때.
  ```
  "localhost:3000에서 결제 버튼 누르고 완료 페이지까지 따라가줘"
  ```
- **페이지 안에 다른 출처가 임베드되어 있을 때** — 다른 URL의 iframe이나 위젯이 포함된 페이지를 검사하거나 조작해야 할 때.
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
