#!/bin/bash
set -e

# Step 1: Kubernetes 이미지 사전 다운로드
echo "[Step 1] Pulling Kubernetes images..."
kubeadm config images pull --cri-socket unix:///run/containerd/containerd.sock --kubernetes-version v1.30.3

# Step 2: kubeadm init 실행 및 출력 저장
echo "[Step 2] Initializing Kubernetes master node..."
kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --upload-certs \
  --kubernetes-version=v1.30.3 \
  --cri-socket unix:///run/containerd/containerd.sock \
  --ignore-preflight-errors=all | tee kubeadm-init.log

# Step 3: 토큰 정보 추출 및 저장
echo "[Step 3] Saving kubeadm join token to token.txt..."
grep -A 2 "kubeadm join" kubeadm-init.log > token.txt

# Step 4: kubeconfig 설정
echo "[Step 4] Setting up kubeconfig for current user..."
mkdir -p "$HOME/.kube"
cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
chown "$(id -u):$(id -g)" "$HOME/.kube/config"

# Step 5: Flannel CNI 적용
echo "[Step 5] Applying Flannel CNI..."
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

echo "[Complete] Kubernetes cluster with Flannel is ready!"
