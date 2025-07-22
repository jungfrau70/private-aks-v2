다음은 지금까지 논의된 내용을 모두 포괄하는 AKS 네트워크 및 DB 연결 진단 스크립트입니다:

---

### ✅ 주요 목적

* **AKS 네트워크 구성** 정보 확인
* **Pod가 어떤 IP로 DB에 접근하는지** 확인
* **Outbound 경로 확인 (trace route 포함)**
* **PostgreSQL / Oracle DB 연결 테스트**
* **간헐적 세션 끊김을 감지하기 위한 반복 테스트**
* **로그 파일에 모든 결과 저장**

---

### 📜 스크립트 개요 (Helm 사용 제외, Bash 기반)


cat <<'EOF' > 1.sh
#!/bin/bash

# === CONFIGURATION ===
RESOURCE_GROUP="rg-spoke"
AKS_NAME="aks-cluster"
RG_NAME="rg-spoke"

DB_HOST="pgsql-hub-server-20250722-01.postgres.database.azure.com"         # 예시: Azure Database for PostgreSQL Flexible Server Private IP
DB_PORT_PG=5432

PG_USER="pgadmin"
PG_DB="postgres"
PG_PASS="P@ssw0rd1234!"

DB_PORT_ORA=1521
ORA_USER="oraadmin"
ORA_PASS="orapassword"
ORA_SERVICE_NAME="orclpdb1"

CHECK_INTERVAL=10
DURATION=600  # 테스트 지속 시간 (초)
LOGFILE="connectivity_test.log"

# === LOGGING ===
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a "$LOGFILE"
}

# ⚙️ Azure 로그인 상태 확인
echo -e "\n🔐 Azure 로그인 상태:"
az account show --output table

# 🔍 AKS 클러스터 기본 정보
echo -e "\n📦 AKS 클러스터 정보:"
az aks show -g "$RESOURCE_GROUP" -n "$AKS_NAME" \
  --query "{Name:name, Location:location, NetworkProfile:networkProfile}" \
  --output table

# 🎯 노드 리소스 그룹 이름 추출
NODE_RG=$(az aks show -g "$RESOURCE_GROUP" -n "$AKS_NAME" \
  --query nodeResourceGroup -o tsv)
echo -e "\n📂 노드 리소스 그룹: $NODE_RG"

# 🌐 AKS 서브넷 및 VNet 정보
SUBNET_ID=$(az aks show -g "$RESOURCE_GROUP" -n "$AKS_NAME" \
  --query 'networkProfile.podCidr' -o tsv)
VNET_NAME=$(az network vnet list -g "$NODE_RG" \
  --query '[0].name' -o tsv)
echo -e "\n🌐 VNet 이름: $VNET_NAME"

# 📡 Outbound 방식 확인
echo -e "\n📤 Outbound 구성 방식:"
az aks show -g "$RESOURCE_GROUP" -n "$AKS_NAME" \
  --query "networkProfile.outboundType" -o tsv

# 📠 Load Balancer 또는 NAT Gateway 확인
echo -e "\n🔍 LB 또는 NAT Gateway:"
az network public-ip list -g "$NODE_RG" \
  --query "[].{Name:name, IP:ipAddress, AllocationMethod:publicIPAllocationMethod}" \
  -o table

# 🔒 NSG (Network Security Group) 리스트 확인
echo -e "\n🔐 NSG 목록:"
az network nsg list -g "$NODE_RG" \
  --query "[].{Name:name, Location:location}" \
  -o table

# 📜 UDR (User Defined Routes) 확인
echo -e "\n📜 User Defined Routes:"
az network route-table list -g "$NODE_RG" \
  --query "[].{Name:name, Routes:routes}" -o json

# 🌎 Public IP 확인 (Pod 기준)
echo -e "\n🌍 multitool Pod의 Public IP 확인:"
POD=$(kubectl get pods -l app=multitool -o jsonpath="{.items[0].metadata.name}")
kubectl exec "$POD" -- curl -s ifconfig.me || echo "❌ 실패"

