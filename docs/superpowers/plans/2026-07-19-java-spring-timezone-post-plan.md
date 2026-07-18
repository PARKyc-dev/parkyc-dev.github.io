# Java/Spring Timezone 포스팅 작성 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** PostgreSQL을 사용하는 Java/Spring 주니어 실무자를 위한 Timezone 포스팅을 작성한다.

**Architecture:** 기존 Jekyll 포스트 형식의 Markdown 파일 하나에 문제 상황, Java와 PostgreSQL의 시간 모델, 설정 예시, 점검 항목을 담는다. 별도 코드나 애플리케이션 설정 파일은 변경하지 않는다.

**Tech Stack:** Jekyll, Markdown, Java Time API, Spring Boot, PostgreSQL

## Global Constraints

- 기존 포스트의 front matter와 한국어 문체를 따른다.
- 시점 데이터는 UTC로 저장하고 표시 시점에 사용자 시간대로 변환하는 원칙만 다룬다.
- PostgreSQL 예시는 `timestamptz`를 기준으로 작성한다.

---

### Task 1: Timezone 포스팅 작성 및 Jekyll 빌드 확인

**Files:**
- Create: `_posts/2026-07-19-java-spring-timezone.md`
- Test: `tools/test.sh`

**Interfaces:**
- Consumes: `_posts/2026-06-24-java-yearmonth.md`의 front matter와 Markdown 문체
- Produces: `Java/Spring - Timezone` 제목의 Jekyll 포스트

- [ ] **Step 1: 작성 기준 확인**

확인할 내용:

```text
독자: Java/Spring 주니어 실무자
DB: PostgreSQL
핵심 원칙: UTC 저장, 사용자 시간대 표시
```

- [ ] **Step 2: 포스팅 작성**

다음 섹션을 포함한 Markdown을 작성한다.

```markdown
## 문제 상황
## 시간대가 없으면 왜 문제가 될까
## Java에서는 Instant를 기준으로 다루기
## PostgreSQL에서는 timestamptz 사용하기
## now()와 PostgreSQL TimeZone 확인하기
## Spring과 DB 설정 점검하기
## 정리
```

- [ ] **Step 3: Jekyll 빌드 확인**

Run: `./tools/test.sh`

Expected: Jekyll build succeeds without Markdown or front matter errors.

- [ ] **Step 4: Commit**

```bash
git add _posts/2026-07-19-java-spring-timezone.md
git commit -m "docs: add java spring timezone post"
```
