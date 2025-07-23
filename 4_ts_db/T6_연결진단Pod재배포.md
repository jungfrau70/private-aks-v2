아래는 `tcptraceroute` 및 네트워크 진단 도구가 설치된 Pod를 배포하기 위한 **Deployment YAML**입니다.
아래 예시를 참조 마이데이터 pod 에 `NET_RAW` 권한이 부여하여 배포하면 `tcptraceroute`, `ping`, `curl` 등을 테스트 할 수 있습니다.

        securityContext:
          capabilities:
            add: ["NET_RAW"]

---

## ✅ 진단용 Deployment YAML

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: net-diagnoser
  labels:
    app: net-diagnoser
spec:
  replicas: 1
  selector:
    matchLabels:
      app: net-diagnoser
  template:
    metadata:
      labels:
        app: net-diagnoser
    spec:
      containers:
      - name: diagnoser
        image: debian:bullseye
        command: [ "sleep", "infinity" ]
        securityContext:
          capabilities:
            add: ["NET_RAW"]
        resources:
          limits:
            memory: "256Mi"
            cpu: "250m"
        volumeMounts:
        - name: tools
          mountPath: /entrypoint
      volumes:
      - name: tools
        emptyDir: {}
      restartPolicy: Always
```

---

## ✅ 배포 방법

```bash
kubectl apply -f net-diagnoser.yaml
```

---

## ✅ 도구 설치 예시 (Pod 내부에서)

```bash
kubectl exec -it deploy/net-diagnoser -c diagnoser -- bash
```

```bash
apt update
apt install -y iputils-ping tcptraceroute curl net-tools dnsutils openjdk-17-jdk
```

---

## ✅ 진단 예시

```bash
tcptraceroute 10.241.185.68 1521
ping 10.241.185.68
curl -v telnet://10.241.185.68:1521
```

---


## 보안 유의사항

NET_RAW 권한은 보안상 민감할 수 있으므로, 반드시 운영용 Pod가 아닌 진단용 Pod에만 설정하세요.
실행 후에는 리소스를 정리하거나 해당 Pod를 삭제하는 것이 좋습니다.