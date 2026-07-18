---
title: "Java/Spring - Timezone"
date: 2026-07-19 22:00:00 +0900
categories: [Backend, Java]
tags: [java, spring, timezone, postgresql, time-api]
---

로컬에서는 문제가 없던 생성 시간이 클라우드에 배포한 뒤 9시간 차이 나는 경우가 있다. 예를 들어 한국에서 개발할 때는 `2026-07-19 10:00`으로 보이던 값이 운영 환경에서는 `2026-07-19 01:00`으로 보일 수 있다.

처음에는 "클라우드 서버가 다른 지역에 있어서 시간이 달라졌다"고 생각하기 쉽다. 하지만 같은 **시점** 자체가 달라진 것은 아니다. 서버 OS, JVM, PostgreSQL 세션이 어떤 시간대를 기본값으로 사용하고 있는지, 그리고 그 시점을 어떤 시간대로 **표시**하는지가 달라서 생기는 문제다.

시간을 다룰 때는 먼저 이 둘을 구분해야 한다.

- **시점(instant)**: 전 세계 어디서 보더라도 같은 한 순간. 예: 주문이 생성된 순간
- **지역 시간(local date-time)**: 시간대가 정해져야 시점이 되는 날짜와 시각. 예: `2026-07-19 10:00`

주문 생성 시각, 수정 시각처럼 실제로 발생한 순간을 저장할 때는 UTC를 기준으로 저장하고, 화면이나 API에서 보여 줄 때만 사용자 시간대로 변환하는 방식이 가장 안전하다.

## `new Date()`와 `Instant.now()`는 시간대를 저장하지 않는다

Java의 `new Date()`와 `Instant.now()`는 모두 특정 시점을 표현한다. 내부적으로는 UTC 기준의 epoch time을 사용하므로, 서버가 서울에 있든 미국에 있든 같은 순간에 실행했다면 같은 시점을 가리킨다.

다만 `Date`를 문자열로 출력하거나 `LocalDateTime.now()`를 호출할 때는 JVM의 기본 시간대가 영향을 준다.

```java
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;

Instant now = Instant.now();
LocalDateTime serverLocalTime = LocalDateTime.now();

ZonedDateTime seoulTime = now.atZone(ZoneId.of("Asia/Seoul"));

System.out.println(now);             // 2026-07-19T01:00:00Z
System.out.println(serverLocalTime); // 서버 JVM 기본 시간대의 날짜와 시각
System.out.println(seoulTime);       // 2026-07-19T10:00+09:00[Asia/Seoul]
```

`Instant`에는 "언제 발생했는가"만 있다. 반면 `LocalDateTime`에는 시간대 정보가 없기 때문에 `2026-07-19 10:00`이 서울 시간인지, UTC인지, 뉴욕 시간인지 알 수 없다.

따라서 생성일시와 수정일시처럼 시점을 저장하는 필드는 `Instant`를 사용하는 편이 명확하다.

```java
public class Order {

    private Instant createdAt;
    private Instant updatedAt;
}
```

사용자에게 지역 시간을 입력받았다면, 어떤 시간대의 값인지 함께 알아야 한다. 예를 들어 한국 시간으로 입력받은 값을 저장할 때는 다음처럼 시점으로 변환한다.

```java
LocalDateTime requestedAt = LocalDateTime.of(2026, 7, 19, 10, 0);
Instant instant = requestedAt
        .atZone(ZoneId.of("Asia/Seoul"))
        .toInstant();
```

## PostgreSQL에서는 `timestamptz`를 사용한다

PostgreSQL에는 비슷해 보이지만 의미가 다른 두 타입이 있다.

- `timestamp`: 시간대 없는 날짜와 시각
- `timestamptz` (`timestamp with time zone`): 하나의 시점

이름만 보면 `timestamptz`가 입력한 시간대까지 그대로 저장할 것 같지만, 그렇지는 않다. PostgreSQL은 `timestamptz` 값을 내부적으로 UTC 기준 시점으로 저장하고, 조회할 때 현재 세션의 `TimeZone`에 맞춰 변환해 보여 준다.

```sql
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

`created_at`처럼 "주문이 생성된 순간"을 저장하는 컬럼에는 `TIMESTAMPTZ`가 잘 맞는다.

반대로 매일 오전 9시에 실행하는 배치 시간처럼 시점이 아니라 지역 기준의 시각 자체가 의미인 값은 `TIME` 또는 `TIMESTAMP`를 사용할 수 있다. 이 경우에도 어느 지역을 기준으로 하는지 도메인 규칙으로 명확히 정해야 한다.

> PostgreSQL의 `timestamptz`는 원래 입력한 시간대 이름을 보존하지 않는다. UTC 기준 시점만 저장하므로, "사용자가 선택한 시간대"도 필요한 서비스라면 `Asia/Seoul` 같은 IANA 시간대 이름을 별도 컬럼으로 보관해야 한다.
{: .prompt-info }

## `now()` 값이 다르게 보이는 이유

다음 SQL을 실행해 보자.

```sql
SET TIME ZONE 'UTC';
SELECT now();

