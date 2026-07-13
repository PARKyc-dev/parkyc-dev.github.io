---
title: "동시성 문제 해결 - 쿠폰"
date: 2026-07-02 23:00:00 +0900
categories: [Backend, Concurrency]
tags: [java, concurrency, coupon, 작성중]
---

Github : https://github.com/PARKyc-dev/concurrency-lab  
File : `CouponServiceTest.java`

---
`현재 게시글은 작성중인 초안입니다.`
---

오늘 `Concurrency-lab` 프로젝트에서는 쿠폰 발급 상황에서 발생할 수 있는 동시성 문제를 실험했다. 핵심은 한정된 수량의 쿠폰이 있을 때 여러 요청이 동시에 들어와도 최대 발급 수량을 넘기지 않도록 만드는 것이다.

이번 작업에서는 쿠폰 도메인을 간단히 만들고, Redis 기반 발급 방식과 RDBMS 기반 발급 방식을 각각 테스트했다.

## 문제 상황

쿠폰 발급은 전형적인 동시성 문제가 발생하기 쉬운 기능이다.

예를 들어 1,000개의 쿠폰이 있고 1,500명의 사용자가 동시에 발급 요청을 보낸다고 가정해보자. 이때 단순히 현재 발급 수량을 조회한 뒤 애플리케이션에서 `+1`을 계산하고 저장하면, 여러 스레드가 같은 값을 읽고 동시에 갱신할 수 있다.

그 결과 실제로는 1,000개만 발급되어야 하는데 그보다 많은 요청이 성공하거나, 남은 수량 계산이 어긋날 수 있다.

이번 실험의 목표는 다음과 같았다.

- 쿠폰 최대 수량을 초과하지 않는다.
- 동시에 많은 요청이 들어와도 성공/실패 결과가 일관된다.
- Redis 방식과 DB update 방식의 차이를 비교한다.

## 쿠폰 도메인

쿠폰은 우선 동시성 테스트에 필요한 최소 필드만 두었다.

```java
@Entity
@Table(name = "coupon")
public class Coupon {

    @Id
    @Column(name = "coupon_id", comment = "쿠폰 아이디")
    private Long couponId;

    @Column(name = "coupon_name", comment = "쿠폰 이름")
    private String couponName;

    @Column(name = "discount_rate", comment = "쿠폰 사용시 할인율")
    private Integer discountRate;

    @Column(name = "issued_coupon", comment = "발급된 쿠폰 수량")
    private Long issuedQuantity;

    @Column(name = "max_coupon_quantity", comment = "쿠폰 최대 발행 수량")
    private Long maxCouponQuantity;
}
```

실제 서비스라면 발급 가능 시간, 사용 가능 기간, 사용자별 발급 이력 같은 필드가 더 필요하다. 하지만 이번 글에서는 동시성 제어 자체가 목적이기 때문에 최대 수량과 발급 수량에 집중했다.

## DB 조건부 UPDATE 방식

두 번째 방식은 DB에서 조건부 update를 수행하는 것이다.

```java
@Modifying(clearAutomatically = true, flushAutomatically = true)
@Query("""
    UPDATE Coupon
       SET issuedQuantity = issuedQuantity + 1
     WHERE issuedQuantity < maxCouponQuantity
       AND couponId = :couponId
""")
int increaseIssuedCouponCount(Long couponId);
```

이 쿼리는 `issuedQuantity < maxCouponQuantity` 조건을 만족할 때만 발급 수량을 증가시킨다. update된 row 수가 `0`이면 더 이상 발급할 수 없는 상태로 판단한다.

서비스 코드는 다음처럼 작성했다.

```java
@Transactional
public IssueCouponResult issueCouponByH2() {
    int updatedCount = couponRepository.increaseIssuedCouponCount(TEST_COUPON_ID);
    if (updatedCount == 0) {
        return new IssueCouponResult(false, 0L, Thread.currentThread().getName());
    }

    Coupon coupon = couponRepository.findById(TEST_COUPON_ID).orElseThrow();
    Long remainCoupon = coupon.getMaxCouponQuantity() - coupon.getIssuedQuantity();

    return new IssueCouponResult(true, remainCoupon, Thread.currentThread().getName());
}
```

