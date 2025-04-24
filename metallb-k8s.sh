#!/bin/bash

set -e

echo "[1] MetalLB 매니페스트 다운로드"
wget -q https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml

echo "[2] MetalLB 매니페스트 적용"
kubectl apply -f metallb-native.yaml

echo "[3] IPAddressPool 및 L2Advertisement 리소스 생성"
cat <<EOF > config-metallb.yml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 211.183.3.200-211.183.3.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
EOF

kubectl apply -f config-metallb.yml

echo "[4] MetalLB Pod 상태 확인"
kubectl get pod -n metallb-system -o wide

