<div align="center">

# PARKyc Note

**공부한 내용을 기록하고, 경험을 회고하며 더 깊이 이해하기 위한 기술 블로그**

![Jekyll](https://img.shields.io/badge/Jekyll-4.4.1-CC0000?logo=jekyll&logoColor=white)
![Chirpy](https://img.shields.io/badge/Theme-Chirpy-2E3440)
![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Deployed-222222?logo=githubpages&logoColor=white)

</div>

---

> PARKyc Note는 개발하며 공부한 기술 개념과 문제를 해결한 경험, 그리고 그 과정에서 얻은 생각을 정리하는 개인 기술 블로그입니다.
>
> 단순히 지식을 모으는 데 그치지 않고, 왜 그런 선택을 했는지와 무엇을 배웠는지를 함께 기록합니다.

## 블로그 구조

```text
PARKyc-web/
├── _posts/      # 기술 학습과 회고 글
├── _tabs/       # 소개, 아카이브, 카테고리, 태그 페이지
├── assets/       # 이미지와 정적 자산
├── _config.yml  # Jekyll 및 블로그 설정
└── index.html    # 블로그 메인 페이지
```

이 블로그는 [Jekyll](https://jekyllrb.com/)과 [Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy) 테마를 사용해 운영합니다.

## 로컬 실행

Ruby 3.4와 Bundler가 필요합니다. 처음 실행할 때 저장소 안의 `vendor/bundle`에 의존성을 설치합니다. 이 디렉터리와 로컬 Bundler 설정은 Git에 포함되지 않습니다.

```bash
bundle config set --local path vendor/bundle
bundle install
bundle exec jekyll serve
```

브라우저에서 `http://127.0.0.1:4000/`을 엽니다. macOS에서 Homebrew로 설치한 Ruby 3.4를 사용하는 경우, 위 명령을 실행하기 전에 다음 명령으로 현재 터미널의 PATH를 설정하세요.

```bash
export PATH="$(brew --prefix ruby@3.4)/bin:$PATH"
```

`Gemfile.lock`은 의존성 버전을 고정하며 Git에서 관리합니다.

## 시리즈 글 작성

게시글의 Front Matter에 같은 `series` 이름을 넣으면 글 상세 상단에 같은 시리즈 글이 작성일 순서로 표시됩니다. 시리즈가 없는 글에는 표시되지 않습니다.

```yaml
---
title: "첫 번째 글"
series: "Java 동시성 살펴보기"
---
```

헤더의 **Series**에서 전체 시리즈를 볼 수 있습니다.
