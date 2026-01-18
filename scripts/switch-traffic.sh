#!/bin/bash
# Blue/Green 트래픽 스위칭 스크립트

set -e

NAMESPACE="production"
VIRTUALSERVICE="myapp"

# 현재 트래픽 가중치 확인
echo "Current traffic weights:"
kubectl get virtualservice $VIRTUALSERVICE -n $NAMESPACE -o jsonpath='{.spec.http[0].route[*].weight}'
echo

# 사용자 확인
read -p "Switch traffic to Green? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

# Blue 0% / Green 100%로 변경
kubectl patch virtualservice $VIRTUALSERVICE -n $NAMESPACE --type='json' -p='[
  {"op": "replace", "path": "/spec/http/0/route/0/weight", "value": 0},
  {"op": "replace", "path": "/spec/http/0/route/1/weight", "value": 100}
]'

echo "Traffic switched to Green (100%)"
echo

# 새로운 가중치 확인
echo "New traffic weights:"
kubectl get virtualservice $VIRTUALSERVICE -n $NAMESPACE -o jsonpath='{.spec.http[0].route[*].weight}'
echo
