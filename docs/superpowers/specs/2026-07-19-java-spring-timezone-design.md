# Java/Spring Timezone 포스팅 설계

## 목표

Java/Spring을 사용하는 주니어 실무자가 클라우드와 PostgreSQL 환경에서 시간대가 달라져 발생하는 문제를 이해하고, UTC 저장과 표시 시점 변환 원칙을 적용할 수 있게 한다.

## 독자와 범위

- 독자: Java/Spring을 사용해 본 주니어 실무자
- 데이터베이스: PostgreSQL
- 포함: Java 시간 타입 선택, PostgreSQL `timestamp`와 `timestamptz`, `now()`의 세션 시간대 의존성, Spring/JVM/DB 점검 항목
- 제외: 특정 클라우드 사업자 설정, 날짜만 필요한 도메인 모델의 상세 설계

## 구성

1. 배포 후 생성 시간이 9시간 다르게 보이는 상황을 문제로 제시한다.
2. `Instant`는 시점을 표현하고, `LocalDateTime`은 시간대 정보가 없다는 점을 설명한다.
3. PostgreSQL에서는 시점 데이터에 `timestamptz`를 사용하고 UTC 기준으로 저장한다.
4. `now()`는 현재 트랜잭션 시점을 반환하며, 결과 표시는 세션의 `TimeZone` 설정에 따라 달라짐을 보인다.
5. API 응답이나 화면에 표시할 때 `Asia/Seoul` 등 사용자 시간대로 변환한다.
6. Spring, JVM, PostgreSQL의 확인 명령과 설정 예시를 체크리스트로 정리한다.

## 성공 기준

- 독자가 `timestamp`와 `timestamptz`를 구분할 수 있다.
- `now()`로 저장한 시각이 환경별로 다르게 보이는 이유를 설명한다.
- UTC 저장과 사용자 시간대 표시라는 일관된 기준을 적용할 수 있다.
