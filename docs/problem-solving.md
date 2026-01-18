# 문제 해결 과정

GitOps CD Pipeline 구축 과정에서 마주친 주요 문제와 해결 방법을 기록합니다.

---

## 문제 1: 2주 1회 수동 배포의 한계

### 상황
- 정기점검 시간(2주 1회)에만 배포 가능
- 긴급 핫픽스 대응이 느림
- 개발자 피드백 주기가 길어짐

### 원인 분석
- 수동 배포 프로세스로 인한 운영 부담
- 배포 시 발생할 수 있는 리스크에 대한 우려
- 명확한 배포 자동화 전략 부재

### 해결 방법
**Stage 환경:**
- ACR 이미지 푸시 시 자동 배포
- CD Daemon이 60초 주기로 신규 이미지 감지
- Git 자동 커밋 → FluxCD 자동 배포

**Prod 환경:**
- Blue/Green 전략으로 안전성 확보
- 트래픽 스위칭 방식으로 롤백 1분 이내 가능
- 수동 승인 유지 (안정성)

### 결과
- Stage: 매일 자동 배포로 빠른 피드백
- Prod: 안전한 배포 + 빠른 롤백
- 개발 속도 향상

---

## 문제 2: 롤백 시간 10분 → 1분

### 상황
- 기존: 롤백 = 이전 이미지 재배포 필요
- Pod 재시작 시간 + 이미지 Pull 시간 = 약 10분
- 장애 영향 시간이 길어짐

### 원인 분석
- Rolling Update 방식의 한계
- 새 Pod 생성/이전 Pod 종료 시간 소요

### 해결 방법
**Blue/Green 배포 채택:**
```yaml
# Istio VirtualService 가중치만 변경
spec:
  http:
  - route:
    - destination:
        host: myapp
        subset: blue
      weight: 0        # 0%로 변경
    - destination:
        host: myapp
        subset: green
      weight: 100      # 100%로 변경
```

**롤백 스크립트:**
```bash
# 트래픽만 스위칭 (재배포 불필요)
kubectl patch virtualservice myapp -p '{"spec":{"http":[{"route":[{"destination":{"subset":"blue"},"weight":100}]}]}}'
```

### 결과
- 롤백 시간: 10분 → **1분**
- Pod 재시작 불필요
- 순단 0분 달성

---

## 문제 3: FluxCD Kustomization 순환 참조

### 상황
- FluxCD가 Kustomization 리소스 적용 시 순환 참조 에러
- `dependsOn` 체인이 복잡해지면서 발생

### 원인 분석
```yaml
# 잘못된 의존성 설정 예시
# A → B → C → A (순환)
```

### 해결 방법
- 의존성 그래프 단순화
- Base → Overlays → Istio 순서로 명확히 분리
- 불필요한 `dependsOn` 제거

### 결과
- FluxCD 배포 성공률 향상
- 명확한 배포 순서 확립

---

## 문제 4: Blue/Green 전환 시 세션 유실

### 상황
- 트래픽 스위칭 시 일부 사용자 세션 끊김
- 특히 WebSocket 연결 문제

### 원인 분석
- VirtualService 전환 시 기존 연결 강제 종료
- Session Affinity 미설정

### 해결 방법
```yaml
# DestinationRule에 Session Affinity 추가
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
spec:
  trafficPolicy:
    loadBalancer:
      consistentHash:
        httpHeaderName: "x-session-id"
```

### 결과
- 세션 유지율 향상
- 사용자 경험 개선

---

## 문제 5: CD 데몬 이미지 다이제스트 감지 누락

### 상황
- 동일 태그에 이미지를 덮어쓸 경우 감지 실패
- 예: `myapp:latest`를 계속 푸시하면 감지 안 됨

### 원인 분석
- 태그 기반 감지의 한계
- 이미지 다이제스트(SHA256) 비교 필요

### 해결 방법
```python
# 다이제스트 기반 감지
new_digest = get_image_digest(image_name, tag)
if new_digest != last_digest:
    deploy_new_version(new_digest)
```

### 결과
- 모든 이미지 변경 감지
- 정확한 배포 트리거

---

## 개선 아이디어

- [ ] Canary 배포 추가 (Blue/Green + Canary)
- [ ] 자동 롤백 트리거 (에러율 기반)
- [ ] Argo CD 도입 검토
- [ ] Progressive Delivery (Flagger)

---

**마지막 업데이트:** 2026-01-XX