-- 2026-07-19 01:00:00+00

SET TIME ZONE 'Asia/Seoul';
SELECT now();

-- 2026-07-19 10:00:00+09
```

두 결과는 9시간 차이가 나지만 같은 시점이다. PostgreSQL 세션의 시간대가 출력 형식만 바꾼 것이다.

`TIMESTAMPTZ` 컬럼도 같은 방식으로 보인다.

```sql
SET TIME ZONE 'UTC';
SELECT created_at FROM orders;

SET TIME ZONE 'Asia/Seoul';
SELECT created_at FROM orders;
```

같은 행을 조회해도 결과의 날짜와 시각, offset이 달라질 수 있다. 저장된 데이터가 바뀐 것이 아니다.

또 하나 주의할 점은 PostgreSQL의 `now()`가 쿼리가 실행된 정확한 시각이 아니라 **현재 트랜잭션이 시작된 시각**을 반환한다는 점이다. 트랜잭션 안에서 여러 번 호출해도 같은 값이 나올 수 있다. 실행 순간의 실제 시각이 꼭 필요하다면 `clock_timestamp()`를 검토할 수 있다.

## DB 시간대는 UTC로 통일한다

운영 환경에서는 PostgreSQL의 기본 시간대를 UTC로 통일해 두면 로그와 DB 조회 결과를 비교할 때 혼란이 줄어든다.

현재 세션의 설정은 다음 SQL로 확인할 수 있다.

```sql
SHOW TIME ZONE;
SELECT current_setting('TimeZone');
```

현재 연결에서만 UTC로 바꾸려면 다음을 사용한다.

```sql
SET TIME ZONE 'UTC';
```

특정 데이터베이스의 기본값으로 설정하려면 다음처럼 설정할 수 있다. 변경 후 새로 생성되는 연결부터 적용된다.

```sql
ALTER DATABASE app_db SET TimeZone TO 'UTC';
```

애플리케이션 커넥션 풀은 연결을 재사용하므로, 어떤 코드가 세션 시간대를 바꿨다면 다른 요청에도 영향을 줄 수 있다. DB 기본값을 UTC로 두고, 필요하다면 커넥션을 생성할 때도 UTC로 설정하는 것이 좋다.

## Spring에서도 기준을 맞춘다

DB만 UTC로 바꾸고 애플리케이션은 지역 시간을 기본값으로 사용하면 다시 혼란이 생긴다. 특히 기존 코드에서 `LocalDateTime.now()`를 많이 사용하고 있다면 JVM 기본 시간대에 의존하게 된다.

새 코드에서는 시점 데이터에 `Instant`를 우선 사용하고, 레거시 `Date`나 `LocalDateTime`을 JDBC/Hibernate로 다루는 환경이라면 JDBC 시간대도 UTC로 맞춰 둘 수 있다.

```yaml
spring:
  jpa:
    properties:
      hibernate.jdbc.time_zone: UTC
```

JVM 기본 시간대가 필요한 라이브러리나 레거시 코드가 있다면 실행 옵션도 UTC로 통일할 수 있다.

```text
-Duser.timezone=UTC
```

다만 이 설정만으로 모든 문제가 해결되지는 않는다. 핵심은 다음처럼 역할을 나누는 것이다.

1. DB와 서버는 UTC 기준으로 시점을 저장하고 처리한다.
2. API 응답에서 시점은 offset이 포함된 ISO-8601 문자열 또는 UTC의 `Z` 표기로 전달한다.
3. 화면 또는 사용자 시간대가 필요한 경계에서만 `ZoneId`를 사용해 변환한다.

`Asia/Seoul`처럼 IANA 시간대 이름을 사용하면 DST를 사용하는 지역도 올바르게 처리할 수 있다. 단순히 `+09:00` 같은 고정 offset만 사용하는 것보다 안전하다.

> 참고: [PostgreSQL Date/Time Types](https://www.postgresql.org/docs/current/datatype-datetime.html), [PostgreSQL Date/Time Functions](https://www.postgresql.org/docs/current/functions-datetime.html)
{: .prompt-tip }

## 정리

클라우드에 배포했다고 시간이 달라지는 것이 아니라, 같은 시점을 서로 다른 시간대로 해석하거나 표시해서 문제가 생긴다.

- Java에서 생성·수정 시각 같은 시점은 `Instant`로 다룬다.
- PostgreSQL에서는 시점 데이터에 `TIMESTAMPTZ`를 사용한다.
- DB와 서버의 기본 시간대는 UTC로 통일한다.
- 사용자에게 보여 줄 때만 `Asia/Seoul` 등 필요한 시간대로 변환한다.

시간대는 데이터가 만들어진 뒤에 억지로 보정하기보다, 저장하는 순간부터 기준을 정하는 편이 훨씬 안전하다.