여기서 중요한 점은 조회 후 애플리케이션에서 판단하는 방식이 아니라, update 조건에 최대 수량 제한을 넣었다는 것이다. 동시에 여러 트랜잭션이 들어오더라도 DB가 update 조건을 기준으로 처리하므로 최대 수량을 넘는 발급을 막을 수 있다.

이 방법의 단점이라고 하면, `@Transactional`어노테이션이 있지만, 남은 수량을 정확하게 알 수 없다는 점.

## Redis DECR 방식

두 번째 방식은 Redis의 `decrement()` 메소드를 하는 방식이다. 

```java
public IssueCouponResult issueCoupon() {
    Long remainCoupon = redis.opsForValue().decrement("coupon:quantity");
    if (remainCoupon < 0) {
        redis.opsForValue().increment("coupon:quantity");
        return new IssueCouponResult(false, 0L, Thread.currentThread().getName());
    }

    return new IssueCouponResult(true, remainCoupon, Thread.currentThread().getName());
}
```

Redis의 `DECR`는 단일 명령으로 실행된다. 여러 요청이 동시에 들어와도 Redis 내부에서는 한 번에 하나씩 수량을 감소시키기 때문에, 애플리케이션에서 별도 락을 잡지 않아도 원자적인 감소 연산을 사용할 수 있다.

남은 수량이 음수가 되면 실패로 처리하고 `INCR`로 수량을 되돌렸다. 이 방식은 간단하지만, 실패 요청이 많을 때는 일단 음수까지 감소시킨 뒤 보정한다는 특징이 있다. 실제 서비스에서는 Lua script로 감소와 검증을 하나의 원자 작업으로 묶는 방식도 고려할 수 있다.

## 동시성 테스트

테스트는 1,000개의 쿠폰에 대해 1,500개의 동시 요청을 보내는 방식으로 구성했다.

```java
Long couponQuantity = 1000L;
couponService.settingCouponQuantity(couponQuantity);

int threadCount = 1500;
CountDownLatch startLatch = new CountDownLatch(1);
CountDownLatch standbyLatch = new CountDownLatch(threadCount);
List<Future<IssueCouponResult>> futures = new ArrayList<>();

try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    for (int i = 0; i < threadCount; i++) {
        futures.add(executor.submit(() -> {
            standbyLatch.countDown();
            startLatch.await();
            return couponService.issueCoupon();
        }));
    }

    standbyLatch.await();
    startLatch.countDown();
}
```

`standbyLatch`로 모든 작업이 준비될 때까지 기다리고, `startLatch.countDown()`으로 동시에 요청을 시작하도록 만들었다. 스레드는 Java virtual thread executor를 사용했다.

검증은 성공 요청과 실패 요청 수를 나누어 확인했다.

```java
assertThat(success).hasSize(couponQuantity.intValue());
assertThat(fail).hasSize(threadCount - couponQuantity.intValue());
```

1,500개 요청 중 1,000개만 성공하고 500개는 실패해야 한다. Redis 방식은 마지막에 Redis의 남은 수량이 `0`인지 확인했고, H2 방식은 DB의 `issuedQuantity`가 최대 발급 수량과 같은지 확인했다.

## 오늘 작업하며 정리한 점

쿠폰 발급처럼 수량 제한이 있는 기능은 단순한 CRUD처럼 보이지만, 동시 요청이 들어오는 순간 별도의 설계가 필요하다.

이번 실험에서 Redis 방식은 구현이 단순하고 빠른 카운터 처리에 잘 맞았다. 다만 Redis 값과 DB 발급 이력을 함께 관리해야 한다면 두 저장소 사이의 정합성을 어떻게 맞출지 추가 설계가 필요하다.

DB 조건부 update 방식은 저장소를 하나로 유지할 수 있고, `WHERE issued_quantity < max_coupon_quantity` 조건으로 최대 수량 제한을 명확하게 표현할 수 있다. 대신 트래픽이 커질수록 DB에 부하가 집중될 수 있다.

아직 벌크 쿠폰 발급과 사용자별 발급 이력은 구현하지 않았다. 다음 단계에서는 사용자 ID를 포함한 발급 이력 테이블을 추가하고, 같은 사용자가 같은 쿠폰을 중복 발급받지 못하도록 제약 조건과 동시성 처리를 함께 실험해볼 예정이다.

---

Github Code : https://github.com/PARKyc-dev/concurrency-lab
