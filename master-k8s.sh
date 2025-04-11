#!/bin/bash
set -e

# Kubernetes 이미지 사전 다운로드
kubeadm config images pull --cri-socket unix:///run/containerd/containerd.sock --kubernetes-version v1.30.3

# kubeadm init 실행 및 토큰 추출
KUBEADM_OUTPUT=$(kubeadm init \
--pod-network-cidr=10.244.0.0/16 \
--upload-certs --kubernetes-version=v1.30.3 \
--cri-socket unix:///run/containerd/containerd.sock \
--ignore-preflight-errors=all)

# 토큰 정보 추출 및 저장
echo "$KUBEADM_OUTPUT" | grep -A 2 "kubeadm join" > token.txt

# kubeconfig 설정
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Flannel CNI 적용
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

