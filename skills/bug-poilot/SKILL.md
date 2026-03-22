---
description: 입력한 GitHub repo의 bug 이슈를 자동으로 찾아 코드를 수정하고 Draft PR을 생성합니다
argument-hint: <owner/repo>
---

# Bug Fix 자동화

## 입력값 확인

사용법: `/bug-poilot <owner/repo>`

`$ARGS`에서 대상 레포를 읽는다. 예: `octocat/Hello-World`

**TARGET_REPO** = `$ARGS` (없으면 현재 디렉토리의 remote origin URL에서 추출)

---

## 현재 상태 파악

대상 repo의 열려있는 bug 이슈 목록을 가져온다:
!`gh issue list --repo $ARGS --label bug --state open --json number,title,body,url --limit 30`

대상 repo의 열려있는 PR 목록을 가져온다 (이미 작업 중인 이슈 확인용):
!`gh pr list --repo $ARGS --state open --json number,title,body --limit 50`

현재 GitHub 로그인 사용자 확인:
!`gh api user --jq .login`

## 지시사항

위 정보를 바탕으로 아래 절차를 순서대로 수행하라.

### 1단계 — 작업 대상 이슈 선정

- `$ARGS`를 TARGET_REPO로 사용한다. 비어있으면 중단하고 사용법을 안내하라.
- bug 라벨이 붙은 open 이슈 중, 이미 PR의 body에 `Closes #이슈번호` 또는 `Fixes #이슈번호`로 연결된 이슈는 제외한다
- 남은 이슈 중 **첫 번째 이슈 하나**를 선택한다
- 이슈가 없으면 "처리할 bug 이슈가 없습니다"를 출력하고 종료한다
- 선택한 이슈 번호와 제목을 출력하고, 작업을 시작한다고 알려라

### 2단계 — 이슈 상세 내용 확인

선택한 이슈의 전체 내용을 가져온다:

```
gh issue view <선택한 이슈 번호> --repo <TARGET_REPO> --json number,title,body,comments
```

### 3단계 — Fork 및 로컬 클론

```bash
# 이미 fork가 있으면 자동으로 기존 fork를 사용함
gh repo fork <TARGET_REPO> --clone --default-branch-only
```

클론된 디렉토리로 이동한다. 디렉토리명은 repo 이름(owner/repo 중 repo 부분)이다.

remote 설정을 확인한다:

```bash
git remote -v
```

- `origin` → 본인 fork
- `upstream` → 원본 repo (gh가 자동 설정)

없으면 수동으로 추가:

```bash
git remote add upstream https://github.com/<TARGET_REPO>.git
```

### 4단계 — 관련 코드 파악

이슈 내용을 읽고 버그와 관련 있어 보이는 파일을 찾는다:

- 이슈 제목/내용에 등장하는 함수명, 파일명, 에러 메시지로 grep 검색
- 관련 파일을 읽어 문제가 되는 코드 확인
- `git log --oneline -- <파일경로>`로 최근 변경 이력 확인

### 5단계 — 코드 수정

- 버그 원인을 파악하고 수정 방법을 결정한다
- 수정 전에 어떤 파일의 어느 부분을 왜 수정하는지 간략히 설명하라
- 실제로 파일을 수정하라 (Write/Edit 도구 사용)
- 수정은 최소한으로, 버그 픽스에 집중하라

### 6단계 — 브랜치 생성 및 커밋

```bash
# 브랜치명 형식: fix/issue-<번호>-<짧은-설명>
git checkout -b fix/issue-<번호>-<짧은-설명>
git add -A
git commit -m "fix: <변경 요약> (#<이슈번호>)"
git push origin fix/issue-<번호>-<짧은-설명>
```

### 7단계 — PR 템플릿 확인

PR body를 작성하기 전에 아래 순서로 템플릿을 탐색한다:

1. **target repo 템플릿 우선**: 클론된 디렉토리 안에서 아래 경로를 순서대로 확인한다.
   - `.github/pull_request_template.md`
   - `.github/PULL_REQUEST_TEMPLATE.md`

2. **없으면 이 스킬 repo 템플릿 사용**: 스킬이 설치된 위치 기준으로 아래 경로를 확인한다.
   - `~/.claude/skills/bug-poilot/` 또는 `.claude/skills/bug-poilot/` 기준의 상위 repo

3. **둘 다 없으면** 아래 기본 형식을 사용한다:

```
## 문제
<무엇이 문제였는지 1-3줄>

## 원인
<버그의 근본 원인>

## 수정 내용
<어떤 파일의 어떤 부분을 어떻게 수정했는지>

## 테스트
- [ ] <테스트 항목 1>
- [ ] <테스트 항목 2>

Closes #<이슈번호>
```

템플릿을 찾으면 그 내용을 기반으로 PR body를 작성하되, `Closes #<이슈번호>`는 반드시 body 마지막에 추가한다.

### 8단계 — Draft PR 생성

원본 repo로 Draft PR을 생성한다:

```bash
gh pr create \
  --repo <TARGET_REPO> \
  --title "fix: <이슈 제목 요약> (#<이슈번호>)" \
  --body "<7단계에서 작성한 PR body>" \
  --draft \
  --head <내-GitHub-username>:fix/issue-<번호>-<짧은-설명> \
  --base main
```

> `--head`에는 `gh api user --jq .login`으로 얻은 내 GitHub username을 사용한다.
> `--base`는 원본 repo의 기본 브랜치명을 확인해서 맞춰라 (main 또는 master).

### 완료 후

- 생성된 PR URL을 출력하라
- 리뷰어가 확인해야 할 사항이 있다면 간략히 언급하라
- 클론된 로컬 디렉토리 경로도 안내하라
