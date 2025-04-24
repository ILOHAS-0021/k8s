#!/bin/bash
set -e

# Kubernetes 이미지 사전 다운로드
echo "[Step 1] Pulling Kubernetes images..."
kubeadm config images pull --cri-socket unix:///run/containerd/containerd.sock --kubernetes-version v1.30.3

# kubeadm init 실행 및 토큰 추출
echo "[Step 2] Initializing Kubernetes master node..."
KUBEADM_OUTPUT=$(kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --upload-certs --kubernetes-version=v1.30.3 \
  --cri-socket unix:///run/containerd/containerd.sock \
  --ignore-preflight-errors=all)

# 토큰 정보 추출 및 저장
echo "[Step 3] Saving kubeadm join token to token.txt..."
echo "$KUBEADM_OUTPUT" | grep -A 2 "kubeadm join" > token.txt

# kubeconfig 설정
echo "[Step 4] Setting up kubeconfig for current user..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Flannel CNI 적용
echo "[Step 5] Applying Flannel CNI..."
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# metalLB 적용
echo "[Step 6] Applying MetalLB manifests..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml

# metalLB 구성 파일 생성 및 적용
echo "[Step 7] Creating MetalLB config..."
cat <<EOF > config-metallb.yml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.240-192.168.1.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
EOF

echo "[Step 8] Applying MetalLB config..."
kubectl apply -f config-metallb.yml

echo "[Complete] Kubernetes cluster with Flannel and MetalLB is ready!"

