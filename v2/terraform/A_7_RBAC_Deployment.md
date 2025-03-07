# AKS RBAC 배포 가이드

이 가이드는 AKS 클러스터에 RBAC(Role-Based Access Control)를 배포하는 방법을 설명합니다.

## 사전 요구 사항

- AKS 클러스터가 배포되어 있어야 합니다.
- Azure AD 그룹이 생성되어 있어야 합니다.
- kubectl이 설치되어 있어야 합니다.

## RBAC 배포 단계

### 1. AKS 자격 증명 가져오기

```bash
# AKS 클러스터 자격 증명 가져오기
az aks get-credentials --resource-group <RESOURCE_GROUP> --name <AKS_CLUSTER_NAME> --admin
```

### 2. 네임스페이스 생성

```bash
# 개발 네임스페이스 생성
kubectl create namespace dev

# 운영 네임스페이스 생성
kubectl create namespace prod

# 모니터링 네임스페이스 생성
kubectl create namespace monitoring
```

### 3. RBAC 역할 및 바인딩 생성

#### 개발자 역할 및 바인딩

```bash
# 개발자 역할 생성
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: dev
rules:
- apiGroups: ["", "extensions", "apps"]
  resources: ["deployments", "replicasets", "pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
EOF

# 개발자 역할 바인딩 생성
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: dev
subjects:
- kind: Group
  name: <AKS_DEV_GROUP_ID>
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
EOF
```

#### 운영자 역할 및 바인딩

```bash
# 운영자 역할 생성
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: operator
  namespace: prod
rules:
- apiGroups: ["", "extensions", "apps"]
  resources: ["deployments", "replicasets", "pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["batch"]
  resources: ["jobs", "cronjobs"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
EOF

# 운영자 역할 바인딩 생성
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: operator-binding
  namespace: prod
subjects:
- kind: Group
  name: <AKS_OPS_GROUP_ID>
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: operator
  apiGroup: rbac.authorization.k8s.io
EOF
```

#### 관리자 클러스터 역할 바인딩

```bash
# 관리자 클러스터 역할 바인딩 생성
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-binding
subjects:
- kind: Group
  name: <AKS_ADMIN_GROUP_ID>
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF
```

### 4. RBAC 확인

```bash
# 역할 확인
kubectl get roles --all-namespaces

# 역할 바인딩 확인
kubectl get rolebindings --all-namespaces

# 클러스터 역할 바인딩 확인
kubectl get clusterrolebindings

# 특정 사용자의 권한 확인
kubectl auth can-i get pods --namespace dev --as <USER_EMAIL>
```

## 참고 사항

- `<AKS_DEV_GROUP_ID>`, `<AKS_OPS_GROUP_ID>`, `<AKS_ADMIN_GROUP_ID>`는 Azure AD 그룹 ID로 대체해야 합니다.
- `<USER_EMAIL>`은 권한을 확인하려는 사용자의 이메일 주소로 대체해야 합니다.
- 역할 및 바인딩은 필요에 따라 수정할 수 있습니다. 