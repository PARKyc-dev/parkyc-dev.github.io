---
title: "Cubrid 데이터베이스 - CAST AS VARCHAR"
date: 2026-07-13 22:20:00 +0900
categories: [Persistence, Cubrid]
tags: [persistence, Database, Cubrid]
---
CUBRID에서 `MERGE`, `INSERT`문을 작성하던 중, `VARCHAR` 컬럼에 문자열(`20260101`)을 넣었는데도 데이터 타입 오류가 발생했다.

처음에는 `NULL`, `문자열 길이` 등 데이터의 문제로 생각했으나, 
`날짜형식(YYYYMMDD)의 문자열을 Date, VARCHAR 둘 중 어느것으로 변환할지` Cubrid가 정확하게 판단하지 못해서 발생한 에러

> 현재는 Cubrid DB에서 Bug Fix 한것으로 파악된다
{: .prompt-info }

## 개발 환경

- CUBRID 9.0.3
- `MERGE ... USING (VALUES (...))` 형태의 쿼리
- 대상 컬럼: `VARCHAR(8)`

## 문제 상황

문제가 발생한 컬럼의 구조를 단순화하면 다음과 같다.

```sql
CREATE TABLE TEST_MERGE_DATES (
    TEST_BASE_YMD  VARCHAR(8) NOT NULL,
    TEST_START_YMD VARCHAR(8),
    TEST_END_YMD   VARCHAR(8)
);
```

`TEST_BASE_YMD`와 `TEST_START_YMD`는 모두 `VARCHAR(8)`이고, 두 컬럼의 차이는 `NOT NULL` 여부뿐이었다.

`MERGE`문에서는 다음과 같이 문자열 데이터를 전달하고 있었다.

```sql
MERGE INTO TEST_MERGE_DATES A
USING (
    VALUES (
        '20260101' AS "TEST_BASE_YMD",
        '20260102' AS "TEST_START_YMD",
        '20260103' AS "TEST_END_YMD"
    )
) B
ON (
    A.TEST_BASE_YMD = B.TEST_BASE_YMD
)
WHEN MATCHED THEN
    UPDATE SET
        A.TEST_START_YMD = B.TEST_START_YMD
WHEN NOT MATCHED THEN
    INSERT (
        TEST_BASE_YMD,
        TEST_START_YMD,
        TEST_END_YMD
    )
    VALUES (
        B.TEST_BASE_YMD,
        B.TEST_START_YMD,
        B.TEST_END_YMD
    );
```

실제 쿼리는 더 많은 컬럼을 포함하고 있었지만, 문제가 된 부분만 단순화했다.

실행 결과 `TEST_START_YMD`에 넣으려던 `'20260102'` 값에서 다음과 같은 오류가 발생했다.

```text
Cannot coerce '20260102' to type unknown data type.
```

대상 컬럼도 `VARCHAR(8)`이고 전달한 값도 문자열 리터럴이므로, 처음에는 타입 오류가 발생할 이유가 없어 보였다.

## 문제 해결과정

### 1. 데이터 문자열 길이 초과 여부 확인

`VARCHAR(8)`보다 긴 값이 포함되어 있는지 확인했다.

하지만 입력되는 값은 모두 8자리였고 길이 초과 데이터는 없었다.

### 2. VALUES 내부의 별칭 사용 여부

다음과 같이 `VALUES` 내부에서 `AS`를 사용한 것이 문제인지 확인했다.

```sql
'20260102' AS "TEST_START_YMD"
```

별칭을 제거한 뒤에도 동일한 오류가 발생했다.

별칭은 컬럼의 **이름**을 정할 뿐, 해당 표현식의 **데이터 타입**을 지정하지는 않는다.

### 3. NULL 데이터 존재 여부 확인

데이터 중 `NULL`값이 존재하여,  `NULL` 값이 포함된 행을 제거 후 다시 시도해보았지만, 여전히 에러가 발생했다.


## 원인: VALUES 컬럼의 타입을 명확하게 추론하지 못함

구글링을 하던 중, CUBRID가 날짜 형식의 문자열을 파싱하지 못하는 경우가 있다는 Q&A를 발견했다.
이를 보고 `VALUES`로 만든 파생 테이블의 일부 컬럼 타입을 실행 시점에 결정하지 못하는 상황을 의심했다.

