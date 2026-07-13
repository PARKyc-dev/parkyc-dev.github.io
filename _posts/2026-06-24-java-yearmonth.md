---
title: "Java YearMonth 정리"
date: 2026-06-24 23:00:00 +0900
categories: [Backend, Java]
tags: [java, yearmonth, time-api]
---

`YearMonth`는 Java 8의 Date and Time API에 포함된 타입으로, 이름 그대로 "연도와 월"만 표현한다. 날짜나 시간 정보가 필요 없고 특정 월 단위의 값을 다룰 때 사용하기 좋다.

예를 들어 카드 유효기간, 월별 정산 기준, 월간 통계 키처럼 `2026-06`까지만 중요하고 `2026-06-24` 같은 일자는 필요 없는 경우가 있다. 이런 값을 `LocalDate`로 표현하면 의미 없는 날짜를 임의로 넣어야 한다. `YearMonth`를 사용하면 도메인 의미를 더 정확하게 드러낼 수 있다.

## 기본 생성

```java
import java.time.YearMonth;

YearMonth current = YearMonth.now();
YearMonth june2026 = YearMonth.of(2026, 6);
YearMonth parsed = YearMonth.parse("2026-06");
```

`YearMonth.parse()`는 기본적으로 `yyyy-MM` 형식의 문자열을 파싱한다.

## 월 단위 계산

`YearMonth`는 월 단위 계산을 자연스럽게 지원한다.

```java
YearMonth base = YearMonth.of(2026, 6);

YearMonth nextMonth = base.plusMonths(1);   // 2026-07
YearMonth previousMonth = base.minusMonths(1); // 2026-05
YearMonth nextYear = base.plusYears(1);     // 2027-06
```

월말 날짜가 필요할 때는 `atEndOfMonth()`를 사용할 수 있다.

```java
YearMonth target = YearMonth.of(2024, 2);

System.out.println(target.atEndOfMonth()); // 2024-02-29
```

윤년 여부까지 알아서 처리해주기 때문에 직접 월별 마지막 날짜를 계산할 필요가 없다.

## LocalDate로 변환

월 정보만 가지고 있다가 실제 날짜가 필요해지는 시점에는 `LocalDate`로 변환할 수 있다.

```java
YearMonth target = YearMonth.of(2026, 6);

System.out.println(target.atDay(1));       // 2026-06-01
System.out.println(target.atEndOfMonth()); // 2026-06-30
```

월별 조회 범위를 만들 때도 유용하다.

```java
YearMonth month = YearMonth.of(2026, 6);

LocalDate startDate = month.atDay(1);
LocalDate endDate = month.atEndOfMonth();
```

## 비교

`YearMonth`는 시간 순서 비교도 가능하다.

```java
YearMonth requested = YearMonth.of(2026, 6);
YearMonth current = YearMonth.now();

if (requested.isAfter(current)) {
    System.out.println("미래 월입니다.");
}
```

`isBefore()`, `isAfter()`, `equals()`를 사용하면 월 단위 조건을 명확하게 표현할 수 있다.

## 정리

`YearMonth`는 연도와 월만 필요한 상황에서 `LocalDate`보다 의도를 더 잘 드러내는 타입이다. 월 단위 계산, 월초/월말 변환, 비교가 필요한 코드에서는 문자열이나 임의 날짜 대신 `YearMonth`를 먼저 고려해볼 만하다.