# === NETWORK 정보 수집 ===
check_aks_network_info() {
    log "🔎 Checking AKS VNet and Outbound Type..."
    az aks show --name $AKS_NAME --resource-group $RG_NAME --query '{vnet:networkProfile.vnetSubnetId, outboundType:networkProfile.outboundType}' -o table
}

check_public_ips() {
    log "🌐 Listing Azure Public IPs..."
    az network public-ip list --query "[?ipConfiguration.id!=null].{ip: ipAddress, name: name}" -o table
}

check_nsg_and_udr() {
    log "🛡  Listing NSG and UDR configurations..."
    az network nsg list -g $RG_NAME --query "[].{name: name, rules: securityRules}" -o table
    az network route-table list -g $RG_NAME -o table
}

# === 네트워크 툴 배포 ===
deploy_network_tool() {
    log "🚀 Deploying network-multitool pod..."
    cat <<EOF2 | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: network-test
spec:
  containers:
  - name: multitool
    image: praqma/network-multitool
    command: ["sleep"]
    args: ["infinity"]
EOF2
}

get_pod_ip_and_exec() {
    log "📡 Getting Pod external IP..."
    kubectl wait --for=condition=Ready pod/network-test --timeout=60s
    POD_IP=$(kubectl exec network-test -- curl -s ifconfig.me)
    log "External IP of Pod: $POD_IP"
}

# === 연결 경로 / 포트 테스트 ===
trace_route() {
    log "🔁 Traceroute to $DB_HOST..."
    kubectl exec network-test -- traceroute $DB_HOST
}

tcp_connect_test() {
    log "🔌 TCP connection test to $DB_HOST:$1"
    kubectl exec network-test -- bash -c "timeout 5 bash -c '</dev/tcp/$DB_HOST/$1' && echo ✅ Connected || echo ❌ Failed"
}

# === DB 연결 테스트 ===
run_pg_test() {
    log "🐘 Testing PostgreSQL Connection..."
    kubectl exec network-test -- bash -c "PGPASSWORD='$PG_PASS' psql -h $DB_HOST -U $PG_USER -d $PG_DB -c 'SELECT now();'"
}

run_ora_test() {
    log "🏛  Testing Oracle Connection..."
    kubectl exec network-test -- bash -c "echo 'SELECT SYSDATE FROM DUAL; EXIT;' | sqlplus $ORA_USER/$ORA_PASS@//$DB_HOST:$DB_PORT_ORA/$ORA_SERVICE_NAME"
}

# === 지속 세션 감시 ===
start_session_watch() {
    log "📊 Starting session stability test for $DURATION seconds..."
    END=$((SECONDS+DURATION))
    while [ $SECONDS -lt $END ]; do
        TIME=$(date '+%Y-%m-%d %H:%M:%S')
        kubectl exec network-test -- bash -c "</dev/tcp/$DB_HOST/$DB_PORT_PG" \
            && echo \"$TIME ✅ OK\" >> "$LOGFILE" \
            || echo \"$TIME ❌ Failed or Timeout\" >> "$LOGFILE"
        sleep "$CHECK_INTERVAL"
    done
}

# === 전체 실행 흐름 ===
log "🚧 Starting AKS to DB connectivity diagnostic script..."

check_aks_network_info
check_public_ips
check_nsg_and_udr
deploy_network_tool
sleep 5
get_pod_ip_and_exec
trace_route
tcp_connect_test $DB_PORT_PG
tcp_connect_test $DB_PORT_ORA
run_pg_test
run_ora_test
start_session_watch

log "✅ Script completed. Results logged to $LOGFILE"
EOF


# === 전체 실행 흐름 ===
log "🚧 Starting AKS to DB connectivity diagnostic script..."

check_aks_network_info
check_public_ips
check_nsg_and_udr
deploy_network_tool
sleep 5
get_pod_ip_and_exec
trace_route
tcp_connect_test $DB_PORT_PG
tcp_connect_test $DB_PORT_ORA
run_pg_test
run_ora_test
start_session_watch

