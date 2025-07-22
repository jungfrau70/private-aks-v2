apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${app_name}
  namespace: ${namespace_name}
  labels:
    app: ${app_name}
spec:
  replicas: ${app_replicas}
  selector:
    matchLabels:
      app: ${app_name}
  template:
    metadata:
      labels:
        app: ${app_name}
    spec:
      containers:
      - name: ${app_name}
        image: ${app_image}
        ports:
        - containerPort: ${app_port}
        resources:
          requests:
            cpu: ${app_cpu_request}
            memory: ${app_memory_request}
          limits:
            cpu: ${app_cpu_limit}
            memory: ${app_memory_limit}
        livenessProbe:
          httpGet:
            path: /
            port: ${app_port}
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: ${app_port}
          initialDelaySeconds: 5
          periodSeconds: 5
