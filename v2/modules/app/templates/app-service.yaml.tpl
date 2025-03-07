apiVersion: v1
kind: Service
metadata:
  name: ${app_name}
spec:
  selector:
    app: ${app_name}
  ports:
  - port: ${app_port}
    targetPort: ${app_port}
  type: ClusterIP 