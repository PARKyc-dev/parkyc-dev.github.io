---
title: "Java 동시성 테스트 방법 - Thread"
date: 2026-06-30 23:00:00 +0900
categories: [Backend, Java]
tags: [java, concurrency, thread, test]
---

Github: https://github.com/PARKyc-dev/concurrency-lab    
File: `CouponServiceTest.java`

동시성 문제가 발생할 수 있는 기능을 만들었을 때는 단순한 단위 테스트만으로는 충분하지 않다.  
실제 문제는 여러 요청이 같은 시점에 몰릴 때 발생하기 때문이다.

이번 글에서는 Java 코드 안에서 여러 작업을 동시에 실행해 동시성 상황을 재현하는 방법을 정리한다. 
예시는 `Concurrency-lab` 프로젝트의 쿠폰 발급 테스트를 기준으로 한다.

## 스레드 생성하기

가장 간단한 Thread 생성 방법은 아래와 같이 `new Thread()`로 생성하는 방법이다.

```java
Thread thread = new Thread(() -> {
    couponService.issueCoupon();
});
thread.start();
```
그러나 이 방법은 플랫폼 OS를 1개 생성하고 작업을 할당하는 방법이기 때문에 많은 리소스를 사용한다.

특히 동시성 테스트를 하기 위해서 많은 양의 스레드를 생성하면 `OutOfMemory` 에러가 뜰 확률이 매우 높다

그래서 보통 동시성 테스트 등 많은 수의 작업을 테스트할 때는 `new Thread()`를 반복해서 직접 생성하기보다 `ExecutorService`를 사용하는 편이 일반적이다.

아래와 같이 `Thread Pool`을 사용하여, 정해진 수의 플랫폼 스레드를 생성하고 재사용할 수 있다.

```java
ExecutorService executor = Executors.newFixedThreadPool(100);
```

또는 Java 21 이상이라면 가상 스레드를 사용할 수 있다.

```java
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    futures.add(executor.submit(() -> couponService.issueCoupon()));
}
```

이번 쿠폰 발급 테스트에서도 가상 스레드를 사용했다.

```java
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

코드만 보면 요청 1개당 작업 1개를 만드는 구조가 명확하게 드러난다. 동시성 테스트처럼 많은 작업을 한 번에 실행해야 하는 상황에서는 가상 스레드가 테스트 코드를 단순하게 만들어준다.

## 동시에 시작시키기

동시성 테스트에서 중요한 점은 단순히 여러 작업을 실행하는 것이 아니라, 가능한 한 같은 시점에 시작되도록 만드는 것이다.

예를 들어 1,500개의 작업을 순서대로 제출하면 앞쪽 작업은 이미 실행되고 있고 뒤쪽 작업은 아직 대기 중일 수 있다. 이렇게 되면 실제로 동시에 경쟁하는 상황이 약해진다.

이를 보완하기 위해 `CountDownLatch`를 사용했다.

```java
int threadCount = 1500;
CountDownLatch startLatch = new CountDownLatch(1);
CountDownLatch standbyLatch = new CountDownLatch(threadCount);
```

`standbyLatch`는 모든 작업이 시작 준비를 마쳤는지 확인하는 용도다. 각 작업은 실행되자마자 `standbyLatch.countDown()`을 호출하고, 이후 `startLatch.await()`에서 대기한다.

```java
futures.add(executor.submit(() -> {
    standbyLatch.countDown();
    startLatch.await();
    return couponService.issueCoupon();
}));
```

테스트 코드는 모든 작업이 준비될 때까지 기다린 뒤, `startLatch.countDown()`을 호출해 대기 중인 작업을 한 번에 풀어준다.

```java
standbyLatch.await();
startLatch.countDown();
```

이렇게 하면 여러 작업이 쿠폰 발급 메서드에 거의 동시에 진입하게 만들 수 있다.

![스레드 테스트 흐름](/assets/image/2026-06-30-java-thread/thread-1.svg)


## 결과 검증

동시성 테스트는 실행만 하는 것으로 끝나면 안 된다. 성공해야 하는 요청 수와 실패해야 하는 요청 수를 명확하게 검증해야 한다.

쿠폰 발급 테스트에서는 1,000개의 쿠폰에 대해 1,500개의 요청을 동시에 보냈다. 따라서 성공은 1,000개, 실패는 500개여야 한다.

```java
assertThat(success).hasSize(couponQuantity.intValue());
assertThat(fail).hasSize(threadCount - couponQuantity.intValue());
```

이런 검증이 없으면 테스트는 단순히 "에러가 안 났다" 정도만 확인하게 된다. 동시성 테스트에서는 최종 수량, 성공/실패 개수, 저장소에 남은 값까지 함께 검증하는 편이 좋다.

## 정리

동시성 테스트를 할 때는 여러 작업을 만드는 것보다, 여러 작업이 같은 시점에 경쟁하도록 만드는 것이 더 중요하다. `CountDownLatch`는 이 시작 시점을 맞추는 데 유용하다.

플랫폼 스레드는 실제 OS 스레드를 사용하기 때문에 많은 수를 직접 만들기 부담스럽다. 스레드 풀은 이 문제를 완화하지만, 작업 수만큼 동시 요청을 표현하는 테스트에서는 설정과 큐 동작을 함께 고려해야 한다.

Java 21의 가상 스레드를 사용하면 많은 동시 작업을 테스트 코드에서 비교적 단순하게 표현할 수 있다. 쿠폰 발급, 재고 차감, 선착순 이벤트처럼 동시에 많은 요청이 몰릴 수 있는 기능을 검증할 때 좋은 선택지가 될 수 있다.

## 참고자료

1. <https://yoonseon.tistory.com/151>
