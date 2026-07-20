---
title: "Java 시간 타입 정리 — 종류, 저장 방법, 실무 사용법"
date: 2026-07-20 22:00:00 +0900
categories: [Backend, Java]
tags: [java, time-api]
toc: true
comments: true
---

# Java 시간타입형

Java로 개발하다 보면 "시간"을 다루는 순간이 반드시 온다. 그런데 막상 코드를 짜려고 하면 `Date`, `Calendar`, `LocalDate`, `LocalDateTime`, `Instant`, `ZonedDateTime`... 후보가 너무 많다. 여기에 실무에서는 `"20260720"` 같은 **String**으로 날짜를 저장하는 코드까지 볼 수 있다.

이 글에서는 (1) Java의 시간 타입에는 어떤 것들이 있는지, (2) 상황별로 어떤 타입을 사용하면 좋은지, (3) 지금까지 경험한 실무에서는 어떻게 저장하고 쓰는지를 정리한다.

---

## 1. Java에는 시간 타입이 정말 많다

### 1-1. 레거시 (Java 7 이하)

| 타입 | 설명 | 문제점 |
|------|------|--------|
| `java.util.Date` | 특정 시점(밀리초) | 가변(mutable), 월(month)이 0부터 시작, API 혼란 |
| `java.util.Calendar` | 날짜 계산용 | 지나치게 복잡, 가변, 버그 유발 |
| `java.sql.Date` / `Time` / `Timestamp` | JDBC 연동용 | `java.util.Date`를 상속한 기형 구조 |

> `java.util.Date`는 **가변 객체**라서 여러 곳에서 참조하면 값이 바뀌는 사고가 나기 쉽다. 신규 코드에서는 쓰지 않는 것을 권장한다.
{: .prompt-warning }

### 1-2. 모던 (Java 8+ `java.time` 패키지) — 표준

Java 8 버전 이상의 `java.time` 패키지는 **불변(immutable)** 이고 스레드 세이프하다.

| 타입 | 담는 정보 | 예시 |
|------|-----------|------|
| `LocalDate` | 날짜만 | `2026-07-20` |
| `LocalTime` | 시각만 | `14:30:00` |
| `LocalDateTime` | 날짜 + 시각 (타임존 X) | `2026-07-20T14:30:00` |
| `ZonedDateTime` | 날짜 + 시각 + **타임존** | `2026-07-20T14:30+09:00[Asia/Seoul]` |
| `OffsetDateTime` | 날짜 + 시각 + UTC 오프셋 | `2026-07-20T14:30+09:00` |
| `Instant` | UTC 기준 타임스탬프(한 시점) | `2026-07-20T05:30:00Z` |
| `Duration` | 시간 간격 (초/나노) | `PT1H30M` (1시간 30분) |
| `Period` | 날짜 간격 (년/월/일) | `P1Y2M3D` (1년 2개월 3일) |
| `Year`, `YearMonth`, `MonthDay` | 부분 날짜 | `2026`, `2026-07`, `--07-20` |

```java
LocalDate today = LocalDate.now();                 // 2026-07-20
LocalDateTime now = LocalDateTime.now();           // 2026-07-20T14:30:00
Instant instant = Instant.now();                   // 2026-07-20T05:30:00Z (UTC)
ZonedDateTime seoul = ZonedDateTime.now(ZoneId.of("Asia/Seoul")); // 2026-07-20T14:30:00+09:00[Asia/Seoul]
```

---

## 2. 어떤 타입을 쓰면 좋은가

Java에서 제공하는 시간 자료형은 아래와 같이 많다.

### 2-1. Java 시간 자료형 종류

