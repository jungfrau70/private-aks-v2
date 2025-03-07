name: Build and Deploy

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

env:
  ACR_LOGIN_SERVER: ${acr_login_server}
  IMAGE_NAME: ${app_image_name}
  SOURCE_DIR: ${app_source_dir}
  RESOURCE_GROUP: ${{ secrets.RESOURCE_GROUP }}
  AKS_CLUSTER_NAME: ${{ secrets.AKS_CLUSTER_NAME }}
  NAMESPACE: ${namespace_name}

permissions:
  id-token: write
  contents: read

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
    
    - name: Azure Login with OIDC
      uses: azure/login@v1
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    
    - name: ACR Login
      run: |
        az acr login --name $(echo $ACR_LOGIN_SERVER | cut -d '.' -f 1)
    
    - name: Build and Push
      run: |
        cd $SOURCE_DIR
        IMAGE_TAG=$(date +%Y%m%d%H%M%S)
        echo "Building image: $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG"
        docker build -t $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG .
        docker push $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG
        echo "IMAGE_TAG=$IMAGE_TAG" >> $GITHUB_ENV
    
    - name: Set AKS Context
      run: |
        az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --admin
    
    - name: Create namespace if not exists
      run: |
        kubectl get namespace $NAMESPACE || kubectl create namespace $NAMESPACE
    
    - name: Generate Kubernetes manifests
      run: |
        # 애플리케이션 배포 매니페스트 생성
        cat > deployment.yaml << EOF
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: ${app_image_name}
          namespace: $NAMESPACE
        spec:
          replicas: 2
          selector:
            matchLabels:
              app: ${app_image_name}
          template:
            metadata:
              labels:
                app: ${app_image_name}
            spec:
              containers:
              - name: ${app_image_name}
                image: $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG
                ports:
                - containerPort: 80
                resources:
                  requests:
                    cpu: "100m"
                    memory: "128Mi"
                  limits:
                    cpu: "500m"
                    memory: "512Mi"
                livenessProbe:
                  httpGet:
                    path: /
                    port: 80
                  initialDelaySeconds: 30
                  periodSeconds: 10
                readinessProbe:
                  httpGet:
                    path: /
                    port: 80
                  initialDelaySeconds: 5
                  periodSeconds: 5
        EOF

        # 서비스 매니페스트 생성
        cat > service.yaml << EOF
        apiVersion: v1
        kind: Service
        metadata:
          name: ${app_image_name}
          namespace: $NAMESPACE
        spec:
          selector:
            app: ${app_image_name}
          ports:
          - port: 80
            targetPort: 80
          type: ClusterIP
        EOF

        # Ingress 매니페스트 생성 (AGIC 사용)
        cat > ingress.yaml << EOF
        apiVersion: networking.k8s.io/v1
        kind: Ingress
        metadata:
          name: ${app_image_name}
          namespace: $NAMESPACE
          annotations:
            kubernetes.io/ingress.class: azure/application-gateway
            appgw.ingress.kubernetes.io/request-timeout: "30"
            appgw.ingress.kubernetes.io/connection-draining: "true"
            appgw.ingress.kubernetes.io/connection-draining-timeout: "30"
        spec:
          rules:
          - http:
              paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: ${app_image_name}
                    port:
                      number: 80
        EOF
    
    - name: Deploy to AKS
      run: |
        kubectl apply -f deployment.yaml
        kubectl apply -f service.yaml
        kubectl apply -f ingress.yaml
    
    - name: Verify deployment
      run: |
        echo "Waiting for deployment to be ready..."
        kubectl rollout status deployment/${app_image_name} -n $NAMESPACE --timeout=180s
        
        echo "Deployment status:"
        kubectl get deployment ${app_image_name} -n $NAMESPACE
        
        echo "Service status:"
        kubectl get service ${app_image_name} -n $NAMESPACE
        
        echo "Ingress status:"
        kubectl get ingress ${app_image_name} -n $NAMESPACE
        
        echo "Application Gateway status:"
        APPGW_NAME=$(az network application-gateway list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv)
        az network application-gateway show --resource-group $RESOURCE_GROUP --name $APPGW_NAME --query "operationalState" -o tsv 