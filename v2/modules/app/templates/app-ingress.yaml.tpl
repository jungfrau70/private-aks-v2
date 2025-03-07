apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${app_name}
  annotations:
    %{ if use_agic }
    kubernetes.io/ingress.class: azure/application-gateway
    appgw.ingress.kubernetes.io/request-timeout: "30"
    appgw.ingress.kubernetes.io/connection-draining: "true"
    appgw.ingress.kubernetes.io/connection-draining-timeout: "30"
    %{ if enable_tls }
    appgw.ingress.kubernetes.io/ssl-redirect: "true"
    %{ endif }
    %{ else }
    kubernetes.io/ingress.class: ${ingress_class}
    %{ endif }
spec:
  %{ if enable_tls }
  tls:
  - hosts:
    - ${app_host}
    secretName: ${tls_secret_name}
  %{ endif }
  rules:
  - host: ${app_host}
    http:
      paths:
      - path: ${app_path}
        pathType: Prefix
        backend:
          service:
            name: ${app_name}
            port:
              number: ${app_port} 