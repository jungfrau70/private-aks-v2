설정 요약
Hub 네트워크에 추가된 PostgreSQL 설정:
서브넷: 10.0.5.0/24 범위로 Hub VNet에 db-subnet 생성
PostgreSQL 서버: pgsql-hub-server라는 이름으로 Hub 리소스 그룹에 배포
프라이빗 엔드포인트: Spoke VNet의 endpoints-subnet에 연결
프라이빗 DNS: privatelink.postgres.database.azure.com 존 사용
네트워크 구성:
Hub VNet (10.0.0.0/16):

Bastion Subnet: 10.0.0.0/26
Jumpbox Subnet: 10.0.0.64/26
Firewall Subnet: 10.0.0.128/26
ACR Subnet: 10.0.1.0/26
Agent Subnet: 10.0.1.64/26
DB Subnet: 10.0.5.0/24 (새로 추가)
Spoke VNet (10.1.0.0/16):

AKS Subnet: 10.1.0.0/24
App Gateway Subnet: 10.1.1.0/24
Endpoints Subnet: 10.1.2.0/24
LoadBalancer Subnet: 10.1.3.0/24
이 구성으로 PostgreSQL이 Hub 네트워크에 안전하게 배포되고, AKS 클러스터에서 VNet 피어링을 통해 접근할 수 있습니다.


---
## Bastion 서버를 통한 AKS 명령어 실행 및 네트워크 진단용 샘플 Pod 배포 가이드

### 1. Bastion 서버에서 kubectl 환경 구성

1. Bastion 서버에 SSH 접속
   - Azure Portal 또는 로컬 PC에서 SSH로 Bastion 서버에 접속합니다.
    - 예시: `ssh <bastion-user>@<bastion-public-ip>`
    
    <<< Jumpbox >>>
    사용자 이름: azureuser
    비밀번호: P@ssw0rd1234!

2. kubectl 설치 (설치되어 있지 않은 경우)
   ```bash
   curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
   chmod +x ./kubectl
   sudo mv ./kubectl /usr/local/bin/kubectl
   ```

3. Azure CLI 설치 및 로그인 (설치되어 있지 않은 경우)
   ```bash
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   az login
   az account set --subscription <your-subscription-id>
   ```

4. AKS kubeconfig 다운로드
   ```bash
   az aks get-credentials --resource-group <aks-resource-group> --name <aks-cluster-name>
   # 예시: az aks get-credentials --resource-group rg-spoke --name aks-cluster
   ```

5. kubectl 정상 동작 확인
   ```bash
   kubectl get nodes
   ```

---
### 2. 네트워크 진단용 샘플 Pod 배포 및 테스트


#!/bin/bash
cat <<EOF > network-multitool.yaml
apiVersion: v1
kind: Pod
metadata:
  name: network-multitool
  labels:
    app: network-multitool
spec:
  containers:
  - name: multitool
    image: praqma/network-multitool
    command: ["sleep", "3600"]
    resources:
      requests:
        cpu: 10m
        memory: 32Mi
      limits:
        cpu: 100m
        memory: 128Mi
    env:
    - name: TZ
      value: "Asia/Seoul"
EOF

chmod +x create-multitool.sh
./create-multitool.sh


1. 네트워크 진단용 Pod 배포 (busybox, nicolaka/netshoot 등)
    kubectl apply -f network-multitool.yaml

2. Pod 진입
    kubectl exec -it network-multitool -- sh

3. PostgreSQL 연결 테스트
   ```bash
   kubectl exec -it net-test -- sh
   # 또는
   kubectl exec -it netshoot -- bash
   # PostgreSQL 연결 테스트 (psql 설치 필요 시 apk add postgresql-client)
   psql -h <postgres-private-fqdn> -U <dbuser> -d <dbname>
   # 또는 nc, telnet 등으로 포트 연결 확인
   nc -vz <postgres-private-fqdn> 5432
   ```

3. 네트워크 경로 및 연결 지속성 진단
   - Pod 내부에서 다음 명령어로 네트워크 경로 및 연결 상태 확인
     ```bash
     # 라우팅 테이블 확인
     ip route
     # DNS 확인
     nslookup <postgres-private-fqdn>
     # 트레이스 경로
     traceroute <postgres-private-fqdn>
     # 연결 지속성 테스트
     while true; do psql -h <postgres-private-fqdn> -U <dbuser> -d <dbname> -c 'select 1'; sleep 5; done
     ```

4. 연결 끊김 발생 시 진단 포인트
   - NSG, UDR, Firewall, Private DNS, VNet Peering 설정 확인
   - AKS 노드 Outbound 설정 (NAT Gateway, Load Balancer)
   - PostgreSQL 서버 Connection Limit, Idle Timeout 등 파라미터 확인
   - Azure Portal의 Network Watcher, Connection Monitor 활용

---
이 가이드를 통해 Bastion 서버에서 AKS 클러스터 접근 및 네트워크 경로, 연결 지속성 등 다양한 진단을 수행할 수 있습니다.

요청사항)
1. AKS pod(Spoke Vnet) 가 postgres(Hub Vnet) 를 이용할 수 있게 보장하고자 할때 고려 사항
   예) 보안, AKS 노드에서 postgres 로 나가는 트래픽을 NAT 처리 (Outbound Load Balancer)
2. App (AKS pod)에서 postgres(Hub Vnet) 까지의 각종 Network 테스트 시나리오 수행을 위한 POD 배포 및 테스트 수행


AKS (Spoke VNet)에 배포된 애플리케이션 Pod가 Hub VNet 내 PostgreSQL 서버와 통신 중 발생하는 연결 끊김 문제에 대해 환경 정보 수집, 네트워크 경로 진단, Pod-to-DB 경로 IP 및 연결 지속성을 포함한 트러블슈팅을 하고 싶은데, 이를 위한 환경 구성 (샘플Pod 배포)를 할 수 있을까?