| 분류       | 타입 | 데이터 예시 |
|----------|------|-------------|
| 타임존 X    | `LocalDate` | `2026-07-20` |
|          | `LocalTime` | `14:30:00` |
|          | `LocalDateTime` | `2026-07-20T14:30:00` |
| 타임존 O    | `Instant` / `OffsetDateTime` | `2026-07-20T05:30:00Z` / `2026-07-20T14:30+09:00` |
|          | `ZonedDateTime` | `2026-07-20T14:30+09:00[Asia/Seoul]` |
| 기간 / 간격  | `Duration` | `PT1H30M` (1시간 30분) |
|          | `Period` | `P1Y2M3D` (1년 2개월 3일) |
| 특정 데이터형식 | `YearMonth` / `MonthDay` | `2026-07` / `--07-20` |
|          | `String` (`yyyyMMdd`) | `"20260720"` |

> **레거시 시스템을 유지보수하는 상황이 아니라면, 레거시 타입(`Date`/`Calendar`/`java.sql.*`)은 쓰지 않는다.**  
> 앞으로 설명하는 내용은 전부 Java 8 버전 이후에 나온 `java.time` 패키지이다.
{: .prompt-warning }

### 2-2. 어떤 시간 자료형을 사용할까?

개인적으로 Java 시간 자료형을 처음 사용할때는 어떤 것을 써야 할지 헷갈렸지만, 나름대로 정한 선택 기준은 두 개다.   
**`(1)타임존 데이터가 필요한가?`**, **`(2)특정 데이터 형식으로 들어오는가?`**

**타임존이 필요한가? (= 글로벌 서비스인가?)**

여러 국가에 제공하는 글로벌 서비스라면 타임존은 필수적인 데이터다. 그러나 국내에서만 서비스 시스템이라면 `LocalDateTime`으로도 충분하다.

만약 당장은 아니어도 나중에 글로벌 서비스를 붙일 것 같아서 미리 타임존 데이터를 저장해 두고 싶다면 `OffsetDateTime`이나 `ZonedDateTime`을 써도 되지만, 굳이 시작부터 그럴 필요가 있나 싶다.  
이런 경우엔 `LocalDateTime` + `ZoneId`를 따로 저장해 두는 것도 하나의 방법이다. 

참고로 `Instant`는 타임존 없이 UTC로만 저장하기 때문에, 특정 지역 시각으로 쓰려면 `ZoneId`로 변환하는 과정이 필요하다.
이와 관련된 자세한 내용은 2-4에서 설명한다.

> 타임존이 필요 없다면 → `LocalDate`, `LocalTime`, `LocalDateTime`  
> 타임존이 필요하다면 → `Instant`, `ZonedDateTime`, `OffsetDateTime`  
> 고민해 볼 만한 대안 → `LocalDateTime` + `ZoneId`  
{: .prompt-info }

### 2-3. 데이터가 무조건 "년-월", "월-일" 이라면 (ex 캘린더 등)

달력·월별 정산·생일처럼 데이터가 애초에 `2026-07`(년-월)이나 `07-20`(월-일) 형태로만 들어온다면, 굳이 `LocalDate`에 억지로 1일을 붙여 쓰지 말고 **부분 날짜 타입**(`YearMonth`, `MonthDay`)을 쓰는 게 깔끔하다.
부분 날짜 타입을 사용할 경우 데이터의 의미도 명확해지고, 변환·계산도 쉽다.

```java
// YearMonth — 그 달의 첫날 / 마지막날 / 일수
YearMonth ym = YearMonth.of(2026, 7);   // 2026-07
LocalDate first = ym.atDay(1);          // 2026-07-01 (첫날)
LocalDate last  = ym.atEndOfMonth();    // 2026-07-31 (마지막날, 윤년/월별 일수 자동 처리)
int days        = ym.lengthOfMonth();   // 31

// MonthDay — 연도와 무관하게 매년 반복되는 날
MonthDay birthday = MonthDay.of(7, 20);        // --07-20
LocalDate thisYear = birthday.atYear(2026);    // 2026-07-20
boolean isToday = birthday.equals(MonthDay.from(LocalDate.now()));
```

> 특히 `atEndOfMonth()`는 2월(28/29일)이나 30일/31일 월을 **자동으로 처리**해 준다. 문자열이나 `LocalDate`로 "그 달 마지막 날"을 직접 계산할 필요가 없다.
{: .prompt-tip }