log "✅ Script completed. Results logged to $LOGFILE"
```

---

### 🔍 진단 포인트 정리

| 항목                   | 설명                                        |
| -------------------- | ----------------------------------------- |
| AKS Outbound Type    | `loadBalancer`, `userDefinedRouting` 등 확인 |
| NSG/UDR              | DB 연결 차단 여부 점검                            |
| Pod 외부 IP            | DB 로그 상 실제 확인 필요                          |
| Traceroute           | Path 분석 (FW, LB, UDR 영향 여부)               |
| TCP 포트 테스트           | 연결 가능 여부 및 latency 추정                     |
| PostgreSQL/Oracle 연결 | 실제 인증·쿼리 테스트                              |
| 세션 연결 지속성            | 간헐적 끊김 여부 확인                              |

---

### 📝 사용법

1. 위 스크립트를 `connectivity_diagnostic.sh` 등으로 저장
2. 필요한 파라미터 설정 (`AKS_NAME`, `DB_HOST`, `PG_USER`, 등)
3. 실행: `chmod +x connectivity_diagnostic.sh && ./connectivity_diagnostic.sh`
4. 결과 확인: `cat connectivity_test.log`

---

필요 시 아래 항목 추가도 가능합니다:

* DNS 확인
* curl을 이용한 HTTPS 연결 검증
* Istio/CNI/Calico 네트워크 정책 확인 등

도움이 더 필요하시면 말씀해 주세요.

---

### 🛠️ 실무 팁 및 고급 트러블슈팅

- **Pod에 네트워크 도구가 없을 때**
  - multitool, ubuntu, bitnami/postgresql 등 이미지로 Pod 생성
  - 또는 아래처럼 직접 설치:
    - Ubuntu/Debian: `apt update && apt install -y tcpdump traceroute mtr`
    - CentOS/RHEL: `yum install -y tcpdump traceroute mtr`
    - Alpine: `apk add tcpdump traceroute mtr`
- **네임스페이스가 다르면**
  - `kubectl exec -n <NAMESPACE> <POD_NAME> -- ...`
  - `kubectl cp <NAMESPACE>/<POD_NAME>:/tmp/trace.pcap ./trace.pcap`
- **특정 Pod에서만 진단하고 싶을 때**
  - `kubectl exec <POD_NAME> -- ...` (위 명령에서 network-test 대신 원하는 Pod명)
- **Oracle 연결은 sqlplus 내장 이미지(ghcr.io/gvenzl/oracle-xe 등) 사용 권장**
- **반복 연결/세션 끊김 자동화**
  - conn_test.sh 등 자동화 스크립트 활용 (로그와 콘솔 동시 출력)
- **패킷 캡처 후 분석**
  - Wireshark에서 `trace.pcap` 열고, RST/FIN/Timeout/손실 등 필터링
  - 예시: `tcp.port == 5432 || tcp.port == 1521`, `tcp.flags.reset == 1`
- **SNAT 포트 소진/네트워크 품질**
  - Azure Log Analytics 쿼리로 진단
- **실시간 모니터링/알림**
  - Prometheus, Grafana, Slack/E-mail 연동 등 확장 가능

---

### 📦 자동화/확장 예시

- 모든 진단 명령을 하나의 `.sh`로 통합하여 반복 실행/로그 저장
- 진단 결과를 Markdown, PDF, HTML 등 다양한 포맷으로 자동 변환
- CI/CD 파이프라인(예: GitHub Actions)에서 네트워크/DB 연결 사전 점검 자동화
- 필요시 Ansible, Python 등으로 진단 모듈화 가능

---

> 현장 상황에 따라 Pod 이미지, 네임스페이스, DB 정보, 도구 설치 방법 등을 유연하게 조정하세요.
> 추가 진단/자동화/문서화 요청은 언제든 가능합니다.
