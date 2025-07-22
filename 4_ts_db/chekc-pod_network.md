cat <<'EOF' > 2.sh
#!/bin/bash

# 네임스페이스 지정 (필요시 수정)
NAMESPACE=default
# Pod 라벨 또는 이름 지정
POD=$(kubectl get pods -n $NAMESPACE -l app=network-multitool -o jsonpath="{.items[0].metadata.name}")
DB_HOST="pgsql-hub-server-20250722-01.postgres.database.azure.com"
DB_PORT=5432
PG_USER="pgadmin"
PG_DB="postgres"
PG_PASS="P@ssw0rd1234!"

if [ -z "$POD" ]; then
  echo "❌ network-multitool Pod를 찾을 수 없습니다. 라벨 또는 네임스페이스를 확인하세요."
  exit 1
fi

echo "📌 대상 Pod: $POD (namespace: $NAMESPACE)"
echo "📌 대상 DB: $DB_HOST:$DB_PORT"

echo -e "\n✅ [1] 외부 IP 확인"
kubectl exec -n $NAMESPACE "$POD" -- curl -s ifconfig.me

echo -e "\n✅ [2] DNS 확인"
kubectl exec -n $NAMESPACE "$POD" -- nslookup "$DB_HOST"

echo -e "\n✅ [3] 포트 연결 테스트"
kubectl exec -n $NAMESPACE "$POD" -- nc -vz "$DB_HOST" "$DB_PORT"

echo -e "\n✅ [4] tracepath (경로 추적)"
kubectl exec -n $NAMESPACE "$POD" -- tracepath "$DB_HOST"

echo -e "\n✅ [5] 반복 연결 확인 (5회)"
for i in {1..5}; do
  kubectl exec -n $NAMESPACE "$POD" -- nc -vz "$DB_HOST" "$DB_PORT"
  sleep 2
done

# PostgreSQL 연결 테스트 (psql pod 자동 생성)
PG_POD=pg-client
kubectl get pod -n $NAMESPACE $PG_POD &>/dev/null || \
  kubectl run $PG_POD --image=bitnami/postgresql --restart=Never -n $NAMESPACE -- sleep infinity
kubectl wait pod -n $NAMESPACE $PG_POD --for=condition=Ready --timeout=60s

echo -e "\n✅ [6] PostgreSQL 실제 쿼리 테스트 (SELECT now())"
kubectl exec -n $NAMESPACE $PG_POD -- bash -c "export PGPASSWORD=$PG_PASS && psql -h $DB_HOST -U $PG_USER -d $PG_DB -c 'SELECT now();'"

echo -e "\n✅ [7] PostgreSQL 세션/상태 쿼리 예시"
kubectl exec -n $NAMESPACE -it $PG_POD -- bash -c "export PGPASSWORD=$PG_PASS && psql -h $DB_HOST -U $PG_USER -d $PG_DB <<EOSQL
SELECT count(*) FROM pg_stat_activity;
SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;
SELECT state, count(*) FROM pg_stat_activity GROUP BY state;
SELECT client_addr, count(*) FROM pg_stat_activity GROUP BY client_addr;
EOSQL"

echo -e "\n✅ [Tip] Oracle 테스트는 sqlplus 이미지 필요 (ghcr.io/gvenzl/oracle-xe 등)"
echo "kubectl run oracle-client --image=ghcr.io/gvenzl/oracle-xe --restart=Never -n $NAMESPACE -- sleep infinity"
echo "kubectl exec -n $NAMESPACE -it oracle-client -- sqlplus ..."

echo -e "\n[실무 팁]"
echo "- Pod에 도구가 없으면 multitool/ubuntu/bitnami-postgresql 이미지 사용 또는 apt/yum/apk로 설치"
echo "- 네임스페이스가 다르면 NAMESPACE 변수 수정"
echo "- 반복 진단, 로그 저장, 자동화 등은 필요에 따라 추가"
EOF