### 2-4. Instant ↔ LocalDateTime + ZoneId 변환

앞 부분에서 얘기한 **`LocalDateTime` + `ZoneId`를 따로 저장하는 방식**을 말한 이유는 `Instant`로 쉽게 변환할 수 있기 때문이다.  
저장해 둔 두 값을 합치면 `Instant`가 되고, 반대로 `Instant` 하나를 특정 `ZoneId` 기준의 `LocalDateTime` + `ZoneId` 두 값으로 분해할 수도 있다. 
어느 쪽으로 저장하든 정보 손실 없이 변환된다.

```java
// LocalDateTime + ZoneId -> Instant 로 합치기
LocalDateTime savedLocal = LocalDateTime.of(2026, 7, 20, 14, 30);
ZoneId savedZone = ZoneId.of("Asia/Seoul");
Instant merged = savedLocal.atZone(savedZone).toInstant();       // 2026-07-20T05:30:00Z

// Instant -> LocalDateTime + ZoneId 두 값으로 분해하기
ZoneId zone = ZoneId.of("Asia/Seoul");
LocalDateTime splitLocal = LocalDateTime.ofInstant(merged, zone); // 2026-07-20T14:30
// (splitLocal, zone) 두 값을 함께 저장하면 위와 동일한 정보가 된다
```

---

## 3. 실무에서 경험한 시간 타입

이제 실무에서는 시간 형식을 어떻게 저장했었는지 제 경험을 토대로 하나씩 말씀드리겠습니다.

### 3-1. DB 컬럼 타입으로 저장

가장 많이 보고, 사용한 방법으로 `LocalDate`, `LocalTime`, `LocalDateTime`을 사용한 방법입니다.  
`java.time` 타입은 대부분 JDBC 드라이버/JPA가 알아서 DB 타입으로 매핑해주기 때문에 사용하기도 편합니다.

| Java 타입 | DB 컬럼 타입 (PostgreSQL) | 주로 쓰는 경우 |
|-----------|--------------------------|----------------|
| `LocalDate` | `DATE` | 날짜만 필요한 경우 |
| `LocalTime` | `TIME` | 매일 같은 시각 등 시각만 필요한 경우 |
| `LocalDateTime` | `TIMESTAMP` | 국내 단일 시간대 서비스의 생성·수정 시각 |
| `Instant` | `TIMESTAMP WITH TIME ZONE` | 여러 시간대가 섞이거나 UTC 기준으로 처리할 시각 |
| `OffsetDateTime` | `TIMESTAMP WITH TIME ZONE` | offset이 포함된 외부 시간을 받을 때 |

이 방식의 장점은 **DB에서 날짜 연산/비교/정렬/범위 조회가 그대로 된다**는 것이다.

```sql
SELECT * FROM orders WHERE order_date BETWEEN '2026-07-01' AND '2026-07-31';
```

### 3-2. String으로 저장 — `"20260720"`, `"2026-07-20"`

의외로 실무에서 자주 볼 수 있는 방식으로 날짜 형식의 문자열로 저장하는 방식입니다.  
처음 문자열의 날짜를 봤을때는 **왜 이렇게 쓸까?** 하는 의문이 많았는데 알고보니 나름의 이유가 있었습니다.

**String으로 쓰는 이유**

1. **레거시/외부 시스템 연동** — 의외로 금융권, 공공기관, EDI 등에서는 날짜를 `yyyyMMdd` 8자리 문자열로 주고받는 경우가 많습니다. 그래서 별도의 파싱/변환 없이 그대로 저장·전달하여 사용합니다.
2. **코드로 만들기 쉽다** - 1번과 연계되는 부분으로, 문자열로 전달받은 데이터를 활용해서 코드로 만들기 쉬워집니다. `문자열 + 문자열`
3. **정렬 가능** — `yyyyMMdd` 형식은 문자열 사전순 정렬 = 날짜순 정렬이 일치한다. `"20260101" < "20260720"` 이 그대로 성립.
4. **표시(display) 목적** — 화면에 보여줄 코드성 값(예: 정산 회차 `"202607"`)은 계산할 일이 없으니 문자열이 단순하고 명확하다.
5. **DB 호환성/이식성** — 벤더마다 다른 날짜 타입 이슈, 마이그레이션 이슈를 피하려고 `VARCHAR`/`CHAR(8)`로 통일하기도 한다.

