# bug-poilot

**[English](./README.md) | 한국어**

Claude Code용 버그 자동 수정 스킬. GitHub repo를 지정하면 PR이 없는 bug 이슈를 찾아 fork → clone → 코드 수정 → Draft PR 생성까지 자동으로 처리합니다.

```
bug 이슈 탐색 → fork & clone → 코드 분석 → 수정 → 커밋 → draft PR 생성
```

---

## 동작 방식

```
당신:      "/bug-poilot octocat/Hello-World"

에이전트:  → octocat/Hello-World의 open bug 이슈 목록 조회
           → 이미 PR이 연결된 이슈 제외
           → 첫 번째 미처리 이슈 선택
           → 본인 GitHub 계정으로 repo fork
           → fork 로컬 클론
           → 이슈 내용 읽고 관련 코드 탐색
           → 최소한의 버그 픽스 적용
           → fix/issue-42-short-description 브랜치에 커밋
           → fork에 push
           → 원본 repo로 Draft PR 생성
           → "Draft PR 생성 완료: https://github.com/octocat/Hello-World/pull/99"
```

---

## 사용법

```
/bug-poilot <owner/repo>
```

**예시:**
```
/bug-poilot vercel/next.js
```

---

## 워크플로우

| 단계 | 작업 |
|------|------|
| 1. 이슈 선정 | PR이 연결되지 않은 open bug 이슈 탐색 |
| 2. 이슈 상세 | 이슈 본문 및 코멘트 전체 조회 |
| 3. Fork & clone | `gh repo fork --clone` (기존 fork 재사용) |
| 4. 코드 분석 | 관련 파일 grep, 컨텍스트 읽기 |
| 5. 수정 | 최소한의 타겟 코드 변경 |
| 6. 커밋 | `fix/issue-<n>-<slug>` 브랜치 생성 후 fork에 push |
| 7. Draft PR | `Closes #n` 포함하여 원본 repo에 PR 생성 |

---

## Draft PR 형식

```markdown
## 문제
<무엇이 문제였는지 1-3줄>

## 원인
<버그의 근본 원인>

## 수정 내용
<어떤 파일의 어느 부분을 왜 수정했는지>

## 테스트
- [ ] 테스트 항목 1
- [ ] 테스트 항목 2

Closes #<이슈번호>
```

---

## 요구사항

- `gh` CLI 인증 완료 (`gh auth login`)
- fork 가능한 GitHub 계정

---

## 설치

```bash
# 전역 설치
cp -r skills/bug-poilot ~/.claude/skills/

# 프로젝트 전용
cp -r skills/bug-poilot ./.claude/skills/
```

또는 setup.sh 사용:
```bash
./setup.sh
```

---

## 라이선스

MIT
