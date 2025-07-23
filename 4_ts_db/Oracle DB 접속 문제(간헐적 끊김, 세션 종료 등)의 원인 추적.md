

############################################################################################################################
# Oracle DB 접속 문제(간헐적 끊김, 세션 종료 등)의 원인 추적
############################################################################################################################

---

## ✅ 목적

* 네트워크/세션 상태를 주기적으로 수집
* 로그에 시간, 상태, 오류 메세지를 명확하게 기록
* JDBC 접속을 지속적으로 모니터링하면서 실패 패턴 확인
* 로그를 외부로 추출하거나 `kubectl logs`로 분석 가능

---

## 📜 고도화된 `entrypoint.sh`

```bash
#!/bin/sh

LOG_FILE="/var/log/oracle-conn-monitor.log"
JDBC_CLASS="OracleKeepAliveTest"
JAR_PATH="/app/ojdbc8.jar"
CHECK_INTERVAL=60  # 초 단위

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a "$LOG_FILE"
}

log "🔎 [START] Oracle Connection Monitoring Script"

# 기본 정보 확인
log "📡 Host IP: $(hostname -i)"
log "📡 Pod Name: $(hostname)"
log "📡 Starting net diagnostics"
ip addr | tee -a "$LOG_FILE"
netstat -ntp | tee -a "$LOG_FILE"

log "🚀 Starting JDBC Connection Loop"

while true; do
    log "🔁 [TRY] Connecting via JDBC..."
    java -cp ".:$JAR_PATH" "$JDBC_CLASS" >> "$LOG_FILE" 2>&1

    if [ $? -eq 0 ]; then
        log "✅ [SUCCESS] JDBC Connection Succeeded"
    else
        log "❌ [FAIL] JDBC Connection Failed"
    fi

    log "⏳ Sleeping for $CHECK_INTERVAL seconds..."
    sleep "$CHECK_INTERVAL"
done
```

---

## 💡 `OracleKeepAliveTest.java` (요약)

이 파일은 다음 조건을 포함해야 합니다:

```java
// OracleKeepAliveTest.java

import java.sql.*;
public class OracleKeepAliveTest {
    public static void main(String[] args) {
        String jdbcUrl = "jdbc:oracle:thin:@//10.241.185.68:1521/YOUR_SERVICE_NAME";
        String username = "YOUR_USER";
        String password = "YOUR_PASSWORD";
        try (Connection conn = DriverManager.getConnection(jdbcUrl, username, password)) {
            System.out.println("✅ Connection successful at " + new java.util.Date());
        } catch (SQLException e) {
            System.err.println("❌ Connection failed: " + e.getMessage());
        }
    }
}
```

---

## 📤 로그 분석 팁

### `kubectl logs`로 확인

```bash
kubectl logs <pod-name> -n <namespace>
```

### 실패 로그 필터링

```bash
kubectl logs <pod> | grep FAIL
```

### 특정 시간 범위 분석

```bash
kubectl logs <pod> | awk '/2025-07-22 09:/,/2025-07-22 10:/'
```

---

############################################################################################################################
# 추가 선택 기능
############################################################################################################################


---

## ✅ 주요 추가 기능 요약

| 기능                      | 구현 방법                                                           |
| ----------------------- | --------------------------------------------------------------- |
| 🧪 DB Latency 측정        | `SELECT SYSDATE FROM DUAL` 쿼리 실행 시간 측정                          |
| 🧠 SNAT 포트 상태 추적        | `/proc/net/nf_conntrack`에서 `dport=1521` 또는 대상 IP로 연결된 세션 카운트 기록 |
| 🛑 idle timeout 감지 및 알림 | 실패 횟수, 실패 간격 측정 → 일정 횟수 이상 실패 시 Slack 알림 (옵션: curl 통한 webhook)  |

---

## 📜 `entrypoint.sh` (고도화 버전)

