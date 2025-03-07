#!/bin/bash
set -e

# 변수 설정
SUBSCRIPTION_ID="<your-subscription-id>"
RESOURCE_GROUP_SPOKE="rg-spoke"
AKS_CLUSTER_NAME="aks-cluster"
LOG_ANALYTICS_WORKSPACE="log-analytics-aks"
LOG_ANALYTICS_SKU="PerGB2018"
LOG_ANALYTICS_RETENTION_DAYS=30

# Azure 로그인
echo "Azure에 로그인합니다..."
az login
az account set --subscription $SUBSCRIPTION_ID

# AKS 자격 증명 가져오기
echo "AKS 자격 증명을 가져옵니다..."
az aks get-credentials --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER_NAME --overwrite-existing

# Log Analytics 워크스페이스 생성
echo "Log Analytics 워크스페이스 생성..."
az monitor log-analytics workspace create \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --workspace-name $LOG_ANALYTICS_WORKSPACE \
  --sku $LOG_ANALYTICS_SKU \
  --retention-time $LOG_ANALYTICS_RETENTION_DAYS

# Log Analytics 워크스페이스 ID 가져오기
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --workspace-name $LOG_ANALYTICS_WORKSPACE \
  --query id -o tsv)

# AKS 모니터링 활성화
echo "AKS 모니터링 활성화..."
az aks enable-addons \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --name $AKS_CLUSTER_NAME \
  --addons monitoring \
  --workspace-resource-id $WORKSPACE_ID

# Prometheus 및 Grafana 설치
echo "Prometheus 및 Grafana 설치..."
kubectl create namespace monitoring

# Helm 리포지토리 추가
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Prometheus 및 Grafana 설치
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.enabled=true \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

# Grafana 서비스를 LoadBalancer로 변경
kubectl patch svc prometheus-grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'

# Grafana 접속 정보 확인
echo "Grafana 접속 정보 확인..."
GRAFANA_PASSWORD=$(kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode)
GRAFANA_IP=$(kubectl get svc prometheus-grafana -n monitoring -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

echo "Grafana 접속 URL: http://$GRAFANA_IP"
echo "Grafana 사용자 이름: admin"
echo "Grafana 비밀번호: $GRAFANA_PASSWORD"

# Azure Monitor 대시보드 생성
echo "Azure Monitor 대시보드 생성..."
DASHBOARD_NAME="AKS-Monitoring-Dashboard"

az portal dashboard create \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --name $DASHBOARD_NAME \
  --input-path - << EOF
{
  "lenses": {
    "0": {
      "order": 0,
      "parts": {
        "0": {
          "position": {
            "x": 0,
            "y": 0,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "resourceTypeMode",
                "isOptional": true,
                "value": "workspace"
              },
              {
                "name": "ComponentId",
                "isOptional": true,
                "value": {
                  "SubscriptionId": "$SUBSCRIPTION_ID",
                  "ResourceGroup": "$RESOURCE_GROUP_SPOKE",
                  "Name": "$LOG_ANALYTICS_WORKSPACE",
                  "ResourceId": "$WORKSPACE_ID"
                }
              },
              {
                "name": "Query",
                "isOptional": true,
                "value": "Perf\n| where ObjectName == \"K8SNode\"\n| where CounterName == \"cpuUsageNanoCores\"\n| summarize CPUUsage = avg(CounterValue) by Computer, bin(TimeGenerated, 1m)\n| render timechart"
              },
              {
                "name": "TimeRange",
                "isOptional": true,
                "value": "PT1H"
              },
              {
                "name": "Dimensions",
                "isOptional": true,
                "value": {
                  "xAxis": {
                    "name": "TimeGenerated",
                    "type": "datetime"
                  },
                  "yAxis": [
                    {
                      "name": "CPUUsage",
                      "type": "real"
                    }
                  ],
                  "splitBy": [
                    {
                      "name": "Computer",
                      "type": "string"
                    }
                  ],
                  "aggregation": "Sum"
                }
              },
              {
                "name": "Version",
                "isOptional": true,
                "value": "1.0"
              },
              {
                "name": "DashboardId",
                "isOptional": true,
                "value": "$DASHBOARD_NAME"
              },
              {
                "name": "PartId",
                "isOptional": true,
                "value": "node-cpu-usage"
              },
              {
                "name": "PartTitle",
                "isOptional": true,
                "value": "노드 CPU 사용량"
              },
              {
                "name": "PartSubTitle",
                "isOptional": true,
                "value": "$AKS_CLUSTER_NAME"
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
            "settings": {}
          }
        },
        "1": {
          "position": {
            "x": 6,
            "y": 0,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "resourceTypeMode",
                "isOptional": true,
                "value": "workspace"
              },
              {
                "name": "ComponentId",
                "isOptional": true,
                "value": {
                  "SubscriptionId": "$SUBSCRIPTION_ID",
                  "ResourceGroup": "$RESOURCE_GROUP_SPOKE",
                  "Name": "$LOG_ANALYTICS_WORKSPACE",
                  "ResourceId": "$WORKSPACE_ID"
                }
              },
              {
                "name": "Query",
                "isOptional": true,
                "value": "Perf\n| where ObjectName == \"K8SNode\"\n| where CounterName == \"memoryRssBytes\"\n| summarize MemoryUsage = avg(CounterValue) by Computer, bin(TimeGenerated, 1m)\n| render timechart"
              },
              {
                "name": "TimeRange",
                "isOptional": true,
                "value": "PT1H"
              },
              {
                "name": "Dimensions",
                "isOptional": true,
                "value": {
                  "xAxis": {
                    "name": "TimeGenerated",
                    "type": "datetime"
                  },
                  "yAxis": [
                    {
                      "name": "MemoryUsage",
                      "type": "real"
                    }
                  ],
                  "splitBy": [
                    {
                      "name": "Computer",
                      "type": "string"
                    }
                  ],
                  "aggregation": "Sum"
                }
              },
              {
                "name": "Version",
                "isOptional": true,
                "value": "1.0"
              },
              {
                "name": "DashboardId",
                "isOptional": true,
                "value": "$DASHBOARD_NAME"
              },
              {
                "name": "PartId",
                "isOptional": true,
                "value": "node-memory-usage"
              },
              {
                "name": "PartTitle",
                "isOptional": true,
                "value": "노드 메모리 사용량"
              },
              {
                "name": "PartSubTitle",
                "isOptional": true,
                "value": "$AKS_CLUSTER_NAME"
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
            "settings": {}
          }
        }
      }
    }
  },
  "metadata": {
    "model": {
      "timeRange": {
        "value": {
          "relative": {
            "duration": 24,
            "timeUnit": 1
          }
        },
        "type": "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
      }
    }
  }
}
EOF

echo "모니터링 설정이 완료되었습니다." 