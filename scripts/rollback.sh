#!/bin/bash
# 롤백 스크립트 (Green → Blue)

set -e

NAMESPACE="production"
VIRTUALSERVICE="myapp"

echo "ROLLBACK: Switching traffic back to Blue"

# Blue 100% / Green 0%로 변경
kubectl patch virtualservice $VIRTUALSERVICE -n $NAMESPACE --type='json' -p='[
  {"op": "replace", "path": "/spec/http/0/route/0/weight", "value": 100},
  {"op": "replace", "path": "/spec/http/0/route/1/weight", "value": 0}
]'

echo "✅ Rollback completed. Traffic is now 100% on Blue"
