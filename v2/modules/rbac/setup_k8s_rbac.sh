#!/bin/bash

# Kubernetes RBAC 설정 스크립트
echo "Kubernetes RBAC 권한 설정 시작..."

# 네임스페이스 생성
kubectl create namespace development --dry-run=client -o yaml | kubectl apply -f -

# ClusterRole 및 Role 생성
cat <<EOF | kubectl apply -f -
---
# AKS Admins를 위한 ClusterRole (이미 cluster-admin이 있으므로 생략 가능)
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: aks-admins-cluster-admin
subjects:
- kind: Group
  name: 0c5f0375-80e6-4626-8d4d-3e06de83e968
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
---
# AKS Developers를 위한 Role (특정 네임스페이스에 한정)
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: namespace-admin
  namespace: development
rules:
- apiGroups: ["", "extensions", "apps", "networking.k8s.io", "batch"]
  resources: ["*"]
  verbs: ["*"]
---
# AKS Developers를 위한 RoleBinding
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: developers-namespace-admin
  namespace: development
subjects:
- kind: Group
  name: 7794c6c0-e7fd-49af-ba69-d41594eeef1d
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: namespace-admin
  apiGroup: rbac.authorization.k8s.io
---
# AKS Operators를 위한 ClusterRole (읽기 전용)
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cluster-reader
rules:
- apiGroups: ["", "extensions", "apps", "networking.k8s.io", "batch"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
---
# AKS Operators를 위한 ClusterRoleBinding
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: operators-cluster-reader
subjects:
- kind: Group
  name: f301f9c6-cd63-4821-88c6-6ffa41a4c7c8
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-reader
  apiGroup: rbac.authorization.k8s.io
EOF

echo "Kubernetes RBAC 권한 설정 완료!"