```bash
#!/bin/sh

LOG_FILE="/var/log/oracle-conn-monitor.log"
JDBC_CLASS="OracleKeepAliveTest"
JAR_PATH="/app/ojdbc8.jar"
CHECK_INTERVAL=60  # seconds
FAIL_COUNT=0
FAIL_THRESHOLD=3  # consecutive failures before alert
SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL:-""}  # optional

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a "$LOG_FILE"
}

send_slack_alert() {
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"🔴 Oracle DB Connection Error Detected in Pod $(hostname) after $FAIL_COUNT consecutive failures\"}" \
            "$SLACK_WEBHOOK_URL"
    fi
}

check_snat_usage() {
    log "🔍 SNAT 상태 추적 중..."
    grep '10.241.185.68' /proc/net/nf_conntrack 2>/dev/null | wc -l | \
        xargs -I {} echo "📊 SNAT 연결 수 (1521 대상): {}" | tee -a "$LOG_FILE"
}

log "🔎 [START] Oracle Connection Monitoring Script"
log "📡 Host IP: $(hostname -i)"
log "📡 Pod Name: $(hostname)"
log "📡 Starting diagnostics"
ip addr | tee -a "$LOG_FILE"
netstat -ntp | tee -a "$LOG_FILE"

while true; do
    log "🔁 [TRY] Connecting via JDBC..."

    # SNAT 상태 추적
    check_snat_usage

    # JDBC 연결 및 latency 측정
    START=$(date +%s%3N)
    OUT=$(java -cp ".:$JAR_PATH" "$JDBC_CLASS" 2>&1)
    RESULT=$?
    END=$(date +%s%3N)
    LATENCY=$((END - START))

    if [ $RESULT -eq 0 ]; then
        log "✅ [SUCCESS] JDBC Connection"
        log "⏱️ DB Latency: ${LATENCY}ms"
        FAIL_COUNT=0
    else
        log "❌ [FAIL] JDBC Connection Failed"
        log "⚠️ Error: $OUT"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        if [ $FAIL_COUNT -ge $FAIL_THRESHOLD ]; then
            log "🚨 Consecutive Failures Reached: $FAIL_COUNT"
            send_slack_alert
        fi
    fi

    log "⏳ Sleeping for $CHECK_INTERVAL seconds..."
    sleep "$CHECK_INTERVAL"
done
```

---

## 📁 `OracleKeepAliveTest.java` (latency 측정 가능한 쿼리 포함)

```java
import java.sql.*;

public class OracleKeepAliveTest {
    public static void main(String[] args) {
        String jdbcUrl = "jdbc:oracle:thin:@//10.241.185.68:1521/YOUR_SERVICE_NAME";
        String username = "YOUR_USER";
        String password = "YOUR_PASSWORD";

        try (Connection conn = DriverManager.getConnection(jdbcUrl, username, password)) {
            PreparedStatement stmt = conn.prepareStatement("SELECT SYSDATE FROM DUAL");
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                System.out.println("✅ DB SYSDATE: " + rs.getString(1));
            }
        } catch (SQLException e) {
            System.err.println("❌ Connection failed: " + e.getMessage());
            System.exit(1);  // non-zero exit to mark failure
        }
    }
}
```

---


## 🔍 로그 예시 출력 (kubectl logs)

```text
2025-07-22 12:00:00 | 🔁 [TRY] Connecting via JDBC...
2025-07-22 12:00:00 | 📊 SNAT 연결 수 (1521 대상): 7
2025-07-22 12:00:00 | ✅ [SUCCESS] JDBC Connection
2025-07-22 12:00:00 | ⏱️ DB Latency: 145ms
```

```text
2025-07-22 12:01:00 | ❌ [FAIL] JDBC Connection Failed
2025-07-22 12:01:00 | ⚠️ Error: ORA-03113: end-of-file on communication channel
2025-07-22 12:01:00 | 🚨 Consecutive Failures Reached: 3
```

---
