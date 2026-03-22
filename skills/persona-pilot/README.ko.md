# persona-pilot

**[English](./README.md) | 한국어**

Claude Code용 멀티 에이전트 유저 테스트 스킬. 프로덕트 스펙, URL, 또는 API를 던져주면 페르소나를 자동으로 생성하고, 각 에이전트가 자신의 관점에서 테스트를 수행한 뒤 구조화된 피드백 보고서를 만들어 줍니다.

```
타겟 분석 → 페르소나 생성 → 에이전트 spawn → 피드백 수합 → 보고서 생성
```

---

## 동작 방식

```
당신:      "이 스펙으로 유저 테스트 해줘: ./docs/onboarding.md"

에이전트:  → 스펙 읽기
           → 페르소나 4개 생성 (초보 사용자, 파워 유저, 모바일 유저, 접근성 유저)
           → 각 페르소나 에이전트가 자신의 관점에서 스펙 리뷰
           → .persona-pilot/report.md에 결과 집계
           → .persona-pilot/improvements.md에 개선 제안 작성
           → "평균 평점: 3.2/5. 주요 문제: 비기술 사용자에게 온보딩 흐름이 불명확합니다."
```

---

## 커맨드

| 커맨드 | 설명 |
|--------|------|
| `/persona-pilot` | 전체 파이프라인 — init → run → improve (기본값) |
| `/persona-pilot:init` | 페르소나 그룹 구성 (프리셋 또는 자동 생성) |
| `/persona-pilot:run` | 구성된 페르소나로 에이전트 실행 → 보고서 생성 |
| `/persona-pilot:improve` | 보고서 기반으로 개선 제안 |

**빠른 시작:**
```
/persona-pilot ./docs/product-spec.md
```

---

## UT 모드

타겟에 따라 자동 판별:

| 모드 | 타겟 | 사용 도구 |
|------|------|----------|
| **spec** | 파일 경로 (`.md`, `.txt`, `.yaml`, `.json`) | Read, Glob, Grep |
| **web** | URL (`http://`, `https://`, `localhost`) | `npx agent-browser` |
| **api** | API 엔드포인트, Swagger, OpenAPI | Bash / curl |

---

## 페르소나

### 자동 생성

타겟 내용으로부터 페르소나를 도출합니다. 에이전트가 스펙을 읽거나 UI/API를 관찰한 뒤, 실제 사용자 세그먼트를 반영하는 3–5개의 페르소나를 생성합니다.

페르소나 예시:
```json
{
  "id": "persona-1",
  "name": "지수",
  "role": "첫 번째 사용자",
  "age": 28,
  "tech_level": "low",
  "goals": ["빠르게 가입하기", "서비스 가치 파악"],
  "frustrations": ["전문 용어가 많은 UI", "단계가 너무 많음"],
  "device": "mobile",
  "test_focus": ["온보딩 흐름", "CTA 명확성"],
  "questions": [
    "10초 안에 이 제품이 무엇인지 이해할 수 있나?",
    "튜토리얼 없이도 가입 흐름이 직관적인가?"
  ]
}
```

### 프리셋

일반적인 제품 유형에 맞는 내장 프리셋 사용:

```
/persona-pilot:init --preset saas
/persona-pilot:init --preset ecommerce
/persona-pilot:init --preset mobile-app
/persona-pilot:init --preset general
```

### 커스텀 페르소나

`.persona-pilot/personas.json`을 위 스키마에 맞게 직접 작성하거나, 자연어로 페르소나를 설명하면 에이전트가 구조화해 줍니다.

---

## 보고서 출력

`/persona-pilot:run` 실행 후 `.persona-pilot/report.md`에 저장됩니다:

```markdown
# Persona Pilot Report

타겟: ./docs/onboarding.md
모드: spec
테스트한 페르소나: 4개
평균 평점: 3.2 / 5

## 요약
전반적인 인상은 엇갈립니다. 비기술 사용자는 온보딩 흐름의 용어에 어려움을 겪습니다.
파워 유저는 기능 세트가 마음에 들지만 고급 설정 문서가 부족합니다.

## 페르소나별 피드백

### 지수 — 첫 번째 사용자 (★★★☆☆)
...

## 종합 인사이트

### 공통 불편 사항
1. 온보딩 용어가 너무 전문적 (4명 중 3명)
2. 설정 가이드에 시각적 예시 없음 (4명 중 2명)
```

---

## 개선 제안 출력

`/persona-pilot:improve` 실행 후 `.persona-pilot/improvements.md`에 저장됩니다:

```markdown
# 개선 제안

## P0 — 필수 수정 (런치 전 반드시)

### 온보딩 용어 간소화
영향 받는 페르소나: 지수, 민준
문제: 1단계에 "API 키 프로비저닝"과 "OAuth 스코프"가 설명 없이 등장합니다.
제안: 쉬운 언어로 대체 + 툴팁 정의 추가
예상 효과: 1단계 이탈률 ~40% 감소
```

---

## web 모드 — agent-browser 연동

web 모드에서는 각 페르소나가 격리된 브라우저 세션에서 라이브 앱을 탐색합니다:

```bash
npx agent-browser --session persona-1 open http://localhost:3000
npx agent-browser --session persona-1 screenshot .persona-pilot/persona-1/landing.png
npx agent-browser --session persona-1 snapshot -i
npx agent-browser --session persona-1 click @e5
npx agent-browser --session persona-1 close
```

스크린샷은 `.persona-pilot/<persona-id>/` 아래에 페르소나별로 저장됩니다.

---

## 파일 구조

```
.persona-pilot/
├── personas.json          # 페르소나 정의 (init이 생성)
├── report.md              # 집계된 피드백 (run이 생성)
├── improvements.md        # 개선 제안 (improve가 생성)
└── <persona-id>/
    ├── 01-landing.png     # 스크린샷 (web 모드 전용)
    └── 02-after-click.png
```

---

## 설치

```bash
# 전역 설치
cp -r skills/persona-pilot ~/.claude/skills/

# 프로젝트 전용
cp -r skills/persona-pilot ./.claude/skills/
```

또는 setup.sh 사용:
```bash
./setup.sh
```

---

## 라이선스

MIT