> 참고: [CUBRID Q&A - Cannot coerce value](https://www.cubrid.com/index.php?_filter=search&mid=qna&search_target=comment&search_keyword=Cannot+coerce+value&document_srl=3815914)
{: .prompt-tip }

문자열 리터럴에 따옴표가 붙어 있더라도, `VALUES` 파생 테이블의 각 열에는 별도의 데이터 타입이 결정되어야 한다. 그런데 CUBRID 9.0.3에서 실행한 해당 쿼리에서는 대상 테이블의 DDL만으로 일부 파생 테이블 열의 타입이 안정적으로 확정되지 않았다.

특히 실제 쿼리에는 날짜나 시간 값을 문자열로 저장한 컬럼, 숫자 리터럴, 타입이 없는 `NULL` 표현식이 함께 포함되어 있었다.
따옴표가 있었기 당연히 DBMS에서 문자열로 판단할 것이라고 생각했지만 아니었다.

## 해결: CAST로 데이터 타입을 명시한다

문제가 발생한 값을 다음과 같이 명시적으로 형 변환했다.

```sql
CAST('20260102' AS VARCHAR(8)) AS "TEST_START_YMD"
```

수정한 쿼리는 다음과 같다.

```sql
MERGE INTO TEST_MERGE_DATES A
USING (
    VALUES (
        CAST('20260101' AS VARCHAR(8)) AS "TEST_BASE_YMD",
        CAST('20260102' AS VARCHAR(8)) AS "TEST_START_YMD",
        CAST('20260103' AS VARCHAR(8)) AS "TEST_END_YMD"
    )
) B
ON (
    A.TEST_BASE_YMD = B.TEST_BASE_YMD
)
WHEN MATCHED THEN
    UPDATE SET
        A.TEST_START_YMD = B.TEST_START_YMD
WHEN NOT MATCHED THEN
    INSERT (
        TEST_BASE_YMD,
        TEST_START_YMD,
        TEST_END_YMD
    )
    VALUES (
        B.TEST_BASE_YMD,
        B.TEST_START_YMD,
        B.TEST_END_YMD
    );
```

처음에는 오류가 발생한 `TEST_START_YMD` 컬럼에만 `CAST`를 적용했다. 그러자 기존 오류는 사라지고 다른 컬럼에서 새로운 타입 오류가 발생했다.

이 결과를 통해 특정 컬럼 하나의 데이터 문제가 아니라, `VALUES`로 만든 파생 테이블의 여러 컬럼에서 타입 추론이 불안정하다는 점을 확인할 수 있었다.

결국 문자열, 숫자, `NULL`을 포함한 각 표현식에 대상 컬럼과 동일한 타입을 명시하여 해결했다.

## 여러 타입이 섞여 있다면 전부 명시하는 것이 안전하다

실제 `MERGE`문에는 문자열뿐 아니라 숫자와 `NULL`도 포함될 수 있다.

```sql
USING (
    VALUES (
        CAST('20260102' AS VARCHAR(8))  AS "TEST_START_YMD",
        CAST('01'       AS VARCHAR(2))  AS "STATUS_CD",
        CAST(0          AS NUMERIC(20, 0)) AS "AMOUNT",
        CAST(NULL       AS VARCHAR(20)) AS "DESCRIPTION"
    )
) B
```

타입을 지정할 때는 단순히 `VARCHAR`라고만 작성하기보다, 가능하면 대상 테이블의 정의와 동일하게 길이와 정밀도까지 맞추는 편이 좋다.

```sql
-- 대상 컬럼이 VARCHAR(8)인 경우
CAST('20260102' AS VARCHAR(8))

-- 대상 컬럼이 NUMERIC(20, 0)인 경우
CAST(0 AS NUMERIC(20, 0))
```

## 정리

결론적으로 이번 오류는 `VARCHAR` 컬럼에 잘못된 값을 넣어서 발생한 문제가 아니었다. `VALUES`로 만든 파생 테이블에서 데이터 타입을 명확하게 결정하지 못해 발생한 문제였으며, 각 컬럼의 타입을 `CAST`로 명시하여 해결할 수 있었다.
