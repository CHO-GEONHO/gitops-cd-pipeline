# GitOps CD Pipeline

## 🎯 프로젝트 개요

FluxCD와 Istio를 활용한 Blue/Green 배포 자동화 GitOps 파이프라인

**핵심 가치:**
- Stage 환경 자동 배포 (이미지 푸시 시 자동 반영)
- Prod 환경 Blue/Green 무중단 배포
- 트래픽 스위칭 기반 1분 롤백
- GitOps 선언적 인프라 관리

## 🏗️ 아키텍처

```
ACR Push → CD Daemon → Git Commit → FluxCD → Kustomize → Kubernetes
                                                              ↓
                                                    Istio VirtualService
                                                    (Traffic Switching)
                                                              ↓
                                                    Blue (100%) / Green (0%)
```

## 🛠️ 기술 스택

| 카테고리 | 기술 |
|---------|------|
| GitOps | FluxCD |
| Service Mesh | Istio (Gateway, VirtualService) |
| 매니페스트 관리 | Kustomize |
| 배포 전략 | Blue/Green Deployment |
| 모니터링 | Fluent-bit, Prometheus |
| 알림 | Slack |

## 🔥 문제 해결 과정

자세한 내용은 [docs/problem-solving.md](docs/problem-solving.md) 참고

### 주요 개선 사항
1. 2주 1회 수동 배포 → Stage 자동 + Prod Blue/Green
2. 롤백 시간 10분 → 1분 (트래픽 스위칭)
3. 순단 발생 → 순단 0분 달성
4. FluxCD Kustomization 순환 참조 해결

## 📊 성과

| 항목 | AS-IS | TO-BE | 개선율 |
|------|-------|-------|--------|
| Stage 배포 빈도 | 2주 1회 | 매일 자동 | - |
| Prod 배포 방식 | 수동 (정기점검) | Blue/Green | - |
| 롤백 시간 | ~10분 | **~1분** | **90% 단축** |
| 순단 시간 | 발생 | **0분** | **100% 개선** |

## 📂 프로젝트 구조

```
gitops-cd-pipeline/
├── docs/                    # 문서
│   ├── architecture.md      # 아키텍처
│   ├── problem-solving.md   # 문제 해결 과정
│   ├── deployment-strategy.md  # 배포 전략
│   └── rollback-procedure.md   # 롤백 절차서
│
├── base/                    # Kustomize Base
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
│
├── overlays/                # Kustomize Overlays
│   ├── blue/               # Blue 환경 (Active)
│   ├── green/              # Green 환경 (Standby)
│   └── test/               # 테스트 환경
│
├── istio/                   # Istio 설정
│   ├── gateway/            # Ingress Gateway
│   ├── prod/               # Prod VirtualService
│   └── stage/              # Stage VirtualService
│
├── cd-daemon/               # CD 자동화 데몬
│   ├── daemon.py           # ACR 감시 데몬
│   ├── git_ops.py          # Git 커밋 자동화
│   └── slack_notify.py     # Slack 알림
│
├── fluxcd/                  # FluxCD 리소스
│   ├── kustomization.yaml  # FluxCD Kustomization CR
│   └── gitrepository.yaml  # Git 소스
│
└── scripts/                 # 운영 스크립트
    ├── switch-traffic.sh   # 트래픽 스위칭
    ├── rollback.sh         # 롤백
    └── health-check.sh     # 헬스체크
```

## 🚀 배포 프로세스

### Stage 환경 (자동)
1. 개발자 코드 Push
2. CI 파이프라인에서 이미지 빌드 → ACR Push
3. CD Daemon이 새 이미지 감지
4. Git에 Stage manifest 업데이트 (자동 커밋)
5. FluxCD가 변경 감지 → Stage 클러스터 배포

### Prod 환경 (Blue/Green)
1. Stage 검증 완료 후 수동 승인
2. Green 환경에 새 버전 배포
3. Green 헬스체크 통과 확인
4. Istio VirtualService 트래픽 가중치 변경 (Blue 100% → Green 100%)
5. 구 버전(Blue)은 Standby 상태 유지 (롤백 대비)

### 롤백 (1분 이내)
```bash
# 트래픽만 스위칭 (이미지 재배포 불필요)
./scripts/rollback.sh
```

## 📖 추가 문서

- [배포 전략 비교](docs/deployment-strategy.md)
- [롤백 절차서](docs/rollback-procedure.md)
- [트래픽 스위칭 가이드](traffic/README.md)

## 📫 Contact

프로젝트 관련 문의: [Your Email]