**String의 단점 (그래서 조심해야 함)**
1. **날짜 연산이 불편하다.** - `+1일`, `기간 차이`를 계산하려면 `LocalDate` 등 날짜 타입으로 파싱해야 한다.
2. **별도의 유효성 검증 필요** — `"20261340"` (13월 40일) 같은 값이 그대로 들어간다.
3. **만약 형식이 변경될 경우** - `"20260720"`에서 `"2026/07/20"` 또는 `"2026-07-20"` 형식이 변경될 경우, DB 데이터 변경, 유효성 로직 수정 등 작업이 많아집니다.
4. **범위 조회 조건에 제약이 있다.** - `yyyyMMdd`등 고정된 형식이면 문자열 범위 조회와 인덱스 사용이 가능하다. 다만 형식이 섞이거나 컬럼을 날짜로 변환해서 조회하면 인덱스를 활용하기 어려워질 수 있다.

> **정리**: String 저장은 "외부 규격이 문자열이거나, 계산이 전혀 필요 없는 코드성 날짜"에 한해 쓰는게 좋은 것 같습니다.  
> 만약 애플리케이션 내부 로직에서 사용한다면 `LocalDate`로 파싱해서 다루는 게 편하고 안전합니다.
{: .prompt-info }

### 3-3. epoch(밀리초/초) long으로 저장

로깅 시스템에서 주로 봤던 부분으로 `Instant`를 `long`(epoch milli)으로 저장하는 방식. 

```java
long epochMilli = Instant.now().toEpochMilli();     // 1784525400000
Instant restored = Instant.ofEpochMilli(epochMilli);
```

- 장점: 타임존 무관하게 절대 시점을 명확히 저장, 언어/시스템 간 이식 쉬움.
- 단점: 사람이 눈으로 읽기 어려움, DB에서 바로 날짜로 안 보임.

### 3-4. JPA 엔티티에는 보통 뭘 쓰나

기존적으로 `LocalDate` / `LocalDateTime` 사용하면 될 것으로 생각됩니다.
만약 타임존 데이터가 필요할 경우 `Instant` or `LocalDateTime` + `ZoneId`  
(개인적으로는 후자의 방법을 선호합니다. DB에 저장할떄는 Instant로 변환하고, 백엔드 서버에서는 Instant를 `LocalDateTime` + `ZoneId`로 사용합니다.)

Hibernate 5.2+ / JPA 2.2부터 `java.time` 타입을 기본 지원한다. 별도 어노테이션 없이 필드 타입만 지정하면 된다.

```java
import java.time.Instant;

@Entity
public class Order {

  @Id
  @GeneratedValue
  private Long id;
  
  private Instant createdAt;
}
```

```java
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;

public class OrderDTO {

  private Long id;

  private LocalDateTime createdAt;

  private ZoneId createdZone;
}
```

---

## 정리

- Java 8+ 라면 무조건 `java.time` 패키지를 쓴다. (`Date`/`Calendar`는 사용 X)
- 타입 선택의 기준 2개 : **`(1)타임존 데이터가 필요한가?`**, **`(2)특정 데이터 형식으로 들어오는가?`**
- 저장 방식은 **DB 날짜 타입이 기본**, String은 "외부 규격/계산 불필요/코드 값으로 사용" 한정, epoch long은 로깅 시스템
- JPA 엔티티는 **`LocalDate`/`LocalDateTime`이 기본**, 글로벌이면 `Instant` or `LocalDateTime` + `ZoneId`
